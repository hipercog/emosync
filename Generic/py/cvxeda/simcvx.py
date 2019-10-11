import numpy as np
import matplotlib.pyplot as plt
import cvxEDA

def bateman(tau0=10.0, tau1=2.0):
    return lambda t: np.exp(-t/tau0) - np.exp(-t/tau1)

dt = 1/32
ts = np.arange(1000)*dt
driver = np.zeros(len(ts))
driver[50] = 1.0
driver[100] = 0.5
driver[400] = 1.0

kernel = bateman()(ts)
kernel = np.array([0.0]*len(kernel) + list(kernel))
halflen = int(len(kernel)/2.0)
signal = np.convolve(driver, kernel, mode='full')[halflen:-halflen+1]

ax = plt.subplot(3,1,2)
plt.plot(ts, driver)
plt.ylabel('Neural activity')
ax = plt.subplot(3,1,1)
plt.plot(ts, signal)
plt.ylabel('Skin conductance')

plt.subplot(3,1,3)
phasic, driver, tonic, *_ = list(cvxEDA.cvxEDA(signal, dt))

plt.ylabel('Estimated neural activity')
plt.xlabel('Time (s)')
plt.plot(ts, driver/np.max(driver))

plt.show()
