%Code for IEM experiment to map spatial attention.
%Based on Tommy Sprague's ap2dAttn_flicker4.m
% Tanks to Xiangrui Li for the codes for WaitTill and ReadKey.

% - attend checkerboards, detect contrast dimming on some trials

%make sure no Java problems
PsychJavaTrouble;
rng shuffle;

% In case previous subject was not cleared
clear Instruct;


%Filename to save data
filename = getFilename();

%Setup experiment parameters

p.ramp_up = 16; %MUX2 with TR 2sec requires 16secs (8TRs) of rampup

p.stim_t = 4;
p.runs = 4; %This number has to be decided
p.nLocArm = 3;
p.nLoc = p.nLocArm * 4 + 1; %'+' horizontal-vertical meridian each arm has 3 plus center
p.ntasks = 1;
p.percentnull = 0.4; 
p.tasks = {'attend stim'}; 
p.trialSecs = p.stim_t + p.mean_ITI;
p.flickerFreq   = 6; % Hz
p.flickerPer  = 1/p.flickerFreq; % s
p.stimContrastChange = 0.5; %prob of trials with contrast change
p.contrastChangeWindow = [0.5 p.stim_t-0.75]; % period over which contrast can change
p.minTargFrame = p.contrastChangeWindow(1)*p.flickerFreq + 1; % these are period index (which period can we start target?)
p.maxTargFrame = p.contrastChangeWindow(2)*p.flickerFreq + 1; % +1 is because want cycle *starting at* this point in time
p.minTargSep = 1; % number of periods
p.nTargs = 1;
p.responseWindow = 1.0;
p.repetitions = 1;
p.nNull = round(p.repetitions * p.nLoc * p.percentnull);
p.TrialSet = p.nLoc + p.nNull;
p.nTrials = p.repetitions * p.nLoc + p.nNull;
p.ITI_Jits = [3.5:0.5:7 repmat(3:0.5:4.5,1,2)];
p.runDur = p.nTrials * p.trialSecs;
p.ITI_Min = 1.5;
p.ITI_Max = 4.5;
p.mean_ITI = 3;
itis = [p.ITI_Min:0.5:p.mean_ITI-.5 p.mean_ITI+.5:.5:p.ITI_Max]; %Set of unique iti values
nmbr_ITIrepeats = floor(p.nTrials/length(itis));
nmbr_ITIremainders = mod(p.nTrials,length(itis));
if nmbr_ITIremainders == 0;
    ITI_Jits = repmat(itis,1,nmbr_ITIrepeats);
else
    ITI_Jits = [repmat(itis,1,nmbr_ITIrepeats) repmat(3,1,nmbr_ITIremainders)];
end
        


%Cursor helps no one here - kill it
HideCursor;

%Don't show characters on matlab screen
ListenChar(2);

% monitor stuff
p.refreshRate = 60; % refresh rate is normally 100 but change this to 60 when on laptop!
p.vDistCM = 277; %CNI
p.screenWidthCM = 58.6; % CNI
p.usedScreenSizeDeg = 12;

%stimulus geometry (in degrees, note that these vars have the phrase 'Deg'
%in them, used by pix2deg below)
p.radDeg = p.usedScreenSizeDeg/(p.nLocArm*2+2); %edge of stim touches borders of screen
p.sfDeg = .6785; %TS parameter value, might need to be changed

%fixation point properties
p.fixColor      = [180 180 180];%[155, 155, 155];
% p.fixSizeDeg    = .25 * .4523;                  % size of dot
p.fixSizeDeg    = .1131;

% font stuff
p.fontSize = 24;    
p.fontName = 'ARIAL';   
p.textColor = [100, 100, 100];


% --------------------Screen properties----------------------------%

p.LUT = 0:255;
% correct all the colors
p.fixColor = p.LUT(p.fixColor)';
p.textColor = p.LUT(p.textColor)';


% Open a PTB Window on our screen
try
    screenid = min(Screen('Screens')); %Originally it was max instead of min changed it for testing purposes (max corresponds to secondary display)
    
    [win, p.sRect] = Screen('OpenWindow', screenid, WhiteIndex(screenid)/2);
    
    color = [255 255 255 255]; %Cam's value was 0 200 255
catch
end

% Enable alpha blending with proper blend-function. We need it
% for drawing of smoothed points:
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% test the refesh properties of the display
p.fps=Screen('FrameRate',win);          % frames per second
p.ifi=Screen('GetFlipInterval', win);   % inter-frame-time
if p.fps==0                           % if fps does not register, then set the fps based on ifi
    p.fps=1/p.ifi;
end
p.flickerFrames = round(1/p.flickerFreq*p.fps);

% make sure the refreshrate is ok
if abs(p.fps-p.refreshRate)>5
    Screen('CloseAll');
    disp('CHANGE YOUR REFRESH RATE')
    ListenChar(0);
    clear all;
    return;
