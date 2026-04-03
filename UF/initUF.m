%This script will be used to intialize the parameters for ultrafiltration
%Primary UF

disp("Priming UF Model. Loading...")

%membrane area
A_UF = 775; %ft^2
modules_UF = 80; %modules/skid
modules_RUF = 30; %modules/skid

%Pressure drop
%deltaPz = p(T) * g * z
%p(T) = density at temperature T, lb/ft3
%g = gravity acceleration, ft/s2
%z = module height
%Pz = pressure drop psi, 
z = 12; %skid height, ft
g = 32.2 * 60^2; %gravity acceleration, ft/min2


 if ~exist("GAM","var")
    disp("UF GAM not found. Loading...")
    S = load("ufFoulingPred_GAM.mat");
    GAM = S.gamMdl;
    GAM = assignin('base','GAM', GAM);
    disp("UF Loaded.")
 end


%Define Initial Condition maximums to be used in a uniform distribution
%across units

CIP_Max_Time = 15000;
CEB_Max_Time = 1000;
BW_Max_Time = 90;
BW_Max_Vol_gal = 5000;
CEB_Max_Vol_gal = 5000;