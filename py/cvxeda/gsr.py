import numpy as np
import scipy
import scipy.signal
from scipy.ndimage.filters import gaussian_filter1d
from scipy.interpolate import interp1d

def gaussian_smooth(signal, sigma):
    return gaussian_filter1d(signal, sigma)

biexp_guess = 3.0, 2.0, 2.0, 0.75
def biexp(g, d, t1, t2, t):
    t = np.array(t)
    t -= d
    t[t < 0] = 0.0
    return g*(np.exp(-t/t1) - np.exp(-t/t2))

def canonical_response(t, peaktime=3.0745, rise=0.7013, d1=3.1487, d2=14.1257,
                cutoff=0.0001):
    normer = np.sqrt(2*np.pi)*rise
    gt = np.exp(-((t - peaktime)**2/(2*rise**2)))/normer
    ht = np.exp(-t/d1) + np.exp(-t/d2)
    ft = np.convolve(gt, ht)
    ft = ft[:len(t)]
    #ft = ft[ft > 0.0001]
    ft /= np.sum(ft)
    return ft

def balance_kernel(k):
    return np.hstack((np.zeros(len(k)), k))

def esc_param(d):
    d = d.copy()
    peak = np.argmax(d)
    if peak == 0:
        peak = 1
    baseline = np.min(d[:peak])
    return np.max(d), baseline

def esc_norm(d):
    d = d.copy()
    peakval, baseline = esc_param(d)
    d -= baseline
    d /= peakval-baseline
    return d

def nonnegdiv(convdata, kernel):
    convdata = convdata.copy()
    nd = len(convdata)
    driver = np.zeros(nd)
    kl = len(kernel)
    
    for i in range(nd-1):
        k = kernel[0:kl-i]
        dvl = np.divide(convdata[i:], k)
        dv = np.min(dvl)
        dv = max(0, dv)
    
        driver[i] = dv
        convdata[i:] = convdata[i:] - k*dv
    
    return driver, convdata

def simple_bandpass(signal, window_len, rate, start, end):
        taps = window_len
        low = scipy.signal.firwin(taps, end/rate/2.0)
        high = scipy.signal.firwin(taps, start/rate/2.0)
        # Make high actually a highpass filter
        high = -high
        high[int(taps/2)] += 1
        
        # Combine the filters
        #band = -high-low
        #band[int(taps/2)] += 1
        band = low
        
        #signal = scipy.signal.lfilterprint band
        # Should give a non-phase-shifted result
        signal = scipy.signal.signaltools.filtfilt(band, [1], signal)
        return signal

def filter_artefacts(signal):
    signal = signal.copy()
    signal[signal > 200] = np.nan
    return signal

def dilate_trues(signal, amount):
        window = [1.0/float(amount)]*amount
        signal = np.convolve(signal, window, mode='same')
        return signal > 0


def bad_gsr_samples(signal):
        return (signal > 100) | (signal <= 10**-6) | ~np.isfinite(signal)

def deartefact_gsr(signal, neigborhood=2048):
        artefacts = bad_gsr_samples(signal)
        bad_samples = dilate_trues(artefacts, neigborhood)
        signal = signal.copy()

        rng = np.arange(len(signal))

        if not np.any(bad_samples):
                return signal, bad_samples

        if np.all(bad_samples):
                signal[:] = 0
                return signal, bad_samples

        valid_interp = interp1d(rng[~bad_samples], signal[~bad_samples], bounds_error=False)
        signal[bad_samples] = valid_interp(rng[bad_samples])

        def find_first(lst, predicate):
                # This really SHOULD be in numpy
                for i in xrange(len(lst)):
                        if predicate(lst[i]):
                                return i
                return None

        first_valid = find_first(signal, np.isfinite)
        last_valid = -find_first(signal[::-1], np.isfinite)

        signal[:first_valid] = signal[first_valid]
        if last_valid < 0:
                signal[last_valid:] = signal[last_valid-1]

        return signal, bad_samples

