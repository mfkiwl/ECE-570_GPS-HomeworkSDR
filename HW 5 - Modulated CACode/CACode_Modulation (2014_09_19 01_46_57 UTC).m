% CACode_Modulation.m
% Description:  Generates carrier modulated CA code power spectrum, auto-
%               correlation, and cross-correlation
% Inputs:       2 PRN's to be cross-correlated, the first of which will
%               also undergo auto-correlation
% Outputs:      Plotted results of the carrier modulated signal, its power 
%               spectrum, and cross- and auto-correlation
% Date:         02/22/2011
% Modified:     N/A
% Creator:      Jared Morell

clc
clear all
close all

% Constants and variables
PRN1 = 1;       % PRN of SV
PRN2 = 2;       % PRN of SV
fs = 5e6;       % sampling rate (Hz)
fd1 = 0;        % Doppler frequency of 1st SV (Hz)
fd2 = 0;        % Doppler frequency of 2nd SV (Hz)
Ts = 1/fs;      % time between samples (s)
fc = 1.25e6;    % carrier frequency (Hz)
A = 1;          % signal amplitude (V)
phi = 0;        % phase of carrier (rad)
endTime = 0.001;% sampling will occur from 0 to endTime seconds
t = 0:Ts/7:(endTime-Ts/7);  % time vector (s)
m = endTime*7000;           % number of CA code periods to generate

% generate and sample CA code for both SVs
C1 = CASamples(m,fs,PRN1,fd1);
C2 = CASamples(m,fs,PRN2,fd2);

% modulate carrier with C1 and C2
x1 = A*C1.*cos(2*pi*fc*t+phi);
x2 = A*C2.*cos(2*pi*fc*t+phi);

% plot carrier modulated signals
figure(1);
subplot(2,1,1); plot(t,x1,'r');
title(['Carrier Modulated Signal Using PRN ',num2str(PRN1),' CA code']); 
xlabel('Time (s)'); ylabel('Amplitude (V)');
subplot(2,1,2); plot(t,x2,'b');
title(['Carrier Modulated Signal Using PRN ',num2str(PRN2),' CA code']); 
xlabel('Time (s)'); ylabel('Amplitude (V)');

% correlation
cross=crossCorr(x1,x2); % cross-correlation of x1 and x2
auto=crossCorr(x1,x1);  % auto-correlation of x1

% power spectrum
power = 10*log10(abs(fft(auto)));

% plot power spectrum and auto- and cross-correlation
[~,s]=size(cross);
c = 0:(s-1);      % samples vector
figure(2);
subplot(3,1,1); plot(c,cross,'r');
title('Cross-Correlation'); xlabel('Index'); ylabel('Correlation Value');
subplot(3,1,2); plot(c,auto,'g');
title('Auto-Correlation'); xlabel('Index'); ylabel('Correlation Value');
subplot(3,1,3); plot(c,power,'b');
title('Power Spectrum'); xlabel('Index'); ylabel('Magnitude');





