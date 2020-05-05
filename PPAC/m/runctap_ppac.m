%% Linear CTAP script for minimal processing of 6-channel PPAC data
% 
% OPERATION STEPS
% # 1
% Install / download:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%       git clone https://github.com/sccn/eeglab.git
%   * CTAP,
%       git clone https://github.com/bwrc/ctap.git
%   * EMOSYNC repo,
%       git clone https://github.com/zenBen/emosync.git
%   * PPAC data,
%       Get it (from TODO below), save to some location IN_DIR,
%       TODO : Upload to a permanent URI, e.g. Figshare or Zenodo
%       If necessary, run batchVPD2EEG to convert VPD+logs to EEGLAB
% 
% # 2
% Add EEGLAB, CTAP, and EMOSYNC to your Matlab path.
% 
% # 4
% Set complete path to your data directory IN_DIR as variable 'in_dir', below
% 
% # 5
% On the Matlab console, execute >> runctap_ppac


%% Setup MAIN parameters
proj_dir = '~/Benslab/project_METHODMAN/project_PPAC/PPAC';
% set the input directory where your data is stored
in_dir = fullfile(proj_dir, 'EEG');
% specify the file type of your data
data_ext = '*.set';
% use ctapID to uniquely name the base folder of the output directory tree
ctapID = 'ctap-ppac';

% use sbj_filt to select all (or a subset) of available recordings
sbj_filt = 6; %setdiff(1:12, [3 7]);
% use keyword 'all' to select all stepSets, or use some index
set_select = 5;
% set the electrode for which to calculate and plot ERPs after preprocessing
% erploc = {'F3' 'F4'};

% Runtime options for CTAP:
STOP_ON_ERROR = true;
OVERWRITE_OLD = true;


%% Create the CONFIGURATION struct
% First, define step sets & their parameters: sbf_cfg() is written by the USER
[Cfg, ctap_args] = sbf_cfg(proj_dir, ctapID);

% Select step sets to process
Cfg.pipe.runSets = set_select;

% Next create measurement config (MC) from in_dir, & select subject subset
Cfg = get_meas_cfg_MC(Cfg, in_dir, 'eeg_ext', data_ext, 'sbj_filt', sbj_filt);

% Assign arguments to the selected functions, perform various checks
Cfg = ctap_auto_config(Cfg, ctap_args);


%% Run the pipe
 tic
CTAP_pipeline_looper(Cfg, 'debug', STOP_ON_ERROR, 'overwrite', OVERWRITE_OLD)
toc


%% Export features
tic;
export_features_CTAP([Cfg.id '_db'], {'bandpowers','PSDindices'}, Cfg.MC, Cfg);
toc;


%% cleanup the global workspace
clear STOP_ON_ERROR OVERWRITE_OLD ctapID *_dir sbj_filt data_ext set_select


%% Subfunctions
% Pipe definition
function [Cfg, out] = sbf_cfg(proj_root_dir, ID)


%% Define important directories and files
% Analysis ID
Cfg.id = ID;
% Directory where to locate project - in this case, just the same as input dir
Cfg.env.paths.projectRoot = proj_root_dir;
% CTAP root dir named for the ID
Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.projectRoot, Cfg.id);
% CTAP output goes into analysisRoot dir, here can be same as CTAP root
Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;
% Channel location directory
Cfg.eeg.chanlocs = fullfile(proj_root_dir, 'res', 'chanlocs6_F34C34P34.elp');


%% Define other important stuff
Cfg.eeg.reference = {'average'};

% NOTE! EOG channel specification for artifact detection purposes.
Cfg.eeg.heogChannelNames = {'F3' 'F4'};
Cfg.eeg.veogChannelNames = 'F4';

Cfg.event.csegEvent = 'cseg';


%% Configure analysis pipe - define each step and it's params

%% Load and prepare - 
% Define the functions and parameters to load data & chanlocs, perform 
% 'safeguard' re-reference, FIR filter, and peek at the data.
i = 1; %stepSet 1
stepSet(i).funH = { @CTAP_load_data,...
                    @CTAP_load_chanlocs,...
                    @CTAP_reref_data,...
                    @CTAP_fir_filter,...
                    @CTAP_detect_bad_channels,...%adjust faster thresholds?
                    @CTAP_peek_data };
