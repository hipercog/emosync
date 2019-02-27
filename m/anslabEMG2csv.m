% convert Anslab EMG to table and write csv
ind = './';
fname = '';
[~, f, ~] = fileparts(fname);

emg = load(fullfile(ind, fname));
emg = emg.emg;
t = [emg.event.time];
ev = {emg.event.name};
zyg = emg.zyg';
orb = emg.orb';
crg = emg.cor';
sampevs = cell(numel(zyg), 1);
for tix = 1:numel(t), sampevs{round(t(tix) * emg.sr)} = ev{tix}; end
T = table(sampevs, zyg, orb', crg');
writetable(T, fullfile(oud, f, '.csv'));

%% Specific to one file
s6emg = load('EMG00601.mat');
s6emg = s6emg.emg;
t6 = [s6emg.event.time];
ev6 = {s6emg.event.name};
zy6 = s6emg.zyg';
or6 = s6emg.orb';
co6 = s6emg.cor';
sampevs = cell(numel(zy6), 1);
for tix = 1:numel(t6), sampevs{round(t6(tix) * s6emg.sr)} = ev6{tix}; end
s6T = table(sampevs, zy6, or6, co6);
writetable(s6T, 'EMG00601.csv')