import numpy as np
import matplotlib.pyplot as plt
import cvxEDA

left = np.loadtxt('L_norp_S05.txt', skiprows=3, delimiter=',')
right = np.loadtxt('R_norp_S05.txt', skiprows=3, delimiter=',')

dt = 1/32
ts = np.arange(len(left))*dt
valid = (ts > 1000) & (ts < 3500)
ts = ts[valid]
left = left[valid]
right = right[valid]

plt.plot(ts, left[:,0])
plt.plot(ts, right[:,0])
plt.show()

def znorm(x):
    return (x - np.mean(x))/np.std(x)

phasic, driver, tonic, *_ = list(cvxEDA.cvxEDA((left[:,0]), dt))

ax = plt.subplot(2,1,1)
plt.plot(ts, left[:,0])
plt.plot(ts, tonic)
plt.subplot(2,1,2, sharex=ax)
plt.ylabel('Skin conductance (microsiemens)')
plt.plot(ts, driver)
plt.ylabel('Estimated neural activity')
plt.xlabel('Time')

#events = np.isfinite(left[:,1])
events = left[:,1] == 20

plt.subplot(2,1,2, sharex=ax)

for et in ts[events]:
    plt.axvline(et, color='black')

"""
for ec in np.unique(left[:,1][events]):
    events = left[:,1] == ec
    
    print(ec)
    for et in ts[events]:
        plt.axvline(et, color='black')

    plt.plot(ts, znorm(left[:,0]))
    plt.plot(ts, znorm(right[:,0]))
    plt.show()
"""
plt.show()