def bandpass_gsr(signal, rate,
        lowfreq=0.0159, highfreq=5.0,
        lpord=1, hpord=1):
    """
    Filter the given signal using Butterworth bandpass signal
    of given specs. The default values are from SCRalyze package
    and based on:
    
    Bach DR, Flandin G, Friston KJ, Dolan RJ (2009).
    Time-series analysis for rapid event-related skin conductance responses. 
    http://scralyze.sourceforge.net/BachFlandinFristonDolan_2009_SCR_GLM.pdf
    """
    
    nyq = rate/2.0
    
    if lpord > 0:
        low = scipy.signal.butter(lpord, highfreq/nyq)
        signal = scipy.signal.filtfilt(*low, x=signal)
    
    if hpord > 0:
        high = scipy.signal.butter(hpord, lowfreq/nyq, 'high')
        signal = scipy.signal.filtfilt(*high, x=signal)
    return signal

def rc_circuit_emulator(time_constant, fs):
    # TODO: Make sure this makes sense!
    cutoff = 1.0/(2.0*np.pi*time_constant)
    return scipy.signal.butter(1, cutoff/(fs/2.0))
    #return scipy.signal.bilinear([1.0], [1.0, time_constant], fs=fs)

def taylor_filter(signal, fs):
    longfilt = rc_circuit_emulator(60.0, fs)
    longresponse = scipy.signal.filtfilt(*longfilt, x=signal)
    
    shortfilt = rc_circuit_emulator(0.1, fs)
    shortresponse = scipy.signal.filtfilt(*shortfilt, x=signal)

    sig = np.abs(shortresponse - longresponse)/longresponse
    return sig


def relative_phasic(signal, fs, tonic_freq=0.01):
    lowpass = scipy.signal.butter(1, tonic_freq/fs)
    tonic = scipy.signal.lfilter(*lowpass, x=signal)
    return signal/tonic

def richardson_lucy(signal, kernel, driver=None, max_iter=200):
    if driver is None:
        driver = np.repeat(np.median(signal), len(signal))
    
    inv_kernel = kernel[::-1]
    kl = len(kernel)
    
    for i in range(max_iter):
        print(i)
        result = padded_convolution(driver, kernel)
        relative_error = signal/result
        relative_error[~np.isfinite(relative_error)] = 0
        error_est = padded_convolution(relative_error, inv_kernel)
        driver *= error_est

    return driver

def padded_convolution(signal, kernel):
    # The "mirroring" approach causes problems in
    # many cases
        #padding_start = signal[len(kernel)/2::-1]
        #padding_end = signal[:-len(kernel)/2:-1]

        padding_start = np.repeat(signal[0], len(kernel)/2)
        padding_end = np.repeat(signal[-1], len(kernel)/2)
        signal = np.hstack((padding_start, signal, padding_end))
        smoothed = np.convolve(signal, kernel, mode='full')
        smoothed = smoothed[len(kernel):-len(kernel)+1]
        return smoothed

def canonical_deconv_kernel(rate):
    kernel_t = np.arange(0, 60, 1.0/rate)
    kernel = balance_kernel(canonical_response(kernel_t))
    return kernel

def deconv_baseline(signal, rate):
    sigma = 10.0*rate
    kernel_t = np.arange(0, 60, 1.0/rate)
    kernel = balance_kernel(canonical_response(kernel_t))
    raw_driver = richardson_lucy(signal, kernel, max_iter=200)

    driver_lp = gaussian_smooth(raw_driver, sigma)
    driver_hp = raw_driver - driver_lp

    driver_tonic_est = driver_lp - np.sqrt(gaussian_smooth(driver_hp**2, sigma))

    driver = raw_driver - driver_tonic_est
    
    return driver, driver_tonic_est, kernel

def laplace_regularizer(weight=0.1, n=0.05, d=0.8):
    def reg(sig):
        grad = np.gradient(sig)
        return weight*np.exp(-np.abs(grad)**d/n)
    return reg

def regularized_rl_deconv(signal, kernel, regularizer, driver=None, max_iter=200):
    # The regularizer formulation is from
    # "Richardson-Lucy Deblurring for Scenes under a Projective Motion Path"
    # TODO: Probably very wrong. The regularizer either does nothing
    #    or causes heavy ringing

    if driver is None:
        driver = np.repeat(np.median(signal), len(signal))
        driver = signal[:]
    
    inv_kernel = kernel[::-1]
    kl = len(kernel)
    
    for i in range(max_iter):
        print(i)
        result = padded_convolution(driver, kernel)
        relative_error = signal/result
        relative_error[~np.isfinite(relative_error)] = 0
        error_est = padded_convolution(relative_error, inv_kernel)
        reg = regularizer(driver)
        reg[~np.isfinite(reg)] = 0
        driver *= error_est/(1.0 - np.gradient(reg))

    return driver


