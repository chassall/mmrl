% MSIT
% C. Hassall
% January, 2019
%
% Outstanding issues:
% Rest breaks
% Font size

%% Standard pre-script code
close all; clear all; clc; % Clear everything
rng('shuffle'); % Shuffle the random number generator
tic;

%% Run flags
justTesting = 0;
windowed = 0;

%% Define control keys
KbName('UnifyKeyNames');
ExitKey = KbName('ESCAPE');
ProceedKey = KbName('p');
left_kb_key	= KbName('f');
right_kb_key = KbName('j');
oneKey = KbName('1');
twoKey = KbName('2');
threeKey = KbName('3');

%% Response box
try
    disp('Attempting to connect to response box...');
    handle = CMUBox('Open', 'pst', 'COM4', 'ftdi','norelease');
    disp('Success!');
    WaitSecs(1);
    useResponseBox = 1;
    inputDevice = 'srb';
    whichResponseCodes = [1 2 4]; % Buttons 1,2,3
catch e
    disp('Connection failed. Press p to proceed with keyboard input (1-key,2-key,3-key), or press escape to quit.');
    useResponseBox = 0;
    inputDevice = 'kb';
    
    % Check for escape key
    KbReleaseWait(-1);
    [~, keyCode, ~] = KbPressWait(-1);
    while ~keyCode(ExitKey) && ~keyCode(ProceedKey)
        [~, keyCode, ~] = KbPressWait(-1);
    end
    if keyCode(ExitKey)
        disp('Goodbye');
        return;
    end
end

%% Display Settings
if windowed
    displayRect = [0 0 800 600]; % Testing window
else
    displayRect = [];
end

%% Participant info and data
participantData = [];
if justTesting
    p_number = '99';
    rundate = datestr(now, 'yyyymmdd-HHMMSS');
    filename = strcat('msit_', rundate, '_', p_number, '.txt');
    sex = 'FM';
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('msit_', rundate, '_', p_number, '.txt');
        checker1 = ~exist(filename,'file');
        checker2 = isnumeric(str2double(p_number)) && ~isnan(str2double(p_number));
        if checker1 && checker2
            break;
        else
            disp('Invalid number, or filename already exists.');
            WaitSecs(1);
        end
    end
    sex = input('Sex (M/F): ','s');
    age = input('Age: ');
    handedness = input('Handedness (L/R): ','s');
end

% Store this participant's info in participant_info.txt
run_line = [num2str(p_number) ', ' datestr(now) ', ' sex ', ' handedness ', ' num2str(age) ', ' inputDevice];
dlmwrite('msitparticipants.txt',run_line,'delimiter','', '-append');

ListenChar(0);

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
fixationSize = 48; % Size for fixation '+'
stimISI = 1.75;
fixationCharacter = '+';
stimSize = 48; % Size for stimuli
stimColour = [255 255 255];
correctResponses = [1 1 2 2]; % 1:left, 2:right
textSize = 24; % Size for instructions and block messages
stimSizeSmall = 18;
stimSizeLarge = 40;

% Blocks, trials, trial types
nBlocks = 8;
trialsPerBlock = 15;
fontSizes = [18 40];
controlStim={'100','020','003'}; % Trials types 1,2,3
controlSize = [2 1 1; 1 2 1; 1 1 2]; % 1 is small font, 2 is big font
controlAnswers = [1 2 3];
controlTypes = [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3];
interferenceStim={'221','212','331','313','112','211','332','233','131','311','232','322','221','212','331','313','112','211','332','233','131','311','232','322'}; % Trial types 1-12
interferencesSize = [1 0 0; 0 1 0; 0 0 1];
interferenceAnswers = [1 1 1 1 2 2 2 2 3 3 3 3 1 1 1 1 2 2 2 2 3 3 3 3];
interferenceTypes = [1:12 1:12];

targets = [1 2 3];
positions = [1 2 3];
distractors = [1 2]; 
sizes = [1 2];
trialTypes = CombVec(targets,positions,distractors,sizes)';
trialOrder = Shuffle(trialTypes);

% Target 1
positions1 = [2 3];
distractors1 = [2 3];
sizes1 = [1 2 1 2 1 2];
trialPool1 = CombVec(positions1,distractors1,sizes1)';
trialPool1 = Shuffle(trialPool1);

% Target 2
positions2 = [1 3];
distractors2 = [1 3];
sizes2 = [1 2 1 2 1 2];
trialPool2 = CombVec(positions2,distractors2,sizes2)';
trialPool2 = Shuffle(trialPool2);

