# two freq and 1/f noise data for phase estimation
# normal distribution is used for modeling the noise here 

import numpy as np
import matplotlib.pyplot as plt
import syncopy as spy
from syncopy.tests import synth_data
import pyplnoise
import pandas as pd
import os

### run the entire file to generate the data which is not using inbuilt syncopy functionality - then save the data and run the further 
# analysis (if required) in a different script or in the terminal 


def filtered_wn_model(nSamples, nChannels, samplerate, foi, eps, rand_ini, seed=None):
     
     wn = synth_data.white_noise(nSamples=nSamples, nChannels=nChannels, seed=seed)

     # moving average filter
     window = 50
     pad_arr = np.zeros((window, nChannels))
     a = np.vstack([pad_arr, wn])
     data = pd.DataFrame(a)
     wnt = data.rolling(window=window, win_type='gaussian').mean(std=3)
     wnt = wnt[window:(nSamples+window)].to_numpy()

     tvec = np.linspace(0, nSamples / samplerate, nSamples)
     omega0 = 2 * np.pi * foi
     lin_phase = np.tile(omega0 * tvec, (nChannels, 1)).T

     # randomize initial phase
     if rand_ini:
        rng = np.random.default_rng(seed)
        ps0 = 2 * np.pi * rng.uniform(size=nChannels)
        lin_phase += ps0

    # relative Brownian increments
     rel_eps = np.sqrt(omega0 / samplerate * eps)
     brown_incrt = rel_eps * wnt

    # combine harmonic and diffusive dynamics
     phase = lin_phase + np.cumsum(brown_incrt, axis=0)
     
     #trial = c_f*np.cos(phasest)
    
     return phase

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EPS =  np.arange(0.001, 0.5, 0.05)
PN = np.arange(0.1, 1, 0.1)

nTrials = 500
nChannels = 1
nSamples = 10000
samplerate = 1000
AdjMat = np.zeros((2, 2))

freqs = [4,6] #frequencies used in the data
fcoef = [1,1] #coefficient of the frequencies -

dir = 'freq46_11' # change this according to the frequencies and the ratios of the frequencies 
parent_dir = "/add/path/to/your/folder/data/simulated_data"
path = os.path.join(parent_dir, dir)
os.mkdir(path)


for eps in EPS:
    eps = round(eps,3)
    for pn_coef in PN:
        pn_coef = round(pn_coef,2)
        betas=[fcoef[0],fcoef[1],pn_coef]

        for tr in range(nTrials):
    
        # signal generation
            phase_1 = filtered_wn_model(nSamples, nChannels, samplerate, foi=freqs[0], eps=eps, rand_ini=False)
            phase1 = (phase_1) % (2 * np.pi)
            sig1 = np.cos(phase1)

            phase_2 = filtered_wn_model(nSamples, nChannels, samplerate, foi=freqs[1], eps=eps, rand_ini=False)
            phase2 = (phase_2) % (2 * np.pi)
            sig2 = np.cos(phase2)

            sig_3 = synth_data.AR2_network(AdjMat=AdjMat, alphas=(0.8, 0), nSamples=nSamples) #pink noise 
            sig3 = sig_3[:,0].reshape(nSamples,1)


            data = betas[0] * sig1 + betas[1] * sig2 + betas[2] * sig3
            data_phases = []
            data_phases.append(np.vstack([data[:,0],phase1[:,0],phase2[:,0]]).T) 
            data_phases = np.array(data_phases)
            data_phases = data_phases.reshape(nSamples,3)


        # saving data
            os.chdir(path)
            fname = f'freq{freqs}_coeff{betas}_eps{eps}_trial{tr+250}.csv'
            header = f'signal,phase{freqs[0]}Hz,phase{freqs[1]}Hz'
            np.savetxt(fname,data_phases,delimiter=',', fmt='%.3f',header=header)
          
        print(str(eps) + ' completed')
        print(str(pn_coef) + ' completed')





