function [] = DrawCenteredNum(Fract, Window, color, time)
%For practice trials time is relative
%TextDisplay displays text on the screen, eg, to give user instructions in
%an experiment. Each line of text must be stored in a cell. Importantly,
%Psychtoolbox must already be initialized and the Window must be open. Also
%note this program does not close the screen so if it is run by itself sca
%or similar should be called to close the window.
% Unlike DrawCenteredFrac this code displays a singlr number in middle of
% screen
%Fract is replaced by an 'X" for fixation

winRect = Screen('Rect', Window);
w = winRect(RectRight);
h = winRect(RectBottom);

textSz = 50;

%Text size is 20, style is 1, color is color
Screen('TextSize',Window, 50);
Screen('TextStyle',Window,1);

%Draw text into backbuffer
fbox11 = Screen('TextBounds', Window, Fract); 
fbox11 = CenterRectOnPoint(fbox11, w/2,h/2);

x11 = fbox11(RectLeft);
y11 = fbox11(RectTop);
xlim1 = fbox11(RectRight);

%Draw number
Screen('DrawText', Window, Fract, x11, y11, color);
Screen('Flip',Window);
wakeup = WaitSecs(time);


end