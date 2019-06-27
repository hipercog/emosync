% TODO: make generic parameters!!
% ROOTDIR = '/home/local/bcowley/Benslab/EMOSYNC/DYNECOM/EDAmat';
ROOTDIR = './';
FILT_STR = 'DCVR';
FILT_MSK = logical(~allgood);

MEASUREMENTS = dir(fullfile(ROOTDIR, [FILT_STR '*.mat']));
MEASUREMENTS(FILT_MSK) = [];

OUTDIR = fullfile(ROOTDIR, 'csv');
if ~isfolder(OUTDIR), mkdir(OUTDIR); end


for k = 1:length(MEASUREMENTS)
	fprintf(1, '%s\n', MEASUREMENTS(k).name)

    if strcmp(MEASUREMENTS(k).name, 'batchmode_protocol.mat')
        continue
    end
    
    file = load(fullfile(MEASUREMENTS(k).folder, MEASUREMENTS(k).name));
    [~, fname, ~] = fileparts(MEASUREMENTS(k).name);
     
    hdr = {'time', 'conductance', 'driver', 'scr', 'scl'};
    data = cat(2, file.data.time', ...
                  file.data.conductance', ...
                  file.analysis.driver', ...
                  file.analysis.phasicData', ...
                  file.analysis.tonicData');

    filename = fullfile(OUTDIR, [fname '.csv']);

    fid = fopen(filename, 'w');

    % Write time offset
    fprintf(fid, '#offset=%f\n', file.data.timeoff);

    % Write header
    for h = 1:length(hdr)
        fprintf(fid, '%s', hdr{h});
        if h == length(hdr)
            fprintf(fid, '\n');
        else
            fprintf(fid, ',');
        end
    end

    % Write data
    for x = 1:size(data, 1)
        fprintf(fid, '%f,%f,%f,%f,%f\n'...
            , data(x, 1), data(x, 2), data(x, 3), data(x, 4), data(x, 5));
    end

    fclose(fid);
end
