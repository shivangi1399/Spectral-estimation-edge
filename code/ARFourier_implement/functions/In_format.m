function [datas] = In_format(data,params) % the input data should be in format trails x time x channels

%% Parameters

t = params.time; % time in seconds
fsample = params.fsample; % sampling frequency
output_folder = params.output_folder; % folder to save data

%% converting to format

cd('/add/path/to/your/folder/code/data_generation')
load zdat.mat

for itrial = 1:size(data,1)
    fdat{1,itrial}(1,:) = data(itrial,:);
    tdat{1,itrial}(1,:) = 0:(1/fsample):(t-(1/fsample));
end

datas = [];
datas = zdat;
datas.time = [];
datas.time  = tdat;
datas.trial = [];
datas.trial = fdat;
datas.label = [];
datas.label{1,1} = 'only 1';
datas.sampleinfo = [];
datas.sampleinfo = [1,2000];
datas.trialinfo = [];
datas.trialinfo = [1,2000];
datas.cfg = [];
datas.fsample = fsample;

cd(fullfile(output_folder))
save datas datas

