function [cm] = ConP(cb, T, dh, L, u, Jw)
% this function calculates the concentration of the feed membrane surface due to concentration polarization
%This model follows a solution diffusion model relating the bulk solution
%concentration (cb) [g/L], temperature (T) [oC], hydraulic diameter (dh) [cm], pore length (L) [cm], and Water Flux (Jw) [L/m2-min] to the concentration at the
%membrane
%Assumes laminar flow in a rectangular channel and diffusion is only for
%NaCl

%convert Jw to cm/s from L/m2/min
Jw = Jw * 0.0016667;

%Kinematic Visc Table. [oC, m2/s]
kin_visc_table = [0 1.792e-6;
    10 1.308e-6;
    20 1.004e-6;
    30 0.797e-6;
    40 0.658e-6;
    50 0.553e-6;
    60 0.477e-6;
    70 0.419e-6;
    80 0.372e-6;
    90 0.334e-6;
    100 0.303e-6];



% Interpolate to find the kinematic viscosity at the given temperature
v = interp1(kin_visc_table(:,1), kin_visc_table(:,2), T) * 10000; %cm2/s


D = 1.135 * 10^-5; %diffusion coefficient of NaCl [cm2/s] THIS CHANGES w/ C AND T [future step]
Sc = v/D; %Schmidt Number [unitless]

Re = dh * u / v; %Reynolds Number [unitless]

Sh = 1.85*(Re * Sc * dh / L)^.33; %Sherwood Number for rectangular channel with laminar flow

kf = Sh * D / dh; %diffusion rate constant for NaCl (cm/s)

cm = cb * exp(Jw / kf); %membrane concentration

end
