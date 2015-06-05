function [p] = TrialLoop(p,center,t, stim, dimStim, end_ITI, end_Stim, start_t)
%Controls all stages of a single trial
% This includes ITI, Stim presentation and collection of response
% Returns results parameters in p struct

    left = [center(1)-p.xOffsetPix, center(2)];

    xLoc = p.stimLocsX(t);
    yLoc = p.stimLocsY(t);

    stimRect = [center(1) + p.radPix*(xLoc) - p.radPix, center(2) + p.radPix*(yLoc) - p.radPix,...
                center(1) + p.radPix*(xLoc) + p.radPix, center(2) + p.radPix*(yLoc) + p.radPix];
    %stimRect = round(stimRect + p.staggered*p.radPix/4.*[1 1 1 1]); % staggered is -1 for up/left, +1 for down/right

    Screen('DrawDots', win, [0,0], p.fixSizePix, p.fixColor, left, 0); %change fixation point
    Screen('DrawingFinished', win);
    Screen('Flip', win);
    p.ITI_StartReal(t) = GetSecs - start_t;
    WaitTill(end_ITI);

    frmCnt=1; %frame count
    p.stim_StartReal(t) = GetSecs - start_t;   % start a clock to get the stim onset time
    % STIMULUS
    FlushEvents;

    while frmCnt<=p.stimExpose % if we want multiple exposure durations, add that here

        if GetSecs >= end_Stim;
            break
        end
        
        if ~p.null(t)
            if p.dimStim(t) && p.stimDimSequ(t,frmCnt) % if stim is dimmed right now, draw a dimStim
                Screen('DrawTexture',win,dimStim(p.flickerSequ(1,frmCnt)),Screen('Rect',dimStim(p.flickerSequ(1,frmCnt))),stimRect);
            else % otherwise, draw a regular stim (both determined by flickerSequ)
                Screen('DrawTexture',win,stim(p.flickerSequ(1,frmCnt)),Screen('Rect',stim(p.flickerSequ(1,frmCnt))),stimRect);
            end
            
            % apperture around fixation
            Screen('DrawDots', win, [0 0], p.appSizePix, p.backColor, left, 1);

%             if ~p.dimStim(t) && p.stimSequ(t,frmCnt)>2
%                Screen('DrawTexture',w, stim(p.stimSequ(t,frmCnt)-2),Screen('Rect',stim(p.stimSequ(t,frmCnt))),stimRect);
%             else
%                Screen('DrawTexture',w, stim(p.stimSequ(t,frmCnt)),Screen('Rect',stim(p.stimSequ(t,frmCnt))),stimRect);
%             end

            Screen('DrawingFinished', w); % Tell PTB that no further drawing commands will follow before Screen('Flip')
            Screen('Flip', w);

            % check response...
            [resp, timeStamp] = WaitTill({'1','2'}); % buttons need to be decided
%             [resp, timeStamp] = checkForResp(p.keys, p.escape); % checks both buttons...
            if~isempty(resp);
                p.resp(t) = resp;
                p.respTime(t) = timeStamp;
                %p.RT(t) = Need to figure out what is the time in which
                %stim dims. Also, need to figure what to do for when there
                %is no dimstim (maybe don't need RT at all
                p.respFrame(t) = frmCnt;
            end
            
        end
        frmCnt = frmCnt + 1;
    end
    
    WaitTill(end_Stim);
    p.stim_EndReal(t) = GetSecs - start_t;
    
    % clear out screen
    Screen('DrawDots', w, [0,0], p.fixSizePix, p.fixColor, left, 0); %draw fixation point
    Screen('Flip',w);
    
%% Have not checked the code for hits, etc...    
     % hits:
    if  p.validTarget(t) && ~isempty(p.actualRespFrm(t).d)
        p.hits = p.hits+1;
        p.rt(t) = 0; %??
        %p.rt(t) = (p.actualRespFrm(t).d(1) - p.targetOnset(t)) * 1/p.fps;
    % misses:
    elseif p.validTarget(t) && isempty(p.actualRespFrm(t).d)
        p.misses = p.misses+1;
        %p.rt(t) = -1; p.rt stays as NaN (for nanmean)
    % false alarms
    elseif ~p.validTarget(t) && ~isempty(p.actualRespFrm(t).d)
        p.falseAlarms = p.falseAlarms+1;
        p.rt(t) = p.actualRespFrm(t).d(1) * 1/p.fps;
    % correct rejections
    elseif ~p.validTarget(t) && isempty(p.actualRespFrm(t).d)
        p.correctRejections = p.correctRejections+1;
        p.rt(t) = -1;
    end 
    %% End of section that need to fix
    %end trial loop

end
