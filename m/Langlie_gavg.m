function EDA = Langlie_gavg(wdir, filefilt, idORname, metrics)
% LANGLIE_GAVG aggregates and saves Ledalab-produced event-related results 
% 
% Usage:
%       Langlie_gavg(wdir)
%
% Description: finds all Ledalab *_era.mat files from an experiment (that is,
%              any file matching string 'filefilt' in any folder below 'wdir')
%
% Prerequisites: 
%   - data analyzed in Ledalab (e.g. Continuous Decomposition Analysis CDA)
%   - exported event-related activation data for specified event-windows,
%     i.e. '*_era.mat' files
%
% Input:
%   wdir        string, root folder: all target files here or in any subfolder
%                       (recursive) are returned for processing
%   filefilt    string, part of filename to match subset of files for, e.g. 
%                       different conditions, default = '*'
%   idORname    string, identify events by ID or name, default = 'id'
%   metrics     cellstr, specify which Ledalab metrics to average, including 
%                       option for logarithm of amplitude sum. Available are:
%                       AmpSum, AmpSum_log, ISCR, AmpSum_TTP
%                       Default = all available
% 
% Output:
%   EDA         struct, fields for each EDA metric requested, containing mean 
%                       calculated per file and per event
% In this script you can specify which scores you want to be included, and modify
% scores (e.g. logarithmize them)

%% Parse input arguments and set varargin defaults
p = inputParser;

p.addRequired('wdir', @ischar)
p.addOptional('filefilt', '*', @ischar)
p.addOptional('idORname', 'id', @ischar)
p.addOptional('metrics',...
    {'AmpSum', 'AmpSum_log', 'ISCR', 'AmpSum_TTP'}, @iscellstr)

p.parse(wdir, filefilt, idORname, metrics)
% Arg = p.Results;


%List all files that resulted from event-related analysis (ERA) in Ledalab
files = subdir(fullfile(wdir, [filefilt '_era.mat']));
filename_list = cell(length(files), 1);
filebits = subdir_parse(files);


 %% Read data for each file
for iFile = 1:length(files)

    [p, f, e] = fileparts(files(iFile).name);
    filename_list{iFile} = strrep(f, '_era', ''); %Get file name (without _era)
    era = load(files(iFile).name);   %Load single file

    % ==> Use event-ID or event-name for identification of event-types
    if strcmpi(idORname, 'id')
        events = era.results.Event.nid;
    else
        events = era.results.Event.name;
    end

    event_list = unique(events); %Create unique list of available event labels

    for iEvent = 1:length(event_list)   %loop over events

        %Get position of specific events within stimulation sequence
        if isnumeric(event_list)%Event.nid was used to identify events
            event_idx = events == event_list(iEvent);
        else                    %Event.name was used to identify events
            event_idx = strcmp(events, event_list{iEvent});
        end

        % ==> Add EDA parameters/scores to be exported
        for iM = 1:numel(metrics)
            switch metrics{iM}
                case 'AmpSum'
                    %Average SCR-AmpSum across trials of a specific event:
                    EDA.AmpSum(iFile, iEvent) =...
                        mean(era.results.CDA.AmpSum(event_idx));
                    
                case 'AmpSum_log'
                    %Logarithmize SCR-scores before averaging:
                    EDA.AmpSum_log(iFile, iEvent) =...
                        mean(log(1 + era.results.CDA.AmpSum(event_idx)));
                    
                case 'ISCR'
                    % Intregral of SCR
                    EDA.ISCR(iFile, iEvent) =...
                        mean(era.results.CDA.ISCR(event_idx));
                    
                case 'AmpSum_TTP'
                    % Trough-to-peak AmpSum:
                    EDA.AmpSum_TTP(iFile, iEvent) =...
                        mean(era.results.TTP.AmpSum(event_idx));
            end
        end

    end
end
