% Tap
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
    filename = strcat('tap_', rundate, '_', p_number, '.txt');
    mfilename = strcat('tap_', rundate, '_', p_number, '.mat');
    sex = 'FM';
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('tap_', rundate, '_', p_number, '.txt');
        mfilename = strcat('tap_', rundate, '_', p_number, '.mat');
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
dlmwrite('tapparticipants.txt',run_line,'delimiter','', '-append');

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
goColour = [0 255 0];
stopColour = [255 0 0];
fixationCharacter = '+';
warningText = '|||';
stimSize = 48; % Size for stimuli (warning + fixation)
stimColour = [255 255 255];
textSize = 24; % Size for instructions and block messages

% Blocks, trials, trial types
% Run Time
nBlocks = 6; % Number of blocks (should be a multiple of two)
tapTime = 15; % Time in seconds
blockTypes = [ones(1,nBlocks/2) 2*ones(1,nBlocks/2)]; % 1 = left, 2 = right
blockTypes = shuffle(blockTypes);
conditionStrings = {'left','LEFT'; 'right','RIGHT'};

% Instructions
instructions{1} = 'In this task, we are going to see how fast you can tap.\nYou will use the labelled keys on the response box in front of you.\n\n(press spacebar to continue)';
instructions{2} = 'Place your arm and hand in a comfortable\nposition. Without moving your wrist or arm,\ntap the button as fast as you can with your index finger.\n\nYou will have to let the button come up all the\n way and push it down to click, or\nthe tap will not be registered.\n\nMove the response box to a comfortable position\nfor your dominant hand and try pressing the\nbutton a few times for practice.\n\n(press spacebar to begin experiment)';

try
    
    if windowed
        Screen('Preference', 'SkipSyncTests', 1);
        [win, rec] = Screen('OpenWindow', 0, bgColour,displayRect, 32, 2);
    else
        [win, rec] = Screen('OpenWindow', 0, bgColour);
    end
    ListenChar(0);
    HideCursor();
    Screen(win,'TextFont','Arial');
    horRes = rec(3);
    verRes = rec(4);
    xmid = round(rec(3)/2);
    ymid = round(rec(4)/2);
    
    % Display instructions
    for i = 1:length(instructions)
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,[instructions{i}],'center','center',textColour);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
    end
    
    
    Screen('Flip',win);
    WaitSecs(3);
    
    % To be saved to disk
    participantData = [];
    
    % Block/trial loop
    for blockNum = 1:nBlocks
        
        % Get block type (1 = left, 2 = right)
        thisBlockType = blockTypes(blockNum);

        % Block start message
        Screen(win,'TextSize',textSize);        
        DrawFormattedText(win,['Using the index finger of your ' conditionStrings{thisBlockType,1} ' hand,\ntap the ' conditionStrings{thisBlockType,2} ' key as fast as you can for the next ' num2str(tapTime) ' seconds.\n\nPRESS THE BUTTON AS QUICKLY AS POSSIBLE.\n\n(press spacebar to begin countdown)'],'center','center',textColour);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
        
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,'3','center','center',stimColour);
        Screen('Flip',win);
        WaitSecs(1);
        
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,'2','center','center',stimColour);
        Screen('Flip',win);
        WaitSecs(1);

        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,'1','center','center',stimColour);
        Screen('Flip',win);
        WaitSecs(1);
        
        % Clear event buffer if using the response box
        if useResponseBox
            evt = CMUBox('GetEvent', handle);
            while ~isempty(evt)
                evt = CMUBox('GetEvent', handle);
            end
        end
        
        Screen('TextSize',win,stimSize);
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,'Tap your finger!','center','center',goColour);
        Screen('Flip',win);
       
        startTime = GetSecs();
        trialNum = 1;
        lastPressTime = startTime;
        theseLines = [];
        while GetSecs - startTime < tapTime 
            
            if useResponseBox
                evt = CMUBox('GetEvent', handle);
                
                if ~isempty(evt) && evt.state
                    thisPressTime = evt.time;
                    thisPressDelta = thisPressTime - lastPressTime;
                    
                    if ~((thisPressTime - startTime) > tapTime)
                        theseLines = [theseLines; blockNum trialNum thisPressDelta];
                        lastPressTime = thisPressTime;
                        trialNum = trialNum + 1;
                    end
%                     
%                     % Wait for button release
%                     evt = CMUBox('GetEvent', handle);
%                     while isempty(evt) || evt.state ~= 0
%                         evt = CMUBox('GetEvent', handle);
%                     end
                    
                end
                
            else
                [keyIsDown, thisPressTime, keyCode] = KbCheck(-1);
                if keyIsDown
                    thisPressDelta = thisPressTime - lastPressTime;
                    
                    if ~((thisPressTime - startTime) > tapTime)
                        theseLines = [theseLines; blockNum trialNum thisPressDelta];
                        lastPressTime = thisPressTime;
                        trialNum = trialNum + 1;
                    end
                    
                end
            end
            
        end
        
        Screen('TextSize',win,stimSize);
        DrawFormattedText(win,'Stop!','center','center',stopColour);
        Screen('Flip',win);
        WaitSecs(2.5);
        
        dlmwrite(filename,theseLines,'delimiter', '\t', '-append');
        participantData = [participantData; theseLines];
        
        % Check for escape key
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyCode(ExitKey)
            ME = MException('ct:escapekeypressed','Exiting script');
            throw(ME);
        end
            
        % Rest break
        if blockNum < nBlocks
            Screen('TextSize',win,stimSize);
            DrawFormattedText(win,'rest','center','center',stimColour);
            Screen('Flip',win);
            WaitSecs(5);
        end
        
    end
    
    % End of Experiment
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
    ShowCursor();
    
    % Close response box
    if useResponseBox
        CMUBox('Close', handle);
    end
    
    rethrow(e);
end