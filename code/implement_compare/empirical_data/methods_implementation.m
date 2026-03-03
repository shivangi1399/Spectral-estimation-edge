% method comparison for emperical data - true phase for comparison is calculated using hann taper
% phase comparison is done at -0.5s (so that the erp does not interfere in comparison)

clear all
close all
clc

%%

addpath /add/path/to/your/folder/software_folder/fieldtrip-master/
ft_defaults
addpath /add/path/to/your/folder/software_folder/esi-nbf
addpath /add/path/to/your/folder/software_folder/slurmfun-master/
clc

%% Create data paths to use with slurm

% path to temporary data
datafolder = '/add/path/to/your/folder/data/empirical_data';

session_names = [];
session_names = {'klecks_20170804_attentional-sampling_1'};

% create cell paths to use with slurm
session_paths = [];
session_paths = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

% path to save (slurm) output
output_folder = '/add/path/to/your/folder/results/empirical_data/';
output_paths = cellfun(@(x) fullfile(output_folder, x),session_names, 'uniform',0);

title_names = {'ARFourier','EMKalman','Zrenner', 'Blackwood', 'Asymmetric Hann', 'Hann'};

% change these to run different parts of the script
run_extrap_method = 1; % keep the value 1 to run all other extrapolation methods
run_ARFourier = 1; % keep the value 1 to run AR Fourier 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Hann Taper (True phase)

% params
t = -0.5010:0.001:-0.4990;
f = 2:2:60;
cycles = 2;

for isess = 1
    cd(fullfile(output_paths{isess}));
    load('clean_data.mat')
    
    % redefine trials (cut at 0)
    cfg=[];
    cfg.toilim    = [-1  0];
    cfg.trials    = find(clean_data.trialinfo(:,5)==1 | clean_data.trialinfo(:,5)==5);
    data = ft_redefinetrial(cfg, clean_data);
    
    % Fourier
    cfg            = [];
    cfg.output     = 'fourier';
    cfg.method     = 'mtmconvol';
    cfg.taper      = 'hann';
    cfg.keeptrials = 'yes';
    cfg.foi        = f;
    cfg.t_ftimwin  = cycles./cfg.foi;
    cfg.toi        = t;
    freqpow        = ft_freqanalysis(cfg, data);
    
    % phase
    toi = 2;
    hannph = squeeze(angle(freqpow.fourierspctrm(:,:,:,toi)));
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AR Fourier method implementation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zscore_run   = 1;
run_iter     = 1;
iter_n       = 100;  % number of iterations to run
t            = -0.5010:0.001:-0.4990;
f            = 2:2:60;
exms         = 600;
arord        = 50; %AR order
cycles       = 2;

%% per session

% Steps:
%--------
% 1) load session
% 2) zscore  and detrend data
% 3) extrapolate data using AR for iter_n
% 4) phase analysis using fourier

if run_ARFourier
    if run_iter
        if zscore_run
            for isess = 1
               
                % load LFP data
                cd(fullfile(output_paths{isess}));
                load('clean_data.mat')
                
                % create session folder to save output if it does not exist
                % already
                if ~isfolder(fullfile(output_paths{isess},'cut_-0_5f'))
                    mkdir(fullfile(output_paths{isess},'cut_-0_5f'))
                end
                
                % redefine trials
                cfg=[];
                cfg.toilim    = [-1  -0.5];
                cfg.trials    = find(clean_data.trialinfo(:,5)==1 | clean_data.trialinfo(:,5)==5);
                dat = ft_redefinetrial(cfg, clean_data);
                
                
                % zscore data in order to be able to pool over sessions
                
                disp(strcat('session- ',num2str(isess),' out of- ',num2str(length(session_names)), ', running LFP z-scoring'))
                
                zdat = fun_zscore_session(dat);
                
                % detrend data
                cfg = [];
                cfg.detrend = 'yes';
                zdat = ft_preprocessing(cfg, zdat);
                
                % save data
                cd(fullfile(output_paths{isess},'cut_-0_5f'))
                save('zdat','zdat')
                
                clear clean_data
                
            end
        end
        
        %% AR extrapolation and fourier
        
        for isess = 1
            
            cfg = cell(1,iter_n);
            
            for iter = 1:iter_n
                
                if ~isdir(fullfile(output_paths{isess},'cut_-0_5f',num2str(iter)))
                    mkdir(fullfile(output_paths{isess},'cut_-0_5f',num2str(iter)))
                end
                
                cfg{iter}.inputfile   = fullfile(output_paths{isess},'cut_-0_5f','zdat.mat');
                cfg{iter}.exms        = exms;
                cfg{iter}.arord       = arord;
                cfg{iter}.cycles      = cycles;
                cfg{iter}.toi         = t;
                cfg{iter}.foi         = f;
                cfg{iter}.fsample     = 1000; % Sampling rate of original data
                cfg{iter}.nfsample    = 1000; % Sampling rate after downsampling
                cfg{iter}.outputfile  = fullfile(output_paths{isess},'cut_-0_5f',num2str(iter));
                
            end
            
            slurmfun(@AR_fourier, cfg, ...
                'partition',     '8GB', ...
                'stopOnError',   false,  ...
                'useUserPath',   true    );
            %         cellfun(@(x)
            %         AR_fourier(x),cfg,'UniformOutput',false); % for local
            %         implementation
        end
        
    end
    
    
    %% Phase estimation using transform
    
    for isess = 1
        
        cd(fullfile(output_paths{isess}));
        load('clean_data.mat')
        
        cfg = [];
        cfg = cell(1,length(clean_data.label));
        
        for ichan = 1:length(clean_data.label)
            
            
            if ~isdir(fullfile(output_paths{isess},'cut_-0_5f','phase',num2str(ichan)))
                mkdir(fullfile(output_paths{isess},'cut_-0_5f','phase',num2str(ichan)))
            end
            
            cfg{ichan}.inputfile   = fullfile(output_paths{isess},'cut_-0_5f');
            cfg{ichan}.ichan       = ichan;
            cfg{ichan}.iter_n      = 100;
            cfg{ichan}.toi         = 2; %specify the index for the time of phase estimation here
            cfg{ichan}.outputfile  = fullfile(output_paths{isess},'cut_-0_5f','phase',num2str(ichan));
            
        end
        
        slurmfun(@phase_transform, cfg, ...
            'partition',     '8GBXS', ...
            'stopOnError',   false,  ...
            'useUserPath',   true    );
        
    end
