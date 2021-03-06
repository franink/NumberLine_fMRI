function [ compResults ] = ConsiderSlow_Abs(Fract, win, color, task, end_cons)
%Version for real trials (time is absolute unlike in practice)
%Consider the numbers on the screen before moving to decision phase
% task is either 'keyb' or 'mouse' and tells the program what needs to log
%Logs the numerator denominator and the magnitude of the fraction

fractMag = Fract(1)/Fract(2);
correct = fractMag;
RT = -1;

compResults = {Fract(1) Fract(2) fractMag}; 


DrawCenteredFrac(Fract,win, color);
Screen('Flip', win);

% t_start = GetSecs;
% 
% if strcmp(task,'keyb')
%     KbReleaseWait;
%     time = end_cons-time_fix;
%     [key, secs] = WaitTill(time, {'z' '/'}, 0); %wait seconds even if there is a press
%     if ~isempty(key);
%         RT = secs - t_start;
%     end
%     
%     % Decide if I will use a fixation during time left. Tight now I think it is better to keep stim all the time
%     
% %     t_start = GetSecs;
% %     t_end = t_start + time_on;
% %     while ~keyResp
% % 
% %         [keyIsDown, secs, keyCode, deltaSecs]  = KbCheck;   
% %         keypress = find(keyCode==1, 1);
% %         if ~isempty(keypress) || GetSecs >= t_end;
% %             if GetSecs >= t_end;
% %                 compResults{4} = 0;
% %                 time_left = 0;
% %                 keyResp = 1;
% %             else
% %                 compResults{4} = secs - t_start; %Make sure I know what position goes fo what pieces of data
% %                 keyResp = 1;
% %             end
% %         end
% %     end
% %     fix_on = time_fix + time_left*(time_on - compResults{4});
% %     DrawCenteredNum('X',win,color,fix_on);
% %     Screen('Flip', win);
% end
% 
% if strcmp(task,'mouse')
%     clearMouseInput;
%     mouseResp = 0;
%     while ~mouseResp
%         [xPos, yPos, click] = GetMouse(win);
%         if ~isempty(click) || GetSecs >= end_cons - time_fix;
%             if GetSecs >= end_cons - time_fix;
%                 RT = 0;
%                 %time_left = 0; Only if fixation after stim is used
%                 mouseResp = 1;
%             else
%                 click = sum(click);
%                 if click == 1;
%                     RT = GetSecs - t_start;
%                     mouseResp = 1;
%                 end
%             end
%         end
%     end
% 
%     %This is if I want fixation to be included
%     % fix_on = time_fix + time_left*(time_on - compResults{4}); 
%     %DrawCenteredNum('X',win,color,fix_on);
%     %Screen('Flip', win); 
% end

end
