clear; clc
ind = '~/Benslab/project_METHODMAN/project_PPAC/PPAC/ctap-ppac/';
ftd = 'features/bandpowers/1_load';
fileslist = dir(fullfile(ind, ftd, '*.mat'));
epidx = readtable(fullfile(ind, 'EEG_epochs.csv'));


%%
load(fullfile(ind, ftd, fileslist(1).name));
chns = ResBPrel.parameters.chansToAnalyze';
abss = allcomb(chns, ResBPabs.labels);
rels = allcomb(chns, ResBPrel.labels);
vars = [cellfun(@(x, y) [x '_' y], abss(:,1), abss(:,2), 'Uni', 0);...
        cellfun(@(x, y) [x '_' y], rels(:,1), rels(:,2), 'Uni', 0)]';
bigT = array2table(zeros(0, numel(vars) + 4)...
    , 'VariableNames', [{'ID' 'event' 'trial' 'ts'} vars]);
fin = {'viha' 'rentoutuneisuus' 'suru' 'innostuneisuus' 'voitto' 'ilo' 'pelko' 'empatia' 'inho'};
eng = {'anger' 'relaxation' 'depression' 'enthusiasm' 'triumph' 'joy' 'fear' 'empathy' 'disgust'};


%%
for fs = 1:numel(fileslist)

    % get subject ID
    sbjx = str2double(regexp(fileslist(fs).name, '\d+', 'match'));
    sbepx = epidx(epidx.ID == sbjx, :);
    
    % get bandpowers data
    load(fullfile(ind, ftd, fileslist(fs).name));

    % parse the data with respect to the epoch index of goodness, epidx
    SGd = SEGMENT.data;
    for i = 1:size(SGd, 1)
        event = lower(regexp(SGd{i, 4}, '[A-Z]+', 'match'));
        if ismember(event, fin)
            event = eng(ismember(fin, event));
        end
        trial = sbf_checktrial(sbepx, event{:}, str2double(SGd{i, 3}));
% TODO : IF TRIAL /= TRX THEN CREATE A MISSING DATA SEGMENT
        dat = cell(1, numel(vars));
        a = 1;
        r = 31;
        for c = 1:numel(chns)
            for l = 1:numel(ResBPabs.labels)
                dat{a} = ResBPabs.(chns{c}).data(i, l);
                a = a + 1;
                dat{r} = ResBPrel.(chns{c}).data(i, l);
                r = r + 1;
            end
        end
        % join all data together
        bigT = [bigT; [sbjx, event, trial, mod(i-1, 5) + 1, dat{:}]]; %#ok<AGROW>
    end

end


%% save file
writetable(bigT, fullfile(ind, 'allBP.csv'), 'WriteRowN', true, 'Delim', 'tab')


%% Subfunctions
function trial = sbf_checktrial(epx, evt, trx)
    
    epx = table2array(epx(ismember(epx.Emo, evt), 3:end));
    offset = find(epx);
    if isempty(offset) || trx > numel(offset)
        disp('SOMETHING HAS GONE TERRIBLY WRONG!')
%     elseif 
%         trial = trx;
    else
        trial = offset(trx);
    end
end
