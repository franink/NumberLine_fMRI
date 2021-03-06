%Code for IEM experiment to map spatial attention.
%Based on Tommy Sprague's ap2dAttn_flicker4.m
% Tanks to Xiangrui Li for the codes for WaitTill and ReadKey.

% - attend checkerboards, detect contrast dimming on some trials

%make sure no Java problems
%Screen('Preference','SkipSyncTests',1); %comment out for scanner
PsychJavaTrouble;
rng shuffle;

% In case previous subject was not cleared
clear Instruct;


%Filename to save data
filename = getFilename();

p.eyetrack = input('eyetracker? (0, 1)  ');

%% eyetracker filename
% Added a dialog box to set your own EDF file name before opening 
% experiment graphics. Make sure the entered EDF file name is 1 to 8 
% characters in length and only numbers or letters are allowed.
if p.eyetrack
    if IsOctave
        edfFile = 'DEMO';
    else

    prompt = {'Enter tracker EDF file name (1 to 8 letters or numbers)'};
    dlg_title = 'Create EDF file';
    num_lines= 1;
    def     = {'DEMO'};
    answer  = inputdlg(prompt,dlg_title,num_lines,def);
    %edfFile= 'DEMO.EDF'
    edfFile = answer{1};
    fprintf('EDFFile: %s\n', edfFile );
    end
end
%% End of eyetracker code
%Setup experiment parameters

p.ramp_up = 16; %MUX2 with TR 2sec requires 16secs (8TRs) of rampup

p.stim_t = 4;
p.runs = 4; %This number has to be decided
p.nLocArm = 3;
p.nLoc = p.nLocArm * 4 + 1; %'+' horizontal-vertical meridian each arm has 3 plus center
p.ntasks = 1;
p.percentnull = 0.4; 
p.tasks = {'attend stim'}; 
p.flickerFreq   = 6; % Hz
p.flickerPer  = 1/p.flickerFreq; % s
p.stimContrastChange = 0.5; %prob of trials with contrast change
p.contrastChangeWindow = [0.5 p.stim_t-0.75]; % period over which contrast can change
p.minTargFrame = p.contrastChangeWindow(1)*p.flickerFreq + 1; % these are period index (which period can we start target?)
p.maxTargFrame = p.contrastChangeWindow(2)*p.flickerFreq + 1; % +1 is because want cycle *starting at* this point in time
p.minTargSep = 1; % number of periods
p.nTargs = 1;
p.responseWindow = 1.0;
p.repetitions = 2;
p.TrialSet = p.nLoc + round(p.percentnull*p.nLoc);
p.nNull = round(p.repetitions * p.nLoc * p.percentnull);
p.nTrials = p.repetitions * (p.TrialSet);
%p.ITI_Jits = [3.5:0.5:7 repmat(3:0.5:4.5,1,2)];
p.ITI_Min = 1.5;
p.ITI_Max = 4.5;
p.mean_ITI = 3;
p.trialSecs = p.stim_t + p.mean_ITI;
p.runDur = (p.nTrials * p.trialSecs) + p.ramp_up;
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
%p.vDistCM = 120; %desktop
%.screenWidthCM = 40; % desktop
p.usedScreenSizeDeg = 12;

%stimulus geometry (in degrees, note that these vars have the phrase 'Deg'
%in them, used by pix2deg below)
p.radDeg = p.usedScreenSizeDeg/(p.nLocArm*2+2); %edge of stim touches borders of screen
p.sfDeg = .6785; %TS parameter value, might need to be changed

p.backColor     = [128, 128, 128];      % background color

%fixation point properties
p.fixColor      = [250, 1, 1];%[155, 155, 155];
% p.fixSizeDeg    = .25 * .4523;                  % size of dot
p.fixSizeDeg    = .1131;
p.appSizeDeg    = p.fixSizeDeg * 4;     % size of apperture surrounding dot

% font stuff
p.fontSize = 40;    
p.fontName = 'HELVETICA';   
p.textColor = [255, 255, 255];


% --------------------Screen properties----------------------------%

p.LUT = 0:255;
% correct all the colors
p.fixColor = p.LUT(p.fixColor)';
p.textColor = p.LUT(p.textColor)';


