#include "TemperatureMonitor.h"
#include <message.h>

configuration TemperatureMonitorAppC {
}
implementation {

  components MainC;
  components new TimerMilliC() as TimerSink;
  components new TimerMilliC() as TimerSensor;

  components ActiveMessageC, new LplAMSenderC(AM_WEATHER_MONITOR), new AMReceiverC(AM_WEATHER_MONITOR);
  components new DemoSensorC() as TSensor;
  components new RandomC;

  //components PrintfC, SerialStartC;
  components TemperatureMonitorC as App;

  App.Boot -> MainC;
  App.Timer0 -> TimerSink;
  App.TimerN -> TimerSensor;

  App.AMSend -> LplAMSenderC;
  App.Receive -> AMReceiverC;
  App.Packet -> LplAMSenderC;
  App.AMPacket -> LplAMSenderC;
  App.AMControl -> ActiveMessageC;

  App.Temperature -> TSensor;
  App.Random -> Random;
}
