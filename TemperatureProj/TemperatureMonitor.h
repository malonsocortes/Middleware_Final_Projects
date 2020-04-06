#ifndef TEMPERATURE_MONITOR_H
#define TEMPERATURE_MONITOR_H

#define AM_TEMPERATURE_MONITOR  6
#define MAX_THRESHOLD 500
//#define TIMER_PERIOD 61440
#define TIMER_SINK_PERIOD 61440
#define TIMER_SENSOR_PERIOD 1024

typedef nx_struct SETUP_msg {
  nx_uint16_t threshold;
} SETUP_msg;

typedef nx_struct DATA_msg {
  nx_uint16_t node_id;
  nx_uint16_t temperature;
} DATA_msg;

#endif
