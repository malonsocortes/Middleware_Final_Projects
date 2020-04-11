/**
* Definition file for the TemperatureMonitorApp
*
* @author Marina Alonso-Cortes
* @author Saul Almazan
* @author Jorge Santisteban
*/
#ifndef TEMPERATURE_MONITOR_H
#define TEMPERATURE_MONITOR_H

#define AM_TEMPERATURE_MONITOR  6
#define MAX_THRESHOLD 70
#define TIMER_SINK_PERIOD 61440
#define TIMER_SENSOR_PERIOD 1024

typedef nx_struct setup_msg_t {
  nx_uint16_t sender_id;
  nx_uint16_t msg_id;
  nx_uint16_t threshold;
} setup_msg_t;

typedef nx_struct data_msg_t {
  nx_uint16_t node_id;
  nx_uint16_t msg_id;
  nx_uint16_t temperature;
} data_msg_t;

#endif
