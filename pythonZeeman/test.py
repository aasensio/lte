import pylte
import numpy as np
import matplotlib.pyplot as pl
import time

try:
	import seaborn as sn
except:
	pass

atmos = np.loadtxt('hsra.model', skiprows=2)
lines = np.loadtxt('lines.dat')

wl = np.linspace(6301.0,6303.0,150)
pylte.initAtmos(atmos)
pylte.initLines(lines, wl)

stokes, continuum = pylte.synthLines(atmos)

pl.close('all')
f, ax = pl.subplots(ncols=2, nrows=2, figsize=(10,8))

labels = ['I/I$_c$','Q/I$_c$','U/I$_c$','V/I$_c$']
loop = 0
for i in range(2):
	for j in range(2):
		ax[i,j].plot(wl, stokes[loop,:] / continuum)
		ax[i,j].set_xlabel('Wavelength [$\AA$]')
		ax[i,j].set_ylabel(labels[loop])
		ax[i,j].ticklabel_format(useOffset=False)
		loop += 1
		
pl.tight_layout()
		
