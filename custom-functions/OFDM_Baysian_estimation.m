% Generate OFDM waveform from 16/64QAM constellation with random phase shift
% includes 6 zero-power subcarriers (DC and guard band) for 20MHz
% bandwidth. The setting corresponds to the non-zero part of the HE-LTF 
% sequence.
% A Baysian MAP estimator, approximated by Monte-Carlo Samples is used to
% estimate the OFDM sequence from partial observation.

% Parameters:
N_symb = 122;        % number of transmitted symbols
N_ifft = 128;        % IFFT size (includes oversampling)
N_alpha = 64;       % 16 or 64; size of alphabet, QAM
sigma_w = 0.000578*2;     % noise assumption 0.000578 = 10dB

s_64QAM = 3/7;      % per dimension variance in 64 QAM
s_16QAM = 5/9;      % per dimension variance in 16 QAM

% Estimate sent sequence
obs_portion = 0.8;  % 0.8 corresponds to 80% OFDM signal observation
N_MC = 300;         % Number of monte carlo rounds

% convert portion into samples:
N_obs = floor(N_ifft*obs_portion);

% preset the rand stream
    stream1 = RandStream('mcg16807','Seed',1); stream2 = RandStream('mcg16807','Seed',2);

% constellation diagram for 16QAM and 64QAM and generate random symbols
    if N_alpha == 16 %16-QAM
        a_sentsequence = randi(stream1,4,N_symb,1)-2.5 + 1i*(randi(stream2,4,N_symb,1)-2.5);
        symb_alphabet = zeros(16,1);
        for i = 1:4
            for q = 1:4
                symb_alphabet(4*(i-1)+q) = i-2.5 + 1i*(q-2.5);
            end
        end
        % Normalization to max I/Q of 1:
        symb_alphabet = symb_alphabet/1.5;
        a_sentsequence = a_sentsequence/1.5;
    
    elseif N_alpha == 64 %64-QAM
        a_sentsequence = randi(stream1,8,N_symb,1)-4.5 + 1i*(randi(stream2,8,N_symb,1)-4.5);
        symb_alphabet = zeros(16,1);
        for i = 1:8
            for q = 1:8
                symb_alphabet(8*(i-1)+q) = i-4.5 + 1i*(q-4.5);
            end
        end
        %Normalization to max I/Q of 1:
        symb_alphabet = symb_alphabet/3.5;
        a_sentsequence = a_sentsequence/3.5;
    else
        warning('wrong symbol number - only 16 and 64 supported')
    end

% add zero-subcarriers:
    a_sentsequence_full = [0;0;0;a_sentsequence(1:N_symb/2);0;a_sentsequence(N_symb/2+1:N_symb);0;0];


% generate OFDM time domain signal:
    %phase_shift = 1;%exp(-1i*pi/4); % for debugging - fixed phase
    phase_shift = exp(1i*pi/4*(1-randi(2))); % random phase shift
    s_true = ifft(a_sentsequence_full*phase_shift,N_ifft); %s_true = fftshift(ifft(a_sentsequence*phase_shift,N_ifft));

% Channel: add noise
    w = randn(N_ifft,1)*sqrt(sigma_w/2) + 1i*randn(N_ifft,1)*sqrt(sigma_w/2); % noise
    s = s_true+w;
    
% phase shift in radiant and as index
    beta = [0,pi/4];
    beta_loop = [1,2];
    
% sample set on OFDM symbols
        % carlo samples
    if N_alpha == 16 % 16QAM
        C_MC = randi(4,N_symb,N_MC)-2.5 + 1i*(randi(4,N_symb,N_MC)-2.5); % generate random symbols
        C_MC = C_MC/1.5;
        s2=s_16QAM/N_ifft;
    elseif N_alpha == 64 % 64QAM
        C_MC = randi(8,N_symb,N_MC)-4.5 + 1i*(randi(8,N_symb,N_MC)-4.5);
        C_MC  = C_MC/3.5;
        s2=s_64QAM/N_ifft;
    end

% Init probability matrices for soft information output
    P_sample = zeros(N_alpha,N_symb,2); 
    P_beta = zeros(2,1);

