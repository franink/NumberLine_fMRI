function [] = DrawProbeBox(probe, win, color, yline, center, jitter, winRect)
%Drwas a box to put probes in.
%Probes include empty field, X's, syllables, or numbers

probe = num2str(probe);
Screen('TextSize',win, 32);
Screen('TextStyle',win, 1);
yline = round(winRect(4)/2);
yprobe = yline - 250;
Box = Screen('TextBounds', win, 'XXXX');
Screen('TextSize',win, 32);
probeBox = Screen('TextBounds', win, probe);
Box = CenterRectOnPoint(Box, center + jitter, yprobe);
if probe == '.'
    Screen('TextSize',win, 60);
    yprobe = yprobe - 30;
end
probeBox = CenterRectOnPoint(probeBox, center + jitter, yprobe);
probeLeft = probeBox(RectLeft);
probeTop = probeBox(RectTop);

Screen('FrameRect', win, [255 255 255 255], Box, 3);
Screen('DrawText', win, probe, probeLeft, probeTop, color);
ReadKey('z'); %To allow ESC to exit

HideCursor;

end

