function [speed, power, total_eff, totalPower] = query_pump(Q_des, h_des, pump_data)
% QUERY_PUMP Find pump speed, power, and efficiency given flow and head
%
% Inputs:
%   Q_des     - Desired flow rate (gpm)
%   h_des     - Desired added head (ft)
%   pump_data - Struct for a single pump (e.g. pump.pump_A)
%
% Outputs:
%   speed      - Interpolated speed
%   power      - Interpolated power
%   total_eff  - Interpolated total efficiency (%)
%   totalPower - Power demand accounting for efficiency (power / total_eff / 100)

%% Step 1: Flow + Head -> Speed
[QQ, HH] = meshgrid(pump_data.Q_grid, pump_data.H_grid);
F_speed = scatteredInterpolant(QQ(:), HH(:), pump_data.speed_grid(:), 'linear', 'nearest');
speed = F_speed(Q_des, h_des);

%% Step 2, 3, 4: Head + Speed -> Power / Total Efficiency
[HH2, SS2] = meshgrid(pump_data.H_grid_pwr, pump_data.S_grid_pwr);
F_power = scatteredInterpolant(HH2(:), SS2(:), pump_data.power_grid(:),     'linear', 'nearest');
F_eff   = scatteredInterpolant(HH2(:), SS2(:), pump_data.total_eff_grid(:), 'linear', 'nearest');

power     = F_power(h_des, speed);
total_eff = F_eff(h_des, speed);

%% Step 5: Total Power = power / efficiency / 100
totalPower = power / (total_eff / 100);

%% Display
fprintf('Speed:        %.2f %% \n', speed);
fprintf('Power:       %.2f\n',     power);
fprintf('Efficiency:  %.2f%%\n',   total_eff);
fprintf('Total Power: %.2f\n',     totalPower);
end