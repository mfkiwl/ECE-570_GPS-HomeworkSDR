% GPS_Acq_and_Track.m
% Description:  Acquire and track GPS signals
% Inputs:       f0, ADC output center frequency, Hz
%               fs, sampling frequency, Hz
%               TI, integration time, s
%               nd, correlation spacing, samples
%               B, filter equivalent noise bandwidth, Hz
%               PRN, SV IDs, array of values
%               a2, PLL damping factor
% Outputs:      Plots of DLL discriminator output (raw and filtered), PLL
%               discriminator output (raw and filtered), and navigation
%               data
% Date:         05/05/2011
% Author:       Jared Morell

clc
clear all
close all

%----------------------------
% Constants and variables
%----------------------------

% Inputs
f0 = 1.25e6;        % ADC output center (Hz)
fs = 5e6;           % Sampling frequency (Hz)
ts = 1/fs;
TI = 0.001;         % Integration time (s)
nTI = TI*fs;        % Number of samples in integration time
nd = 2;             % Correlator spacing (samples) btw early-prompt, prompt-late
B = 10;              % Filter equivalent noise bandwidth, Hz
PRN = [4 7 4 15];  % SV IDs
noSV = length(PRN); % number of SVs
phi0 = zeros(noSV,1);% initial carrier phase
deg2rad = pi/180;   % convert radians to degrees

% PLL parameters
a2 = 1.4;           % Damping factor;
wn = B*4/(a2+1/a2);

% Bilinear transformation transfer function coefficients
wnTI = wn*TI; wnTI2 = (wnTI)^2; wnTIa2 = wnTI*a2*2;
b0 = wnTI2 + wnTIa2;
b1 = 2*wnTI2;
b2 = wnTI2 - wnTIa2;
d0 = wnTI2 + wnTIa2 + 4;
d1 = 2*wnTI - 8;
d2 = wnTI2 - wnTIa2 + 4;

%-----------------------
% Begin program
%-----------------------

% Read input data and downconvert to baseband
fileName = 'simGPSL1_1sec_Nav.dat';  
fid = fopen(fileName,'r');
xm = fread(fid,'schar');  
fclose(fid);
ns = length(xm);  % number of samples in signal from data file
xb = xm'.*exp(-j*2*pi*f0*ts*[0:ns-1]);  % baseband signal
xm = xm';

% Coarse and fine acquisition
[n0Acq(3) fdAcq(3)] = Acquisition(xb, PRN(3), fs, 0.002);
%fdAcq(3) = 20;

% DLL and PLL output variables
nBlocks = floor(ns/nTI);        % number of 1 ms blocks of data
L = zeros(noSV, nBlocks);
Lp = zeros(noSV, nBlocks);
L2 = zeros(noSV, nBlocks);
Lf = zeros(noSV, nBlocks);
Zp = zeros(noSV, nBlocks);

%---------------------
% 1st millisecond
%---------------------

% Wipe Doppler frequency from 1st ms
x_in = xm(1:nTI);                       % 1 ms of data from input data signal
s = exp(-j*2*pi*(fdAcq(3)+f0)*ts*[0:nTI-1]); % generate sinusoid with coarse Doppler frequency
xTI = x_in.*s;                          % Doppler wiped

% Compute DLL discriminator output for 1st ms
L(3,1) = DLLDiscriminator6(xTI, PRN(3), fs, fdAcq(3), n0Acq(3), nd, TI);
Lp(3,1) = L(3,1);

% Compute updated code phase index
n0Acq(3) = round(n0Acq(3) + Lp(3,1));

% Wipe code and compute PLL discriminator output for 1st ms
Code = CASamples(TI,fs,fdAcq(3),PRN(3));
CP = [Code(nTI-n0Acq(3)+2:nTI) Code(1:nTI-n0Acq(3)+1)];
[L2(3,1),Zp(3,1)] = CostasDiscriminator2(xTI,CP);
Lf(3,1) = L2(3,1);

% Compute updated Doppler frequency
% phi(3) = phi(3) + Lf(3,1)*deg2rad;
fd_err = Lf(3,1)*deg2rad/(pi*TI);
fdAcq(3) = fdAcq(3) + fd_err;

