function [Jw, cperm] = solutionDiffusion(T, Pfeed, Pperm, A, B, cmem, cperm_prev, pi_feed, pi_perm)
%calculates the water and solute flux across the membranes surface. Note
%that movement towards the permeate side is positive
%Pi_x = osmostic pressure (bar)
%Px =mechanical pressure (bar)
%A,B = permeability and selectivity coefficients (L/m2/min/bar, L/m2/min)
%cx = TDS concentration (g/L)

%This section of code will need to be updated if using PRO or TSRO
%PRO TCF calcs

R = 8.314; %Gas constant [J/molK]


TCF = exp(2700 *(1/(T + 273)-1/(25+273)));

delta_pi = pi_feed - pi_perm; %osm pressure across the surface. expected positive
delta_P = Pfeed - Pperm; %mechanical pressure across the mem surface. Expected Positive
Pnet = delta_P - delta_pi; %total transmembrane pressure
Jw = A * Pnet/TCF; %Water Flux [L/m2/min]

cnet = cmem - cperm_prev; %net concentration gradient
Js = B * cnet; %salt flux [g/m2min]

%handle NaNs when Jw == 0
if Jw > 0.01
    cperm = Js/Jw;
else
    cperm = 0;
end
end