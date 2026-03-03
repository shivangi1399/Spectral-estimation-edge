% This script runs the AR Fourier method on the session and data specified by isess. You can specify which dataset you want to run
% the code for by specifying eps for phase diffusion constant and pn_coef for the noise coefficient. You can replace the simulated 
% data by your data but make sure to convert the data into the appropriate fieldtrip format, an example of this conversion is 
% given in this file

clear all
close all
clc

%% Load files

datafolder = '/add/path/to/your/folder/data/simulated_data'; 
resultfolder = '/add/path/to/your/folder/results/simulated_data';

session_names = [];
session_names = {'freq46_11','freq46_10_8','freq46_10_6','freq46_10_4','freq46_10_2'}; %for different ratios of frequencies

data_paths_folder = [];
data_paths_folder = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(resultfolder,x), session_names, 'uniform',0);

%% Parameters

ntrials = 500; %number of trials
Fs = 1000; %sampling frequency
load_in_format = 0; % load simulated data if it hasn't already been extracted

EPS = [0.001, 0.051, 0.101, 0.151, 0.201, 0.251, 0.301, 0.351, 0.401, 0.451]; %different phase diffusion coefficients, select the 
% ones for which the data is given 
PN = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]; %different noise coefficient

%% Loading files and getting data into fieldtrip format

if load_in_format
    for isess = 1
        for eps = EPS(6)
            eps
            for pn_coef = PN(5)
                pn_coef
                
                cd(data_paths_folder{isess})
                s= ['files = dir("freq[4, 6]_coeff[1, 1, ' num2str(pn_coef) ']_eps' num2str(eps) '_trial*.csv");'];
                eval(s)
                Nt = 10000; %number of samples
                dat = zeros(1,Nt);
                datf1 = zeros(1,Nt);
                datf2 = zeros(1,Nt);
                
                for file = files'
                    csv = table2array(readtable(file.name));
                    dat = vertcat(dat,csv(:,1)'); % data array
                    datf1 = vertcat(datf1,csv(:,2)'); % array for phase of f1 
                    datf2 = vertcat(datf2,csv(:,3)'); % array for phase of f2
                end
                
                dat(1,:)=[];
                datf1(1,:)=[];
                datf2(1,:)=[];
                clc
                
                cd('/add/path/to/your/folder/code/data_generation')
                load zdat.mat
                
                for itrial = 1:ntrials
                    fdat{1,itrial}(1,:) = dat(itrial,:);
                    tdat{1,itrial}(1,:) = 0:0.001:9.999; %to create the time arrays
                end
                
                datas = [];
                datas = zdat;
                datas.time = [];
                datas.time  = tdat;
                datas.trial = [];
                datas.trial = fdat;
                datas.label = [];
                datas.label{1,1} = 'only 1';
                datas.fsample = Fs; % you can remove the trialinfo part, it's not relevant
                
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
            simdata = []; %for the first run
            simData.data = datas; 
            simData.phase_f1 = datf1; %gives true phase of f1 frequency
            simData.phase_f2 = datf2;
               
            %% AR Fourier Method
            
            params.iter_n = 100; % number of AR extrapolation iterations
            params.t = 5:0.001:5.01; % times at which the spectral estimation is performed
            params.f = 2:1:8; % frequencies at which the spectral estimation is done
            params.cycles = 3; % number of cycles for fourier
            params.exms = 800; % number of extrapolated samples
            params.fsample = Fs; % sampling frequency
            params.input_folder = fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)); % input data folder
            params.cp = 5; % critical time or time at which the data is cut before starting phase estimation
            params.toe = 2; % index of time in params.t for which the phase estimation is performed
            [ar_phase] = AR_fourier_imp(params);
         
            simData.ARfourier = ar_phase;
            
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            save simData simData
        end
    end
end

% Speficy and change paths to fieldtrip and slurm (this is used for parallel computation) in the AR_fourier_imp file according 
% to your systems
% Add the code folder in path before running this file