end

%% Getting all AR Fourier phases in one structure

for isess = 1
    
    cd(fullfile(output_paths{isess},'cut_-0_5f'));
    load('zdat.mat')
    
    ar_fourierph = zeros(length(zdat.trial),length(f),length(zdat.label));
    
    for ichan = 1:length(zdat.label)
        cd(fullfile(output_paths{isess},'cut_-0_5f','phase',num2str(ichan)))
        load('phase.mat')
        ar_fourierph(:,:,ichan) = phase.ar_phase;
    end
    
    %ar_fourierph = reshape(ar_fourierph,[503,length(f),length(clean_data.label)]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running phase estimation for other extrapolation methods
%% Filter parameters for EM Kalman

Fs = 1000;
fNQ = Fs/2;
locutoff = 9;                               
hicutoff = 10;
filtorder = 3*fix(Fs/locutoff);
MINFREQ = 0;
trans  = 0.15;                      % fractional width of transition zones
f=[MINFREQ (1-trans)*locutoff/fNQ locutoff/fNQ hicutoff/fNQ (1+trans)*hicutoff/fNQ 1];
m=[0       0                      1            1            0                      0];
filtwts = firls(filtorder,f,m);             % get FIR filter coefficients

%determine default parameters (median of optimized values)
default_parameters = [];
default_parameters.window_length = 750;%ceil(median(T.optim_window));
default_parameters.filter_order = 165;%ceil(median(T.optim_filter_ord));
default_parameters.edge = 64;% ceil(median(T.optim_edge));
default_parameters.ar_order = 30;% ceil(median(T.optim_ar_ord));

D = designfilt('bandpassfir', 'FilterOrder', default_parameters.filter_order, ...
    'CutoffFrequency1', 9, 'CutoffFrequency2', 10, 'SampleRate', Fs, 'DesignMethod', 'window');


%% Running phase estimation for other extrapolation methods

isess = 1;
cd(fullfile(output_paths{isess},'cut_-0_5f'))
load('zdat.mat')

if run_extrap_method
    for ichan = 1:length(zdat.label)
        
        if ~isfolder(fullfile(output_paths{isess},'channels',num2str(ichan)))
            mkdir(fullfile(output_paths{isess},'channels',num2str(ichan)))
        end
        
        for tr = 1:length(zdat.trial)
            data = zdat.trial{1,tr}(ichan,:);
            
            %% EM Kalman Method
            
            initParams.freqs = [10]; %target frequency
            initParams.Fs = 1000;
            initParams.ampVec = [.99];
            initParams.sigmaFreqs = [.1];
            initParams.sigmaObs = 1;
            initParams.window = 250; %window size might not necessary affect estimation
            initParams.lowFreqBand = [9,10];
            
            [phase,phaseBounds, fullX] = causalPhaseEM_MKmdl_noSeg(data, initParams,0); %window size > Fs clause changed
            
            
            phase = reshape(phase', size(phase,1) * size(phase,2),1);
            EM_Kalman_phase(tr,:) =  phase;
            
            %% Blackwood method
            
            [phase_AW, analytic] = hilbert_transformer_causal_emp(data',499,[9,10]);
            Blackwood_phase(tr,:) = phase_AW;
            
            %% Zrenner Method
            
            % parameters
            edge = default_parameters.edge;
            filter_order = default_parameters.filter_order; %changed filter order to 165 from 192
            ord = default_parameters.ar_order;
            hilbertwindow = 128;
            iterations = edge + ceil(hilbertwindow/2);
            offset_correction = 0 ;
            armethod = @aryule;
            
            % demean the data
            data = detrend(data,'constant');
            
            % filter the data
            data_filtered = filtfilt(D, data); %note that filtfilt uses reflection and sets the initial values
            data_filtered_withoutedge = data_filtered(1,edge+1:end-edge);
            
            % determine AR parameters
            [a, e, rc] = armethod(data_filtered_withoutedge, ord);
            coefficients = -1 * flip(a(:, 2:end)');
            
            % prepare matrix with the aditional time points for the forward prediction
            data_filtered_withoutedge_predicted = [data_filtered_withoutedge, ones(1,iterations)];
            
            % run the forward prediction
            for i = iterations:-1:1
                data_filtered_withoutedge_predicted(1,end-i+1) = ...
                    sum(coefficients .* data_filtered_withoutedge_predicted(1,(end-i-ord+1):(end-i))');
            end
            
            % hilbert transform
            data_filtered_withoutedge_predicted_hilbertwindow = data_filtered_withoutedge_predicted(1,end-hilbertwindow+1:end);
            
            % analytic signal and angle
            data_filtered_withoutedge_predicted_hilbertwindow_analytic = hilbert(data_filtered_withoutedge_predicted_hilbertwindow);
            
            phasez = angle(data_filtered_withoutedge_predicted_hilbertwindow_analytic(1,end-iterations+edge+offset_correction));
            Zrenner_phase(tr,:) = phasez;
            
        end
        
        cd(fullfile(output_paths{isess},'channels',num2str(ichan)))
        
        phase_est = [];
        phase_est.chan = ichan;
        phase_est.EMKalman = EM_Kalman_phase;
        phase_est.Blackwood = Blackwood_phase;
        phase_est.Zrenner = Zrenner_phase;
        
        save phase_est phase_est
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running phase estimation for taper based methods

%% Asymmetric Hann Taper

cd('/add/path/to/your/folder/software_folder/fieldtrip-master')

f      = 10; %for 10Hz frequency
t      = minus(-0.5,(1./f));
cycles = 2;

for isess = 1
    
    cd(fullfile(output_paths{isess}));
    load('clean_data.mat')
    
    % redefine trials
    cfg=[];
    cfg.toilim    = [-1  -0.5];
    cfg.trials    = find(clean_data.trialinfo(:,5)==1 | clean_data.trialinfo(:,5)==5);
    data = ft_redefinetrial(cfg, clean_data);
    
    
    % fourier
    cfg            = [];
    cfg.output     = 'fourier';
    cfg.method     = 'mtmconvol';
    cfg.taper      = 'hann_at';
    cfg.keeptrials = 'yes';
    cfg.foi        = f;
    cfg.t_ftimwin  = 0.199; %cycles./cfg.foi;
    cfg.toi        = t;
    freqpow        = ft_freqanalysis_at(cfg, data);
    
    % phase
    hannph_at = [];
    for ift= 1:length(f)
        hannph_at(:,:,ift) = squeeze(angle(freqpow.fourierspctrm(:,:,ift,ift)));
    end
    
end

%% Hann taper (proxy critical time)

% params

f      = 10;
t      = minus(-0.5,(1./f));
cycles = 2;

for isess = 1
    cd(fullfile(output_paths{isess}));
    load('clean_data.mat')
    
    % redefine trials
    cfg=[];
    cfg.toilim    = [-1  -0.5];
    cfg.trials    = find(clean_data.trialinfo(:,5)==1 | clean_data.trialinfo(:,5)==5);
    data = ft_redefinetrial(cfg, clean_data);
    
    
    % Fourier
    cfg            = [];
    cfg.output     = 'fourier';
    cfg.method     = 'mtmconvol';
    cfg.taper      = 'hann';
    cfg.keeptrials = 'yes';
    cfg.foi        = f;
    cfg.t_ftimwin  = 0.199; %cycles./cfg.foi;
    cfg.toi        = t;
    freqpow        = ft_freqanalysis(cfg, data);
    
    % phase
    toi = 1;
    hannph_pr = squeeze(angle(freqpow.fourierspctrm(:,:,:,toi)));
    
end

