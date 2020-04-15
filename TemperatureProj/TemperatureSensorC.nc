/**
* Configuration file for the TemperatureSensor. It defines its wiring with
* other modules.
*
* @author Marina Alonso-Cortes
* @author Saul Almazan
* @author Jorge Santisteban
*/

generic configuration TemperatureSensorC(){

  provides interface Read<uint16_t>;

}
implementation {

  components new TemperatureSensorP();
  Read = TemperatureSensorP;

  components MainC, RandomC;

  TemperatureSensorP.Random -> RandomC;
  RandomC <- MainC.SoftwareInit;

  components new TimerMilliC();

  TemperatureSensorP.Timer0 -> TimerMilliC;
}
