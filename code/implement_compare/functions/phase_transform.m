function [phase_ar] = phase_transform(cfg_diff)

ichan  = cfg_diff.ichan;
iter_n = cfg_diff.iter_n;
toi    = cfg_diff.toi;

% phase

for iter=1:iter_n
    cd(cfg_diff.inputfile)
    cd(num2str(iter))
    load('freqpow.mat')
    %ph(iter,:,:) = squeeze(angle(freqpow.fourierspctrm(:,ichan,:,toi)));
    phf(iter,:,:) = squeeze(freqpow.fourierspctrm(:,ichan,:,toi));
    clear freqpow
end

cd(cfg_diff.inputfile)
cd(num2str(iter))
load('freqpow.mat')

ph_vec= squeeze(mean(phf,1)./abs(mean(phf,1)));
amp_vec=squeeze(mean(abs(phf),1));
Pf_avg = amp_vec.*(ph_vec);   % the phase we decided to use
phase_ar = angle(Pf_avg);

% save
phase = [];
%phase.trialinfo = freqpow.trialinfo; % remove comment when using on real data
phase.label = freqpow.label;
phase.iter_phase = angle(phf);
phase.ar_phase = phase_ar;
%phase.ogs_phase = phase_og;
% phase.diff = diff;

cd(cfg_diff.outputfile)
ESIsave phase phase







