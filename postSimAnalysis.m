%% This script writes the scenario summary table and generates plots into a results folder.


%%% Plots of interest
%1) Permeate vs. Brine Flow Generation
%2) Power demand by treatment stage
%3) Net Power Demand vs. Solar Generation + Battery Discharge
%4) Flow Setpoint vs. Flow Actual
%5) Brine vs. Permeate Salinity (g/L)
%%%

% Defined in runSimSettings.mlx function:
%   - Peak demand charge times
%   - Demand charges
%   - Brine charges

% From simout simulation output:
%   - time
%   - total energy consumption
%   - energy consumption by skid
%   - total permeate flow
%   - total brine flow
%   - permeate/brine salinity
%   - instantaneous power consumption
%   - instantaneous solar generation
%   - instantaneous battery discharge/charge
%%%


%% Summary Data
% Summary Data Needed:
%   -max on peak demand (kW)
%   -max off peak demand (kWh)
%   -On peak demand charge ($)
%   - Off peak demand charge ($)
%   - Net demand charge ($)
%   -Total Energy consumption (kWh)
%   -Total Energy costs ($)

%Calculate outputs
%1) peak demands
%Get on peak and off peak windows
window_min = peak_window(1) * 60;
window_max = peak_window(2) * 60;

peakIdx = rem(simOut.tout,1440) >= window_min & rem(simOut.tout,1440) <= window_max;

% Calculate maximum on-peak and off-peak demands
max_on_peak_demand_kW = max(simOut.power.Plant_NetPowerDemand_kW.Data(peakIdx));
max_off_peak_demand_kW = max(simOut.power.Plant_NetPowerDemand_kW.Data(~peakIdx));

% Calculate demand charges
on_peak_demand_charge_dol = max_on_peak_demand_kW * peak_demand_charge;
off_peak_demand_charge_dol = max_off_peak_demand_kW * offpeak_demand_charge;
net_demand_charge_dol = on_peak_demand_charge_dol + off_peak_demand_charge_dol;

%2) total energy consumption 
total_energy_consumption_kWh = abs(simOut.power.Plant_TotalEnergyDemand_kWh.Data(end));
total_energy_cost_dol = simOut.power.Plant_TotalEnergyCosts_dol.Data(end);

%3) Brine costs
total_brine_generated_MG = simOut.flows.Plant_TotalBrineProduction_MG.Data(end);
total_brine_cost_dol = total_brine_generated_MG*brine_disposal_rate_dolMG;
total_permeate_generated_MG = simOut.flows.Plant_TotalPermeateProduction_MG;


%create new row. 
newRow = table( ...
    string(operations_case), ...
    string(solar_generation_worksheet), ...
    maximum_solar_generation, ...
    string(TOU_case), ...
    peak_demand_charge, ...
    offpeak_demand_charge, ...
    peak_window(1), ...
    peak_window(2),...
    batteryScenario, ...
    UF_ShutdownEnabled, ...
    UF_RecoveryRate, ...
    ROstabilization_time, ...
    PROS1_recoveryrate, ...
    PROS2_recoveryrate, ...
    TSRO_recoveryrate, ...
    brine_disposal_rate_dolaf, ...
    max_on_peak_demand_kW, ...
    max_off_peak_demand_kW, ...
    on_peak_demand_charge_dol, ...
    off_peak_demand_charge_dol, ...
    net_demand_charge_dol, ...
    total_energy_consumption_kWh, ...
    total_energy_cost_dol,...
    total_brine_cost_dol,...
    total_permeate_generated_MG,...
    total_brine_generated_MG,...
    'VariableNames', { ...
        'operations_case', ...
        'solar_generation_sampledate', ...
        'maximum_solar_generation', ...
        'TOU_case', ...
        'peak_demand_cost', ...
        'offpeak_demand_cost', ...
        'peak_window_start', ...
        'peak_window_end',...
        'Battery_Scenario', ...
        'UF_ShutdownEnabled', ...
        'UF_RecoveryRate', ...
        'ROstabilization_time', ...
        'PROS1_recoveryrate', ...
        'PROS2_recoveryrate', ...
        'TSRO_recoveryrate', ...
        'brine_disposal_rate_dolaf', ...
        'max_on_peak_demand_kW', ...
        'max_off_peak_demand_kW', ...
        'on_peak_demand_charge_dol', ...
        'off_peak_demand_charge_dol', ...
        'net_demand_charge_dol', ...
        'total_energy_consumption_kWh', ...
        'total_energy_cost_dol', ...
        'total_brine_cost_dol',...
        'total_permeate_generated_MG',...
        'total_brine_generated_MG'
    });


if ~isfile(fullfile(results_folder,"results.xlsx"))
    writetable(newRow, fullfile(results_folder,"results.xlsx"), "WriteMode", "overwrite", "WriteVariableNames", true);
else
    writetable(newRow, fullfile(results_folder,"results.xlsx"), "WriteMode", "append", "WriteVariableNames", false);
