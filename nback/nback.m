% N-Back
% C. Hassall
% January, 2019

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

%% Response box 
try
    disp('Attempting to connect to response box...');
    handle = CMUBox('Open', 'pst', 'COM4', 'ftdi','norelease'); 
    disp('Success!');
    WaitSecs(1);
    useResponseBox = 1;
    inputDevice = 'srb';
    whichResponseCodes = [2 4]; % For left, right button (buttons 2,3 for N-Back)
catch e
    disp('Connection failed. Press p to proceed with keyboard input (f-key, j-key), or press escape to quit.');
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
    filename = strcat('nback_', rundate, '_', p_number, '.txt');
    mfilename = strcat('nback_', rundate, '_', p_number, '.mat');
    sex = 'FM';
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('nback_', rundate, '_', p_number, '.txt');
        mfilename = strcat('nback_', rundate, '_', p_number, '.mat');
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
dlmwrite('nbackparticipants.txt',run_line,'delimiter','', '-append');

ListenChar(0);

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
stimSize = 48; % Size for stimuli (warning + fixation)
stimColour = [255 255 255];
textSize = 24; % Size for instructions and block messages
e = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

% Blocks, trials, trial types
nBlocks = 14; % Number of blocks
trialsPerBlock = 10; % Trials per block
blockTypes = [2 3 2 3 2 3 2 3 2 3 2 3 2 3];

% Generate practice trials
b = false(1,10); 
whichOnes = randperm(9,4)+1; % Pick 4 (but not the first)
b(whichOnes) = true;
practiceTrials = nan(1,10);
practiceTrials(~b) =  e(randi(25,1,sum(~b)));
for bi = find(b)
    practiceTrials(bi) = practiceTrials(bi-1);
end

% Instructions
instructions{1} = 'N-BACK TASK\n\nIndividual letters will appear in the center of the screen, with new letters appearing every 2 seconds.\n\nYou must decide whether the CURRENT letter is IDENTICAL to the letter presented N TRIALS EARLIER.\n\nFor example...';

% Instruction images
slide1 = imread('Slide1.bmp');
slide2 = imread('Slide2.bmp');
slide3 = imread('Slide3.bmp');
slide4 = imread('Slide4.bmp');
slide5 = imread('Slide5.bmp');

onebackInst = imread('1Back.bmp');
twobackInst = imread('2Back.bmp');
threebackInst = imread('3Back.bmp');
nbackInst = imread('NBack.bmp');

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
    
    % Prepare images
    slide1Texture = Screen('MakeTexture', win, slide1);
    slide2Texture = Screen('MakeTexture', win, slide2);
    slide3Texture = Screen('MakeTexture', win, slide3);
    slide4Texture = Screen('MakeTexture', win, slide4);
    slide5Texture = Screen('MakeTexture', win, slide5);

    onebackInstTexture = Screen('MakeTexture', win, onebackInst);
    twobackInstTexture = Screen('MakeTexture', win, twobackInst);
    threebackInstTexture = Screen('MakeTexture', win, threebackInst);
    nbackInstTexture = Screen('MakeTexture', win, nbackInst);
    
    % Display instructions
    for i = 1:length(instructions)
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,[instructions{i}],'center','center',textColour);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
    end
    
    Screen('DrawTexture', win, slide1Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, slide2Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, slide3Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, slide4Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, slide5Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('TextSize',win,textSize);
    DrawFormattedText(win,'N-BACK TASK\n\nUsing the RESPONSE BOX, please indicate whether the CURRENT letter is IDENTICAL to the letter presented N-TRIALS BACK.\n\nYou must provide your response PRIOR to the presentation of the next letter.','center','center',textColour);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, nbackInstTexture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('TextSize',win,textSize);
    DrawFormattedText(win,'N-BACK TASK\n\nPlease press the SPACEBAR on the keyboard to begin with a few PRACTICE TRIALS.','center','center',textColour);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    % To be saved to disk
    participantData = [];
    
    % Practice trials
    Screen('TextSize',win,textSize);
    DrawFormattedText(win,'Get ready to begin','center','center',textColour);
    Screen('Flip',win);
    WaitSecs(2);
    
%     Screen('DrawTexture', win, onebackInstTexture);
%     Screen('Flip',win);
%     WaitSecs(10);
    
    for pt = 1:10
        
        % Clear event buffer if using the response box
        if useResponseBox
            evt = CMUBox('GetEvent', handle);
            while ~isempty(evt)
                evt = CMUBox('GetEvent', handle);
            end
        end
        
        thisStimulus = practiceTrials(pt);
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,thisStimulus,'center','center',stimColour);
        Screen('Flip',win);
        
        startTime = GetSecs();
        responseTime = -1;
        madeResponse = 0;
        while GetSecs - startTime < 1.5
            
            if ~madeResponse
                
                    if useResponseBox
                        evt = CMUBox('GetEvent', handle);
                        if ~isempty(evt) && evt.state
                            madeResponse = 1;
                            pressTime = evt.time;
                            
