Instruct = {};

pts_txt = sprintf('You have earned %d practice points in this section', block_p_points);
block_pts_txt = sprintf('In total, you have earned %d practice points', p_points);

Instruct{1} = {'REST BREAK',
               ' ',
               pts_txt,
               ' ',
               block_pts_txt,
               ' ',
               'If you have any questions please ask now',
               ' ',
               'Please PRESS ANY BUTTON when you are ready to continue'};
           
Instruct{2} = {'Now you will see another 5 practice trials',
                'before the start of the experiment',
               ' ',
               'Please PRESS ANY BUTTON when you are ready to continue'};


for ii = 1:length(Instruct)
    %clear keyboard, display screen four, wait for z or / to be pressed
    KbReleaseWait;
    keyResp = 0;
    TextDisplay(Instruct{ii}, win, color);
    Screen('Flip', win);
    WaitSecs(0.5);
    WaitTill({'1' '2' '3' '4' '6' '7' '8' '9'});
end
    
