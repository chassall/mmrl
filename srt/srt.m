% SRT
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
    whichResponseCodes = [1 16]; % For left, right button 
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
    filename = strcat('srt_', rundate, '_', p_number, '.txt');
    mfilename = strcat('srt_', rundate, '_', p_number, '.mat');
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('srt_', rundate, '_', p_number, '.txt');
        mfilename = strcat('srt_', rundate, '_', p_number, '.mat');
        checker1 = ~exist(filename,'file');
        checker2 = isnumeric(str2double(p_number)) && ~isnan(str2double(p_number));
        if checker1 && checker2
            break;
        else
            disp('Invalid number, or filename already exists.');
            WaitSecs(1);
        end
    end
    age = input('Age: ');
    handedness = input('Handedness (L/R): ','s');
end

% Store this participant's info in participant_info.txt
run_line = [num2str(p_number) ', ' datestr(now) ', ' handedness ', ' num2str(age) ', ' inputDevice];
dlmwrite('srtparticipants.txt',run_line,'delimiter','', '-append');

ListenChar(0);

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
fixationCharacter = '+';
warningText = '|||';
stimSize = 96; % Size for stimuli (warning + fixation)
stimColour = [255 255 255];
textSize = 32; % Size for instructions and block messages

% Blocks, trials, trial types
nBlocks = 5; % Number of blocks
trialsPerBlock = 10; % Trials per block
blockISIs = [2500 1500 1500 500 2000 2000 2500 500 1000 1000];
isiOrder = [];
for i = 1:nBlocks
    isiOrder = [isiOrder; Shuffle(blockISIs)];
end

% Instructions
instructions{1} = 'In this task, a warning stimulus (|||) will be presented followed by a target stimulus (+).\n\nUsing the index finger of your preferred hand,\npress the far left key AS QUICKLY AS POSSIBLE\nwhen the target stimulus (+) appears on the screen.\n\nReturn your finger to the STARTING DOT immediately after responding.\n\nPress the SPACEBAR on the keyboard to begin with a few PRACTICE TRIALS.';

% Instruction images
srtInst1 = imread('SRTinst1.bmp');
srtInst2 = imread('SRTinst2.bmp');

%% Experiment
try

    if windowed
        Screen('Preference', 'SkipSyncTests', 1);
        [win, rec] = Screen('OpenWindow', 0, bgColour,displayRect, 32, 2);
    else
        % Screen('Preference', 'SkipSyncTests', 1);
        [win, rec] = Screen('OpenWindow', 0, bgColour);
    end
    ListenChar(0);
    HideCursor();
    horRes = rec(3);
    verRes = rec(4);
    xmid = round(rec(3)/2);
    ymid = round(rec(4)/2);
    
    % Prepare images
    srtInst1Texture = Screen('MakeTexture', win, srtInst1);
    srtInst2Texture = Screen('MakeTexture', win, srtInst2);
    
    % Display instructions
    for i = 1:length(instructions)
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,[instructions{i}],'center','center',textColour);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
    end
    
    Screen('DrawTexture', win, srtInst1Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('DrawTexture', win, srtInst2Texture);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    Screen('Flip',win);
    WaitSecs(3);
    
    % To be saved to disk
    participantData = [];
    
    % Practice trials
    practiceISIs = [2500 2500 500 1500 1000];
    for p = 1:length(practiceISIs)
        
        thisISI = practiceISIs(p);
        
        Screen('Flip',win);
        WaitSecs(1.3);
        
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,warningText,'center','center',stimColour);
        Screen('Flip',win);
        WaitSecs(1);
        
        Screen('Flip',win);
        WaitSecs(thisISI/1000);
        
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,fixationCharacter,'center','center',stimColour);
        Screen('Flip',win);
        
        % Check for escape key
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyCode(ExitKey)
            ME = MException('ct:escapekeypressed','Exiting script');
            throw(ME);
        end
        
        WaitSecs(3);
    end
    
    Screen('TextSize',win,textSize);
    DrawFormattedText(win,'End of practice trials.\n\nDuring the experiment, there are 5 blocks of trials, which are separated by rest periods.\n\nPress the SPACEBAR on the keyboard when you are ready to begin.','center','center',textColour);
    Screen('Flip',win);
    KbReleaseWait(-1);
    KbPressWait(-1);
    
    % Block/trial loop
    for blockNum = 1:nBlocks
        
        for trialNum = 1:trialsPerBlock
            
            
            thisISI = isiOrder(blockNum,trialNum);
            
            Screen('Flip',win);
            WaitSecs(1.3);
            
            Screen('TextSize',win,stimSize);
            DrawFormattedText(win,warningText,'center','center',stimColour);
            Screen('Flip',win);
            WaitSecs(1);
            
            Screen('Flip',win);
            WaitSecs(thisISI/1000);
            
            % Clear event buffer if using the response box
            if useResponseBox
                evt = CMUBox('GetEvent', handle);
                while ~isempty(evt)
                    evt = CMUBox('GetEvent', handle);
                end
            end
            
            Screen('TextSize',win,stimSize);
            DrawFormattedText(win,fixationCharacter,'center','center',stimColour);
            Screen('Flip',win);
            
            startTime = GetSecs();
            pressDelta = -1;
            madeResponse = 0;
            while GetSecs - startTime < 3
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
                        pressDelta = pressTime - startTime;
                    end
                    
                end
            end
            
            thisLine = [blockNum trialNum thisISI madeResponse pressDelta];
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