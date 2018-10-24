%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subfolder = '02_preproc';
  cfg.filename  = 'JOEI_p01_02_preproc';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data  
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in eyecor data folder
  sourceList    = dir([strcat(desPath, '02_preproc/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_02_preproc_', sessionStr, '.mat'));
  end
end

%% part 6
% Calculate the power spectral density of the preprocessed data

cprintf([0,0.6,0], '<strong>[6] - Power analysis (pWelch)</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of power spectral density using Welch's method (pWelch)
choise = false;
while choise == false
  cprintf([0,0.6,0], 'Should the power spectral density by using Welch''s method be calculated?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    choise = true;
    pwelch = true;
  elseif strcmp('n', x)
    choise = true;
    pwelch = false;
  else
    choise = false;
  end
end
fprintf('\n');

if pwelch == true
  choise = false;
  while choise == false
    cprintf([0,0.6,0], 'Should rejection of detected artifacts be applied before PSD estimation?\n');
    x = input('Select [y/n]: ','s');
    if strcmp('y', x)
      choise = true;
      artifactRejection = true;
    elseif strcmp('n', x)
      choise = true;
      artifactRejection = false;
    else
      choise = false;
    end
  end
  fprintf('\n');
  
  % Write selected settings to settings file
  file_path = [desPath '00_settings/' sprintf('settings_%s', sessionStr) '.xls'];
  if ~(exist(file_path, 'file') == 2)                                       % check if settings file already exist
    cfg = [];
    cfg.desFolder   = [desPath '00_settings/'];
    cfg.type        = 'settings';
    cfg.sessionStr  = sessionStr;
  
    JOEI_createTbl(cfg);                                                    % create settings file
  end

  T = readtable(file_path);                                                 % update settings table
  warning off;
  T.artRejectPSD(numOfPart) = { x };
  warning on;
  delete(file_path);
  writetable(T, file_path);
  
  for i = numOfPart
    fprintf('<strong>Participant %d</strong>\n', i);
    
    % Load preprocessed data
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '02_preproc/');
    cfg.filename    = sprintf('JOEI_p%02d_02_preproc', i);
    cfg.sessionStr  = sessionStr;

    fprintf('Load preprocessed data...\n\n');
    JOEI_loadData( cfg );
    
    % Segmentation of conditions in segments of one second with 75 percent
    % overlapping
    cfg          = [];
    cfg.length   = 1;                                                       % window length: 1 sec       
    cfg.overlap  = 0.75;                                                    % 75 percent overlap
    
    fprintf('<strong>Segmentation of preprocessed data.</strong>\n');
    data_preproc = JOEI_segmentation( cfg, data_preproc );

    fprintf('\n');
    
    % Load artifact definitions 
    if artifactRejection == true
      cfg             = [];
      cfg.srcFolder   = strcat(desPath, '05b_allart/');
      cfg.filename    = sprintf('JOEI_p%02d_05b_allart', i);
      cfg.sessionStr  = sessionStr;

      file_path = strcat(cfg.srcFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');
      if ~isempty(dir(file_path))
        fprintf('Loading %s ...\n', file_path);
        JOEI_loadData( cfg );                                                  
        artifactAvailable = true;     
      else
        fprintf('File %s is not existent,\n', file_path);
        fprintf('Artifact rejection is not possible!\n');
        artifactAvailable = false;
      end
    fprintf('\n');  
    end
    
    % Artifact rejection
    if artifactRejection == true
      if artifactAvailable == true
        cfg           = [];
        cfg.artifact  = cfg_allart;
        cfg.reject    = 'complete';
        cfg.target    = 'single';

        fprintf('<strong>Artifact Rejection with preprocessed data.</strong>\n');
        data_preproc = JOEI_rejectArtifacts(cfg, data_preproc);
        fprintf('\n');
      end
      
      clear cfg_allart
    end
    
    % Estimation of power spectral density
    cfg         = [];
    cfg.foi     = 1:1:50;                                                   % frequency of interest
      
    data_preproc = JOEI_pWelch( cfg, data_preproc );                        % calculate power spectral density using Welch's method
    data_pwelch = data_preproc;                                             % to save need of RAM
    clear data_preproc
    
    % export PSD data into a *.mat file
    cfg             = [];
    cfg.desFolder   = strcat(desPath, '06a_pwelch/');
    cfg.filename    = sprintf('JOEI_p%02d_06a_pwelch', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');

    fprintf('Power spectral density data of participant %d will be saved in:\n', i); 
    fprintf('%s ...\n', file_path);
    JOEI_saveData(cfg, 'data_pwelch', data_pwelch);
    fprintf('Data stored!\n\n');
    clear data_pwelch
  end
end

%% clear workspace
clear file_path cfg sourceList numOfSources i choise tfr pwelch T ...
      artifactRejection artifactAvailable