end
%% Plots
if plot_save == true
    simTime = simOut.tout;
    %% Plot 1 - Permeate vs. Brine Flow Generation
    flows = simOut.flows;
    permeate_target = 62.48; %Million Gallons
    
    % Calculate total permeate and brine flow for plotting
    totalPermeateFlow = squeeze(flows.Plant_TotalPermeateProduction_MG.Data);
    totalBrineFlow = squeeze(flows.Plant_TotalBrineProduction_MG.Data);
    
    %brine and permeate conductivity for plotting
    permeateSalinity = flows.Plant_PermeateTDS_gL.Data;
    brineSalinity = squeeze(flows.Plant_BrineTDS_gL.Data);
    
    
    
    figure('Name','Permeate vs. Brine Flow Generation','NumberTitle','off');
    subplot(2,1,1);
    p1 = plot(simTime, totalPermeateFlow, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
    hold on
    p2 = plot(simTime, totalBrineFlow, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2);
    p3 = yline(permeate_target, 'k:', 'LineWidth', 1.5);
    ax = gca;
    ax.XLimitMethod = 'tight';
    hold off
    
    xlabel('Simulation Time (min)')
    ylabel('Total Flow (MG)')
    title('Permeate and Brine Flow Generation')
    
    legend([p1 p2 p3], {'Total Permeate Flow','Total Brine Flow','Permeate Target'}, 'Location','best')
    grid on
    
    subplot(2,1,2);
    yyaxis left
    p1 = plot(simTime, permeateSalinity, '-', 'Color', [0 0.45 0.74], 'LineWidth', 1.2);
    hold on
    
    yyaxis right
    p2 = plot(simTime, brineSalinity, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2);
    ax = gca;
    ax.XLimitMethod = 'tight';
    hold off
    
    xlabel('Simulation Time (min)')
    ylabel('Salinity (g/L)')
    title('Permeate and Brine Flow Salinity')
    
    legend([p1 p2], {'Combined Permeate Salinity','Brine Salinity'}, 'Location','best')
    grid on
    
    exportgraphics(gcf, fullfile(run_folder, "flows_salinties.png"), 'Resolution', 300)
    
    
    %% Plot 2 - Power Demand by treatment unit
    % Plot 2.1 - Stacked area chart of grouped power demands
    
    pd = simOut.power;
    
    % Make sure simTime is a column vector
    simTime = simTime(:);
    
    groups = struct([]);
    
    groups(1).label  = "UF Pumps";
    groups(1).fields = ["UFPump_1_Power", ...
                        "UFPump_2_Power", ...
                        "UFPump_3_Power", ...
                        "UFPump_4_Power"];
    
    groups(2).label  = "PROS1";
    groups(2).fields = ["PROS1_1_Power_kW", ...
                        "PROS1_2_Power_kW", ...
                        "PROS1_3_Power_kW", ...
                        "PROS1_4_Power_kW"];
    
    groups(3).label  = "PROS2";
    groups(3).fields = ["PROS2_1_Power_kW", ...
                        "PROS2_2_Power_kW", ...
                        "PROS2_3_Power_kW", ...
                        "PROS2_4_Power_kW"];
    
    groups(4).label  = "TSRO";
    groups(4).fields = ["TSRO_1_Power_kW", ...
                        "TSRO_2_Power_kW", ...
                        "TSRO_3_Power_kW", ...
                        "TSRO_4_Power_kW"];
    
    groups(5).label  = "UVAOP";
    groups(5).fields = ["UVAOP_1_Power_kW", ...
                        "UVAOP_2_Power_kW"];
    
    groups(6).label  = "Decarbonator";
    groups(6).fields = "Decarbonator_Power_kW";
    
    
    % Sum to get power demand of each equipment group
    
    Y = zeros(numel(simTime), numel(groups));
    labels = strings(numel(groups), 1);
    
    for g = 1:numel(groups)
    
        labels(g) = groups(g).label;
    
        for f = 1:numel(groups(g).fields)
    
            fieldName = groups(g).fields(f);
    
            if ~isfield(pd, fieldName)
                warning("Missing field: %s", fieldName);
                continue;
            end
    
            sig = pd.(fieldName);
    
            % Extract signal time and data
            t = sig.Time(:) / 60;      % convert seconds to minutes
            y = squeeze(sig.Data);
            y = y(:);                  % force column vector
    
    
            % Add this signal to the group total
            Y(:,g) = Y(:,g) + y;
        end
    end
    
    
    % Generate stacked area chart
    
    figure("Name", "Stacked Power Demand", "Color", "w");
    
    area(simTime, Y);
    ax = gca;
    ax.XLimitMethod = 'tight';
    grid on;
    box on;
    
    xlabel("Simulation Time [min]");
    ylabel("Power Demand [kW]");
    title("Process Power Demand");
    
    legend(labels, ...
        "Location", "best");
    exportgraphics(gcf, fullfile(run_folder, "local_power_demand.png"), 'Resolution', 300)
    
    %% Plot 3: Net Power Demand vs. Solar and Battery
    demand  = squeeze(pd.Plant_LocalPowerDemand_kW.Data);
    solar   = squeeze(pd.Plant_SolarGeneration_kW.Data);
    battery = squeeze(pd.Plant_Battery_Power_kW.Data);
    net     = -1*demand + solar - battery;
    
    figure('Name','Power Demand Components','NumberTitle','off');
    
    % net drawn first as a filled area so it sits behind everything else
    a1 = area(simTime, net, 'FaceColor', 'w', 'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1.0, 'FaceColor',[0.85 0.85 0.85]);
    hold on
    
    p1 = plot(simTime, demand,  '-', 'Color', [0 0.45 0.74],  'LineWidth', 2);
    p2 = plot(simTime, solar,   '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 2);
    p3 = plot(simTime, battery, '-', 'Color', [0.47 0.67 0.19], 'LineWidth', 2);
    ax = gca;
    ax.XLimitMethod = 'tight';
    hold off
    
    xlabel('Simulation Time (min)')
    ylabel('Power (kW)')
    title('Net Power Generation')
    legend([p1 p2 p3 a1], {'Process Power Demand','Solar Generation','Battery Power','Net Power'}, 'Location','best')
    grid on
    exportgraphics(gcf, fullfile(run_folder, "net_power_demand.png"), 'Resolution', 300)
end

