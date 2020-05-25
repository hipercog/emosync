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
LOCK_EVTS =...
    {'EMPATIA' 'ILO' 'INHO' 'INNOSTUNEISUUS' 'PELKO'...
    'RENTOUTUNEISUUS' 'SURU' 'VIHA' 'VOITTO'...
    'EMPATHY' 'JOY' 'DISGUST' 'ENTHUSIASM' 'FEAR'...
    'RELAXATION' 'DEPRESSION' 'ANGER' 'TRIUMPH'};


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

    [~, f, ~] = fileparts(fs(i).name);
    emg = load(fullfile(ind, fs(i).name));
    emg = emg.emg;
    t = [emg.event.time];
    ev = {emg.event.name};
    zyg = emg.zyg';
    orb = emg.orb';
    crg = emg.cor';
    sampevs = cell(numel(zyg), 1);
    for tix = 1:numel(t)
        if ismember(ev{tix}, LOCK_EVTS) &&...% event t is emotion prompt
                tix < numel(t) - 1 &&...% the vectors have enough space... 
                    t(tix + 1) * 10 < numel(zyg) - (5 * emg.sr) &&...% & time
                        ~isempty(str2double(ev{tix + 1})) % event t+1 is number
            rspix = tix + 1;
            dupix = t(tix + 2:end) == t(tix + 1);
            if any(dupix)
                rspix = [rspix tix + find(dupix) + 1]; %#ok<AGROW>
            end
            [ev{rspix}] =...
                deal([LOCK_EVTS{ismember(LOCK_EVTS, ev{tix})} '_rsp']);
        end
        sampevs{max(1, round(t(tix) * emg.sr))} = ev{tix}; 
    end
    
    if numel(sampevs) > numel(zyg)
        sampevs = sampevs(1:numel(zyg));
    elseif numel(sampevs) < numel(zyg)
        warning('Something has gone terribly wrong! %s', f)
        continue
    end
    
    T = table(sampevs, zyg, orb, crg);
    writetable(T, fullfile(oud, [f '.csv']));
    clear emg t ev zyg orb crg sampevs f T
end
