#include "WeatherMonitor.h"
#include <message.h>

configuration WeatherMonitorAppC {
}
implementation {
  components MainC;
  components NoLedsC as LedsC;
  components new TimerMilliC() as Timer0;

  components ActiveMessageC, new LplAMSenderC(AM_WEATHER_MONITOR), new AMReceiverC(AM_WEATHER_MONITOR);

  components new HamamatsuS1087ParC(), new HamamatsuS10871TsrC(), new SensirionSht11C(), new Msp430InternalVoltageC();
  components PrintfC, SerialStartC;
  components WeatherMonitorC as App;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;

  App.AMSend -> LplAMSenderC;
  App.Receive -> AMReceiverC;
  App.Packet -> LplAMSenderC;
  App.AMPacket -> LplAMSenderC;
  App.AMControl -> ActiveMessageC;

  App.Temperature -> SensirionSht11C.Temperature;
  App.Humidity -> SensirionSht11C.Humidity;
  App.LightPar -> HamamatsuS1087ParC;
  App.LightTsr -> HamamatsuS10871TsrC;
  App.Volt -> Msp430InternalVoltageC;
}
