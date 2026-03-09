% Zero-power GI PSD estimation

% The PSD and spectral-mask analysis code is meant to run inside the WLAN Toolbox IEEE 802.11az positioning example "HERangingPositioningExample.mlx".
% It should be placed in the helper function "heRangingWavGenPlot.m", after the ranging waveform has been generated, so that it can reuse the existing variables.

% -- Use the following settings in "HERangingPositioningExample.mlx":
%
%     cfg = heRangingConfig('NumTransmitAntennas',2);
%     cfg.User{1}.NumSpaceTimeStreams = 2;
%     cfg.User{1}.NumHELTFRepetition = 5;

%     cfg = heRangingConfig('NumTransmitAntennas',2,'SecureHELTF',true);
%     cfg.User{1}.NumSpaceTimeStreams = 2;
%     cfg.User{1}.NumHELTFRepetition = 8;
%     cfg.User{1}.SecureHELTFSequence = '12345678ABCDEF1234';

% ----------------------------
% Spectrum plots (ideal vs PA, with mask) + metrics
% ----------------------------

plotSpectrum = true;
if plotSpectrum

    nfft   = 16384; % power of two for efficient computation
    maxWin = 4096;

    osf = 6; % oversample for PA + PSD evaluation
    usePA = true; % do we want NL model

    % ---- 20 MHz interim transmit spectral mask (27.3.19.1), dBr ----
    maskPos_f = [0    9.75  10.5  20   30]; % breakpoints
    maskPos_y = [0    0     -20   -28  -40]; % max levels

    fMaxPlot = 35; % for plotting, extended
    maskPos_f_ext = [maskPos_f  fMaxPlot];
    maskPos_y_ext = [maskPos_y  -40];

    mask_f = [-fliplr(maskPos_f_ext(2:end)) maskPos_f_ext];
    mask_y = [ fliplr(maskPos_y_ext(2:end)) maskPos_y_ext];

    % Helper: evaluate mask at arbitrary frequency offsets (MHz), symmetric
    maskAt = @(fMHz) interp1(maskPos_f, maskPos_y, min(abs(fMHz), fMaxPlot), 'linear', 'extrap');

    % ---- Prepare PA model (Rapp) ----
    if usePA
        nl = comm.MemorylessNonlinearity;
        nl.Method = 'Rapp model';
        nl.Smoothness = 4;              
        nl.OutputSaturationLevel = 0.7; 
        nl.InputScaling  = 1;
        nl.OutputScaling = 1;
    end

    % ============================
    % Figure 1: Full packet
    % ============================

    x1 = y(:); % take everything
    x1_os = resample(x1, osf, 1);
    sr_os = sr * osf; % sample rate oversampled

    x1_ideal = x1_os; % without NL model

    if usePA
        x1_pa = nl(x1_os);
    else
        x1_pa = x1_os;
    end

    L1 = min(maxWin, length(x1_ideal));

    if L1 < 64
        error('Full packet segment too short for PSD (length %d samples).', length(x1_ideal));
    end

    win1 = hann(L1,'periodic'); % define window
    noverlap1 = floor(0.75*L1);
    nfft1 = max(nfft, 2^nextpow2(L1));

    [PpktIdeal,f] = pwelch(x1_ideal, win1, noverlap1, nfft1, sr_os, 'centered');
    [PpktPA,   ~] = pwelch(x1_pa,    win1, noverlap1, nfft1, sr_os, 'centered');

    % --- dBr references ---
    refPktIdeal = max(PpktIdeal);
    refPktPA    = max(PpktPA);

    % Ideal shown relative to its own peak (0 dBr at peak)
    PpktIdeal_dB = 10*log10(PpktIdeal./refPktIdeal);

    % PA shown relative to its own peak (mask definition)
    PpktPA_dB    = 10*log10(PpktPA./refPktPA);

    fMHz = f/1e6;

    % -------- Packet metrics, helpers: margin to mask (PA curve, PA-referenced dBr) --------
    maskPkt_dB = arrayfun(maskAt, fMHz);
    marginPkt_dB = PpktPA_dB - maskPkt_dB; % >0 means PA PSD exceeds mask

    roiPkt = (abs(fMHz) >= 20) & (abs(fMHz) <= 30);
    worstPkt = max(marginPkt_dB(roiPkt));
    p99Pkt   = prctile(marginPkt_dB(roiPkt), 99);

    exceedIdxPkt = roiPkt & (marginPkt_dB > 0);
    fracExceedPkt = 100 * nnz(exceedIdxPkt) / nnz(roiPkt);
    maxExceedPkt  = max([0; marginPkt_dB(exceedIdxPkt)]);

    fprintf('PACKET (PA): 20-30 MHz margin-to-mask: worst=%+0.2f dB, p99=%+0.2f dB, exceed=%0.1f%%, maxExceed=%0.2f dB\n', ...
            worstPkt, p99Pkt, fracExceedPkt, maxExceedPkt);

    % Optional diagnostic: how different the PA peak spectral density is vs ideal
    fprintf('PACKET peak PSD shift (PA vs ideal): %+0.2f dB\n', 10*log10(refPktPA/refPktIdeal));
    
    % -------- Plotting --------
    figure;
    axP = gca;
    plot(axP, fMHz, PpktIdeal_dB, 'LineWidth', 1.0); hold on;
    plot(axP, fMHz, PpktPA_dB,    'LineWidth', 1.0); hold on;
    plot(axP, mask_f, mask_y, 'k-', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency offset (MHz)');
    ylabel('PSD (dBr, each curve referenced to its own peak)');
    title('Packet spectrum (ideal vs PA) with 20 MHz spectral mask');
    legend('Packet ideal','Packet with PA','Spectral mask','Location','best');
    xlim(axP, [-35 35]);
    ylim(axP, [-80 10]);

    figure;
    plot(fMHz, marginPkt_dB, 'LineWidth', 1.0); grid on;
    xlim([-35 35]); ylim([-40 20]);
    xlabel('Frequency offset (MHz)');
    ylabel('Margin to mask (dB) (PA PSD minus mask)');
    title('PACKET: Margin to spectral mask (positive means violation)');

    % ============================
    % Figure 2: HE-LTF only
    % ============================

    hStart = ind(1,1);
    hStop  = ind(numel(cfg.User),2);
    hStop  = min(hStop, length(y));

    x2 = y(hStart:hStop);
    x2_os = resample(x2(:), osf, 1);

    x2_ideal = x2_os;
    if usePA
        x2_pa = nl(x2_os);
    else
        x2_pa = x2_os;
    end

    L2 = min(maxWin, length(x2_ideal));
    if L2 < 64
        error('HE-LTF segment too short for PSD (length %d samples).', length(x2_ideal));
    end
    win2 = hann(L2,'periodic');
    noverlap2 = floor(0.75*L2);
    nfft2 = max(nfft, 2^nextpow2(L2));

    [PheIdeal,f2] = pwelch(x2_ideal, win2, noverlap2, nfft2, sr_os, 'centered');
    [PhePA,   ~ ] = pwelch(x2_pa,    win2, noverlap2, nfft2, sr_os, 'centered');

    % --- dBr references ---
    refHeIdeal = max(PheIdeal);
    refHePA    = max(PhePA);

    PheIdeal_dB = 10*log10(PheIdeal./refHeIdeal);
    PhePA_dB    = 10*log10(PhePA./refHePA);

    f2MHz = f2/1e6;

    % -------- HE-LTF metrics: margin to mask (PA curve, PA-referenced dBr) --------
    maskHe_dB = arrayfun(maskAt, f2MHz);
    marginHe_dB = PhePA_dB - maskHe_dB;

    roiHe = (abs(f2MHz) >= 20) & (abs(f2MHz) <= 30);
    worstHe = max(marginHe_dB(roiHe));
    p99He   = prctile(marginHe_dB(roiHe), 99);

    exceedIdxHe = roiHe & (marginHe_dB > 0);
    fracExceedHe = 100 * nnz(exceedIdxHe) / nnz(roiHe);
    maxExceedHe  = max([0; marginHe_dB(exceedIdxHe)]);

    fprintf('HE-LTF (PA): 20-30 MHz margin-to-mask: worst=%+0.2f dB, p99=%+0.2f dB, exceed=%0.1f%%, maxExceed=%0.2f dB\n', ...
            worstHe, p99He, fracExceedHe, maxExceedHe);

    fprintf('HE-LTF peak PSD shift (PA vs ideal): %+0.2f dB\n', 10*log10(refHePA/refHeIdeal));

    % Plots
    figure;
    axH = gca;
    plot(axH, f2MHz, PheIdeal_dB, 'LineWidth', 1.0); hold on;
    plot(axH, f2MHz, PhePA_dB,    'LineWidth', 1.0); hold on;
    plot(axH, mask_f, mask_y, 'k-', 'LineWidth', 1.5);
    grid on;
    xlabel('Frequency offset (MHz)');
    ylabel('PSD (dBr, each curve referenced to its own peak)');
    title('HE-LTF spectrum (ideal vs PA) with 20 MHz spectral mask');
    legend('HE-LTF ideal','HE-LTF with PA','Spectral mask','Location','best');
    xlim(axH, [-35 35]);
    ylim(axH, [-80 10]);

    figure;
    plot(f2MHz, marginHe_dB, 'LineWidth', 1.0); grid on;
    xlim([-35 35]); ylim([-40 20]);
    xlabel('Frequency offset (MHz)');
    ylabel('Margin to mask (dB) (PA PSD minus mask)');
    title('HE-LTF: Margin to spectral mask (positive means violation)');

end
