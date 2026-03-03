% Run this file for methods comparisons - these components were used to compose the results figure 
% This code compares the methods across the different simulated datsets to check which methods are 
% better suited for different combinations of phase diffusion and noise coefficient 
% results are only shown for the dataset with 1:1 ratio of 4Hz and 6Hz

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

title_names = {'ARFourier','Wodeyar2021','Blackwood2018','Zrenner2020','Asbai2014', 'Mitchell2007', 'Hann', 'Schreglmann2021'};

%% plotting the colorplots for one session %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% blue color palatte 

cd('/add/path/to/your/folder/plotting')
colormap_data = load('YlGnBu_colormap.mat');
YlGnBu_colormap = colormap_data.YlGnBu_colormap;

% Ensure the colormap is in the correct format (RGB only)
if size(YlGnBu_colormap, 2) == 4
    YlGnBu_colormap = YlGnBu_colormap(:, 1:3); 
end

%% plv plots

plvfolder = '/add/path/to/your/folder/comparison';

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(plvfolder,x), session_names, 'uniform',0);

idata = 5;
cd(fullfile(session_paths_folder{idata}))
load('plv_allmeth.mat')
plv = plv_allmeth;
    
fs = 16;
fontName = 'Arial';
imageWidth = 700;
imageHeight = 600;
clims = [0,1];

