# Simulation1 with meyer-heavy noise
# Authors:
# Saul Almazan del Pie
# Marina Alonso-Cortes Lledo
# Jorge Santisteban Rivas

print "********************************************";
print "*                                          *";
print "*             TOSSIM Script 1              *";
print "*                                          *";
print "********************************************";
#!/usr/bin/python

DBG_CHANNELS = "nodes"#"error,nodes,radio"
N_MOTES = 14
SIM_TIME = 120
TOPO_FILE = "linkgain.out"
NOISE_FILE = "/usr/src/tinyos/tos/lib/tossim/noise/meyer-heavy.txt"
#NOISE_FILE = "/usr/src/tinyos/tos/lib/tossim/noise/casino-lab.txt"

from TOSSIM import *
from tinyos.tossim.TossimApp import *
from random import *
import sys
import tempfile

nesc = NescApp("TemperatureMonitorC", "app.xml")
variables = nesc.variables.variables()
t = Tossim(variables)
r = t.radio()

t.randomSeed(2)

for channel in DBG_CHANNELS.split(","):
    t.addChannel(channel, sys.stdout)


#add gain links
f = open(TOPO_FILE, "r")
lines = f.readlines()

for line in lines:
    s = line.split()
    if (len(s) > 0):
        if s[0] == "gain":
            r.add(int(s[1]), int(s[2]), float(s[3]))
        elif s[0] == "noise":
            r.setNoise(int(s[1]), float(s[2]), float(s[3]))

#add noise trace
noise = open(NOISE_FILE, "r")
lines = noise.readlines()
for line in lines:
    str = line.strip()
    if (str != ""):
        val = int(float(str))
        for i in range(0, N_MOTES):
            t.getNode(i).addNoiseTraceReading(val)


for i in range (0, N_MOTES):
    time=i * t.ticksPerSecond() / 100
    m=t.getNode(i)
    m.bootAtTime(time)
    m.createNoiseModel()
    print "Booting ", i, " at ~ ", time*1000/t.ticksPerSecond(), "ms"

sys.stdout = tempfile.TemporaryFile()

root = t.getNode(0)
cnt = root.getVariable("TemperatureMonitorC.counter")
datCnt = root.getVariable("TemperatureMonitorC.dataCounter")
maxTemp = root.getVariable("TemperatureMonitorC.maxTemp")
prev_counter = 0
prev_dataCounter = 0
totalSent = 0
maxSent = 0
minSent = 2000

sentList = list()
tempList = list()
for i in range(0, N_MOTES):
    sentList.append(t.getNode(i).getVariable("TemperatureMonitorC.sentCounter"))
    tempList.append(t.getNode(i).getVariable("TemperatureMonitorC.measurements"))

sys.stdout.close()
sys.stdout = sys.__stdout__

time = t.time()
lastTime = -1
while (time + SIM_TIME * t.ticksPerSecond() > t.time()):
    timeTemp = int(t.time()/(t.ticksPerSecond()*10))
    if( timeTemp > lastTime ): #stampa un segnale ogni 10 secondi... per leggere meglio il log
        lastTime = timeTemp
        print "----------------------------------SIMULATION: ~", lastTime*10, " s ----------------------\n\n"

        counter = cnt.getData()
        dataCounter = datCnt.getData()
        print "Sink | Sent SETUP msgs = ", counter-prev_counter, " | Received DATA msgs =", dataCounter-prev_dataCounter
        prev_counter = counter
        prev_dataCounter = dataCounter

        sent = 0
        for count in sentList:
            sent += count.getData()
        print "Exchanged msgs = ", sent - totalSent, "\n\n"
        if(sent-totalSent > maxSent):
            maxSent = sent-totalSent
        if(sent- totalSent < minSent):
            minSent = sent-totalSent
        totalSent = sent

    t.runNextEvent()

print "----------------------------------END OF SIMULATION-------------------------------------\n\n"
measurements = 0
for measure in tempList:
    measurements += measure.getData()

print "----------------------------------------RESULTS-----------------------------------------"
print "Total exchanged msgs             =", totalSent
print "Max exchanged msgs               =", maxSent
print "Min exchanged msgs               =", minSent
print "Average exchanged msgs           =", totalSent*10/SIM_TIME
print "Total SETUP msgs sent by Sink    =", counter
print "Total DATA msgs received by Sink =", dataCounter
print "Total temperature measurements  =", measurements
print "Highest temperature              =", maxTemp.getData(),"Celsius"
print "Temperatures > threshold         =", dataCounter*100/measurements,"%"
