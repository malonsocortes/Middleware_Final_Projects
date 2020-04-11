/**
* Configuration file. Wires the TenperatureMonitorC component to other
* TinyOS components.
*
* @author Marina Alonso-Cortes
* @author Saul Almazan
* @author Jorge Santisteban
*/
#include "TemperatureMonitor.h"
#include <message.h>

configuration TemperatureMonitorAppC {
}
implementation {

  components TemperatureMonitorC as App;
  components MainC;
  components new TimerMilliC() as TimerSink;
  components new TimerMilliC() as TimerSensor;

  App.Boot -> MainC;
  App.Timer0 -> TimerSink;
  App.TimerN -> TimerSensor;

  components new AMSenderC(AM_WEATHER_MONITOR);
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMSend -> AMSenderC;

  components new AMReceiverC(AM_WEATHER_MONITOR);
  App.Receive -> AMReceiverC;

  components new TemperatureSensorC() as TSensor;
  App.Temperature -> TSensor;

  components ActiveMessageC;
  App.AMControl -> ActiveMessageC;

  components new RandomC;
  App.Random -> RandomC;

}
