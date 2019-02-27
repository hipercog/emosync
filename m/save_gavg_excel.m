
%% Save EDA results to Excel file
eda_scores = fieldnames(EDA);   %Get list of scores saved in the Matlab variable EDA

for iScore = 1:length(eda_scores)
    %Write one worksheet per EDA parameter/score
    
    %Write event names to worksheet
    xlswrite([wdir, 'EDA_Results'], event_list, eda_scores{iScore},'B1');
    %Write file names/codes
    xlswrite([wdir, 'EDA_Results'], filename_list', eda_scores{iScore},'A2');
    %Write EDA scores
    xlswrite([wdir, 'EDA_Results'], EDA.(eda_scores{iScore}), eda_scores{iScore},'B2');

end