
Instruct = {};

if LR == 0;
    hands_small = 'RED';
    hands_large = 'GREEN';
end;
if LR == 1;
    hands_small = 'GREEN';
    hands_large = 'RED';
end;

small_txt = sprintf('the %s button.', hands_small);
large_txt = sprintf('the %s button.', hands_large);


Instruct{1} = {'In this section, two numbers will appear on the screen.',
                'Your job is to add both numbers.',
                ' ',
                'On some trials, after 2 seconds you will see',
                'another number in the middle of the screen.',
                ' ',
                'If you see a number, your job is to decide',
                'if the number shown is smaller or greater than',
                'the value of the sum of the first two numbers.'
                ' ',
                'A white frame around the screen will remind you',
                'that is time to answer.' 
                ' ',
                'Please PRESS ANY BUTTON to go on to the next screen.'};
                       
Instruct{2} = {'You will have 2.5 seconds to decide.',
                ' ',
                'If you think the last number is SMALLER than the sum',
                'of the first two numbers you should press',
                small_txt,
                ' ',
                'If you think the last number is GREATER than the sum',
                'of the first two numbers you should press',
                large_txt,
                ' ',
                'Please press only once.',
                ' ',
                'After the practce phase, if you answer correctly,',
                'you will receive 1 point. We will keep track of the points',
                'and at the end you will recieve 5 cents per point',
                ' ',
                'Remember to answer FAST and ACCURATELY.'
                ' ',
                'Please PRESS ANY BUTTON to go on to the next screen.'};
            
Instruct{3} = {'For example, if the numbers you see are 5 and 10',
              'and in the next screen you see a number like 17',
              'which is GREATER than the sum of 5 and 10',
              'you should press',
              small_txt',
              ' ',
              'On the other hand, if in the next screen you see a SMALLER number',
              'like 13 you should press',
              large_txt,
              ' ',
              'Please PRESS ANY BUTTON to go on to the next screen.'};            
   
Instruct{4} = {'On some trials, instead of getting a second number for comparison',
                'you will see an X. This means you DO NOT need',
                'to do anything in this trial.',
                ' ',
               'If you have any questions please ask now',
               ' ',
              'Please PRESS ANY BUTTON to go on to the next sceen.'};
          
Instruct{5} = {'We are now ready to begin.',
              ' ',
              'In the following screens there will be 3 practice trials',
              ' ',
              'Please PRESS ANY BUTTON to begin the practice trials.'};
            

for ii = 1:length(Instruct);
%     %This is the code if we want to use mouse instead of keyboard
%     clearMouseInput;
%     TextDisplay(Instruct{ii}, win, color);
%     Screen('Flip', win);
%     WaitSecs(0.5);GetClicks(win,0);
    %This is the code if we want to use keyboard instead of mouse to move
    %screen
    %clear keyboard, display screen four, wait for z or / to be pressed
    KbReleaseWait;
    keyResp = 0;
    TextDisplay(Instruct{ii}, win, color);
    Screen('Flip', win);
    WaitSecs(0.5);
    WaitTill({'1' '2' '3' '4' '6' '7' '8' '9'});
end
