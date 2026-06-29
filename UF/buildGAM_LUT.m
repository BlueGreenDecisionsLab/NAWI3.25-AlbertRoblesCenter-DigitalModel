% this returns the full path to the current file (script)
fullFileName = matlab.desktop.editor.getActiveFilename;

% split off the folder
[folderPath, ~, ~] = fileparts(fullFileName);

%add complete folder & subfolders to cd
cd(folderPath)
addpath(genpath(folderPath));

%Load in spreadsheet names and extract intercept
XLSheet_file = "gam_luts.xlsx";
sheets = sheetnames(XLSheet_file);

%get intercept value
% Extract the intercept value from the specified sheet
interceptValue = readtable(XLSheet_file, Sheet="intercept");
interceptValue = interceptValue.intercept(1); % Assuming the value is in the first row

%get the other parameters in the GAM
breakpoint_sheets = sheets(~strcmpi(sheets, "intercept")); %location of GAM intercept
n = numel(breakpoint_sheets); %this counts the number of inputs


%preallocate final structure parameters
variables = cell(1,n); %variable name 
breakpoints = cell(1,n); %input variable value vector 
values = cell(1,n); %Associated Bx * fx(X) value vector (GAM output)

for var = 1:n
    %import data
    sheet = breakpoint_sheets(var);
    
    %note that data takes the shape [inpu    t value vector, GAM parameter
    %value
    table = readtable(XLSheet_file,Sheet=sheet);

    variables{var} = sheet;
    breakpoints{var} = table.breakpoint(:);

    %check for monotonocity
    %Simulink requires monotonically increasing breakpoints
    for i = 1:numel(breakpoints{var})
        if any(diff(breakpoints{var}<=0))
            error('Breakpoints for %s are not monotonically increasing', vars{i})
        end
    end

    values{var} = table.value(:);
end

%Create structure to save and call in future steps
gamLUT.vars = variables;
gamLUT.breakpoints = cell2mat(breakpoints);
gamLUT.intercept = interceptValue;
gamLUT.values = cell2mat(values);

save gamLUT.mat gamLUT