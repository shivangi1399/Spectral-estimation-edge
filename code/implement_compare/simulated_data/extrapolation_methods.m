% change weights of different frequencies and phase diffusion strengths to implement the different 
% extraploation based phase estimation methods for each of the simulated datasets
% The other extrapolation methods are adapted for this dataset using the code provided by Wodeyar et al 2021 

clear all
close all
clc

%% load files

datafolder = '/add/path/to/your/folder/data/simulated_data';
resultfolder = '/add/path/to/your/folder/results/simulated_data';
session_names = [];
session_names = {'freq46_11','freq46_10_8','freq46_10_6','freq46_10_4','freq46_10_2'}; % for different ratios of freq

data_paths_folder = [];
data_paths_folder = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(resultfolder,x), session_names, 'uniform',0);

%% Parameters

ntrials = 500;
Fs = 1000;
load_in_format = 0; % load simulated data in fieldtrip format

EPS = [0.001, 0.051, 0.101, 0.151, 0.201, 0.251, 0.301, 0.351, 0.401, 0.451];
PN = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

%% Filter parameters for EM Kalman

fNQ = Fs/2;
locutoff = 4;                               
hicutoff = 6;
filtorder = 3*fix(Fs/locutoff);
MINFREQ = 0;
trans  = 0.15;                      % fractional width of transition zones
f=[MINFREQ (1-trans)*locutoff/fNQ locutoff/fNQ hicutoff/fNQ (1+trans)*hicutoff/fNQ 1];
m=[0       0                      1            1            0                      0];
filtwts = firls(filtorder,f,m);             % get FIR filter coefficients

%determine default parameters (median of optimized values)
default_parameters = [];
default_parameters.window_length = 750;%ceil(median(T.optim_window));
default_parameters.filter_order = 192;%ceil(median(T.optim_filter_ord));
default_parameters.edge = 64;% ceil(median(T.optim_edge));
default_parameters.ar_order = 30;% ceil(median(T.optim_ar_ord));

D = designfilt('bandpassfir', 'FilterOrder', default_parameters.filter_order, ...
    'CutoffFrequency1', 4, 'CutoffFrequency2', 8, 'SampleRate', Fs, 'DesignMethod', 'window');

%% load files in fieldtrip format

if load_in_format
    
    for isess = 1
        for eps = EPS(6)
            eps
            for pn_coef = PN(5)
                pn_coef
                cd(data_paths_folder{isess})
                s= ['files = dir("freq[4, 6]_coeff[1, 1, ' num2str(pn_coef) ']_eps' num2str(eps) '_trial*.csv");'];
                eval(s)
                dat = zeros(1,10000);
                datf1 = zeros(1,10000);
                datf2 = zeros(1,10000);
                for file = files'
                    
                    csv = table2array(readtable(file.name));
                    dat = vertcat(dat,csv(:,1)');
                    datf1 = vertcat(datf1,csv(:,2)');
                    datf2 = vertcat(datf2,csv(:,3)');
                end
                
                dat(1,:)=[];
                datf1(1,:)=[];
                datf2(1,:)=[];
                clc
                
                cd('/add/path/to/your/folder/code/data_generation')
                load zdat.mat
                
                for itrial = 1:ntrials
                    fdat{1,itrial}(1,:) = dat(itrial,:);
                    tdat{1,itrial}(1,:) = 0:0.001:9.999;
                end
                
                datas = [];
                datas = zdat;
                datas.time = [];
                datas.time  = tdat;
                datas.trial = [];
                datas.trial = fdat;
                datas.label = [];
                datas.label{1,1} = 'only 1';
                datas.fsample = Fs;
                
                if ~isdir(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
                    mkdir(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
                end
                
                datf1 = datf1(1:ntrials,:);
                datf2 = datf2(1:ntrials,:);
                
                cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
                save datas datas
                save datf1 datf1
                save datf2 datf2
                clear zdat
            end
        end
    end
end

%% Phase estimation

for isess = 1
    for eps = EPS(6)
        eps
        for pn_coef = PN(5)
            pn_coef
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            load('datas.mat')
            load('datf1.mat')
            load('datf2.mat')
            
            %load('simData.mat')
            simdata = [];
            simData.data = datas;
            simData.phase_f1 = datf1;
            simData.phase_f2 = datf2;
            
           
            for tr= 1:500 
                data = datas.trial{1,tr}(1,1:10000);
                
                %% EM Kalman Method
                
                initParams.freqs = [4]; %target frequency
                initParams.Fs = 1000; %sampling rate
                initParams.ampVec = [.99];
                initParams.sigmaFreqs = [.1];
                initParams.sigmaObs = 1;
                initParams.window = 2000; %window size used to fit the parameters
                initParams.lowFreqBand = [4,6];
                
                [phase,phaseBounds, fullX] = causalPhaseEM_MKmdl_noSeg(data, initParams,0);
                
                phase = reshape(phase', size(phase,1) * size(phase,2),1);
                phaseBounds = reshape(permute(phaseBounds,[2,1,3]), size(phaseBounds,1) * size(phaseBounds,2),size(phaseBounds,3));
                fullX = reshape(permute(fullX,[2,1,3]), size(fullX,1) * size(fullX,2),size(fullX,3));
                
                EM_Kalman_phase(tr,:) =  phase;
            
                %% Blackwood method
                
                [phase_AW, ~, ~, analytic] = hilbert_transformer_causal(data', 1000,[4,6]);
                Blackwood_phase(tr,:) = phase_AW;
                
                %% Zrenner Method
                
                epochs = create_epochs_overlapping(data,Fs);
                epochwindowmask = ((-default_parameters.window_length+1):0)+ceil(size(epochs,1)/2);
                [zrenner_phase, estamp] = phastimate(epochs(epochwindowmask,:), D, default_parameters.edge, default_parameters.ar_order, 128);
                Zrenner_phase(tr,:) = zrenner_phase;
                
            end
                     
            simData.EM_Kalman = EM_Kalman_phase;
            simData.Blackwood = Blackwood_phase;
            simData.zrenner = Zrenner_phase;
            
            %% AR Fourier Method
            
            params.iter_n = 100; % number of AR iternations
            params.t = 5:0.001:5.01; % time of phase estimation - specify the exact index in AR_fourier_sim
            params.f = 2:1:8; % frequencies for phase estimation
            params.cycles = 3; % number of cycles for fourier
            params.exms = 800; % number of time points for AR extrapolation
            params.fsample = Fs; % sampling rate
            params.input_folder = fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef));
            params.cp = 5; % critical time or time at which the data is cut before starting phase estimation
            [ar_phase] = AR_fourier_sim(params);
         
            simData.ARfourier = ar_phase;
            
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            save simData simData
        end
    end
end















