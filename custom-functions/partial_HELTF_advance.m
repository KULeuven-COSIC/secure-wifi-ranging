% Signal generation for attacking secure HE-LTF signal.
%
% -- include the subsequent code lines in "HERangingPositioningExample.mlx"
%
% The following code lines have to be included in MATLAB IEEE802.11az 
% positioning example "HERangingPositioningExample.mlx" at line 125, i.e.:
%
% 123> % Pass waveform through AWGN channel
% 124> rx = awgn(txMultipath,snrVal);
% 125>   % --- include here ----%
% 126> % Perform synchronization and channel estimation
% 127> [chanEstActiveSC,integerOffset] = heRangingSynchronize(rx,cfg);
%
%
% -- Use the following settings in "HERangingPositioningExample.mlx":
%
%     chanBW = 'CBW20'; % Channel bandwidth
%     numTx  = 1; % Number of transmit antennas
%     numRx  = 1; % Number of receive antennas
%     numSTS = 1; % Number of space-time streams
%     numLTFRepetitions = 1; % Number of HE-LTF repetitions
%     cfgSTABase = heRangingConfig;
%     cfgSTABase.ChannelBandwidth = chanBW;
%     cfgSTABase.NumTransmitAntennas = numTx;
%     cfgSTABase.SecureHELTF = true;
%     cfgSTABase.User{1}.NumSpaceTimeStreams = numSTS;
%     cfgSTABase.User{1}.NumHELTFRepetition = numLTFRepetitions;
%     cfgSTABase.GuardInterval = 1.6;
%     cfgAPBase = cell(1,numAPs);
%     for iAP = 1:numAPs
%         cfgAPBase{iAP} = heRangingConfig;
%         cfgAPBase{iAP}.ChannelBandwidth = chanBW;
%         cfgAPBase{iAP}.NumTransmitAntennas = numTx;
%         cfgAPBase{iAP}.SecureHELTF = true;
%         cfgAPBase{iAP}.User{1}.NumSpaceTimeStreams = numSTS;
%         cfgAPBase{iAP}.User{1}.NumHELTFRepetition = numLTFRepetitions;
%         cfgAPBase{iAP}.GuardInterval = 1.6;
%     end
%     
%     ofdmInfo = wlanHEOFDMInfo('HE-LTF',chanBW,cfgSTABase.GuardInterval);
%     sampleRate = wlanSampleRate(chanBW);
%
% and the channel settings:
%
%     delayProfile = 'Model-A'; % TGax channel multipath delay profile
%     
%     carrierFrequency = 5.18e9; % Carrier frequency, in Hz
%     speedOfLight = physconst('lightspeed');
%     
%     chanBase = wlanTGaxChannel;
%     chanBase.DelayProfile = delayProfile;
%     chanBase.NumTransmitAntennas = numTx;
%     chanBase.NumReceiveAntennas = numRx;
%     chanBase.SampleRate = sampleRate;
%     chanBase.CarrierFrequency = carrierFrequency;
%     chanBase.ChannelBandwidth = chanBW;
%     chanBase.PathGainsOutputPort = true;
%     chanBase.NormalizeChannelOutputs = false;
%
%
% -- Configuration of the attack:
%
%   observed         ... in %; indicates the signal portion before attack.
%   advance          ... in samples; indicates the time advance of the
%                        attack portion
%
% simplified assumption: legitimate rx signal is used as attacker input.
% The following code till modify the variable "rx".

advance = 0.1;  % time advance of the attack portion
observed = 0.8; % 0.8 indicates that 80% of the samples are observed before
                % an attack is launched

% indices of secure HE-LTF sequence for the settings indicated above
index_secureLTFstart = 754; index_secureLTFend = 880; 
index_attack_start = index_secureLTFstart + round((index_secureLTFend - ...
                     index_secureLTFstart)*observed);



% separate advance value in integer and fractional part
A = floor(advance);       % integer samples
alpha = advance - A;      % fractional samples in [0,1)


% obtain the attack sequence
seg =  rx(index_attack_start:index_secureLTFend+A); % integer extraction
Nseg = numel(seg);
n = (0:Nseg-1).';                 % original sample indices
seg_frac = interp1(n, seg, n + alpha, 'spline', 0); % interpolate to obtain
                                  % fractional advance

% overwrite the rx signal in the attack portion:
rx(index_attack_start-A:index_secureLTFend) = seg_frac;