end

% convert relevant timing stuff to vid frames for stim presentation
p.stimExpose = round((p.stim_t*1000)./(1000/p.refreshRate));

% set the priority up way high to discourage interruptions
Priority(MaxPriority(win));

% convert from degrees to pixel units
p = deg2pix(p);

% compute and store the center of the screen: p.sRect contains the upper
% left coordinates (x,y) and the lower right coordinates (x,y)
center = [(p.sRect(3) - p.sRect(1))/2, (p.sRect(4) - p.sRect(2))/2];

Screen('TextSize', win, p.fontSize);
Screen('TextStyle', win, 1);
Screen('TextFont',win, p.fontName);
Screen('TextColor', win, p.textColor);


% start a block loop. I will probably send this loops to a different file
% like I did in my previous experiments (this laso just mught be the
% creation of run stimuli sequences, if so then leave here but translate to
% my style

armNeg = linspace(-p.nLocArm, 1, p.nLocArm);
armPos = linspace(1, p.nLocArm, p.nLocArm);

p.StimOnset = zeros(p.runs,p.nTrials);
p.StimEnd = zeros(p.runs,p.nTrials);
p.ITI_Onset = zeors(p.runs,p.nTrials);
p.Condition = zeros(p.runs,p.nTrials); %order left-right;up-down;center;null

% prepare run before start of scan
for r= 1:p.runs
    % Need to distinguish here from runs and repettions.
    % I should probably shuffle independently for each repetition but then
    % combine all results and files in a format the is separate only for
    % runs and not repettions
    for rep = 1:p.repetitions
        stimLocsX(rep,:) = [armNeg armPos];
        stimLocsY(rep,:) = zeros(1, length(p.stimLocsX));
        stimLocsX(rep,:) = [p.stimLocsX zeros(1,length(p.stimLocsY)) 0]';
        stimLocsY(rep,:) = [p.stimLocsY armNeg armPos 0]';
        dimStim(rep,:) = Shuffle([ones(ceil(length(p.stimLocsX)/2),1); zeros(floor(length(p.stimLocsX)/2),1)]); %If odd number of locations more dimcontrasts (ceil(dimcontrasts))
        condition(rep,:) = 1:p.nLoc; %order left-right;up-down;center;
    
        % mark null trials
        stimLocsX(rep,end+1:p.TrialSet) = NaN;
        stimLocsY(rep,end+1:p.TrialSet) = NaN;
        null = zeros(p.repetitions,p.TrialSet,1); null(isnan(stimLocsX)) = 1;
        dimStim(rep,end+1:p.TrialSet) = 0;
        condition(rep,end+1:p.TrialSet) = p.nLoc + 1; %order left-right;up-down;center;
        
    
        % shuffle trial order
        rndInd(rep,:) = randperm(p.TrialSet);
        stimLocsX(rep,:) = stimLocsX(rep,rndInd);
        stimLocsY(rep,:) = stimLocsY(rep,rndInd);
        null(rep,:) = null(rep,rndInd);
        dimStim(rep,:) = dimStim(rep,rndInd);
        condition(rep,:) = condition(rep,rndInd);
    end
    
    %Then combine all repetitioms in one line for each block
    tmp = rndInd';
    p.rndInd(r,:) = tmp(:)';
    
    tmp = stimLocsX';
    p.stimLocsX(r,:) = tmp(:)';
    
    tmp = stimLocsY';
    p.stimLocsY(r,:) = tmp(:)';
    
    tmp = null';
    p.null(r,:) = tmp(:)';
    
    tmp = dimStim';
    p.dimStim(r,:) = tmp(:)';
    
    tmp = condition';
    p.conditon(r,:) = tmp(:)'; 
    
%% Need to check if this section is correct specifically if this should be 
    %done inside the run block, the repetition block or outside of any of
    %this
    
    % generate checkerboards we use...
    p.stimContrast = 1;
    p.targetContrast = p.stimContrast - p.stimContrastChange; 
    c = make_checkerboard(p.radPix,p.sfPix,p.stimContrast);
    stim(1)=Screen('MakeTexture', win, c{1});
    stim(2)=Screen('MakeTexture', win, 127*ones(size(c{2})));
    stim(3)=Screen('MakeTexture', win, c{2});
    t = make_checkerboard(p.radPix,p.sfPix,p.targetContrast);
    dimStim(1)=Screen('MakeTexture', win, t{1});
    dimStim(2)=stim(2);
    dimStim(3)=Screen('MakeTexture', win, t{2});
 
    % generate a distribution for choosing the target time
    nStims = (p.stimExpose/p.refreshRate)*(p.flickerFreq ); % nStims = # periods to show (# of stim1/stim2 or targ1/targ2 alternations)
    p.targX = p.minTargFrame:p.minTargSep:p.maxTargFrame;   % this will be used to select when to show target(s) 
    for ii=1:p.nTrials
        tmp = randperm(length(p.targX));
        %p.targFrame(ii,:) = sort(p.targX(tmp(1:p.nTargs)))*(p.flickerFreq*2)-(p.flickerFreq*2)+1;
        p.targFrame(ii,:) = sort(p.targX(tmp(1:p.nTargs)))*(p.flickerFrames) - p.flickerFrames+1;
        p.targOnTime(ii,:) = p.targFrame(ii,:).*(1/p.refreshRate);
        p.targMaxRespTime(ii,:) = (p.targFrame(ii,:).*(1/p.refreshRate))+p.responseWindow;
    end
    
    % pick the stimulus sequence for every trial (the exact grating to be shown)
    for i=1:p.nTrials
        p.flickerSequ = repmat([ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2))],1,round(p.stimExpose/p.flickerFrames));
        p.stimSequ(1,:)=p.flickerSequ;
        p.flickerSequ = repmat([ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2)) 3*ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2))],1,(0.5)*round(p.stimExpose/p.flickerFrames));
        p.stimDimSequ(i,:) = zeros(1,size(p.flickerSequ,2));
        % mark the tarket spots with low contrast stims
        for j=1:p.nTargs
            p.stimDimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+2*p.flickerFrames-1) = 1;
            %p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+2*p.flickerFrames-1)=p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+2*p.flickerFrames-1)+2;
            % +2 above --> change to "target"
        end
    end
    
