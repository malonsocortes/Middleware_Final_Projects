#ifndef WEATHER_MONITOR_H
#define WEATHER_MONITOR_H

#define AM_WEATHER_MONITOR  6
//#define TIMER_PERIOD 61440
#define TIMER_PERIOD 1024

typedef nx_struct WeatherMonitorMsg {
  nx_uint16_t node_id;
  nx_uint16_t temperature;
  nx_uint16_t humidity;
  nx_uint16_t light_par;
  nx_uint16_t light_tsr;
  nx_uint16_t voltage;
} WeatherMonitorMsg;

#endif
