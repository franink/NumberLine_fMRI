function trialResponse = NumLineRGSlow(fract, win, lineLength, jitter, color, time, num_denom)

%plots a line starting at x1, finishing at x2, with cursor starting on
%either left (lrStart = 0) or right (lrStart = 1) side.

%trialResponse format is [startPos, RT, propLine)

    ppc_adjust = 23/38;

    lineLength = round(lineLength*ppc_adjust);

    rng shuffle
    jitter = jitter*randi([-300 300]);
    jitter = round(jitter*ppc_adjust);% Here position of line is jittered

    clearMouseInput;

    FlushEvents;
    click = 0;

    %set variables
    mouse_pos = -1;
    correct =-1;
    response = -1;
    RT = -1;
    error = -2;
    %time_left = 1;
    time_fix = 0.0;
    time_on = time - time_fix;


    trialResponse = {mouse_pos correct response RT error};




    
    correct = fract(num_denom);
    trialResponse{2} = correct;

    lineSZ = round(20*ppc_adjust);

    winRect = Screen('Rect', win);

    y = round(winRect(4)/2);
    center = winRect(3)/2;
    
   % yprobe = round(winRect(4)/4); % This is to signal number to be placed

    x1 = round(center - lineLength/2 + jitter); % Here position of line is jittered
    x2 = round(center + lineLength/2 + jitter);% Here position of line is jittered
    
    %Find out where mark should be placed
    correct = correct/25;
    trialResponse{2} = correct;

    HideCursor;
    t_start = GetSecs;

    trialResponse{1} = 0.8*rand + 0.1; %If rand 0 cursonr starts at 0.1 if rand 1 starts at 0.9

    MouseStartPosX = round(trialResponse{1}*(x2-x1) + x1);

    SetMouse(MouseStartPosX,y,win);

    Screen('TextSize',win, 25);
    Screen('TextStyle',win, 1);

    yTextPos = 2*round(rand) - 1;

    zeroBox = Screen('TextBounds', win, '0');
    oneBox = Screen('TextBounds', win, '25');
    zeroBox = CenterRectOnPoint(zeroBox, x1, y + yTextPos*40);
    oneBox = CenterRectOnPoint(oneBox, x2, y + yTextPos*40);
    
    if num_denom == 1;
        yprobe = y - 100;
        probeBox = Screen('TextBounds', win, 'TOP');
        probeBox = CenterRectOnPoint(probeBox, center + jitter, yprobe);
        probeLeft = probeBox(RectLeft);
        probeTop = probeBox(RectTop);
    end
    if num_denom == 2;
        yprobe = y + 100;
        probeBox = Screen('TextBounds', win, 'BOTTOM');
        probeBox = CenterRectOnPoint(probeBox, center + jitter, yprobe);
        probeLeft = probeBox(RectLeft);
        probeTop = probeBox(RectTop);
    end

    zX=zeroBox(RectLeft); oX = oneBox(RectLeft); yNum=oneBox(RectTop);

    t_start = GetSecs;
    t_end = t_start + time_on;
    mouseResp = 0;
    
    

    while ~mouseResp;
        [xPos, yPos, click] = GetMouse(win);
        if ~isempty(click) || GetSecs >= t_end;
           if GetSecs >= t_end;
                %sprintf('timeout');
                time_left = 0;
                mouseResp = 1;
           else

                if xPos < x1;
                    xPos = x1;
                end

                if xPos > x2;
                    xPos = x2;
                end

                click = sum(click);

                if click == 1;
                    trialResponse{4} = GetSecs - t_start;
                    trialResponse{3} = (xPos - x1)/(x2-x1);
                    trialResponse{5} = trialResponse{3} - correct;
                    %mouseResp = 1;
                end


                Screen('Drawline', win,color, x1, y, x2, y, round(5*ppc_adjust)); %instead of color he had [0 0 200 255]
                Screen('Drawline', win, color, x1, y - lineSZ, x1, y + lineSZ, round(5*ppc_adjust));
                Screen('Drawline', win, color, x2, y - lineSZ, x2, y + lineSZ, round(5*ppc_adjust));

                Screen('DrawText', win, '0', zX, yNum, color);
                Screen('DrawText', win, '25', oX, yNum, color);
                
                if num_denom == 1;
                    Screen('DrawText', win, 'TOP', probeLeft, probeTop, color);
                end
                if num_denom == 2;
                    Screen('DrawText', win, 'BOTTOM', probeLeft, probeTop, color);
                end

                Screen('Drawline', win, [0 0 0 0], xPos, y - lineSZ/1.5, xPos, y + lineSZ/1.5, round(5*ppc_adjust));

                Screen('Flip', win);
           end

        end
    end

    %This is if I want fixation to be included
    % fix_on = time_fix + time_left*(time_on - trialResponse{4});
    % DrawCenteredNum('X',win,color,fix_on);
    % Screen('Flip', win);
end
