% This function is to implement AR_fourier analysis on example dataset
% Make sure to convert data into appropriate fieldtrip format before applying the function


function [ar_fourier_phase] = AR_fourier_phase(data,params)

% Input:
%   data - data in appropriate format
%
% Output:
%   ar_fourier_phase - estimated phase

%% Add to path

addpath /add/path/to/your/folder/software_folder/fieldtrip-master
ft_defaults
addpath /add/path/to/your/folder/software_folder/esi-nbf
addpath /add/path/to/your/folder/software_folder/slurmfun-master

%% Parameters

iter_n = params.iter_n; % number of AR iternations
t = params.t; % time of phase estimation
f = params.f; % frequencies for phase estimation
cycles = params.cycles; % number of cycles for fourier
exms = params.exms; % number of time points for AR extrapolation
fsample = params.fsample; % sampling rate
input_folder = params.input_folder;
output_folder = params.output_folder;
cp = params.cp; % critical time or time at which the data is cut before starting phase estimation

%% zscoring

cd(fullfile(input_folder));
load('datas.mat')

% redefine trials
cfg = [];
cfg.toilim = [0 cp];
dat = ft_redefinetrial(cfg, datas);

% zscore data in order to be able to pool over sessions
disp(strcat('running LFP z-scoring'))
zdat = fun_zscore_session(dat);

% detrend data
cfg = [];
cfg.detrend = 'yes';
zdat = ft_preprocessing(cfg, zdat);

% save data
cd(fullfile(input_folder))
save('zdat','zdat')

clear datas

%% Find model order

arordmin = 1;
arordmax = 300;

for ichan = 1
    
    data = cellfun(@(x) x(ichan,:),zdat.trial,'UniformOutput',false);
    
    [Aest,Cest,SBC,FPE] = subfunc_ARord(data,arordmin,arordmax);
    
    min_sbc = min(SBC);
    order_sbc = find(min_sbc==SBC)
end

%% AR extrapolation and fourier

cfg = [];
cfg = cell(1,iter_n);

for iter = 1:iter_n
    
    if ~isdir(fullfile(input_folder,'AR_iter',num2str(iter)))
        mkdir(fullfile(input_folder,'AR_iter',num2str(iter)))
    end
    
    cfg{iter}.inputfile   = fullfile(input_folder,'zdat.mat');
    cfg{iter}.exms        = exms;
    cfg{iter}.arord       = order_sbc;
    cfg{iter}.cycles      = cycles;
    cfg{iter}.toi         = t;
    cfg{iter}.foi         = f;
    cfg{iter}.fsample     = fsample;
    cfg{iter}.nfsample    = fsample;
    cfg{iter}.outputfile  = fullfile(input_folder,'AR_iter',num2str(iter));
end

slurmfun(@AR_fourier, cfg, ...
    'partition',     '8GB', ...
    'stopOnError',   false,  ...
    'useUserPath',   true    );

%% Check phase at extrapolation

cfg = [];
cfg = cell(1,1);

for ichan = 1
    
    
    if ~isdir(fullfile(input_folder,'phase',num2str(ichan)))
        mkdir(fullfile(input_folder,'phase',num2str(ichan)))
    end
    
    cfg{ichan}.inputfile   = fullfile(input_folder,'AR_iter');
    cfg{ichan}.ichan       = ichan;
    cfg{ichan}.iter_n      = iter_n;
    cfg{ichan}.toi         = 2; %time point of phase estimation
    cfg{ichan}.outputfile  = fullfile(input_folder,'phase',num2str(ichan));
    
end

slurmfun(@phase_transform, cfg, ...
    'partition',     '8GB', ...
    'stopOnError',   false,  ...
    'useUserPath',   true    );

%% Output

cd(fullfile(input_folder,'phase',num2str(ichan)))
load('phase.mat')
ar_fourier_phase = phase.ar_phase;



