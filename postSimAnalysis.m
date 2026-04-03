%% Build Scenario Summary Table from SimulationOutput

scenarioNames = {
    'highTOU_HighSolar',     ... % High Solar   | High TOU
    'baseTOU_HighSolar',     ... % High Solar   | Baseline TOU
    'staticTOU_HighSolar',   ... % High Solar   | No TOU
    'HighTOU_baseSolar',     ... % Base Solar   | High TOU
    'baseline',              ... % Base Solar   | Baseline TOU
    'staticTOU_BaseSolar',   ... % Base Solar   | No TOU
    'HighTOU_noSolar',       ... % No Solar     | High TOU
    'baseTOU_NoSolar',       ... % No Solar     | Baseline TOU
    'staticTOU_NoSolar'      ... % No Solar     | No TOU
};

% Demand rate constants
onPeakDemandRate  = 3.27;   % $/kW  (4pm–9pm)
offPeakDemandRate = 23.28;  % $/kW  (all other hours)

% On-peak window in minutes since midnight (4pm = 960, 9pm = 1260)
onPeakStart = 960;
onPeakStop  = 1260;

% Preallocate output arrays
nScenarios       = numel(scenarioNames);
totalEnergyKWh   = zeros(nScenarios, 1);
totalOpex        = zeros(nScenarios, 1);
onPeakDemCharge  = zeros(nScenarios, 1);
offPeakDemCharge = zeros(nScenarios, 1);
totalDemCharge   = zeros(nScenarios, 1);

for i = 1:nScenarios
    sName = scenarioNames{i};

    % Pull the dataset from the SimulationOutput logsout
    % Alternative: if out is a struct of structs
    ds = out.(sName);
    % Squeeze out singleton dimensions (1x1xN → Nx1)
    power  = squeeze(ds.PowerDemand_Net_kW.Data);
    energy = squeeze(ds.EnergyDemand_Total_kWh.Data);
    opex   = squeeze(ds.Total_Opex__.Data);
    t      = out.tout;   % or ds.tout, etc.
    % --- On-peak mask: 4pm (960 min) to 9pm (1260 min) ---
    onPeakMask  = (t >= onPeakStart) & (t <= onPeakStop);
    offPeakMask = ~onPeakMask;

    % --- Peak demands (raw kW) ---
    maxOnPeakKW(i)  = max(power(onPeakMask));
    maxOffPeakKW(i) = max(power(offPeakMask));

    onPeakDemCharge(i)  = maxOnPeakKW(i)  * onPeakDemandRate;
    offPeakDemCharge(i) = maxOffPeakKW(i) * offPeakDemandRate;
    totalDemCharge(i)   = onPeakDemCharge(i) + offPeakDemCharge(i);

    % --- Total Energy Demand: last value in cumulative kWh column ---
    totalEnergyKWh(i) = energy(end);

    % --- Total OpEx: last value in cumulative Opex column ---
    totalOpex(i) = opex(end);
end

%% Assemble the Table
T = table( ...
    scenarioNames(:), ...          % force Nx1 cell array
    totalEnergyKWh(:), ...         % force Nx1
    maxOnPeakKW(:), ...
    maxOffPeakKW(:), ...
    onPeakDemCharge(:), ...
    offPeakDemCharge(:), ...
    totalDemCharge(:), ...
    totalOpex(:), ...
    'VariableNames', { ...
        'Scenario', ...
        'TotalEnergyDemand_kWh', ...
        'OnPeakDemand_kW', ...
        'OffPeakDemand_kW', ...
        'OnPeakDemandCharge_USD', ...
        'OffPeakDemandCharge_USD', ...
        'TotalDemandCharge_USD', ...
        'TotalOpex_USD' ...
    });
%% Helper: format a number with commas and 2 decimal places
fmt = @(x) regexprep(sprintf('%.2f', x), '\d{1,3}(?=(\d{3})+\.)', '$0,');

%% Print formatted table to console
fprintf('\n%-25s %22s %18s %18s %22s %22s %22s %20s\n', ...
    'Scenario', ...
    'TotalEnergy(kWh)', ...
    'OnPeakDem(kW)', ...
    'OffPeakDem(kW)', ...
    'OnPeakCharge($)', ...
    'OffPeakCharge($)', ...
    'TotalDemCharge($)', ...
    'TotalOpex($)');

fprintf('%s\n', repmat('-', 1, 175));

for i = 1:nScenarios
    fprintf('%-25s %22s %18s %18s %22s %22s %22s %20s\n', ...
        scenarioNames{i}, ...
        fmt(totalEnergyKWh(i)), ...
        fmt(maxOnPeakKW(i)), ...
        fmt(maxOffPeakKW(i)), ...
        fmt(onPeakDemCharge(i)), ...
        fmt(offPeakDemCharge(i)), ...
        fmt(totalDemCharge(i)), ...
        fmt(totalOpex(i)));
end

fprintf('%s\n', repmat('-', 1, 175));

fprintf('Total Permeate Produced: %.02f MG', out.flows.Plant_TotalPermeateProduction_MG.Data(end))
fprintf('Total Brine Produced: %.02f MG', out.flows.Plant_TotalBrineProduction_MG.Data(end))