% Target 3
positions3 = [2 3];
distractors3 = [2 3];
sizes3 = [1 2 1 2 1 2];
trialPool3 = CombVec(positions3,distractors3,sizes3)';
trialPool3 = Shuffle(trialPool3);

actualTrials = [];
oneIndex = 1;
twoIndex = 1;
threeIndex = 1;
targets = [1 1 1 1 1 2 2 2 2 2 3 3 3 3 3];
if mod(str2double(p_number),2)
    blockType = [1 2 1 2 1 2 1 2]; % 1 = control, 2 = interference, set order
else
    blockType = [2 1 2 1 2 1 2 1];
end

for b = 1:nBlocks
    switch blockType(b)
        case 1
            thisTargetOrder = Shuffle(targets);
            for t = 1:trialsPerBlock
                switch thisTargetOrder(t)
                    case 1
                        actualTrials(b,t,:) = [1 1 0 2]; % Target, Position, Distractor, Size
                    case 2
                        actualTrials(b,t,:) = [2 2 0 2];
                    case 3
                        actualTrials(b,t,:) = [3 3 0 2];
                end
            end
        case 2
            thisTargetOrder = Shuffle(targets);
            for t = 1:trialsPerBlock
                switch thisTargetOrder(t)
                    case 1
                        actualTrials(b,t,:) = [1 trialPool1(oneIndex,:)];
                        oneIndex = oneIndex + 1;
                    case 2
                        actualTrials(b,t,:) = [2 trialPool2(twoIndex,:)];
                        twoIndex = twoIndex + 1;
                    case 3
                        actualTrials(b,t,:) = [1 trialPool1(threeIndex,:)];
                        threeIndex = threeIndex + 1;
                end
            end 
    end
end

trialTypes = [];
for b = 1:nBlocks
    switch blockType(b)
        case 1
            trialTypes(b,:) = Shuffle(controlTypes);
        case 2
            trialTypes(b,:) = Shuffle(interferenceTypes);
    end
end

% Instructions
instructions{1} = 'In the following task, three numbers will be presented on the display.\n\nFor each set of numbers, one number will always differ from the other two.\n\nPress the SPACE bar to continue...';
instructions{2} = 'Your goal is to press the key on the response box that corresponds to the number that differs.\n\nConsider the following examples...\n\nPress the SPACE bar to continue...';

slide1 = imread('Slide1.bmp');
slide2 = imread('Slide2.bmp');

