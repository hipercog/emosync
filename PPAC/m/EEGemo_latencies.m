% THIS SCRIPT HAS BEEN ADDED TO CTAP AS /src/utils/events/eeg_tile_locked_evts.m

ind = '/home/bcowley/Benslab/project_METHODMAN/project_PPAC/PPAC/ctap-ppac/4_cleaned';
fileslist = dir(fullfile(ind, '*.set'));

%%
for fs = 1:numel(fileslist)

EEG = pop_loadset('filepath', ind, 'filename', fileslist(fs).name);

%% 
bndx = ismember({EEG.event.type}, 'boundary');
bndlats = [EEG.event(bndx).latency];

blkx = ismember({EEG.event.type}, 'blink');
blklats = [EEG.event(blkx).latency];

LOCK_EVTS = {'EMPATIA_rsp' 'ILO_rsp' 'INHO_rsp' 'INNOSTUNEISUUS_rsp' 'PELKO_rsp' 'RENTOUTUNEISUUS_rsp' 'SURU_rsp' 'VIHA_rsp' 'VOITTO_rsp'...
            'EMPATHY_rsp' 'JOY_rsp' 'DISGUST_rsp' 'ENTHUSIASM_rsp' 'FEAR_rsp' 'RELAXATION_rsp' 'DEPRESSION_rsp' 'ANGER_rsp' 'TRIUMPH_rsp'};

END_EVTS = {'white noise video', 'ATTRACTION'};

cseg_type = 'cseg';


%%
ev = 1;
rsps = 0;
lockev_register = zeros(1, numel(LOCK_EVTS));
while ev < length(EEG.event) %go through all the events
    if ismember(EEG.event(ev).type, LOCK_EVTS) %act on those that are LOCKs
        lockevix = ismember(LOCK_EVTS, EEG.event(ev).type);
        lockev_register(lockevix) = lockev_register(lockevix) + 1;
        rsps = rsps + 1;
        lats = zeros(1, 5);
        evlat = EEG.event(ev).latency;
        for evd = ev+1:length(EEG.event)
            if ismember(EEG.event(evd).type, END_EVTS)
                break
            end
        end
        wnlat = EEG.event(evd).latency;
        evlen = wnlat - evlat;
        evsec = evlen / EEG.srate;
        curr_evs = ev:evd;
        bndx_in_epc = bndlats >= evlat & bndlats <= wnlat;
        blkx_in_epc = blklats >= evlat & blklats <= wnlat;
        
        % calculate onsets from less than 5 seconds of data
        if evlen <= 5 * EEG.srate
            % so, uniformly spread five 1sec windows...
            olp = ((5 * EEG.srate) - evlen) / 4;
            lats = evlat + 1 : EEG.srate - olp : wnlat - 1;
            % 6 onsets are created but we can simply discard the last
            if numel(lats) > 5
                lats(6:end) = [];
            end
            
        % calculate onsets that minimise overlap with boundaries
        elseif numel(curr_evs) > 2 && any(bndx_in_epc)
            
            % calculate sparse onsets, but from cut-up data
            cslat = evlat + 1;
            % try to get five clean slices if gaps exist between boundaries
            for e = (1:5)
                while cslat <= wnlat - ((6 - e) * EEG.srate)
                    bndx_in_wnd = bndlats >= cslat & bndlats <= cslat + EEG.srate;
                    if any(bndx_in_wnd)
                       cslat = max(bndlats(bndx_in_wnd)) + 1;
                    else
                        lats(e) = cslat;
                        cslat = cslat + EEG.srate + 1;
                        break
                    end
                end
            end
            % Try to place the missing event where there is fewest boundaries
            if sum(lats == 0) == 1
                lat0x = lats(lats ~= 0);
                allat = evlat + 1 : wnlat - 1;
                stx = evlat + 1;
                for i = 1:numel(lat0x)
                    allat(ismember(allat, lat0x(i):lat0x(i) + EEG.srate)) = [];
                    stx(end + 1) = lat0x(i) + EEG.srate + 1; %#ok<*SAGROW>
                end
                stx(~ismember(stx, allat)) = [];
                jumps = diff(allat) > 1;
                jumps(end) = 1;
                for i = 1:numel(stx)
                    if allat(find(jumps, 1)) - stx(i) < EEG.srate
                        break
                    else
                        stx_bndx_in_wnd(i) = sum(ismember(bndlats...
                                            , stx(i):allat(find(jumps, 1))));
                    end
                end
                [mnst, mnstx] = min(stx_bndx_in_wnd);
                lats(lats == 0) = stx(mnstx);
            end
        end
        % create 5 windows from clean sparse data
        if any(lats == 0)
            lats = evlat + 1 : EEG.srate : evlat + EEG.srate * 5;
        end
 
        cseg = eeglab_create_event(lats, cseg_type...
                            , 'duration', {EEG.srate}...
                            , 'label', {EEG.event(ev).type}...
                            , 'kind', {num2str(lockev_register(lockevix))});
%         fprintf('Event #%d : %s\n', ev, EEG.event(ev).type)
        EEG.event = eeglab_merge_event_tables(EEG.event, cseg, 'ignoreDisc');
    end
    ev = ev + 1;
end
% check csegs
csegs = sum(ismember({EEG.event.type}, 'cseg'));
fprintf('%d csegs from %d responses for %s\n', csegs, rsps, EEG.CTAP.subject.subject)
% save file
if csegs == rsps * 5
%     pop_saveset(EEG, 'filepath', ind, 'filename', fileslist(fs).name)
else
    disp('SOMETHING HAS GONE TERRIBLY WRONG!!')
end
end