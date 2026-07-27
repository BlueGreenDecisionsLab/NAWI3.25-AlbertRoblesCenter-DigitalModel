%% ARC_ParameterSweep.m
% Defines a parameter grid, builds every combination (full factorial),
% and loops through them. Fill in the set_param calls and constants in
% the marked section below.
% this returns the full path to the current file (function or script)
fullFileName = matlab.desktop.editor.getActiveFilename;

% split off the folder
[folderPath, ~, ~] = fileparts(fullFileName);

%add complete folder & subfolders to cd
cd(folderPath)
addpath(genpath(folderPath));

%Load underlying models into workspace.
% UVAOP ANNs
try
    if ~exist('net_1flow', 'var') || ~exist('net_2flow', 'var')
        load('UVAOP_ANN_Flow.mat', 'net_1flow', 'net_2flow');
        disp('UVAOP ANNs loaded')
    else
        disp('UVAOP ANNs already in workspace.')
    end
catch ME
    error('Failed to load UVAOP_ANN_Flow.mat: %s', ME.message);
end

%UF, PROS1, PROS2, and TSRO pump loads.
try
    load("Pumps\LookupTables.mat")
    disp('Pump lookup tables loaded')
catch ME
    error('Failed to load pump lookup tables. Please see Pumps/LookupTables.mat. \n %s', ME.message)
end

%UF Fouling model
try
    LUT_load = load("gamLUT.mat");
    LUT = LUT_load.gamLUT;
    disp('UF Fouling model loaded.')
catch ME
    error('Failed to load UF fouling model. Please see UF/ufFoulingPred_GAM.mat. \n %s', ME.message)
end

initUF;
minimum_UF_system_flow = 5833;
UF_ShutdownEnabled = 0;
PROS1_recoveryrate = 61;
PROS2_recoveryrate = 62;
TSRO_recoveryrate = 51;
UF_BWCycleTime = 55;
UF_RecoveryRate=96;
Electricity_SalePriceModifier = 50/100; %this is passed direct to simulation
peak_window = [16 21];
solar_generation_worksheet_options =  dir(fullfile(folderPath,"SolarSimulationData","*.xls*"));
solar_generation_worksheet_names = string({solar_generation_worksheet_options.name})';
solar_generation_worksheet = solar_generation_worksheet_names(1);
brine_disposal_rate_dolaf = 517.96;
brine_disposal_rate_dolMG = brine_disposal_rate_dolaf / .3259;

Initialize_ReverseOsmosis;

%% Parameter ranges to sweep
TOU_file = "_TOURates.xlsx";
TOU_block_path = "ARC_DTm/Plant Setpoints/TOURateImport";

%Operations spreadsheet and selection
operations_setpoints_spreadsheet = "OperationalScenarios.xlsx";
operations_setpoints_sheet_names = sheetnames(operations_setpoints_spreadsheet);
operations_import_block_path = "ARC_DTm/Plant Setpoints/Controls";


paramGrid.maximum_solar_generation   = {1300};
paramGrid.TOU_case  = num2cell(sheetnames(TOU_file));
paramGrid.demandCharges  = {[3.27 23.28]};
paramGrid.ROstabilization_time = {105};
paramGrid.batteryScenario  = {0,1,2};
%paramGrid.operations_case = num2cell(sheetnames(operations_setpoints_spreadsheet));
paramGrid.operations_case = {"CompleteShutdown_TOU"};          % last sheet only

%% Build every combination (full factorial)
paramNames = fieldnames(paramGrid);
nParams    = numel(paramNames);
valueSets  = struct2cell(paramGrid);
nLevels    = cellfun(@numel, valueSets);
totalRuns  = prod(nLevels);

idxVectors = arrayfun(@(n) 1:n, nLevels, 'UniformOutput', false);
idxGrids   = cell(1, nParams);
[idxGrids{1:nParams}] = ndgrid(idxVectors{:});

comboIdx = zeros(totalRuns, nParams);
for i = 1:nParams
    comboIdx(:,i) = idxGrids{i}(:);
end

combos = struct([]);
for r = 1:totalRuns
    for i = 1:nParams
        combos(r).(paramNames{i}) = valueSets{i}{comboIdx(r,i)};
    end
end

fprintf('Total combinations: %d\n', totalRuns);

%% Run simulation for each combination
simulink_model = "ARC_DTm";

for r = 1:totalRuns
    p = combos(r);
    fprintf('\nRun %d/%d: solar=%g, TOU=%s, ops=%s, demand=[%g %g], battery=%d\n', ...
        r, totalRuns, p.maximum_solar_generation, p.TOU_case, p.operations_case, ...
        p.demandCharges(1), p.demandCharges(2), p.batteryScenario);
    %Initialize model parameters
    in = Simulink.SimulationInput(simulink_model);

    TOU_case = char(p.TOU_case);
    operations_case = char(p.operations_case);
    maximum_solar_generation = p.maximum_solar_generation;
    batteryScenario = p.batteryScenario;
    ROstabilization_time = p.ROstabilization_time;
    %set demand charges used in postSimAnalysis
    peak_demand_charge = p.demandCharges(1);
    offpeak_demand_charge = p.demandCharges(2);

    %Set solar modifiers and write to model gain parameters
    solarModifier = maximum_solar_generation / 300; %this is passed to the simulation
    in = in.setVariable('solarModifier', solarModifier);


    %Set TOU case and write to block
    in = in.setBlockParameter(TOU_block_path, "SheetName", TOU_case);
    in = in.setBlockParameter(TOU_block_path, "Range", "");
    in = in.setBlockParameter(TOU_block_path, "TreatFirstColumnAs", "Data");
    in = in.setBlockParameter(TOU_block_path, "SampleTime", "1");

    %battery enable/disable to modify gain parameter
    in = in.setVariable('batteryScenario', p.batteryScenario);
    in = in.setVariable('ROstabilization_time', p.ROstabilization_time);

    %set operations strategy
    in = in.setBlockParameter(operations_import_block_path, "SheetName", operations_case);
    in = in.setBlockParameter(operations_import_block_path, "Range", "");
    in = in.setBlockParameter(operations_import_block_path, "TreatFirstColumnAs", "Time");
    in = in.setBlockParameter(operations_import_block_path, "OutputAfterLastPoint", "Repeating sequence");
    in = in.setBlockParameter(operations_import_block_path, "SampleTime", "1");

    %Conduct simulation
    simOut = sim(in);

    %generate results
    results_folder = fullfile(folderPath,"sweep_results");
    run_folder = fullfile(results_folder, "Visualizations",p.operations_case + "_"+num2str(p.maximum_solar_generation) + "kWSolar_"+p.TOU_case);

    if ~exist(run_folder, 'dir')
        mkdir(run_folder)
    end
    plot_save = true;
    postSimAnalysis

end
