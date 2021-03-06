function trialResponse = NumLineSlow_Abs(stim, points, left_end, right_end, lineLength, lineSZ, jitter, ppc_adjust, win, color, x1, x2, yline, center, winRect, junk, end_decision, slow, wrong, badpress)

%plots a line starting at x1, finishing at x2, with cursor starting on
%either left (lrStart = 0) or right (lrStart = 1) side.

    KbReleaseWait;

    FlushEvents;
    %click = 0;
    
    %% Temporary code for exact vs not exact
%     % Pick a random number to decide whether the trial is exact or not
%     exact = round(rand(1));
    %%

    %set variables Need to change this when I know what vars I will need
    cursor_pos = -1;
    correct =-1;
    response = -1;
    RT = -1;
    error = -1;
    %time_left = 1;
    time_fix = 0.005;
    Press = -1; %Does the trial require a key press?
    Acc = -1;
    
    probe = num2str(stim{1});
    probeMag = stim{2};

    %Initialize log
    trialResponse = {cursor_pos correct response RT error Press points slow wrong badpress Acc};

    
    if junk ==1;
        Press = 0; 
        correct = 0;
    else
        Press = 1;
    end;
    
    
    HideCursor;
    
    %Add displacement to the list of results when I know all variables I
    %need
    %% The if exact statement is temporary
%     if exact
%         displacement = 0;
%     else
%         displacement = JitterCursor();
%     end
    displacement = JitterCursor();
    %%
   
%     trialResponse{1} = 0.5 + displacement; %Cursor will always appear outside of nline range.
     trialResponse{1} = probeMag + displacement; %Cursor will always appear +/- 1-5 from correct position.
%     trialResponse{1} = 0.9*rand + 0.1; %If rand 0 cursonr starts at 0.1 if rand 1 starts at 0.9
%     trialResponse{1} = 0.5; %Fixed position

    %Extended endpoints
    %extension = lineLength/2;
    xStart = x1; % - extension;
    xEnd = x2; % + extension;
    
    CursorStartPosX = round(trialResponse{1}*(x2-x1) + x1); %cursor is +/- range in JitterCursor
%     MouseStartPosX = round(0.5*(x2-x1) + x1) %Mouse position in center of line this can change
    %SetMouse(CursorStartPosX,yline,win);
    
    %% This is going to be a temporary solution
    if junk == 0
        if displacement < 0
            correct = 1;
        else
            correct = 2;
        end
    end

%     if junk == 0
%         if exact == 0
%             correct = 1;
%         else
%             correct = 2;
%         end
%     end
    
    %%
    % Log changes to control variables
    trialResponse{2} = correct;
    trialResponse{6} = Press;

    Screen('TextSize',win, 30);
    Screen('TextStyle',win, 1);

    t_start = GetSecs;
      
%     %Draw frame
%     winRect = Screen('Rect', win);
%     Screen('FrameRect', win, [255 255 255 255], winRect, 30);
%     Screen('Flip', win, 0, 1);

%Remove the hold cue
    %Draw numberline
    DrawNline(left_end, right_end, lineLength, lineSZ, jitter, ppc_adjust, win, color, x1, x2, yline, center, winRect, 1);
    %Draw probe
    DrawProbeBox('.', win, color, yline, center, jitter, winRect);
    
    line_start = GetSecs;
    %Draw cursor line
    lineSZc = round(7);
    if junk ==0;
        Screen('Drawline', win, [0 0 0 0], CursorStartPosX, yline - lineSZc/1.5, CursorStartPosX, yline + lineSZc/1.5, round(7));
    end
    
    %Draw arrow for junk trials
    if junk == 1;
        %DrawArrow(round(probeMag*(x2-x1) + x1),yline,win,1);
    end

    Screen('Flip', win);
    
    WaitTill(t_start + 0.1);
    
    %Draw numberline
    DrawNline(left_end, right_end, lineLength, lineSZ, jitter, ppc_adjust, win, color, x1, x2, yline, center, winRect, 1);
    DrawProbeBox('.', win, color, yline, center, jitter, winRect);
    Screen('Flip', win);
    %GetSecs - line_start
    
%     test = 0;
%     % Wait for subject to click mouse before displaying cursor
%     %[xPos_old, yPos_old] = GetMouse(win);
%     while ~test;
%         [xPos, yPos, click] = GetMouse(win);
%         click = sum(click);
%         %if or(xPos_old ~=xPos, yPos_old ~= yPos);
%         if click == 1;
%             test = 1;
%         end;
%         if GetSecs >= end_decision - 0.001;
%             test = 1;
%             draw = 0;
%         end;
%     end;
    
