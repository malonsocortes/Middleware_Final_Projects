#include "TemperatureMonitor.h"

#include <printf.h>
#define PRINTF(...) printf(__VA_ARGS__); printfflush()


module TemperatureMonitorC {
  uses {
    interface Boot;

    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;
    interface SplitControl as AMControl;

    interface Read<uint16_t> as Temperature;  /* Temperature measurements */

    interface Timer<TMilli> as TimerSink;     /* Period to send SETUP msg */
    interface Timer<TMilli> as TimerSensor;   /* Period to meassure Data */
    interface Random;                         /* Generates random threshold */
  }
}

implementation {
  uint16_t threshold, temperature;
  message_t pkt;
  bool busy;


  task void sendSETUP_msg() {

    SETUP_msg * msg;

    if(TOS_NODE_ID==0) {

      if(busy) return;

      threshold = (call Random.rand16 % 100) + 30

      PRINTF("0 new threshold %d\n", threshold);
      PRINTF("Sending SETUP msg: %d %d\n", TOS_NODE_ID, threshold);

      msg = (SETUP_msg*) (call Packet.getPayload(&pkt, sizeof(SETUP_msg)));
      if (msg == NULL) return;
      msg->threshold = threshold;

      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(SETUP_msg))==SUCCESS) {
        busy = TRUE;
      }
    }
  }

  task void sendDATA_msg() {

    DATA_msg * msg;

    if(TOS_NODE_ID != 0){

      if(busy) return;

      PRINTF("Sending DATA msg: %d %d\n", TOS_NODE_ID, temperature);

      msg = (DATA_msg*) (call Packet.getPayload(&pkt), sizeof(DATA_msg));
      if( msg == NULL) return;
      msg->node_id = TOS_NODE_ID;
      msg->temperature = temperature;

      if(call AMSend.send(0, &pkt, sizeof(DATA_msg)) == SUCCESS){
        busy = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt==msg && err == SUCCESS) {
      busy = FALSE;
    }
  }

  //***************************** Boot Interface *****************************//
  event void Boot.booted() {
    /* Sensor nodes set the threshold to a maxvalue before receiving the Setup Message from sink node */
    threshold = MAX_THRESHOLD;

    temperature = 0;
    busy = FALSE;

    dbg("boot", "Application booted.\n");
    call AMControl.start();
  }

  //*************************** AMControl Interface **************************//
  event void AMControl.startDone(error_t err){

    if (err == SUCCESS) {

      dbg("radio", "Radio on.\n");
      PRINTF("Node %d started\n", TOS_NODE_ID);

      if(TOS_NODE_ID == 0){
        call TimerSink.startPeriodic(TIMER_SINK_PERIOD);
      }
      else{
        call TimerSensor.startPeriodic(TIMER_SENSOR_PERIOD);
      }
    } else {
      call AMControl.start();
    }
  }

  event void TimerSink.fired(){
    post sendSETUPMsg();
  }

}
