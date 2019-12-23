function evts = PresentationEvents(indir, varargin)
% PresentationEvents - Extract events to usable format from Pres log files
%==========================================================================
% Description   : Works through all files in given directory, extracting
%                   the event times and writing to separate txt files
%
% Parameters    : directory - holds all files
%
% Call Sequence : PresentationEvents(directory)
%               Files should be Presentation log format (as defined for
%               PPAC validation experiment)
%
% Author        : Ben Cowley
%==========================================================================


%% Initialise params and data
p = inputParser;

p.addRequired('indir', @ischar)

p.addParameter('outdir', '', @ischar)
p.addParameter('filt', '*', @ischar)

p.parse(indir, varargin{:});
Arg = p.Results;

% Having a directory, get all the files therein
files = dir(fullfile(indir, [Arg.filt '.log']));
logs = cell(1, numel(files));


%% LOOP LOG FILE(S) AND PARSE
for i = 1:length(files)

    % Read the file handle, then scan into a vector
    fid = fopen(fullfile(indir, files(i).name));
    top = textscan(fid, '%*s %s', 1);
    vpd = datevec(top{1}, 'HH:MM:SS');

    textscan(fid, '%s', 2, 'delimiter', '\n');
    endtime = textscan(fid, '%*s %*s %*s %*s %s', 1);
    textscan(fid, '%s', 1, 'delimiter', '\n');
    header = textscan(fid, '%*s %s %s %s %s %*s %*s %*s %*s %*s %*s'...
                                                    , 1, 'delimiter', '\t');
	header = cellfun(@(x) strrep(lower(x{:}), 'event ', ''), header, 'Uni', 0);
    textscan(fid, '%s', 1, 'delimiter', '\n');
    evts = textscan(fid, '%*s %d %s %s %d %*s %*s %*s %*s %*s %*s'...
                                                    , 'delimiter', '\t');

    p = evts{3}{1};
    pnd = length(p);
    p = strcat(p(9:10), ':', p(11:12), ':', p(13:14), '.', p(15:min(17, pnd)));
    p = datevec(p, 'HH:MM:SS.FFF');
    osdv = p - vpd;
    offsex = osdv(4)*3600 + osdv(5)*60 + osdv(6);

    endtime = datevec(endtime{1}, 'HH:MM:SS');
    endtime = endtime - vpd;
    endsex = endtime(4)*3600 + endtime(5)*60 + endtime(6);

    times = evts{4}/10000 + offsex;
    if endsex <= times(length(times))
        warning( 'Time calculations wrong somehow.' );
    end
    evts{4} = times;

    if ~isempty(Arg.outdir)
%         TODO - FIX THIS TO BE OUTDIR
        fid = fopen(strcat(indir, files(i).name(1:end-11), 'events.txt'), 'w');
        for a = 1:3
            fprintf(fid,'%s\t',header{a});
        end
        fprintf(fid,'%s\n',header{4});

        for j = 1:length(times)
            fprintf(fid,'%d\t',evts{1}(j));
            fprintf(fid,'%s\t',evts{2}{j});
            fprintf(fid,'%s\t',evts{3}{j});
            fprintf(fid,'%d\n',evts{4}(j));
        end
    end
    fclose(fid);
    logs{i} = table(evts{:}, 'VariableNames', header);
end
evts = vertcat(logs{:});
%%% END PresentationEvents FUNCTION %%%