function [flow, power, total_eff, totalPower] = query_pump_from_speed_head(speed_des, h_des, pump_data)
% QUERY_PUMP_FROM_SPEED_HEAD Find flow, power, and efficiency given speed and head
%
% Inputs:
%   speed_des - Desired speed
%   h_des     - Desired head (ft)
%   pump_data - Struct for a single pump (e.g. pump.pump_A)
%
% Outputs:
%   flow       - Interpolated flow (gpm)
%   power      - Interpolated power
%   total_eff  - Interpolated total efficiency (%)
%   totalPower - Power demand accounting for efficiency (power / total_eff / 100)

%% Reconstruct interpolants from saved grids
[HH, SS] = meshgrid(pump_data.H_grid_pwr, pump_data.S_grid_pwr);
F_flow  = scatteredInterpolant(HH(:), SS(:), pump_data.flow_grid(:),      'linear', 'nearest');
F_power = scatteredInterpolant(HH(:), SS(:), pump_data.power_grid(:),     'linear', 'nearest');
F_eff   = scatteredInterpolant(HH(:), SS(:), pump_data.total_eff_grid(:), 'linear', 'nearest');

%% Query
flow      = F_flow(h_des,  speed_des);
power     = F_power(h_des, speed_des);
total_eff = F_eff(h_des,   speed_des);

%% Total Power
totalPower = power / (total_eff / 100);

%% Display
fprintf('Flow:        %.2f gpm\n', flow);
fprintf('Power:       %.2f\n',     power);
fprintf('Efficiency:  %.2f%%\n',   total_eff);
fprintf('Total Power: %.2f\n',     totalPower);

end