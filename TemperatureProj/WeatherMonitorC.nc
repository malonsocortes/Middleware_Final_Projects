#include "WeatherMonitor.h"

#include <printf.h>
#define PRINTF(...) printf(__VA_ARGS__); printfflush()

module WeatherMonitorC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer0;
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
    interface SplitControl as AMControl;
    interface Read<uint16_t> as Temperature;
    interface Read<uint16_t> as Humidity;
    interface Read<uint16_t> as LightPar;
    interface Read<uint16_t> as LightTsr;
    interface Read<uint16_t> as Volt;
  }
}

implementation {
  uint8_t readings_to_collect, collected_readings;
  uint16_t temperature, humidity, light_par, light_tsr, voltage;
  message_t pkt;
  bool busy;

  task void sendMsg() {
    WeatherMonitorMsg* msg;
    if(TOS_NODE_ID==0) {
      PRINTF("0 %d %d %d %d %d\n", temperature, humidity, light_par, light_tsr, voltage);
      return;
    }
    if(busy) return;
    PRINTF("Sending msg: %d %d %d %d %d %d\n", TOS_NODE_ID, temperature, humidity, light_par, light_tsr, voltage);

    msg = (WeatherMonitorMsg*) (call Packet.getPayload(&pkt, sizeof(WeatherMonitorMsg)));
    if(msg==NULL) return;
    msg->node_id = TOS_NODE_ID;
    msg->temperature = temperature;
    msg->humidity = humidity;
    msg->light_par = light_par;
    msg->light_tsr = light_tsr;
    msg->voltage = voltage;
    if (call AMSend.send(0, &pkt, sizeof(WeatherMonitorMsg))==SUCCESS) {
      busy = TRUE;
      call Leds.led0On();
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt==msg) {
      busy = FALSE;
      call Leds.led0Off();
    }
  }

  event void Boot.booted() {
    readings_to_collect = collected_readings = 0;
    temperature = humidity = light_par = light_tsr = voltage = 0;
    busy = FALSE;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      PRINTF("Node %d started\n", TOS_NODE_ID);
      call Timer0.startPeriodic(TIMER_PERIOD);
    } else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    call Timer0.stop();
    PRINTF("Node %d stopped\n", TOS_NODE_ID);
  }

  event void Timer0.fired() {
    call Leds.led2On();
    collected_readings = readings_to_collect = 0;
    if(call Temperature.read()==SUCCESS) readings_to_collect++;
    if(call Humidity.read()==SUCCESS) readings_to_collect++;
    if(call LightPar.read()==SUCCESS) readings_to_collect++;
    if(call LightTsr.read()==SUCCESS) readings_to_collect++;
    if(call Volt.read()==SUCCESS) readings_to_collect++;
  }

  event void Temperature.readDone(error_t result, uint16_t val) {
    collected_readings++;
    if(result == SUCCESS) {
      temperature = val-3960;  // celsius = -39.6 + T*0.01
      if(TOS_NODE_ID==3) temperature = (uint16_t) rintf(temperature + (2944.4-temperature)/55.76);
    }
    if(collected_readings==readings_to_collect) {
      call Leds.led2Off();
      post sendMsg();
    }
  }

  event void Humidity.readDone(error_t result, uint16_t val) {
    collected_readings++;
    if(result == SUCCESS) {
      humidity = (uint16_t) rintf((temperature/100.0-25.0)*(0.01+0.00008*val)-4.0+0.0405*val-0.0000028*val*val); // temp corrected humidity
    }
    if(collected_readings==readings_to_collect) {
      call Leds.led2Off();
      post sendMsg();
    }
  }

  // Vsensor = value/4096 * Vref where Vref = 1.5V
  // I = Vsensor / 100,000
  // S1087    lx = 0.625 * 1e6 * I * 1000 (photosynthetically-active radiation sensor)
  // S1087-01 lx = 0.769 * 1e5 * I * 1000 (total solar radiation sensor)
  event void LightPar.readDone(error_t result, uint16_t val) {
    collected_readings++;
    if(result == SUCCESS) {
      light_par = (uint16_t) (2.2888*((float)val));
    }
    if(collected_readings==readings_to_collect) {
      call Leds.led2Off();
      post sendMsg();
    }
  }

  event void LightTsr.readDone(error_t result, uint16_t val) {
    collected_readings++;
    if(result == SUCCESS) {
      light_tsr = (uint16_t) (0.281616*((float)val));
    }
    if(collected_readings==readings_to_collect) {
      call Leds.led2Off();
      post sendMsg();
    }
  }

  event void Volt.readDone(error_t result, uint16_t data) {
    collected_readings++;
    if(result == SUCCESS) {
      voltage = data*3000l/4096l;
    }
    if(collected_readings==readings_to_collect) {
      call Leds.led2Off();
      post sendMsg();
    }
  }

  event message_t* Receive.receive(message_t* p, void* payload, uint8_t len) {
    if (len == sizeof(WeatherMonitorMsg)) {
      WeatherMonitorMsg* msg = (WeatherMonitorMsg *) payload;
      call Leds.led1Toggle();
      PRINTF("%d %d %d %d %d %d\n", msg->node_id, msg->temperature, msg->humidity, msg->light_par, msg->light_tsr, msg->voltage);
    }
    return p;
  }
}
