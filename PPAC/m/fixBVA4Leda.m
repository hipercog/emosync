function good = fixBVA4Leda(ind, filt, ext, sizes)


fs = dir(fullfile(ind, [filt, '*.' strrep(ext, '.', '')]));
% fs = dir('DCVR*.mat');
type = {'Ledaded' 'EDA' 'C+C12?' 'none'};
good = zeros(numel(fs), 1);

for i = 1:numel(fs)
    edachs = 0;
    samps = 0;
    Markers = struct('Position', 1, 'Type', 'null', 'Description', 'null');
    load(fs(i).name);

    if exist('analysis', 'var') &&...
       exist('fileinfo', 'var') &&...
       exist('data', 'var')
   
        [edachs, samps] = size(data.conductance);
        if any(samps == sizes)
            good(i) = 1;
        end
        clear analysis fileinfo data
        t = 1;

    elseif exist('ChannelCount', 'var') &&...
       exist('Channels', 'var') &&...
       exist('EDA', 'var') &&...
       exist('MarkerCount', 'var') &&...
       exist('SampleRate', 'var') &&...
       exist('SegmentCount', 'var') &&...
       exist('t', 'var')

        save(fs(i).name, 'ChannelCount', 'Channels', 'EDA', 'MarkerCount'...
                        , 'SampleRate', 'SegmentCount', 't', 'Markers') %#ok<*USENS>
        [edachs, samps] = size(EDA);
        clear ChannelCount Channels EDA MarkerCount SampleRate SegmentCount t Markers
        t = 2;
        
    elseif exist('ChannelCount', 'var') &&...
       exist('Channels', 'var') &&...
       exist('CEDA', 'var') &&...
       exist('C12', 'var') &&...
       exist('MarkerCount', 'var') &&...
       exist('SampleRate', 'var') &&...
       exist('SegmentCount', 'var') &&...
       exist('t', 'var')
   
        if any(C12)
            fprintf('\n%s : C12 has %d signals!', fs(i).name, sum(C12 ~= 0))
            continue
        end
        EDA = CEDA;
        ChannelCount = 1;
        Channels = Channels(strcmp({Channels.Name}, 'EDA'));
        save(fs(i).name, 'ChannelCount', 'Channels', 'EDA', 'MarkerCount'...
                        , 'SampleRate', 'SegmentCount', 't', 'Markers')
        [edachs, samps] = size(CEDA);
        clear ChannelCount Channels EDA CEDA C12 MarkerCount SampleRate SegmentCount t Markers
        t = 3;
    else
        t = 4;
    end

    fprintf('\n%s = %s \t size = %d, %d', fs(i).name, type{t}, edachs, samps)
    if edachs > 1
        warning('BIG DATA!');
    end
    
end
