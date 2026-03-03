% This code compares the methods using an accuracy measure called PLV - this is done across the 
% different simulated datsets to check which methods are better suited for different combinations of 
% phase diffusion and noise coefficient

clear all
close all
clc

%% load files

datafolder = '/add/path/to/your/folder/results/simulated_data';
session_names = [];
session_names = {'freq46_10_2','freq46_10_4','freq46_10_6','freq46_10_8','freq46_11'}; % for different ratios of freq

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(datafolder,x), session_names, 'uniform',0);

EPS = [0.001, 0.051, 0.101, 0.151, 0.201, 0.251, 0.301, 0.351, 0.401, 0.451];
PN = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

%% performance of different methods - plv (Phase Locking Value) 

plvfolder = '/add/path/to/your/folder/comparison';

plv_path_folder = [];
plv_path_folder = cellfun(@(x) fullfile(plvfolder,x), session_names, 'uniform',0);

for isess = 5
    isess
    for epsi = 1:length(EPS)
        eps = EPS(epsi);
        for pn_coefi = 1:length(PN)
            pn_coef = PN(pn_coefi);
            
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            load('simData.mat')
            load('simData_tap.mat')
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
            load('echt_phase.mat')
            
            method_names = {simData.ARfourier(:,3),simData.EM_Kalman(:,5001),simData.Blackwood(:,5001)+(pi/2),simData.zrenner(:,4002),simData_tap.hann_at(:,2),simData_tap.alpha_at(:,2),simData_tap.hann(:,2),echt_phase(:,5001)};
            title_names = {'ARfourier','EMKalman','Blackwood','Zrenner','Asymmetric Hann', 'Asymmetric Alpha', 'Hann', 'ecHT'};
   
            %% PLV
            
            for method = 1:8
                
                diffn = method_names{method}-simData.phase_f1(:,5001); 
                vec = 1i*diffn;
                plv(epsi,pn_coefi,method) = (abs(sum(exp(vec))))/length(vec);
                
            end
            
        end
    end
    plv_allmeth = plv;
    cd(fullfile(plv_path_folder{isess}))
    save plv_allmeth plv_allmeth 
end

% this will only run properly if you have all the phase estimations for all the different 
% datsets (i.e. all combinations of phase diffusion and noise coefficient for a particular 
% session or ratio of frequency). We have saved plv_allmeth saved from our
% run for the results figures script.

%% plotting the plv

clims = [0,1];
figure
for method = 1:8
    subplot(4,2,method)
    imagesc(EPS,PN,plv(:,:,method),clims)
    title(title_names(method))
    colormap('gray');
    colorbar
    set(gca,'YDir','normal')
end


