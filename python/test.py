import pylte
import numpy as np
import time


atmos = np.loadtxt('hsra.model', skiprows=1)
lines = np.loadtxt('lines.dat')

wl = np.linspace(6301.0,6303.0,100)
pylte.initAtmos(atmos)
pylte.initLines(lines, wl)

start = time.time()
for i in range(10):
	out = pylte.synthLines(atmos)
print time.time() - start