%     % Measure RT from the moment the hold signal is released until mouse is
%     % moved
%     RTHold = GetSecs - t_start;
%     trialResponse{6} = RTHold;
%     
%     clearMouseInput;

    FlushEvents;
%     click = 0;
%     SetMouse(CursorStartPosX,yline,win);
%     mousetrack = [(CursorStartPosX - x1)/(x2-x1)];
    %xPos = MouseStartPosX;
    %[xPos, yPos, click] = GetMouse(win);
    time = end_decision - time_fix;
    [key, secs] = WaitTill(time, {'1','2','3','4','6','7','8','9'});
    
    
    if strcmp(key,'1') || strcmp(key,'2') || strcmp(key,'3')|| strcmp(key,'4')
        key = '1';
    end

    if strcmp(key,'6') || strcmp(key,'7') || strcmp(key,'8')|| strcmp(key,'9')
        key = '2';
    end
    
    %xPos = CursorStartPosX + (xPosNew-CursorStartPosX)* speed;
    %mousetrack = [mousetrack (xPos - x1)/(x2-x1)];
    if isempty(key);
        %sprintf('timeout');
        %time_left = 0;
        trialResponse{3} = 0; %Response
        if junk;
            trialResponse{5} = 0; %Error
            trialResponse{11} = 1; %Acc
        else
            trialResponse{5} = 1; %Error, didn't click when was needed
            trialResponse{11} = 0; %Acc
            trialResponse{8} = slow + 1; %Error for being slow
        end
        if abs(trialResponse{5}) <= 0.05;
            trialResponse{7} = points + 1;
        end
    end
%                 if testX == 1;
%                     trialResponse{9} = points;
%                     trialResponse{10} = move + 1;
%                 end
       

%                 if xPos < xStart;
%                     xPos = xStart;
%                     xPosNew = xStart;
%                 end
% 
%                 if xPos > xEnd;
%                     xPos = xEnd;
%                     xPosNew = xEnd;
%                 end

%                 click = sum(click);
    if ~isempty(key);
        trialResponse{4} = secs - t_start;
        trialResponse{3} = str2double(key);
        if junk; % if catch trial do something if not catch trial do something else
            trialResponse{5} = 1; %Error clicked when should not
            trialResponse{11} = 0;
        else
            trialResponse{5} = abs(trialResponse{3} - correct);
            trialResponse{11} = 1 - abs(trialResponse{3} - correct);
        end
        if abs(trialResponse{5}) <= 0.05;
            trialResponse{7} = points + 1;
            good = 1;
        else
            if junk;
                trialResponse{10} = badpress + 1;
            else
                trialResponse{9} = wrong + 1;
            end
        end
%                     if testX == 1;
%                         trialResponse{9} = points;
%                         trialResponse{10} = move + 1;
%                     end
        
    %Draw numberline
    DrawNline(left_end, right_end, lineLength, lineSZ, jitter, ppc_adjust, win, color, x1, x2, yline, center, winRect, 1);
    if good == 1
        DrawProbeBox('.', win, [255 215 0], yline, center, jitter, winRect);
    else
        DrawProbeBox('.', win, [0 200 255], yline, center, jitter, winRect);
    end
    Screen('Flip', win);
        %Screen('Flip', win);
        %WaitSecs(0.07);
        
    end
    
    
    %GetSecs - line_start

%     %Draw numberline
%     DrawNline(left_end, right_end, lineLength, lineSZ, jitter, ppc_adjust, win, color, x1, x2, yline, center, winRect, 1);
%     %Draw probe
%     DrawProbeBox('.', win, [0 255 0], yline, center, jitter, winRect);
% %                 Screen('DrawText', win, probe, probeLeft, probeTop, color);
% 
% 
%     %Draw cursor line
%     lineSZc = round(35);
%     Screen('Drawline', win, [0 0 0 0], CursorStartPosX, yline - lineSZc/1.5, CursorStartPosX, yline + lineSZc/1.5, round(7));
% 
% 
%     %Draw arrow for junk trials
%     if junk == 1;
%         DrawArrow(round(probeMag*(x2-x1) + x1),yline,win,1);
%     end
% 
% 
%     Screen('Flip', win);

%         trialResponse{14} = mousetrack;

    %This is if I want fixation to be included
    % fix_on = time_fix + time_left*(time_on - trialResponse{4});
    % DrawCenteredNum('X',win,color,fix_on);
    % Screen('Flip', win);
end