for method = 1:8
    figure('Position', [100, 100, imageWidth, imageHeight])
    imagesc(EPS,PN,plv(:,:,method)',clims)
    title(title_names(method))
    %xlim([0 0.455])
    xticks([0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45])
    yticks([0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9])
    colormap(YlGnBu_colormap); 
    colorbar
    set(gca,'YDir','normal')
    ax = gca;
    ax.FontSize = fs-1;
    ax.FontName = fontName;
    set(gca,'TickLength',[0 0])
end

%% spectral color palatte 

cd('/add/path/to/your/folder/plotting')
colormap_data = load('spectral_colormap.mat');
spectral_colormap = colormap_data.spectral_colormap;

% Ensure the colormap is in the correct format (RGB only)
if size(spectral_colormap, 2) == 4
    spectral_colormap = spectral_colormap(:, 1:3); 
end

%% plv difference plots

plvfolder = '/add/path/to/your/folder/comparison';

session_paths_folder = [];
session_paths_folder = cellfun(@(x) fullfile(plvfolder,x), session_names, 'uniform',0);

idata = 5;
cd(fullfile(session_paths_folder{idata}))
load('plv_allmeth.mat')
plv = plv_allmeth;
    
fs = 16; 
fontName = 'Arial';
imageWidth = 700;
imageHeight = 600;
clims = [-0.6,0.61];

for method = 2:8
    figure('Position', [100, 100, imageWidth, imageHeight])
    a = plv(:,:, 1)' - plv(:,:, method)';
    max(a,[],'all')
    min(a,[],'all')
    imagesc(EPS,PN,a,clims)
    title(title_names(method))
    xticks([0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45])
    yticks([0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9])
    colormap(spectral_colormap)
    colorbar
    set(gca,'YDir','normal')
    ax = gca;
    ax.FontSize = fs-1;
    ax.FontName = fontName;
    set(gca,'TickLength',[0 0])
end

%% plv difference with transparency mask to show significance

% range for the transparency mask
gray_min = -0.117; %we get this after running the statistical_analysis code
gray_max = 0.116; %we get this after running the statistical_analysis code

transparency_factor = 0.5; %transparency factor for the mask (0 = fully transparent, 1 = fully opaque)
clims = [-0.6,0.61];

for method = 2:8
    figure('Position', [100, 100, imageWidth, imageHeight])
    a = plv(:,:,1)' - plv(:,:,method)';
    
    mask = a >= gray_min & a <= gray_max; % Create a mask for the specified range

    h = imagesc(EPS, PN, a, clims); % Plot the data
    
    % Apply the original colormap
    colormap(spectral_colormap);
    colorbar;
    set(gca, 'YDir', 'normal');

    % Set alpha data for transparency
    alpha_data = ones(size(a)); % Default alpha (fully opaque)
    alpha_data(mask) = transparency_factor; % Apply transparency to the masked region

    set(h, 'AlphaData', alpha_data); 

    % Customize appearance
    title(title_names(method));
    %xlim([0 0.455]);
    xticks([0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45]);
    yticks([0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]);
    ax = gca;
    ax.FontSize = fs - 1;
    ax.FontName = fontName;
    set(gca, 'TickLength', [0 0]);
end

%% Plotting cross sections %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plotting cross section of the colorplots - PLV
colors = [
    14, 39, 72;    
    0, 157, 154;     
    59, 141, 204;    
    39, 59, 145;   
    159, 29, 84;    
    240, 79, 88;   
    84, 16, 18   
    204, 121, 167   
] / 255;

plvfolder = '/add/path/to/your/folder/comparison';
session_paths_folder = cellfun(@(x) fullfile(plvfolder, x), session_names, 'uniform', 0);

fs = 12.5;
fontName = 'Arial';  

imageWidth = 750;
imageHeight = 600;

for idata = 5
    cd(fullfile(session_paths_folder{idata}))
    load('plv_allmeth.mat')
    plv = plv_allmeth;
    
    % Plot with Noise Coefficient fixed at 0.25
    figure('Position', [100, 100, imageWidth, imageHeight])  
    for pn_idx = 5
        for method = 1:8  
            plot(EPS, plv(:, pn_idx, method), '-o','Color', colors(method, :), 'LineWidth', 2)
            hold on
        end
        xlim([0 0.455])
        xticks([0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45])
        ylim([0 1])
      
        ax = gca;
        ax.FontSize = fs-1;
        ax.FontName = fontName;
        ax.XAxis.TickDirection = 'out';
        ax.YAxis.TickDirection = 'out';
        leg = legend('ARFourier', 'Wodeyar2021', 'Blackwood2018', 'Zrenner2020', 'Asbai2014', 'Mitchell2007', 'Hann', 'Schreglmann2021');
        leg.FontSize = fs;
        leg.FontName = fontName;  
        legend boxoff
        xlabel('Phase Diffusion', 'FontSize', fs, 'FontName', fontName)
        ylabel('PLV', 'FontSize', fs, 'FontName', fontName)
        title('Noise Coefficient fixed at 0.5', 'FontSize', fs+2, 'FontName', fontName, 'FontWeight', 'normal')
        
    end
    
    % Plot with Phase Diffusion fixed at 0.5 
    figure('Position', [100, 100, imageWidth, imageHeight])  
    for eps_idx = 6
        for method = 1:8
            plot(PN, plv(eps_idx, :, method),  '-o','Color', colors(method, :), 'LineWidth', 2)
            hold on
        end
        xticks([0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9])
        ylim([0 1])
        xlim([0.1 0.9])
        
        ax = gca;
        ax.FontSize = fs-1;
        ax.FontName = fontName;
        ax.XAxis.TickDirection = 'out';
        ax.YAxis.TickDirection = 'out';
        leg = legend('ARFourier', 'Wodeyar2021', 'Blackwood2018', 'Zrenner2020', 'Asbai2014', 'Mitchell2007', 'Hann', 'Schreglmann2021');
        leg.FontSize = fs;
        leg.FontName = fontName;  
        legend boxoff
        xlabel('Noise Coefficient', 'FontSize', fs, 'FontName', fontName)
        ylabel('PLV', 'FontSize', fs, 'FontName', fontName)
        title('Phase Diffusion fixed at 0.25', 'FontSize', fs+2, 'FontName', fontName, 'FontWeight', 'normal')  
        
    end
end
%% plotting cross section of the colorplots - Difference in PLV

colors = [   
    0, 157, 154;     
    59, 141, 204;    
    39, 59, 145;   
    159, 29, 84;    
    240, 79, 88;   
    84, 16, 18   
    204, 121, 167   
] / 255;

plvfolder = '/add/path/to/your/folder/comparison';
session_paths_folder = cellfun(@(x) fullfile(plvfolder, x), session_names, 'uniform', 0);

fs = 12.5;
fontName = 'Arial';  
imageWidth = 750;
imageHeight = 600;

for idata = 5
    cd(fullfile(session_paths_folder{idata}))
    load('plv_allmeth.mat')
    plv = plv_allmeth;
    
    % Plotting difference in PLV with respect to Phase Diffusion
    figure('Position', [100, 100, imageWidth, imageHeight]) 
    for pn_idx = 5
        for method = 2:8
            a = plv(:, pn_idx, 1) - plv(:, pn_idx, method);
            plot(EPS, a,'-o', 'Color', colors(method - 1, :), 'LineWidth', 2)
            hold on
        end
        yline(0.1161, '--', 'Color', 'k', 'LineWidth', 1.5)  
        yline(-0.1170, '--', 'Color', 'k', 'LineWidth', 1.5)  
        xlim([0 0.455])
        ylim([-0.2 1])
        yticks([-0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1])
        ax = gca;
        ax.FontSize = fs-1;
        ax.FontName = fontName;
        ax.XAxis.TickDirection = 'out';
        ax.YAxis.TickDirection = 'out';
        xlabel('Phase Diffusion', 'FontSize', fs, 'FontName', fontName)
        ylabel('Difference in PLV', 'FontSize', fs, 'FontName', fontName)
        title('Noise Coefficient fixed at 0.5', 'FontSize', fs+2, 'FontName', fontName, 'FontWeight', 'normal')
        legend('Wodeyar2021', 'Blackwood2018', 'Zrenner2020', 'Asbai2014', 'Mitchell2007', 'Hann', 'Schreglmann2021', 'FontSize', fs, 'FontName', fontName)
        legend boxoff
    end
    
    % Plotting difference in PLV with respect to Noise Coefficient
    figure('Position', [100, 100, imageWidth, imageHeight]) 
    for eps_idx = 6
        for method = 2:8
            a = plv(eps_idx, :, 1) - plv(eps_idx, :, method);
            plot(PN, a, '-o','Color', colors(method - 1, :), 'LineWidth', 2)
            hold on
        end
        yline(0.1161, '--', 'Color', 'k', 'LineWidth', 1.5)  
        yline(-0.1170, '--', 'Color', 'k', 'LineWidth', 1.5)  
        ylim([-0.2 1])
        yticks([-0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1])
        ax = gca;
        ax.FontSize = fs-1;
        ax.FontName = fontName;
        ax.XAxis.TickDirection = 'out';
        ax.YAxis.TickDirection = 'out';
        xlabel('Noise Coefficient', 'FontSize', fs, 'FontName', fontName)
        ylabel('Difference in PLV', 'FontSize', fs, 'FontName', fontName)
        title('Phase Diffusion fixed at 0.25', 'FontSize', fs+2, 'FontName', fontName, 'FontWeight', 'normal')
        legend('Wodeyar2021', 'Blackwood2018', 'Zrenner2020', 'Asbai2014', 'Mitchell2007', 'Hann', 'Schreglmann2021', 'FontSize', fs, 'FontName', fontName)
        legend boxoff
    end
end










