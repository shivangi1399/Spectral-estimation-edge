% this code implements ecHT method in different datasets of simulated data

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

EPS = [0.001, 0.051, 0.101, 0.151, 0.201, 0.251, 0.301, 0.351, 0.401, 0.451];
PN = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

%% parameters

f0 = 4; %frequency of interest
filt_BW = f0/2;
Fs = 1000;
Filt_LF = f0 - filt_BW/2;
Filt_HF = f0 + filt_BW/2;

%% phase estimation for 4Hz frequency

for isess = 1
    for eps = EPS(6)
        eps
        for pn_coef = PN(5)
            pn_coef
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            load('datas.mat')
            load('datf1.mat')
            load('datf2.mat')  
            t = datas.trial{1,1}(1,1:5001);
           
            for tr= 1:500
                tr
                data = datas.trial{1,tr}(1,1:5001);
                x = echt(data, Filt_LF, Filt_HF, Fs, length(data));
                echt_phase(tr,:) = angle(x);
            end
            
            if ~isdir(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
                mkdir(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
            end
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
            save echt_phase echt_phase
        end
    end
end

%% comparison plot

for isess = 1
    isess
    for epsi = 1:length(EPS)
        eps = EPS(epsi);
        for pn_coefi = 1:length(PN)
            pn_coef = PN(pn_coefi); 
            
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef)))
            load('simData.mat')
            cd(fullfile(session_paths_folder{isess},num2str(eps),num2str(pn_coef),'echt'))
            load('echt_phase.mat')
            
            method_names = {echt_phase(:,5001)};
            title_names = {'echt'};
             
            %% PLV
            
            for method = 1
                
                diffn = method_names{method}-simData.phase_f1(:,5001); 
                vec = 1i*diffn;
                plv(epsi,pn_coefi) = (abs(sum(exp(vec))))/length(vec);
            end
            
        end
    end

end

clims = [0,1];
figure
for method = 1
    imagesc(EPS,PN,plv,clims)
    title(title_names(method))
    colormap('gray');
    colorbar
    set(gca,'YDir','normal')
end