stepSet(i).id = [num2str(i) '_load'];

out.load_chanlocs = struct(...
    'overwrite', true,...
    'index_match', true);
out.load_chanlocs.field = {{{'HEOG' 'VEOG'} 'type' 'EOG'}...
     , {{'F3' 'F4' 'C3' 'C4' 'P3' 'P4'} 'type' 'EEG'}};

out.fir_filter = struct(...
    'locutoff', 1,...
    'hicutoff', 45);

out.detect_bad_channels = struct(...
    'method', 'faster',...
    'channelType', {'EEG'},...
    'match_logic', @any,...
    'bounds', [-2.5 2.5]);

out.peek_data = struct(...
    'secs', [10 30],... %start few seconds after data starts
    'peekStats', true,... %get statistics for each peek!
    'overwrite', true);


%% Segment - dummy as this is done manually
i = i + 1;
stepSet(i).funH = { };
stepSet(i).id = [num2str(i) '_segment'];


%% Find blinks
i = i + 1;
stepSet(i).funH = { @CTAP_blink2event,...
                    @CTAP_run_ica,...
                    @CTAP_detect_bad_comps };
stepSet(i).id = [num2str(i) '_blinks'];

out.run_ica = struct(...
    'method', 'fastica',...
    'overwrite', true);
out.run_ica.channels = {'EEG'};

out.detect_bad_comps = struct(...
    'method', 'blink_template');


%% Manual Cleaning - dummy
i = i + 1;
stepSet(i).funH = { };
stepSet(i).id = [num2str(i) '_cleaned'];


%% Compute band power features from segment data
i = i + 1;
stepSet(i).funH = { @CTAP_generate_cseg,...
                    @CTAP_compute_psd,...
                    @CTAP_extract_bandpowers,...
                    @CTAP_extract_PSDindices };
stepSet(i).id = [num2str(i) '_csegs'];
% stepSet(i).save = false;

out.generate_cseg = struct(...
    'regev', false,...
    'TILESxEV', 5);
out.generate_cseg.LOCK_EVTS =...
    {'EMPATIA_rsp' 'ILO_rsp' 'INHO_rsp' 'INNOSTUNEISUUS_rsp' 'PELKO_rsp'...
    'RENTOUTUNEISUUS_rsp' 'SURU_rsp' 'VIHA_rsp' 'VOITTO_rsp'...
    'EMPATHY_rsp' 'JOY_rsp' 'DISGUST_rsp' 'ENTHUSIASM_rsp' 'FEAR_rsp'...
    'RELAXATION_rsp' 'DEPRESSION_rsp' 'ANGER_rsp' 'TRIUMPH_rsp'};
out.generate_cseg.END_EVTS = {'white noise video', 'ATTRACTION'};


% Compute PSD
% Uses Cfg.event.csegEvent as cseg event type.
out.compute_psd = struct(...
    'm', 0.2,...% in sec
    'excludeBoundaries', false);
% 	'nfft', 256); % in samples (int), should be 2^x, nfft > m*srate


% Extract features
% Bandpowers
out.extract_bandpowers = struct(...
    'fmin', [4  8  13 19 30],...%Lower frequency limits, in Hz
    'fmax', [8  12 18 29 45]); %Upper frequency limits, in Hz
out.extract_bandpowers.names =...
    {'theta' 'alpha' 'beta1' 'beta2' 'gamma'};


% PSD indices
out.extract_PSDindices = struct();
out.extract_PSDindices.entropy = struct(...
    'fmin', [3.5 5  4 8  2  3  6  10],...%Low freq limits, in Hz
    'fmax', [45  15 8 12 45 45 45 45]);%Hi freq limits, in Hz

%NOTE! Here adjust frequency limits for bands: 'delta' 'theta' 'alpha' 'beta'
out.extract_PSDindices.eind = struct(...
    'fmin', [2  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');

out.extract_PSDindices.eindcc = struct(...
    'fmin', [2  4  8  13],...%Lower frequency limits, in Hz
	'fmax', [4  8  13 20],...%Upper frequency limits, in Hz
	'integrationMethod', 'trapez');


%% Store to Cfg
Cfg.pipe.stepSets = stepSet; % return all step sets inside Cfg struct

end
