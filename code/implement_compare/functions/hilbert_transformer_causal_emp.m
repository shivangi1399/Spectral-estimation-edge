function [phase, analytic] = hilbert_transformer_causal_emp(data, buffer_len, band)
% hilbert_transformer_phase: estimate real-time phase using a hilbert transformer,
% using AR prediction to offset the group delay.
%
% Syntax: [phase, estimate_mask, analytic] = hilbert_transformer_phase(...
%   data, buffer_len, [ht_b], [band], [Fs], [upsample]);
%
% Input:
%    data:       raw data at 30 kHz
%    buffer_len: number of 30 kHz samples per buffer
%    [ht_b]:     (designed using firpm) numerator of (FIR) Hilbert
%                transformer to use, at 500 Hz sample rate.
%    [band]:     ([4 8]) target frequency band, in Hz
%    [Fs]:       (30000) sample rate in Hz, must be a multiple of 500.
%    [upsample]: (false) whether to upsample using linear interpolation
%
% Output:
%    phase:         estimated phase in radians
%    lower/upperPhase: estimated confidence bounds for phase
%    analytic:      analytic signal (same size as "phase" output)

assert(isvector(data), 'Data must be a vector');

fit_ws = buffer_len;

Fs = 1000;
Fs_ds = 1000;
ds_factor = Fs / Fs_ds;

% bandpass filter
[b, a] = butter(2, band/(Fs/2));
data_filt = filter(b, a, data);

% hilbert transformer
ht_order = 18; 
ht_freq = [band(1) (Fs_ds/2)-band(1)] / (Fs_ds/2);
ht_b = firpm(ht_order, ht_freq, [1 1], 'hilbert');

ht_offset_samp = ht_order / 2;
f_resp = freqz(ht_b, 1, (band(1):0.1:band(2)) * 2 * pi / Fs_ds);
mag_resp = abs(f_resp);
% normalize by geometric mean of magnitude response range
scale_factor = 1/sqrt(min(mag_resp) * max(mag_resp));

% ar prediction (want to save ~1 second of data for training)
ar_order = 5; % ALTERED FROM 20 -- note that thinking in the oscillator fromework an order of 5 allows two potential oscillators.
ar_buf_len = max(fit_ws, 2 * ar_order); % max(Fs_ds, 2 * ar_order); 
ar_buf = zeros(ar_buf_len, 1);

% state setup for filter
ht_state = zeros(ht_order, 1);

%outputs
analytic_buf = zeros(size(data_filt)-buffer_len);

max_n_samp = ceil(buffer_len / ds_factor);

ar_out = zeros(ar_buf_len + ht_offset_samp + 1, 1);
ht_buf = zeros(max_n_samp + ht_offset_samp + 1, 1);
ht_out = ht_buf;

for kBuf = 1+buffer_len:length(data_filt) % runs across all data points
    % get downsampled samples in this buffer
    buf_ds = data_filt(kBuf-buffer_len+1:kBuf);
    n_samp = length(buf_ds);
    ht_buf_offset = max_n_samp - n_samp;
    
    % push new samples to ar buffer
    ht_buf = buf_ds;
    ar_buf = buf_ds;
    
    % extend by the hilbert transformer offset
    % only fit the AR model every second: ---- remove this condition
    if mod(kBuf-1,fit_ws) ==0
        [ar_out(:),params, noise,~] = ar_extend(ar_buf, ht_offset_samp + 1, [], ar_order);
        ht_buf = ar_out;
        x_ext = ar_out(end-ht_offset_samp:end);
    else
        % else predict out the AR model at every new sample
        [x_ext,~] = ar_predict(ht_buf, ht_offset_samp+1, params, noise);
        ht_buf = [ht_buf', x_ext'];
    end
    
    % apply hilbert transformer (2 steps)
    ht_out(:) = 0;
    % save state at t0
    [ht_out(ht_buf_offset + 1:max_n_samp), ht_state] = filter(ht_b, 1, ...
        ht_buf(ht_buf_offset + 1:max_n_samp),ht_state);
    
    % apply to extension w/o saving state
    [ht_out(max_n_samp+1:max_n_samp+1+ht_offset_samp)] = filter(ht_b, 1, ...
        ht_buf(max_n_samp+1:max_n_samp+1+ht_offset_samp),ht_state);
    
    % get analytic signal
    % note that analytic signal is coming only from the AR forecasted
    % samples alone
    analytic_buf(kBuf-fit_ws+1) = complex(ht_buf(max_n_samp+1), scale_factor * ht_out(max_n_samp+1+ht_offset_samp));
    
end

% reshape and get phase estimates
analytic  = [zeros(1,length(data_filt) - length(analytic_buf)),analytic_buf];
phase = angle(analytic);

