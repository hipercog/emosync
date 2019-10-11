function anslabEMG2csv(varargin)
% convert Anslab EMG to table and write csv
%
%       default, we choose to do 1 file only

p = inputParser;
p.addParameter('dir', '/Users/niinapeltonen/Desktop/EMG_processing/', @ischar)
p.addParameter('start', 1, @isscalar)
p.addParameter('end', 0, @isscalar)

p.parse(varargin{:});
Arg = p.Results;

ind = Arg.dir;
oud = ind;


%% Find files and parse them to csv
fs = dir(fullfile(ind,'*.mat'));
if Arg.start > numel(fs)
    error('anslabEMG2csv:bad_param', 'Pass ''start''<= number of EMG files ')
end
if Arg.end < Arg.start
    Arg.end = Arg.start;
end
if Arg.end > numel(fs)
    Arg.end = numel(fs);
end

for i = Arg.start:Arg.end

    emg = load(fullfile(ind, fs(i).name));
    emg = emg.emg;
    t = [emg.event.time];
    ev = {emg.event.name};
    zyg = emg.zyg';
    orb = emg.orb';
    crg = emg.cor';
    sampevs = cell(numel(zyg), 1);
    for tix = 1:numel(t)
        sampevs{max(1, round(t(tix) * emg.sr))} = ev{tix}; 
    end
    [~, f, ~] = fileparts(fs(i).name);
    if numel(sampevs) == numel(zyg)
        T = table(sampevs, zyg, orb, crg);
        writetable(T, fullfile(oud, [f '.csv']));
        clear T
    else
        warning('Something has gone terribly wrong! %s', f)
    end
    clear emg t ev zyg orb crg sampevs f
end


%% What we're doing, specific to one file
% s6emg = load('EMG00601.mat');
% s6emg = s6emg.emg;
% t6 = [s6emg.event.time];
% ev6 = {s6emg.event.name};
% zy6 = s6emg.zyg';
% or6 = s6emg.orb';
% co6 = s6emg.cor';
% sampevs = cell(numel(zy6), 1);
% for tix = 1:numel(t6), sampevs{round(t6(tix) * s6emg.sr)} = ev6{tix}; end
% s6T = table(sampevs, zy6, or6, co6);
% writetable(s6T, 'EMG00601.mat')