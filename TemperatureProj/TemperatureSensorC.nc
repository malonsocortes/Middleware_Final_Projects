/**
* Configuration file for the TemperatureSensor. It defines its wiring with
* other modules.
*
* @author Saul Almazan del Pie
* @author Marina Alonso-Cortes Lledo
* @author Jorge Santisteban Rivas
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
