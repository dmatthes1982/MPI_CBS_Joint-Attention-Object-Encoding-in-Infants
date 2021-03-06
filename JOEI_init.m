% -------------------------------------------------------------------------
% Add directory and subfolders to path
% -------------------------------------------------------------------------
clear;
clc;

filepath = fileparts(mfilename('fullpath'));
addpath(sprintf(['%s/:%s/easyplot:%s/export:%s/functions'...
                ':%s/general:%s/layouts:%s/utilities'], ...
        filepath, filepath, filepath, filepath, filepath, filepath, ...
        filepath));

clear filepath