%% Experiment
try
    
    if windowed
        Screen('Preference', 'SkipSyncTests', 1);
        [win, rec] = Screen('OpenWindow', 0, bgColour,displayRect, 32, 2);
    else
        [win, rec] = Screen('OpenWindow', 0, bgColour);
    end
    ListenChar(0);
    HideCursor();
    horRes = rec(3);
    verRes = rec(4);
    xmid = round(rec(3)/2);
    ymid = round(rec(4)/2);
    digitXPositions = [xmid - stimSizeLarge xmid xmid + stimSizeLarge];

    % Prepare images
    slide1Texture = Screen('MakeTexture', win, slide1);
    slide2Texture = Screen('MakeTexture', win, slide2);
    
    % Display instructions
    for i = 1:length(instructions)
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,[instructions{i}],'center','center',[255 255 255]);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
    end
    Screen('Flip',win);
    
    Screen('DrawTexture', win, slide1Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, slide2Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    WaitSecs(3);
    
    % To be saved to disk
    participantData = [];
    
    % Block/trial loop
    for blockNum = 1:nBlocks
        
         thisBlockType = blockType(blockNum);
        
        for trialNum = 1:trialsPerBlock
            
            thisTarget = actualTrials(blockNum,trialNum,1); 
            thisTargetPosition = actualTrials(blockNum,trialNum,2); 
            thisDistractor = actualTrials(blockNum,trialNum,3);
            thisTargetSize = actualTrials(blockNum,trialNum,4);
            thisTrialDigits = [];
            thisTrialDigits(1:3) = thisDistractor;
            thisTrialDigits(thisTargetPosition) = thisTarget;
            thisCorrectResponse = thisTarget;
            
            Screen(win,'TextFont','Arial'); % ??
            switch thisTargetSize
                % Small target, large distractors
                case 1
                    for d = 1:3
                        if d == thisTargetPosition
                            Screen('TextSize',win, stimSizeSmall);
                            yOffset = stimSizeSmall/2;
                            xOffset = stimSizeSmall/2;
                        else
                            Screen('TextSize',win, stimSizeLarge);
                            yOffset = stimSizeLarge/2;
                            xOffset = stimSizeLarge/2;
                        end
                        Screen('DrawText', win, num2str(thisTrialDigits(d)), digitXPositions(d)-xOffset, ymid-yOffset, stimColour);
                    end
                % Large target, small distractors
                case 2
                    for d = 1:3
                        if d == thisTargetPosition
                            Screen('TextSize',win, stimSizeLarge);
                            yOffset = stimSizeLarge/2;
                            xOffset = stimSizeLarge/2;
                        else
                            Screen('TextSize',win, stimSizeSmall);
                            yOffset = stimSizeSmall/2;
                            xOffset = stimSizeSmall/2;
                        end
                        Screen('DrawText', win, num2str(thisTrialDigits(d)), digitXPositions(d)-xOffset, ymid-yOffset, stimColour);
                    end 
            end
            Screen('Flip',win);
            
            % Clear event buffer if using the response box
            if useResponseBox
                evt = CMUBox('GetEvent', handle);
                while ~isempty(evt)
                    evt = CMUBox('GetEvent', handle);
                end
            end
            
            % Get response
            madeResponse = 0;
            responseCode = -1; % Invalid response
            responseCorrect = -1; % Invalid response
            responseTime = -1;
            startTime = GetSecs();
            while GetSecs() - startTime < 1.75 %% ISI??
                
                if ~madeResponse
                    
                    if useResponseBox
                        evt = CMUBox('GetEvent', handle);
                        if ~isempty(evt) && evt.state
                            madeResponse = 1;
                            pressTime = evt.time;
                            srBoxCode = evt.state;
                        end
                    else
                        [madeResponse, pressTime, keyCode] = KbCheck(-1);
                    end
                    
                    if madeResponse
                        responseTime  = pressTime - startTime;
                        
                        if useResponseBox
                            if  srBoxCode == whichResponseCodes(1)
                                responseCode = 1;
                            elseif srBoxCode == whichResponseCodes(2)
                                responseCode = 2;
                            elseif srBoxCode == whichResponseCodes(3)
                                responseCode = 3;
                            end
                        else
                            if  keyCode(oneKey)
                                responseCode = 1;
                            elseif keyCode(twoKey)
                                responseCode = 2;
                            elseif keyCode(threeKey)
                                responseCode = 3;
                            end
                            
                        end
                        
                        if  responseCode == 1
                            if thisCorrectResponse == 1
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        elseif responseCode == 2
                            if thisCorrectResponse == 2
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        elseif responseCode == 3
                            if thisCorrectResponse == 3
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        end
                        Screen('Flip',win); % Blank screen
                    end
                end
            end
            
            Screen('Flip',win); % Blank screen
            WaitSecs(0.25); % 250 ms between trials
            
            thisLine = [blockNum trialNum thisBlockType thisTarget thisTargetPosition thisDistractor thisTargetSize madeResponse responseCode responseTime responseCorrect];
            dlmwrite(filename,thisLine,'delimiter', '\t', '-append');
            participantData = [participantData; thisLine];
            
            % Check for escape key
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyCode(ExitKey)
                ME = MException('ct:escapekeypressed','Exiting script');
                throw(ME);
            end
        end

        % Rest break
        if blockNum < nBlocks
            Screen('TextSize',win,textSize);
            DrawFormattedText(win,'please take as long of a break as needed\n\npress any key when you are ready to continue','center','center',[255 255 255]);
            Screen('Flip',win);
            KbReleaseWait(-1);
            KbPressWait(-1);
        end
        
    end
    
    % End of Experiment
    Screen(win,'TextFont','Arial');
    Screen(win,'TextSize',textSize);
    DrawFormattedText(win,'end of experiment - thank you','center','center',textColour);
    Screen('Flip',win);
    WaitSecs(2);
    
    % Close the Psychtoolbox window and bring back the cursor and keyboard
    Screen('CloseAll');
    ListenChar();
    
    % Close response box
    if useResponseBox
        CMUBox('Close', handle);
    end
    
    experimentTime = toc;
    disp(experimentTime);
catch e
    
    % Close the Psychtoolbox window and bring back the cursor and keyboard
    Screen('CloseAll');
    ListenChar();
    
    % Close response box
    if useResponseBox
        CMUBox('Close', handle);
    end
    
    rethrow(e);
end