% Open a PTB Window on our screen
try
    screenid = max(Screen('Screens')); %Originally it was max instead of min changed it for testing purposes (max corresponds to secondary display)
    
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
p.center = [(p.sRect(3) - p.sRect(1))/2, (p.sRect(4) - p.sRect(2))/2];

Screen('TextSize', win, p.fontSize);
Screen('TextStyle', win, 1);
Screen('TextFont',win, p.fontName);
Screen('TextColor', win, p.textColor);


% start a block loop. I will probably send this loops to a different file
% like I did in my previous experiments (this laso just mught be the
% creation of run stimuli sequences, if so then leave here but translate to
% my style

armNeg = linspace(-p.nLocArm, -1, p.nLocArm);
armPos = linspace(1, p.nLocArm, p.nLocArm);

p.StimOnset = zeros(p.nTrials,p.runs);
p.StimEnd = zeros(p.nTrials,p.runs);
p.ITI_Onset = zeros(p.nTrials,p.runs);
p.Condition = zeros(p.nTrials,p.runs); %order left-right;up-down;center;null

% prepare run before start of scan

%allocate some arrays for storing the subject response
    p.hits =        0;
    p.misses =      0;
    p.falseAlarms = 0;
    p.correctRejections = 0; % sum of these by end of expt = p.nTrials
    p.rt =          zeros(p.nTrials, p.runs);       % store the rt on each trial (from target onset in seconds)
    p.resp =        zeros(p.nTrials, p.runs);     % store the response
    p.respTime =    zeros(p.nTrials, p.runs); %from stim onset in seconds
    p.respFrame =   zeros(p.nTrials, p.runs); %from stim onset in frames
    p.ITI_Onset = nan(p.nTrials,p.runs);
    p.StimOnset = nan(p.nTrials,p.runs);
    p.StimEnd =  nan(p.nTrials,p.runs);
    p.stim_StartReal = zeros(p.nTrials, p.runs);
    p.stim_EndReal = zeros(p.nTrials, p.runs);
    p.targOnTimeReal = zeros(p.nTrials, p.runs);
    p.hit =        zeros(p.nTrials, p.runs);
    p.miss =      zeros(p.nTrials, p.runs);
    p.falseAlarm = zeros(p.nTrials, p.runs);
    p.correctRejection = zeros(p.nTrials, p.runs);
    
    
for r= 1:p.runs
    % Need to distinguish here from runs and repettions.
    % I should probably shuffle independently for each repetition but then
    % combine all results and files in a format the is separate only for
    % runs and not repettions
    tmpx = [armNeg armPos];
    tmpy = zeros(1, length(tmpx));
    tmpx = [tmpx, zeros(1,length(tmpy)) 0]';
    tmpy = [tmpy, armNeg armPos 0]';
    stimLocsX = zeros(p.nLoc,p.repetitions);
    stimLocsX = zeros(p.nLoc,p.repetitions);
    dimstim = zeros(p.nLoc,p.repetitions);
    for rep = 1:p.repetitions
        stimLocsX(1:p.nLoc,rep) = tmpx;
        stimLocsY(1:p.nLoc,rep) = tmpy;
%         stimLocsX(rep,:) = [armNeg armPos];
%         stimLocsY(rep,:) = zeros(1, length(stimLocsX));
%         stimLocsX(rep,:) = [stimLocsX(rep,:) zeros(1,length(stimLocsY)) 0]';
%         stimLocsY(rep,:) = [stimLocsY(rep,:) armNeg armPos 0]';
        dimstim(1:ceil(p.nLoc/2),rep) = ones;
        dimStimOnes = ceil(p.nLoc/2);
        %dimstim(:,rep) = Shuffle([ones(dimStimOnes,1); zeros(p.TrialSet-dimStimOnes,1)]); %If odd number of locations more dimcontrasts (ceil(dimcontrasts))
        condition(1:p.nLoc,rep) = 1:p.nLoc; %order left-right;up-down;center;
    
        % mark null trials
        stimLocsX(p.nLoc+1:p.TrialSet,rep) = NaN;
        stimLocsY(p.nLoc+1:p.TrialSet,rep) = NaN;
        null = zeros(p.TrialSet,p.repetitions,1); null(isnan(stimLocsX)) = 1;
        dimstim(end+1:p.TrialSet,rep) = 0;
        condition(p.nLoc+1:p.TrialSet,rep) = p.nLoc + 1; %order left-right;up-down;center;
        
    
        % shuffle trial order
        
        % the following code is a potential fix for preventing
        % consecutive null trials
        move_on = 0;
        while move_on == 0
            move_on = 1;
            rndInd(:,rep) = randperm(p.TrialSet);
            stimLocsX(:,rep) = stimLocsX(rndInd(:,rep),rep);
            stimLocsY(:,rep) = stimLocsY(rndInd(:,rep),rep);
            null(:,rep) = null(rndInd(:,rep),rep);
            rep_test = null(1:end-1,rep) + null(2:end,rep);
            dimstim(:,rep) = dimstim(rndInd(:,rep),rep);
            condition(:,rep) = condition(rndInd(:,rep),rep);
            % if any item in rep_test >= 2 then move_on =0
            if sum(rep_test >= 2) >= 1
              move_on = 0
            end
        end
        


%         rndInd(:,rep) = randperm(p.TrialSet);
%         stimLocsX(:,rep) = stimLocsX(rndInd(:,rep),rep);
%         stimLocsY(:,rep) = stimLocsY(rndInd(:,rep),rep);
%         null(:,rep) = null(rndInd(:,rep),rep);
%         dimstim(:,rep) = dimstim(rndInd(:,rep),rep);
%         condition(:,rep) = condition(rndInd(:,rep),rep);
    end
    
    %Then combine all repetitioms in one line for each block
    p.rndInd(:,r) = rndInd(:);
    
    p.stimLocsX(:,r) = stimLocsX(:);
    
    p.stimLocsY(:,r) = stimLocsY(:);
    
    p.null(:,r) = null(:);
    
    p.dimStim(:,r) = dimstim(:);
    
    p.Conditon(:,r) = condition(:); 
    
        
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
    
    %Generate timing for each trial in absolute time...
    end_ramp_up = p.ramp_up;
    current_time = end_ramp_up;
    p.ITI_JITS(:,r) = datasample(ITI_Jits, p.nTrials, 'Replace', false);
    for ii = 1:p.nTrials
        p.ITI_Onset(ii,r) = current_time;
        current_time = current_time + p.ITI_JITS(ii,r);
        p.StimOnset(ii,r) = current_time;
        current_time = current_time + p.stim_t;
        p.StimEnd(ii,r) = current_time;
    end
       
end

% generate checkerboards we use...
p.stimContrast = 1;
p.targetContrast = p.stimContrast - p.stimContrastChange;
c = make_checkerboard(p.radPix,p.sfPix,p.stimContrast);
%c{1}
stim(1)=Screen('MakeTexture', win, c{1});
stim(2)=Screen('MakeTexture', win, 127*ones(size(c{2})));
stim(3)=Screen('MakeTexture', win, c{2});
%stim(3)
T = make_checkerboard(p.radPix,p.sfPix,p.targetContrast);
%T{1}
dimStim(1)=Screen('MakeTexture', win, T{1});
dimStim(2)=stim(2);
dimStim(3)=Screen('MakeTexture', win, T{2});
%dimStim(3)
        
p.targX = p.minTargFrame:p.minTargSep:p.maxTargFrame;   % this will be used to select when to show target(s)

p.flickerSequ = repmat([ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2)) 3*ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2))],1,(0.5)*round(p.stimExpose/p.flickerFrames));
p.stimDimSequ = zeros(p.nTrials, p.runs, size(p.flickerSequ,2));
    for r= 1:p.runs
        % generate a distribution for choosing the target time
        for ii=1:p.nTrials
            tmp = randperm(length(p.targX));
            %p.targFrame(ii,:) = sort(p.targX(tmp(1:p.nTargs)))*(p.flickerFreq*2)-(p.flickerFreq*2)+1;
            p.targFrame(ii,r) = sort(p.targX(tmp(1:p.nTargs)))*(p.flickerFrames) - p.flickerFrames+1;
            p.targOnTime(ii,r) = p.targFrame(ii,r).*(1/p.refreshRate);
            p.targMaxRespTime(ii,r) = (p.targFrame(ii,r).*(1/p.refreshRate))+p.responseWindow;
        end
        
        
        % pick the stimulus sequence for every trial (the exact grating to be shown)
        
        for i=1:p.nTrials
            p.flickerSequ = repmat([ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2))],1,round(p.stimExpose/p.flickerFrames));
            p.stimSequ(i,r,:)=p.flickerSequ;
            %p.flickerSequ = repmat([ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2)) 3*ones(1,round(p.flickerFrames/2)) 2*ones(1,round(p.flickerFrames/2))],1,(0.5)*round(p.stimExpose/p.flickerFrames));
            % mark the tarket spots with low contrast stims
            p.stimDimSequ(i,r,p.targFrame(i,r):p.targFrame(i,r)+2*p.flickerFrames-1) = 1;
            %p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+2*p.flickerFrames-1)=p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+2*p.flickerFrames-1)+2;
            % +2 above --> change to "target"
        end
        
        %When null trial, remove target information
        for t=1:p.nTrials
            if p.null(t,r) == 1 || p.dimStim(t,r) == 0
                p.targFrame(t,r) = NaN;
                p.targOnTime(t,r) = NaN;
                p.targMaxRespTime(t,r) = NaN;
            end
        end
    end
