function write_txt_eda(fname, indir, oud, sensor_left2_right4)
% WRITE_TXT_EDA - convert BioTrace mat file to cleaned-up txt file
% 
% Description:
%   loads an EDA mat file exported by BioTrace, parses the messy header info,
%   writes a txt file with a clean header and a given column of data + events
% 
% Input:
%   fname               string, file name
%   indir               string, input path
%   oud                 string, output path
%   sensor_left2_right4 int, column number of the data to export: Langlie
%                            data had EDA-left in col 2, EDA-right in col 4
% 

    if nargin < 2, indir = cd; end
    if nargin < 3, oud = indir; end
    if nargin < 4, sensor_left2_right4 = 2; end
    
    vars = load(fullfile(indir, fname));
    Sessiondata = vars.Sessiondata;
    Sessioninfo = vars.Sessioninfo;
    clear vars
    
    [~, f, ~] = fileparts(fname);
    savename = fullfile(oud, [f '.txt']);
    
    s = mat2cell(Sessioninfo, ones(8, 1), 31);
    srate = ...
        str2double(regexprep(s(contains(s, 'Output rate:'), :), '\D', ''));
    time = regexprep(s(contains(s, 'Time:'), :), '\D', '');
    date = regexprep(s(contains(s, 'Date:'), :), '\D', '');
    
    fid = fopen(savename, 'w');
    fprintf(fid, '%s%s\n%s%s\n%d%s\n'...
        , date{:}, ',date'...
        , time{:}, ',time'...
        , srate, ',srate');
    fclose(fid);
    
    sd = [Sessiondata{4:end, sensor_left2_right4}]';
    ev = cellfun(@str2double, Sessiondata(4:end, 3));
    
    dlmwrite(savename, [sd ev], '-append')

end