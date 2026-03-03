% This file has code for the statistical analysis for the simulated data - this is only done here for the 
% dataset with 1:1 ratio of 4Hz and 6Hz

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

title_names = {'ARfourier','EMKalman','Blackwood','Zrenner','Asymmetric Hann', 'Asymmetric Alpha', 'Hann'};

%% multiple comparisons across methods and datasets for one session - 1:1 ratio of 4Hz and 6Hz
%  plv difference is used as test statistic

%% permutations and max-min distribution

for isess = 5
    for permi = 1:1000 %number of permutations
        permi
        for epsi = 1:length(EPS)
            eps = EPS(epsi);
            for pn_coefi = 1:length(PN)
                pn_coef = PN(pn_coefi);
                
                cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
                load('simData.mat')
                load('simData_tap.mat')
                cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
                load('echt_phase.mat')
                
                method_est = {simData.ARfourier(:,3),simData.EM_Kalman(:,5001),simData.Blackwood(:,5001)+(pi/2),simData.zrenner(:,4002);...
                    simData_tap.hann_at(:,2),simData_tap.alpha_at(:,2),simData_tap.hann(:,2), echt_phase(:,5001)};
                
                title_names = {'ARfourier','EMKalman','Blackwood','Zrenner','Asymmetric Hann', 'Asymmetric Alpha', 'Hann', 'ecHT'};
                
                %% permuted plvs and percent changes
                
                perm = permutate([1:1000]);
                
                for method = 2:8
                    
                    pooled_est = vertcat(method_est{1},method_est{method});
                    ARF_perm = pooled_est(perm(1:500)); %permuted estimate for AR Fourier
                    meth_perm = pooled_est(perm(501:1000)); %permuted estimate for method 
                    
                    diffn_arf = ARF_perm-simData.phase_f1(:,5001);
                    vec_arf = 1i*diffn_arf;
                    plv_ARF = (abs(sum(exp(vec_arf))))/length(vec_arf);
                    
                    diffn_meth = meth_perm-simData.phase_f1(:,5001);
                    vec_meth = 1i*diffn_meth;
                    plv_meth = (abs(sum(exp(vec_meth))))/length(vec_meth);
                    
                    plv_diff_perf(epsi,pn_coefi,method-1) = (plv_ARF-plv_meth); %difference in PLV for permuted estimate
                    
                end
                
            end
        end
        max_dist_plvdif(1,permi) = max(plv_diff_perf,[],"all"); %max distribution
        min_dist_plvdif(1,permi) = min(plv_diff_perf,[],"all"); %min distribution
    end
end

%% Upper and lower bound for the test statistic

limh = prctile(max_dist_plvdif,97.5,"all"); %upper bound
liml = prctile(min_dist_plvdif,2.5,"all"); %lower bound



