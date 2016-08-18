% HW_14.m
% Main program to test probDet.m

Pfa = 0.10;                     % 10% probability of a false alarm
sigma = 1;                      % RMS value of noise power
T = [0.001 0.1];                % Dwell time (s)
CN0 = [20 25 30 35 40 45 50];   % Carrier-to-noise ratios (dB-Hz)

[Vt Pd] = probDet(Pfa,sigma,T(1),CN0(1));