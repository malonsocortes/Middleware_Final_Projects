/**
* Definition file for the TemperatureMonitorApp
*
* @author Saul Almazan del Pie
* @author Marina Alonso-Cortes Lledo
* @author Jorge Santisteban Rivas
*/
#ifndef TEMPERATURE_MONITOR_H
#define TEMPERATURE_MONITOR_H

#define AM_TEMPERATURE_MONITOR 20
#define MAX_TEMP 70
#define TIMER_SINK_PERIOD 30000
#define TIMER_SENSOR_PERIOD 5000

typedef nx_struct setup_msg_t {
  nx_uint16_t msg_id;
  nx_uint16_t threshold;
} setup_msg_t;

typedef nx_struct data_msg_t {
  nx_uint16_t node_id;
  nx_uint8_t msg_id;
  nx_uint16_t temperature;
} data_msg_t;

#endif
