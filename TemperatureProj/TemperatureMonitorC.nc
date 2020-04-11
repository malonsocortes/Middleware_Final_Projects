/**
* Source file for the TemperatureMonitor.
*
* @author Marina Alonso-Cortes
* @author Saul Almazan
* @author Jorge Santisteban
*/
#include "TemperatureMonitor.h"
#include "Timer.h" /* To use TMilli */

#include <printf.h>
#define PRINTF(...) printf(__VA_ARGS__); printfflush()


module TemperatureMonitorC {
  uses {

    interface Boot;

    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface Receive;

    interface SplitControl as AMControl;

    interface Read<uint16_t> as Temperature;  /* Temperature measurements */

    interface Timer<TMilli> as TimerSink;     /* Period to send SETUP msg */
    interface Timer<TMilli> as TimerSensor;   /* Period to meassure Data */

    interface Random;                         /* Generates random threshold */
  }
}

implementation {

  uint16_t    threshold,
  uint16_t    temperature;
  uint16_t    counter;

  bool        busy = FALSE;

  message_t   pkt;
  setup_msg_t setup_pkt;
  data_msg_t  data_pkt;

  am_addr_t   prev_node = 0;


  task void sendSETUP() {

    setup_msg_t * msg;

    if (TOS_NODE_ID == 0) {

      if (busy) return;
      counter ++;

      msg = (setup_msg_t *) (call Packet.getPayload(&pkt, sizeof(setup_msg_t)));
      if (msg == NULL) return;
      msg->sender_id = TOS_NODE_ID;
      msg->msg_id = counter;
      msg->threshold = threshold;

      if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(setup_msg_t)) == SUCCESS) {
        busy = TRUE;
        dbg("radio", "%s | Node 0 | Sent SETUP (ID=%d): threshold = %d\n",
        sim_time_string(), msg->msg_id, msg->threshold);
      }
    }
  }

  task void forwardSETUP() {

    setup_msg_t * msg;

    if(busy) return;

    dbg("nodes", "%s | Node %d | Must forward SETUP\n", sim_time_string(), TOS_NODE_ID);

    msg = (setup_msg_t *) (call Packet.getPayload(&pkt, sizeof(setup_msg_t)));
    if(msg == NULL) return;
    msg->sender_id = setup_pkt.sender_id;
    msg->msg_id = setup_pkt.msg_id;
    msg->threshold = setup_pkt.threshold;

    if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(setup_msg_t)) == SUCCESS) {
      busy = TRUE;
      dbg("radio", "%s | Node %d | Forwarded SETUP (ID=%d): threshold = %d\n",
      sim_time_string(), TOS_NODE_ID, msg->msg_id, msg->threshold);
    }
  }

  task void sendDATA() {

    data_msg_t * msg;

    if(TOS_NODE_ID != 0) {

      if(busy) return;
      counter ++;

      dbg("nodes", "%s | Node %d | Temperature above threshold. Must inform Sink\n", sim_time_string(), TOS_NODE_ID);

      msg = (data_msg_t *) (call Packet.getPayload(&pkt), sizeof(data_msg_t));
      if( msg == NULL) return;
      msg->node_id = TOS_NODE_ID;
      msg->msg_id = counter;
      msg->temperature = temperature;

      if(call AMSend.send(prev_node, &pkt, sizeof(data_msg_t)) == SUCCESS) {
        busy = TRUE;
        dbg("radio",  "%s | Node %d | Sent DATA (ID=%d): temp = %d\n",
        sim_time_string(), TOS_NODE_ID, msg->msg_id, msg->temperature);
      }
    }
  }

  task void forwardDATA() {

    data_msg_t * msg;

    if(busy) return;

    dbg("nodes", "%s | Node %d | Must forward DATA\n", sim_time_string(), TOS_NODE_ID);

    msg = (data_msg_t *) (call Packet.getPayload(&pkt), sizeof(data_msg_t));
    if( msg == NULL) return;
    msg->node_id = data_pkt.node_id;
    msg->msg_id = data_pkt.msg_id;
    msg->temperature = data_pkt.temperature;

    if(call AMSend.send(prev_node, &pkt, sizeof(data_msg_t)) == SUCCESS) {
      busy = TRUE;
      dbg("radio",  "%s | Node %d | Forwarded DATA (ID=%d): temp = %d\n",
      sim_time_string(), TOS_NODE_ID, msg->msg_id, msg->temperature);
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt==msg && err == SUCCESS) {
      busy = FALSE;
    }
  }

  //***************************** Boot Interface *****************************//
  event void Boot.booted() {
    /* Initialization of variables */
    threshold = MAX_THRESHOLD;
    temperature = 0;
    busy = FALSE;
    counter = 0;

    dbg("nodes", "%s | Node %d | Booted.\n", sim_time_string(), TOS_NODE_ID);
    call AMControl.start();
  }

  //*************************** AMControl Interface **************************//
  event void AMControl.startDone(error_t err) {

    if (err == SUCCESS) {

      dbg("radio", "Radio on.\n");
      dbg("nodes", "%s | Node %d | Radio started\n", sim_time_string(), TOS_NODE_ID);

      if(TOS_NODE_ID == 0) {
        call TimerSink.startPeriodic(TIMER_SINK_PERIOD);
      }
      else {
        call TimerSensor.startPeriodic(TIMER_SENSOR_PERIOD);
      }
    } else {
      dbgerror("error", "%s | Node %d | Error booting\n", sim_time_string(), TOS_NODE_ID);
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {

    if(TOS_NODE_ID == 0) {
      call TimerSink.stop();
    }
    else {
      call TimerSensor.stop();
    }

    dbg("nodes", "%s | Node %d | Stopped\n", sim_time_string(), TOS_NODE_ID);
  }

  //*************************** Timers **************************//
  event void TimerSink.fired() {
    /* Calculate new threshold */
    threshold = (call Random.rand16 % 40) + 30 /* Temperatures from 30 to 70 ºC */
    dbg("nodes", "%s | Node 0 | New threshold %d.\n", sim_time_string(), TOS_NODE_ID, threshold);
    post sendSETUP();
  }

  event void TimerSensor.fired() {
    call Temperature.read();
  }

  //*************************** Temperature Sensor **************************//
  event void Temperature.readDone(error_t err, uint16_t val) {
    if(err == SUCCESS) {
      temperature = val;
      dbg("nodes" "%s | Node %d | Read temp = %d", sim_time_string(), TOS_NODE_ID, temperature);
      /* If measured temperature is higher than threshold, it must be sent to Sink Node */
      if(temperature > threshold) {
        post sendDATA();
      }
    }
  }

  //*************************** Receive Interface **************************//
  event message_t Receive.receive(message_t * msg, void * payload, uint8_t len) {

    setup_msg_t setup;
    data_msg_t data;

    am_addr_t source_node;
    am_addr_t dest_node;

    source_node = call AMPacket.source(msg);
    dest_node = call AMPacket.destination(msg);

    if (TOS_NODE_ID == 0) {

      if (len == sizeof (data_msg_t)) {

        data = (data_msg_t *) payload;
        dbg("radio","%s | Node 0 | Received DATA (ID = %d): sender = ID%d, origin = ID%d, temp = %d > threshold\n",
        sim_time_string(), data->msg_id, source_node, data->node_id, dat->temperature)
      }
    }
    else {

      if (len == sizeof (setup_msg_t)) {
        setup = (setup_msg_t *) payload;
        dbg("radio", "%s | Node %d | Received SETUP (ID = %d): sender = ID%d, origin = ID%d, threshold = %d\n",
        sim_time_string(), TOS_NODE_ID, setup->msg_id, source_node, setup->sender_id, setup->threshold);

        if(setup->msg_id > counter) {
            threshold = setup->threshold;
            prev_node = source_node;
            setup_pkt = *setup;

            post forwardSETUP();
        }
      }
      else if (len == sizeof (data_msg_t)) {
        data = (data_msg_t *) payload;
        dbg("radio", "%s | Node %d | Received DATA (ID = %d): sender = ID%d, origin = ID%d, forwardto = ID%d\n",
        sim_time_string(), TOS_NODE_ID, data->msg_id, source_node, data->node_id, prev_node);
        data_pkt = *data;
        post forwardDATA();
      }
    }
    return msg;
  }
}
