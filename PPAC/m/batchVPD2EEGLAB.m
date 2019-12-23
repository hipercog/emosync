% CONVERT EEG FROM PPAC VPDs TO EEGLAB, WITH PRES LOGS ADDED)
vpd_fs = dir(fullfile('VPD', '*.vpd'));

for i = 1:numel(vpd_fs)
    vpd = ImportVPD(fullfile('VPD', vpd_fs(i).name));
    sbj = cell2mat(regexp(vpd_fs(i).name, '\d', 'match'));
    sbn = round(str2double(sbj) / 100);
    evt = PresentationEvents('logs', 'filt', ['*' sbj(1:end-1) '*']);
    evt = rmfield(table2struct(evt), 'trial');
    [evt.name] = evt.code;
    [evt.kind] = evt.type;
    evt = rmfield(evt, {'type' 'code'});
    
    EEG = vpd2eeglab(vpd, 'events', evt);
    [~, savename, ~] = fileparts(vpd_fs(i).name);
    pop_saveset(EEG, 'filename', savename, 'filepath', 'EEG')
end