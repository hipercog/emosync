function fix_langlie(fname, indir)

if nargin < 2 || isempty(indir)
    indir = cd;
end

if ~exist(fullfile(indir, fname), 'file')
    error('fix_langlie:no_file', 'No such file as: %s', fullfile(indir, fname))
end

indir = sbf_abspath(indir);
    
outdr = strrep(indir, '0_input', '2_data_analysis');
if ~isfolder(outdr)
    mkdir(outdr)
end


%% GET DATA & SPECS
% Load data, set name for output
vars = load(fullfile(indir, fname));
Sessiondata = vars.Sessiondata;
Sessioninfo = vars.Sessioninfo;
clear vars

% Data format specs
rows = size(Sessioninfo, 1);
cols = size(Sessioninfo, 2);
s = mat2cell(Sessioninfo, ones(rows, 1), cols);

srate = str2double(regexprep(s(contains(s, 'Output rate:'), :), '\D', ''));

durix = contains(s, 'Duration:');
dur1 = cell2mat(regexprep(s(durix, :), '\D', ''));

rcd = cell2mat(regexprep(s(contains(s, 'Date:'), :), '\D', ''));
rct = cell2mat(regexprep(s(contains(s, 'Time:'), :), '\D', ''));
dattim = str2double({rcd(5:end) rcd(3:4) rcd(1:2) rct(1:2) rct(3:4) rct(5:6)});

% Extract events
events = Sessiondata(:,5); %#ok<*NODEF>
tst = find(~cellfun(@isempty, events) & ~strcmp(events, 'Events'));
if isempty(tst)
    error('fix_langlie:no_events', 'NO events found in %s', fname)
end
block = 0;


%% PREPPING
% Find subject number
[~, n, ~] = fileparts(fname);
subj_num = str2double(strrep(n, 'S', ''));

% if number came from early, buggy Presentation, fix it
if subj_num < 12
    FIX = true;
    counter_balance_mat = [  1 2 3 4;
                                4 3 1 2;
                                2 1 4 3;
                                4 3 2 1;
                                2 1 3 4;
                                4 3 2 1;
                                1 2 3 4;
                                4 3 1 2;
                                1 2 3 4;
                                3 4 2 1;
                                1 2 3 4];
	oldnew = cell2table(events(tst), 'VariableNames', {'Oldev'});
    oldnew.Newev = NaN(numel(tst),1);
else
    FIX = false;
end


%% TEXT 2 NUM
% Loop events, convert text to trigger number, fix if needed
trigs = NaN(numel(tst), 1);
lagnum = NaN;
for i = 1:numel(tst)
    % get event code as number
	evnum = sbf_parse_pres_code(Sessiondata{tst(i), 5}); %#ok<*AGROW>
    if isnan(evnum)
        continue
    elseif evnum == 99 && lagnum ~= 99
        block = block + 1;
    elseif FIX
        if block > 0 && block < 5
            evnum = sbf_fix_evnum(evnum, counter_balance_mat(subj_num, block));
            oldnew(i,2) = {evnum};
        else
            fprintf('sthg has gone wrong!\nevnum: %d\nsubj: %d\nblock: %d\n'...
                , evnum, subj_num, block)
        end
    end
    trigs(i) = evnum;
    lagnum = evnum;
end
Sessiondata(tst, 5) = cellfun(@num2str, num2cell(trigs), 'Un', 0);
ssn = Sessiondata;