%                             % Wait for button release (Is this the right
%                             % place??)
%                             evt = CMUBox('GetEvent', handle);
%                             while isempty(evt) || evt.state ~= 0
%                                 evt = CMUBox('GetEvent', handle);
%                             end
                        end
                    else
                        [madeResponse, pressTime, keyCode] = KbCheck(-1);
                    end
                
                if madeResponse
                    responseTime = pressTime - startTime;
                end
            end
        end
        
        Screen('Flip',win);
        WaitSecs(0.5);
    end
    
    
    Screen('TextSize',win,textSize);
    DrawFormattedText(win,'Press the SPACEBAR on the keyboard when you are ready to begin','center','center',textColour);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    
    % Block/trial loop
    for blockNum = 1:nBlocks
        
        thisBlockType = blockTypes(blockNum);
        thisBlockAnswers = nan(1,trialsPerBlock);
        
        switch thisBlockType
            case 2
                % Generate 2-back trials
                b = false(1,10);
                whichOnes = randperm(8,4)+2; % Pick 4 (but not the first two)
                b(whichOnes) = true;
                theseTrials = nan(1,10);
                theseTrials(~b) =  e(randi(25,1,sum(~b)));
                for bi = find(b)
                    theseTrials(bi) = theseTrials(bi-2);
                end
                Screen('DrawTexture', win, twobackInstTexture);
                Screen('Flip',win);
                WaitSecs(10);
            case 3
                % Generate 3-back trials
                b = false(1,10);
                whichOnes = randperm(7,4)+2; % Pick 4 (but not the first three)
                b(whichOnes) = true;
                theseTrials = nan(1,10);
                theseTrials(~b) =  e(randi(25,1,sum(~b)));
                for bi = find(b)
                    theseTrials(bi) = theseTrials(bi-2);
                end
                Screen('DrawTexture', win, threebackInstTexture);
                Screen('Flip',win);
                WaitSecs(10);
        end
        thisBlockAnswers(b) = 1; % 1 = left (yes)
        thisBlockAnswers(~b) = 2; % 2 = right (no)
        
        for trialNum = 1:trialsPerBlock
            
            % Clear event buffer if using the response box
            if useResponseBox
                evt = CMUBox('GetEvent', handle);
                while ~isempty(evt)
                    evt = CMUBox('GetEvent', handle);
                end
            end
            
            thisStimulus = theseTrials(trialNum);
            thisCorrectResponse = thisBlockAnswers(trialNum);
            Screen('TextSize',win,stimSize);
            DrawFormattedText(win,thisStimulus,'center','center',stimColour);
            Screen('Flip',win);
            
            startTime = GetSecs();
            responseTime = -1;
            madeResponse = 0;
            responseCode = -1;
            responseCorrect = -1;
            while GetSecs - startTime < 1.5
                if ~madeResponse
                    
                    
                    if useResponseBox
                        evt = CMUBox('GetEvent', handle);
                        if ~isempty(evt) && evt.state
                            madeResponse = 1;
                            pressTime = evt.time;
                            srBoxCode = evt.state;
                            
%                             % Wait for button release (Is this the right
%                             % place??)
%                             evt = CMUBox('GetEvent', handle);
%                             while isempty(evt) || evt.state ~= 0
%                                 evt = CMUBox('GetEvent', handle);
%                             end
                        end
                    else
                        [madeResponse, pressTime, keyCode] = KbCheck(-1);
                    end
                    
                    
                    if madeResponse
                        responseTime = pressTime - startTime;
                        
                        if useResponseBox
                            if  srBoxCode == whichResponseCodes(1)
                                responseCode = 1;
                            elseif srBoxCode == whichResponseCodes(2)
                                responseCode = 2;
                            end
                        else
                            if  keyCode(left_kb_key)
                                responseCode = 1;
                            elseif keyCode(right_kb_key)
                                responseCode = 2;
                            end
                            
                        end
                        
                        if  responseCode == 1
                            if thisCorrectResponse == 1
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        elseif responseCode == 2
                            if thisCorrectResponse == 0
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        end
                    end
                end
            end
            
            Screen('Flip',win);
            WaitSecs(0.5);
            
            thisLine = [blockNum trialNum thisBlockType thisCorrectResponse madeResponse responseCode responseTime responseCorrect];
            dlmwrite(filename,thisLine,'delimiter', '\t', '-append');
            participantData = [participantData; thisLine]; % Redundant
            
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