%---------------------
% 2nd millisecond
%---------------------

% Wipe Doppler frequency
x_in = xm(nTI+1:2*nTI);                 % 2nd ms of data from input data signal
s = exp(-j*2*pi*(fdAcq(3)+f0)*ts*[nTI:2*nTI-1]); % generate sinusoid with coarse Doppler frequency
xTI = x_in.*s;                          % Doppler wiped

% Compute DLL discriminator output
L(3,2) = DLLDiscriminator6(xTI, PRN(3), fs, fdAcq(3), n0Acq(3), nd, TI);
Lp(3,2) = Lp(3,1) + TI*4*B*(L(3,2)-Lp(3,1));

% Compute updated code phase index
n0Acq(3) = round(n0Acq(3) + Lp(3,2));

% Wipe code and compute PLL discriminator output
Code = CASamples(TI,fs,fdAcq(3),PRN(3));
CP = [Code(nTI-n0Acq(3)+2:nTI) Code(1:nTI-n0Acq(3)+1)];
[L2(3,2),Zp(3,2)] = CostasDiscriminator2(xTI,CP);
Lf(3,2) = L2(3,2);

% Compute updated Doppler frequency
% phi(3) = phi(3) + Lf(3,1)*deg2rad;
fd_err = Lf(3,2)*deg2rad/(pi*TI);
fdAcq(3) = fdAcq(3) + fd_err;

%-------------------------
% Compute rest of data
%-------------------------

% ii is the millisecond (block) index
for ii = 3:nBlocks
    % Wipe Doppler frequency
    x_in = xm((ii-1)*nTI+1:ii*nTI);         % ms of data from input data signal
    s = exp(-j*2*pi*(fdAcq(3)+f0)*ts*[(ii-1)*nTI:ii*nTI-1]); % generate sinusoid with coarse Doppler frequency
    xTI = x_in.*s;                          % Doppler wiped
    
    % Compute DLL discriminator output
    L(3,ii) = DLLDiscriminator6(xTI, PRN(3), fs, fdAcq(3), n0Acq(3), nd, TI);
    Lp(3,ii) = Lp(3,ii-1) + TI*4*B*(L(3,ii)-Lp(3,ii-1));
    
    % Compute updated code phase index
    n0Acq(3) = round(n0Acq(3) + Lp(3,ii));
    
    % Wipe code and compute PLL discriminator output
    Code = CASamples(TI,fs,fdAcq(3),PRN(3));
    CP = [Code(nTI-n0Acq(3)+2:nTI) Code(1:nTI-n0Acq(3)+1)];
    [L2(3,ii), Zp(3,ii)] = CostasDiscriminator2(xTI, CP);
    Lf(3,ii)=(b0*L2(3,ii)+b1*L2(3,ii-1)+b2*L2(3,ii-2)-d1*Lf(3,ii-1)- ...
        d2*Lf(3,ii-2))/d0;
    
    % Compute updated Doppler frequency
    % phi(3) = phi(3) + Lf(3,1)*deg2rad;
    fd_err = Lf(3,ii)*deg2rad/(pi*TI);
    fdAcq(3) = fdAcq(3) + fd_err;
    
end

%----------------------
% Plot Results
%----------------------

% DLL Discriminator
figure();
plot(1:nBlocks,L(3,:),'r+',1:nBlocks,Lp(3,:),'bo');
h = legend('Raw Discriminator','Filtered Output',2);
set(h,'Interpreter','none');
title('DLL Discriminator Output Before and After Applying Filter'); 
xlabel('Time (ms)'); ylabel('DLL Discriminator #6');

figure();
plot(1:nBlocks,L2(3,:),'r+',1:nBlocks,Lf(3,:),'bo');
h = legend('Raw Costas Discriminator','Filtered Output',2);
set(h,'Interpreter','none');
title('PLL Discriminator Output Before and After Applying Filter'); 
xlabel('Time (ms)'); ylabel('Costas Discriminator #2');

figure();
plot(1:nBlocks,real(Zp(3,:)));
title('Navigation Data'); 
xlabel('Time (ms)'); ylabel('Data Bits');



%end