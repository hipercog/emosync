% CONVERT PPAC AUTOBIO RESPONSE EVENT CODES TO = [EMOTION-NAME]_rsp
ind = '/home/bcowley/Benslab/project_METHODMAN/project_PPAC/PPAC/EDA';
strf = 23;
endf = 0;
LOCK_EVTS =...
    {'EMPATIA' 'ILO' 'INHO' 'INNOSTUNEISUUS' 'PELKO'...
    'RENTOUTUNEISUUS' 'SURU' 'VIHA' 'VOITTO'...
    'EMPATHY' 'JOY' 'DISGUST' 'ENTHUSIASM' 'FEAR'...
    'RELAXATION' 'DEPRESSION' 'ANGER' 'TRIUMPH'};


%% Find files and parse them to csv
fs = dir(fullfile(ind, '*autobio.mat'));
if endf < strf
    endf = strf;
end
if endf > numel(fs)
    endf = numel(fs);
end

for i = strf:endf

    load(fullfile(ind, fs(i).name));
    t = [data.event.time];
    ev = {data.event.name};
    
    for tix = 1:numel(t)
        if ismember(ev{tix}, LOCK_EVTS) &&...% event t is emotion prompt
                tix < numel(t) &&...         % event t+1 exists 
                    ~isempty(str2double(ev{tix + 1})) % event t+1 is number
                
            data.event(tix + 1).name =...
                [LOCK_EVTS{ismember(LOCK_EVTS, ev{tix})} '_rsp'];
        end
    end
    
    save(fullfile(ind, fs(i).name), 'data', 'analysis', 'fileinfo')
    
    clear t ev tix data analysis fileinfo
end
clear fs i strf endf LOCK_EVTS ind 
