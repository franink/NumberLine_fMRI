Instruct = {};

Instruct{1} = {'Please read carefully the following instructions',
               'for the next section.'
               ' ',
               'PLease PRESS ANY BUTTON to go on to the next screen.'};

Instruct{2} = {'In this section, a fraction will appear on the screen.',
               'Your job is to to think about the magnitude of this fraction',
               ' ',
                'On some trials, after 2 seconds you will see an X.',
                'This means you DO NOT need to do anything in this trial.',
                ' ',
                'On other trials, after the 2 seconds you will see',
                'another fraction.',
                ' ',
                'If you see another fraction, then your job is to decide',
                'if the magnitude of the second fraction is smaller',
                'or greater than the first fraction.'
                ' ',
                'Please PRESS ANY BUTTON to go on to the next screen.'};

Instruct{3} = {'You will have 2.5 seconds to decide.',
                ' ',
                'If you think the last fraction is SMALLER than the first',
                'you should press a button with your LEFT hand.'
                ' ',
                'If you think the last fraction is GREATER than the first',
                'you should press a button with your RIGHT hand.'
                ' ',
                'Please press only once.',
                ' ',
                'If you answer correctly',
                'you will receive 1 point. We will keep track of the points',
                'and the top 5 participants will receive an extra $10 bonus',
                ' ',
                'Remember to answer FAST and ACCURATELY.'
                ' ',
                'Please PRESS ANY BUTTON to go on to the next screen.'};

Instruct{4} = {'We are now ready to begin.',
              ' ',
              'In the following screens there will be 3 practice trials',
              ' ',
              'Please PRESS ANY BUTTON to begin the experiment.'};


for ii = 1:length(Instruct);
    KbReleaseWait;
    keyResp = 0;
    TextDisplay(Instruct{ii}, win, color);
    Screen('Flip', win);
    WaitSecs(0.5);
    WaitTill({'1' '2' '3' '4' '6' '7' '8' '9'});
end