% Get block start indices
bstarts = [tst(trigs == 99)' min(tst(end) + srate * 8, size(ssn, 1))];
idx = max(bstarts(1) - (8 * srate), 1) : bstarts(end);
dur2 = num2str(length(idx) / srate);
tmp = [strrep(Sessioninfo(durix, :), dur1, dur2) repmat(' ', 1, cols)];
Sessioninfo(durix, :) = tmp(1:cols);

% Write out log of event changes
if FIX
    writetable(oldnew, fullfile(outdr, 'old-new_events.txt'), 'Delimiter', '\t')
end


%% NO-REP TARGET DATA
% combine target triggers under one number
norpt = NaN(numel(trigs), 1);
for i = 1:numel(norpt)
    evnum = trigs(i);
    if ismember(trigs(i), [([1:8]*10)+1 ([1:8]*10)+2]) %#ok<NBRAK>
        evnum = evnum - mod(evnum, 10);
    end
    norpt(i) = evnum;
end
ssn(tst, 6) = cellfun(@num2str, num2cell(norpt), 'Un', 0);
ssn(2, 6) = ssn(2, 5);


%% EXPORT DATA
hdr = 1:3;
% Write out new data file(s) with events field with target repetition preserved
Sessiondata = ssn([hdr idx], [1 2 5]);
sbf_writeout('L_raw_trim_', 'Extracted LEFT-hand E-chan EDA & original events')

Sessiondata = ssn([hdr idx], [1 4 5]);
sbf_writeout('R_raw_trim_', 'Extracted RIGHT-hand F-chan EDA & original events')

Sessiondata = ssn([hdr idx], [1 3 5]);
save(fullfile(outdr, ['BVP_' fname]), 'Sessioninfo', 'Sessiondata')

% Write out dummy file with events field with all targets under 1 trigger code
tmphdr = [ssn(1, 2); strrep(ssn(2, 2), '-E:', '_E-F:'); ssn(3, 2)];
tmpdat = cellfun(@(x,y) x - y, ssn(idx, 2), ssn(idx, 4));
Sessiondata = [ssn([hdr idx], 1)... 
                [tmphdr; num2cell(tmpdat + min(tmpdat))]...
                ssn([hdr idx], 6)];
sbf_writeout('diffEDA_NoRepTrg_'...
    , ['Extracted LEFT minus RIGHT hand (E-F channel) EDA'...
    ', events have target triggers combined under one number'])


%% SUBFUNCTION TO WRITE DATA
    function sbf_writeout(nmstr, msg)
        svnm = fullfile(outdr, [nmstr fname]);
        save(svnm, 'Sessioninfo', 'Sessiondata')
        [time, cond, evnt] = getBiotraceMatData(svnm);
        data.time = time;
        data.timeoff = 0;
        data.conductance = cond; 
        data.event = evnt;
        fileinfo.version = 3.49;
        clockt = datestr(rem(now,1), 13);
        fileinfo.log = {[clockt ': Imported biotracemat-file '...
                        fullfile(indir, fname) ' successfully'];
                [clockt ': ' msg];
                [clockt ': ' 'Saved ' svnm]};
        fileinfo.date = dattim;
        save(svnm, 'data', 'fileinfo')
        
    end
% function sbf_writeout(idx, prfx)
%     Sessiondata = ssn(:, idx);
%     save(fullfile(outdr, [prfx fname]), 'Sessioninfo', 'Sessiondata')
%     for b = 1:numel(bstarts) - 1
%         Sessiondata = ssn([hdr bstarts(b)-(2*srate) : bstarts(b+1)-1], idx);
%         save(fullfile(outdr, [prfx 'b' num2str(b) '_' fname])...
%             , 'Sessioninfo', 'Sessiondata')
%     end
% end


%% SUBFUNCTION TO PARSE TRIGGER CODE
    function out = sbf_parse_pres_code(instr)
        instr = strrep(instr, 'RS232 Trigger: ', '');
        out = instr(1);
        while true
            instr = instr(2:end);
            if isnan(str2double(instr(1)))
                break
            end
            out = [out instr(1)];
        end
        out = str2double(out);
    end


%% SUBJFUNCTION TO  FIX TRIGGER CODE
    function fixed = sbf_fix_evnum(badnum, blocknum)
        c = 1:8;
        codes = [c; c*10; c*10+1; c*10+2; c+100]';
        codes = [codes(1:2:7,:) codes(2:2:8,:)];
        testi = codes(1,:) == badnum;
        fixed = codes(blocknum, testi);
        if isempty(fixed)
            fixed = badnum;
        end
    end

    function abspath = sbf_abspath(relpath)
        tmp = pwd;
        if ~isfolder(relpath), mkdir(relpath); end
        cd(relpath)
        abspath = pwd;
        cd(tmp)
    end

end %fix_langlie()