%% end of section I need to check
        
%         
%         
%     p.stimLocsX(r,:) = [armNeg armPos];
%     p.stimLocsY(r,:) = zeros(1, length(p.stimLocsX));
%     p.stimLocsX(r,:) = [p.stimLocsX zeros(1,length(p.stimLocsY)) 0]';
%     p.stimLocsY(r,:) = [p.stimLocsY armNeg armPos 0]';
%     p.dimStim(r,:) = Shuffle([ones(ceil(length(p.stimLocsX)/2),1); zeros(floor(length(p.stimLocsX)/2),1)]); %If odd number of locations more dimcontrasts (ceil(dimcontrasts))
%     
%     % mark null trials
%     p.stimLocsX(r,end+1:p.nTrials) = NaN;
%     p.stimLocsY(r,end+1:p.nTrials) = NaN;
%     p.null = zeros(r,p.nTrials,1); p.null(isnan(p.stimLocsX)) = 1;
%     p.dimStim(r,end+1:p.nTrials) = 0;
%     
%     % shuffle trial order
%     p.rndInd(r,:) = randperm(p.nTrials);
%     p.ITI_Jits(r,:) = p.ITI_Jits(r,p.rndInd);
%     p.stimLocsX(r,:) = p.stimLocsX(r,p.rndInd);
%     p.stimLocsY(r,:) = p.stimLocsY(r,p.rndInd);
%     p.null(r,:) = p.null(r,p.rndInd);
%     p.dimStim(r,:) = p.dimStim(r,p.rndInd);
    
    %allocate some arrays for storing the subject response
    p.hits(r) =        0;
    p.misses(r) =      0;
    p.falseAlarms(r) = 0;
    p.correctRejections(r) = 0; % sum of these by end of expt = p.nTrials
    p.rt(:,r) =          nan(p.nTrials, 1);       % store the rt on each trial
    p.resp(:,r) =        zeros(p.nTrials, 1);     % store the response
    p.respTime(:,r) =    zeros(p.nTrials, 1); %from stim onset in seconds
    p.respFrame(:,r) =   zeros(p.nTrials, 1); %from stim onset in frames
    p.trialStart(:,r) =  nan(p.nTrials,1);
    p.trialEnd(:,r) =  nan(p.nTrials,1);
    p.stimStart(:,r) =  nan(p.nTrials,1);
    p.stimEnd(:,r) =  nan(p.nTrials,1);
    
    %Generate timing for each trial in absolute time...
    end_ramp_up = p.ramp_up;
    current_time = end_ramp_up;
    p.ITI_JITS(r,:) = datasample(ITI_Jits, p.nTrials, 'Replace', false);
    for ii = 1:p.nTrials
        p.ITI_Onset(r,ii) = current_time;
        current_time = current_time + p.ITI_JITS(r,ii);
        p.StimOnset(r,ii) = current_time;
        current_time = current_time + p.stim_t;
        p.StimEnd(r,ii) = current_time;
    end
       
end

% Start of experiment
%Introductory instructions
DrawCenteredNum('Welcome', win, p, 0.5);
WaitTill('9');
DisplayInstructsInt; %% Need to write instructions

%start run loop for start of scan

p = Run_Loop(filename, win, p);


DrawCenteredNum('Thank You', win, color, 2);
    
%save results
save(filename, 'p')
ListenChar(1);
ShowCursor;
%Show characters on matlab screen again
close all;
sca    
    
    
    
    