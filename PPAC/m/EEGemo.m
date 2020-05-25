
ind = '/Users/niinapeltonen/Desktop/Gradu/gradu-data/EEG_processing/ctap-ppac/3_blinks';
fs = dir(fullfile(ind, '*.set'));

for f = 1:numel(fs)
    eeg = pop_loadset('filepath', ind, 'filename', fs(f).name);
    eeg = sbf_editevs(eeg);
    pop_saveset(eeg, 'filepath', ind, 'filename', fs(f).name)
end

function EEG = sbf_editevs(EEG)
    emo = {'EMPATIA' 'ILO' 'INHO' 'INNOSTUNEISUUS' 'PELKO' 'RENTOUTUNEISUUS' 'SURU' 'VIHA' 'VOITTO'...
            'EMPATHY' 'JOY' 'DISGUST' 'ENTHUSIASM' 'FEAR' 'RELAXATION' 'DEPRESSION' 'ANGER' 'TRIUMPH'};

    [EEG.event.oldtype] = EEG.event.type;

    for i = 1:length(EEG.event)
        if ismember(EEG.event(i).type, emo)
            emo_ix = ismember(emo, EEG.event(i).type);
            emo_nm = emo{emo_ix};
            for j = i:length(EEG.event)
                evtype = EEG.event(j).type;
                if ~isempty(str2double(evtype)) && length(evtype) == 2
                    EEG.event(j).type = [emo_nm '_rsp'];
                    break
                end
            end
        end
    end
    
    
end
    
    
