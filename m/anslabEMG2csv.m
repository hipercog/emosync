% convert Anslab EMG to table and write csv
ind = '/Users/niinapeltonen/Desktop/EMG_processing/';
oud = ind;
%fname = 'EMG00601.mat';
fs = dir(fullfile(ind,'*.mat'));
for i=1:numel(fs)

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

%% Specific to one file
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