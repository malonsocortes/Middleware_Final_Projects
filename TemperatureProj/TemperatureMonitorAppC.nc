/**
* Configuration file. Wires the TenperatureMonitorC component to other
* TinyOS components.
*
* @author Saul Almazan del Pie
* @author Marina Alonso-Cortes Lledo
* @author Jorge Santisteban Rivas
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
  components new TimerMilliC() as WaitingTimer;

  App.Boot -> MainC;
  App.TimerSink -> TimerSink;
  App.TimerSensor -> TimerSensor;
  App.WaitingTimer -> WaitingTimer;

  components new AMSenderC(AM_TEMPERATURE_MONITOR);
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMSend -> AMSenderC;

  components new AMReceiverC(AM_TEMPERATURE_MONITOR);
  App.Receive -> AMReceiverC;

  components new TemperatureSensorC() as TSensor;
  App.Temperature -> TSensor;

  components ActiveMessageC;
  App.AMControl -> ActiveMessageC;

  components RandomC;
  App.Random -> RandomC;

}
