function [ compResults ] = NumMatchSlow_Abs(Fract, Window, color, time, ctch)
%Decide if second number matches one of the original numbers


    correct = -1;
    response = -1;
    accuracy = -1;
    RT = 0;
    time_fix = 0.05;
    time_left = 1;
    time_on = time - time_fix;
    compResults = {Fract(3) correct response RT accuracy}; %I still need to think about what I will log and if I can put names

    % Check if this is a catch trial or not
    if ctch;

        if or(Fract(1) == Fract(3), Fract(2) == Fract(3));
            correct = 1;
        else
            correct = 0;
        end

        compResults{2} = correct;

        winRect = Screen('Rect', Window);
        w = winRect(RectRight);
        h = winRect(RectBottom);

        textSz = 50;

        %Text size is 20, style is 1, color is black
        Screen('TextSize',Window, 45);
        Screen('TextStyle',Window,1);
        %color = [0 0 200 255];

        %Iterate through TextCell and draw text into backbuffer
        fbox11 = Screen('TextBounds', Window, num2str(Fract(3)));
        fbox11 = CenterRectOnPoint(fbox11, w/2,h/2);

        x11 = fbox11(RectLeft);
        y11 = fbox11(RectTop);
        xlim1 = fbox11(RectRight);
        
        ctch

        Screen('DrawText', Window, num2str(Fract(3)), x11, y11, color);
        Screen('Flip',Window);

        t_start = GetSecs;
        KbReleaseWait;
        [key, secs] = WaitTill(time-time_fix, {'z' '/'}, 0); %wait seconds even if there is a press
        if~isempty(key);
            compResults{3} = key;
            compResults{4} = secs - t_start;
            if key == 'z';
                response = 0;
            end
            if key == '/';
                response = 1;
            end
            compResults{5} = correct==response;
        end





        % keyResp = 0;
        % t_end = t_start + time_on;
        % while ~keyResp
        %     [~, secs, keyCode, ~]  = KbCheck;   
        %     keypress = find(keyCode==1, 1);
        %     if ~isempty(keypress) || GetSecs >= t_end
        %         if GetSecs >= t_end; %timed out
        %             time_left = 0;
        %             keyResp = 1;
        %         end
        %         if keypress == 29 %they press z
        %                 keyResp = 1;
        %                 response = 0;
        %                 compResults{3} = response;   
        %                 compResults{4} = secs - t_start;
        %                 compResults{5} = correct==response;
        %         end
        %         
        %         if keypress == 56 %they press /
        %                 keyResp = 1;
        %                 response = 1;
        %                 compResults{3} = response;
        %                 compResults{4} = secs - t_start;
        %                 compResults{5} = correct==response;
        %         end
        %         
        %         
        %     end
        % end

        %This is if I want fixation to be included
        % fix_on = time_fix + time_left*(time_on - compResults{4});
        % DrawCenteredNum('X',Window,color,fix_on);
        % Screen('Flip', Window);
    end
    

end