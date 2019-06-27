import numpy as np
import sys
import cvxEDA
import json
import matplotlib.pyplot as plt
import scipy.optimize
import gsr

def bateman(tau0, tau1):
    return lambda t: np.exp(-t/tau0) - np.exp(-t/tau1)

ts = np.arange(0, 100, 0.1)
plt.plot(ts, bateman(10.0, 5.0)(ts))
plt.show()

data = []
for line in sys.stdin:
    row = json.loads(line)
    data.append((row[0]['ts'], row[1]['E']))


data = np.array(data)
data = data[::3]
#data = data[5000:10000]
data = data[data[:,1] > 0]
ts, scr = data.T
scr = 1.0/scr
oscr = scr.copy()
scr -= np.mean(scr)
scr /= np.std(scr)
dt = np.median(np.diff(ts))
ts = np.arange(len(ts))*dt

#plt.plot(data[:,0], 1.0/data[:,1])

def objective(taus):
    tau0, tau1 = np.exp(taus)
    wtf = list(cvxEDA.cvxEDA(scr, dt, tau0=tau0, tau1=tau1))
    print(tau0, tau1, float(wtf[-1]))
    return float(wtf[-1])

#print(objective([2.0, 0.7]))
#fit = scipy.optimize.minimize(objective, np.log((10.0, 5.0)))
#print(fit)
#tau0, tau1 = np.exp(fit.x)
#tau0, tau1 = np.exp([ 4.40451525, -1.79824158]) # WTF!!
wtf = list(cvxEDA.cvxEDA(scr, dt))


driver, tonic, kernel = gsr.deconv_baseline(oscr, 1/dt)

ax = plt.subplot(2,1,1)
plt.plot(ts, scr)
recon = scr - wtf[5]
plt.plot(ts, recon)
#plt.plot(ts, wtf[2])
plt.subplot(2,1,2,sharex=ax)
plt.plot(ts, wtf[1]/np.max(wtf[1]))
plt.plot(ts, driver/np.max(driver))
plt.show()
