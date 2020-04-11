/**
* Source file for the TemperatureSensor module, which simulates a temperature
* measuring sensor by reading a randmon number between 0 an 70, assuming
* temperatures do not leave this range.
*
* @author Marina Alonso-Cortes
* @author Saul Almazan
* @author Jorge Santisteban
*/
generic module TemperatureSensorP() {

  provides interface Read<uint16_t>;

  uses interface Random;
  uses interface Timer<TMilli> as Timer0;

}
implementation {

  command error_t Read.read(){
    call Timer0.startOneShot(10);
    return SUCCESS;
  }

  event void Timer0.fired(){
    signal Read.readDone(SUCCESS, call Random.rand16()%70);
  }
}
