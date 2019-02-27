indir = '/home/ben/Benslab/PROJECT_LANGLIE/Batchalyze';
filt = '';% {'S04' 'S11'};
FIX = false;
%starts & ends can also be a range, e.g. 0,1,2 -> 4,5,6
starts = 3;
ends = starts + 3;

% Get biotrace mat files
fs = subdirflt(indir, 'patt_ext', '*mat', 'filefilt', filt);

if FIX
    for i = 1:numel(fs)
        try
            fix_langlie(fs(i).name, fs(i).folder)
        catch ME
            warning(ME.message)
        end
    end
end

Ledalab_batch_tree(indir, 'filt', 'L_norp_S'...
    , 'era_beg', starts...
    , 'era_end', ends ...
    , 'DA', false...
    , 'exp_scrlist', false)

Ledalab_batch_tree(indir, 'filt', 'R_norp_S'...
    , 'era_beg', starts...
    , 'era_end', ends ...
    , 'DA', false...
    , 'exp_scrlist', false)