% change weights of different frequencies and phase diffusion strengths to implement the different 
% filter based phase estimation methods for each of the simulated datasets

clear all
close all
clc

%%

addpath /add/path/to/your/folder/software_folder/fieldtrip-master/
ft_defaults
addpath /add/path/to/your/folder/software_folder/esi-nbf
addpath /add/path/to/your/folder/software_folder/slurmfun-master/
clc

%% load files

datafolder = '/add/path/to/your/folder/results/simulated_data';
session_names = [];
session_names = {'freq46_10_2','freq46_10_4','freq46_10_6','freq46_10_8','freq46_11'}; % for different ratios of freq

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

%% Parameters

EPS = [0.001, 0.051, 0.101, 0.151, 0.201, 0.251, 0.301, 0.351, 0.401, 0.451];
PN = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

%% Taper based methods

Fs     = 1000;
f      = 2:2:10;

for isess = 5
    isess
    for epsi = 6%1:length(EPS)
        eps = EPS(epsi)
        for pn_coefi = 5%1:length(PN)
            pn_coef = PN(pn_coefi)
            
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            load('datas.mat')
            load('datf1.mat')
            load('datf2.mat')
            
            simData_tap = [];
            simData_tap.data = datas;
            simData_tap.phase_f1 = datf1;
            simData_tap.phase_f2 = datf2;
            
            %% asymmetric hann taper
            
            cycles = 2;
            toi    = minus(5.0010,(1./f));
            
            % fourier
            cfg            = [];
            cfg.output     = 'fourier';
            cfg.method     = 'mtmconvol';
            cfg.taper      = 'hann_at';
            cfg.keeptrials = 'yes';
            cfg.foi        = f;
            cfg.t_ftimwin  = cycles./cfg.foi;
            cfg.toi        = toi; 
            freqpow        = ft_freqanalysis_at(cfg, datas);
            
            % phase
            hann_at = [];
            for ift= 1:length(f)
                hann_at(:,ift) = squeeze(angle(freqpow.fourierspctrm(:,1,ift,ift)));
            end
           
            simData_tap.hann_at = hann_at;
            
            %% asymmetric alpha taper
            
            cycles = 5;
            toi    = minus(5.0010,(1./f));
            
            % fourier
            cfg            = [];
            cfg.output     = 'fourier';
            cfg.method     = 'mtmconvol';
            cfg.taper      = 'alpha';
            cfg.keeptrials = 'yes';
            cfg.foi        = f;
            cfg.t_ftimwin  = cycles./cfg.foi;
            cfg.toi        = toi; 
            freqpow        = ft_freqanalysis_at(cfg, datas);
            
            % phase
            alpha_at = [];
            for ift= 1:length(f)
                alpha_at(:,ift) = squeeze(angle(freqpow.fourierspctrm(:,1,ift,ift)));
            end
            
            simData_tap.alpha_at = alpha_at;
            
            %% hann taper - proxy critical time
            
            cycles = 2;
            toi    = minus(5.0010,(1./f));
            
            % fourier
            cfg            = [];
            cfg.output     = 'fourier';
            cfg.method     = 'mtmconvol';
            cfg.taper      = 'hann';
            cfg.keeptrials = 'yes';
            cfg.foi        = f;
            cfg.t_ftimwin  = cycles./cfg.foi;
            cfg.toi        = toi;
            freqpow        = ft_freqanalysis(cfg, datas);
            
            % phase
            hannph = [];
            for ift= 1:length(f)
                hannph(:,ift) = squeeze(angle(freqpow.fourierspctrm(:,1,ift,ift)));
            end
            
            simData_tap.hann = hannph;
            
            %% saving 
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            save simData_tap simData_tap
            
        end
    end
end











