clear all
close all
clc

%% Create data paths to use with slurm

% path to temporary data
datafolder = '/add/path/to/your/folder/data/empirical_data';

session_names = [];
session_names = {'klecks_20170804_attentional-sampling_1'};

% create cell paths
session_paths = [];
session_paths = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

% path to save
output_folder = '/add/path/to/your/folder/results/empirical_data/';
output_paths = cellfun(@(x) fullfile(output_folder, x),session_names, 'uniform',0);

title_names = {'echt'};

%% parameters

f0 = 10; % for 10Hz frequency
filt_BW = f0/2;
Fs = 1000;
Filt_LF = f0 - filt_BW/2;
Filt_HF = f0 + filt_BW/2;

%% phase

isess = 1;
cd(fullfile(output_paths{isess},'cut_-0_5f'))
load('zdat.mat')

for ichan = 1:length(zdat.label)
    ichan
    
    for tr = 1:length(zdat.trial)
        data = zdat.trial{1,tr}(ichan,:);
        x = echt(data, Filt_LF, Filt_HF, Fs, length(data));
        echt_phase(tr,:) = angle(x);
    end
    
    if ~isfolder(fullfile(output_paths{isess},'channels',num2str(ichan),'echt'))
        mkdir(fullfile(output_paths{isess},'channels',num2str(ichan),'echt'))
    end
    cd(fullfile(output_paths{isess},'channels',num2str(ichan),'echt'))
    save echt_phase echt_phase
    
end







