disp("Initializing RO Membrane Values and TSRO PPC.")

fullFileName = matlab.desktop.editor.getActiveFilename;

% split off the folder
[folderPath, ~, ~] = fileparts(fullFileName);
[path,~,~] = fileparts(folderPath);
[parentpath,~,~] = fileparts(path);

%% general membrane values
E = 0.78;
s=.5;
s2 = .50;
FF = .00;
L = 1.016; %m
h = 0.86; %mm
w = .3; %m
 
% Establish TSRO membrane Values

A_TSRO = 0.8022;
B_TSRO = 2.7881;

%Train1
A_PROS1 = 0.76627;
A_PROS2 = .56159;

B_PROS1 = 2.2154;
B_PROS2 = 1.3775;