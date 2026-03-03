% method comparison for emperical data (scanning data) - true phase for comparison is calculated using hann taper
% phase compariosn is done at -0.5s (so that the erp does not interfere in comparison)- some method results 
% are already saved before when methods_implementation.m was run

clear all
close all
clc

%%

addpath /add/path/to/your/folder/software_folder/fieldtrip-master/
ft_defaults
addpath /add/path/to/your/folder/software_folder/esi-nbf
addpath /add/path/to/your/folder/software_folder/slurmfun-master/
clc

%% Create data paths 

% path to temporary data
datafolder = '/add/path/to/your/folder/data/empirical_data';

session_names = [];
session_names = {'klecks_20170804_attentional-sampling_1'};

% create cell paths
session_paths = [];
session_paths = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

% path to save output
output_folder = '/add/path/to/your/folder/results/empirical_data/';
output_paths = cellfun(@(x) fullfile(output_folder, x),session_names, 'uniform',0);

title_names = {'ARFourier','Wodeyar2021','Zrenner2020','Blackwood2018','Asbai2014', 'Hann', 'Schreglmann2021'};

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
%% AR Fourier method - rest of the extrapolation methods are saved already

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
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Running phase estimation for taper based methods

%% Asymmetric Hann Taper

cd('/add/path/to/your/folder/software_folder/fieldtrip-master/')

f      = 10; %10Hz
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
f      = 10; %10Hz
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Comparison and statistics

%% plots

freq = 5; %for 10Hz

for ichan = 1:length(zdat.label)
    
    cd(fullfile(output_paths{isess},'channels',num2str(ichan)))
    load phase_est
    
    diffn = ar_fourierph(:,freq,ichan)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(1,ichan) = (abs(sum(exp(vec))))/length(vec);
    
    diffn = phase_est.EMKalman(:,501)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(2,ichan)= (abs(sum(exp(vec))))/length(vec);
    
    diffn = phase_est.Zrenner(:,1)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(3,ichan) = (abs(sum(exp(vec))))/length(vec);
    
    diffn = (phase_est.Blackwood(:,501)+(pi/2))-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(4,ichan) = (abs(sum(exp(vec))))/length(vec);
    
    diffn = hannph_at(:,ichan)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(5,ichan) = (abs(sum(exp(vec))))/length(vec);
    
    diffn = hannph_pr(:,ichan)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(6,ichan) = (abs(sum(exp(vec))))/length(vec);
    
    cd(fullfile(output_paths{isess},'channels',num2str(ichan),'echt'))
    load echt_phase
    
    diffn = echt_phase(:,501)-hannph(:,ichan,freq);
    vec = 1i*diffn;
    plv(7,ichan)= (abs(sum(exp(vec))))/length(vec);
    
end

%% result figure

% parameters
sz = 35;
markerEdgeColor = [14, 39, 72] / 255;
markerFaceColor = [0, 157, 154] / 255;

% figure
figure('Color', 'w', 'Position', [100, 100, 950, 600])

for imethod = 2:7
    subplot(2,3,imethod-1) 
    
    scatter(plv(imethod,:), plv(1,:), sz, 'MarkerEdgeColor', markerEdgeColor, ...
        'MarkerFaceColor', markerFaceColor,...
        'LineWidth', 2, 'Marker', 'o');
    
    %scatterhist(plv(imethod,:), plv(1,:));
    
    % Set axis limits
    xlim([0, 1])
    ylim([0, 1])
    xticks([0 0.2 0.4 0.6 0.8 1])
    yticks([0 0.2 0.4 0.6 0.8 1])
    
    ax = gca;
    ax.XAxis.TickDirection = 'out';
    ax.YAxis.TickDirection = 'out';
    hold on
    
    plot(xlim, ylim, '--k', 'LineWidth', 1) % Plot diagonal reference line
    
    xlabel(title_names(imethod), 'FontSize', 11, 'FontWeight', 'bold', 'FontName', 'Arial')
    ylabel('AR Fourier', 'FontSize', 11, 'FontWeight', 'bold', 'FontName', 'Arial')
   
end

sgtitle('Scatter Plot of PLV for Different Methods', 'FontSize', 12, 'FontWeight', 'bold', 'FontName', 'Arial')

%% wilcoxon sign ranked test - non parametric

for imethod = 2:7
    [p,h] = signrank(plv(imethod,:),plv(1,:)); 
    p
    h
end
% null hypothesis that x - y comes from a distribution with zero median
% h = 1 indicates a rejection of the null hypothesis







