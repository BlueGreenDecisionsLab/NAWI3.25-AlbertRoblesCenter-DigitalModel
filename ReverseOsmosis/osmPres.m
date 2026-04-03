function [p] = osmPres(T, c)
    %this function finds the osmotic pressure at the membrane's surface
    %assumes that all osmotic pressure is driven by NaCl
    %c = concentration in g/L
    %T = temp in C
    osmCoef = .93; %next step: create index table 
    vantHoff = 2;
    R = 8.314; %Gas constant [J/molK]
    c_mol = c / 58.44 * vantHoff; %convert g/L to Mol of NaCl
    p = osmCoef * (T+273) * R * c_mol * .01; %pressure in Bar

end