% Estimation    
    for i_beta = beta_loop % loop through phase shift
        for i=1:N_MC       % Monte Carlo iterations
            for k_symb=1:N_symb % loop through non-zero subcarriers
                    C_is = C_MC(:,i) * exp(-1i*beta(i_beta)); % select current MC sample and apply phase shiftN_obs(n_obs)
                    C_is_full = [0;0;0;C_is(1:N_symb/2);0;C_is(N_symb/2+1:N_symb);0;0;0];
                    s_guess = ifft(C_is_full,N_ifft); %s_guess = fftshift(ifft(C_is,N_ifft));
                    diff2_received_reconstructed = sum(abs(s(1:N_obs)-s_guess(1:N_obs)).^2);

                    % Soft information on phase shift
                    p_observed = exp(-diff2_received_reconstructed/2/sigma_w)*1/sqrt(pi*sigma_w);

                    % catch numerical instabilities
                    if diff2_received_reconstructed<inf
                        P_beta(i_beta) = P_beta(i_beta) + p_observed;
                    end

                    % Soft information on constellation diagram
                    for symb = 1:N_alpha % loop through all possible constellation points of k_symb subcarrier
                        % overwrite k_symb position
                        C_is(k_symb) = symb_alphabet(symb) * exp(-1i*beta(i_beta));

                        % generate time-domain signal
                        C_is_full = [0;0;0;C_is(1:N_symb/2);0;C_is(N_symb/2+1:N_symb);0;0;0];
                        s_guess = ifft(C_is_full,N_ifft);
                
                        % compute probability of MC sample at current
                        % constellation point:
                        diff2_received_reconstructed = sum(abs(s(1:N_obs)-s_guess(1:N_obs)).^2);
                        p_word = exp(-diff2_received_reconstructed/2/sigma_w);

                        % sum up probabilities
                        P_sample(symb,k_symb,i_beta) = P_sample(symb,k_symb,i_beta) + p_word;
                    end    
            end % end subcarrier loop
        end % end MC   
    end % end phase loop

% estimate phase shift
i_beta_est = find(P_beta==max(P_beta));
beta_loop = [i_beta_est];   

% estimate symbols and evaluate entropy
C_est_max = zeros(N_symb,1);
H=0; NLL=0;
beta_est = beta(i_beta_est);
for k_symb = 1:N_symb
    % max value
    C_est_max(k_symb) = symb_alphabet(P_sample(:,k_symb,i_beta_est)==max(P_sample(:,k_symb,i_beta_est)))*exp(-1i*beta_est);
    C_est_max_full = [0;0;0;C_est_max(1:N_symb/2);0;C_est_max(N_symb/2+1:N_symb);0;0;0];

    P_symb = P_sample(:,k_symb,i_beta_est)/sum(P_sample(:,k_symb,i_beta_est));
    % negative log loss as measure for posterior probability (proper
    % scoring rule): NLL = -log(p(x*)
    % average NLL is cross entropy
    % lower is better
    NLL = NLL - log2(P_symb(symb_alphabet == a_sentsequence(k_symb)))/N_symb;

    % entropy (sharpness)
    % H(p) = - sum_x p(x) log_2(p(x))
    H = H + sum(sum(P_symb.*log2(P_symb)))/N_symb;
end

% time domain signal
s_est_max = ifft(C_est_max_full,N_ifft);
% time domain error:
td_err = s_true-s_est_max;



% NLL and entropy result
fprintf(1,"NLL=%.1f; H=%.1f;\n",NLL,H);

% plot
figure(1)
subplot(2,1,1)
rectangle('Position',[0,-0.25,N_obs,0.5],'FaceColor',[0.8 .9 .9]); hold on;
text(5,-0.2,'observed samples','FontSize',9,'Color',[0.478, 0.510, 0.514])
plot(real(s_true),'r--','LineWidth',2)
ylabel('Amplitude I')
subplot(2,1,2)
rectangle('Position',[0,-0.25,N_obs,0.5],'FaceColor',[0.8 .9 .9]); hold on;
text(5,-0.2,'observed samples','FontSize',9,'Color',[0.478, 0.510, 0.514])
plot(imag(s_true),'r--','LineWidth',2)
ylabel('Amplitude Q')
xlabel('Time domain sample')
s_display = s_est_max;
subplot(2,1,1)
plot(real(s_display),'g')
plot(real(td_err),'b:')
subplot(2,1,2)
plot(imag(s_display),'g')
plot(imag(td_err),'b:')

legend('OFDM Signal','MAP estimate','Error Signal','Location','southeast')

