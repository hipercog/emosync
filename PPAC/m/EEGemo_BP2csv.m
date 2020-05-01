
ind = '~/Benslab/project_METHODMAN/project_PPAC/PPAC/ctap-ppac/';
fileslist = dir(fullfile(ind, 'features/bandpowers/1_load', '*.mat'));
epidx = readtable(fullfile(ind, 'EEG_epochs.csv'));

%%
bigT = table();
for fs = 1:numel(fileslist)

    % get subject ID
    sbjx = str2double(regexp(fileslist(fs).name, '\d+', 'match'));
    sbepx = epidx(epidx.ID == sbjx, :);
    
    % get bandpowers data
    load(fullfile(ind, fileslist(fs).name));

    % parse the data with respect to the epoch index of goodness, epidx
    for i = 1:size(SEGMENT.data, 1)
        
    end

    % join all data together
    bigT = [bigT; T]; %#ok<AGROW>
end

% save file
writetable(bigT, fullfile(ind, 'allBP.csv'), 'WriteRowN', true, 'Delim', 'tab')