%% Start of eyetracker code (uncomment when using eyetracker)

    if p.eyetrack
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        el=EyelinkInitDefaults(window);

        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(dummymode)
            fprintf('Eyelink Init aborted.\n');
            cleanup;  % cleanup function
            return;
        end

        % the following code is used to check the version of the eye tracker
        % and version of the host software

        [v vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );

        % open file to record data to
        i = Eyelink('Openfile', edfFile);
        if i~=0
            fprintf('Cannot create EDF file ''%s'' ', edffilename);
            Eyelink( 'Shutdown');
            Screen('CloseAll');
            return;
        end

        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox''');
        width = p.sRect(3) - p.sRect(1);
        height = p.sRect(4) - p.sRect(2);

        % SET UP TRACKER CONFIGURATION
        % Setting the proper recording resolution, proper calibration type, 
        % as well as the data file content;
        Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);                
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');
        % set parser (conservative saccade thresholds)

        % set EDF file contents using the file_sample_data and
        % file-event_filter commands
        % set link data thtough link_sample_data and link_event_filter
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');

        % check the software version
        % add "HTARGET" to record possible target data for EyeLink Remote
        if sscanf(vs(12:end),'%f') >=4
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,HTARGET,GAZERES,STATUS,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
        else
            Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
            Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
        end

        % allow to use the big button on the eyelink gamepad to accept the 
        % calibration/drift correction target
        Eyelink('command', 'button_function 5 "accept_target_fixation"');


        % make sure we're still connected.
        if Eyelink('IsConnected')~=1 && dummymode == 0
            fprintf('not connected, clean up\n');
            Eyelink( 'Shutdown');
            Screen('CloseAll');
            return;
        end

        % Calibrate the eye tracker
        % setup the proper calibration foreground and background colors
        el.backgroundcolour = [128 128 128];
        el.calibrationtargetcolour = [0 0 0];

        % parameters are in frequency, volume, and duration
        % set the second value in each line to 0 to turn off the sound
        el.cal_target_beep=[600 0 0.05];
        el.drift_correction_target_beep=[600 0 0.05];
        el.calibration_failed_beep=[400 0 0.25];
        el.calibration_success_beep=[800 0 0.25];
        el.drift_correction_failed_beep=[400 0 0.25];
        el.drift_correction_success_beep=[800 0 0.25];
        % you must call this function to apply the changes from above
        EyelinkUpdateDefaults(el);

        % Hide the mouse cursor;
        Screen('HideCursorHelper', window);
        EyelinkDoTrackerSetup(el); %puts host and display pc's camera setup mode
    end
    
%% End of eyetracking section



% Start of experiment
%Introductory instructions
DrawCenteredNum('Welcome', win, p, 0.5);
WaitTill('0');
DisplayInstructsInt; %% Need to write instructions

%start run loop for start of scan

p = Run_Loop(filename, win, p, stim, dimStim);

if p.eyetrack
    % End of Experiment; close the file first   
    % close graphics window, close data file and shut down tracker
        
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    Eyelink('CloseFile');
    
    % download data file
    try
        fprintf('Receiving data file ''%s''\n', edfFile );
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFile, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFile );
    end
    Eyelink('ShutDown');
end
    
    
    
DrawCenteredNum('Thank You', win, p, 2);
    
%save results
save(filename, 'p')
ListenChar(1);
ShowCursor;
%Show characters on matlab screen again
close all;
sca    
    
    
    
    