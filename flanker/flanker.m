% Flanker
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
    filename = strcat('flanker_', rundate, '_', p_number, '.txt');
    sex = 'FM';
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('flanker_', rundate, '_', p_number, '.txt');
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
dlmwrite('flankerparticipants.txt',run_line,'delimiter','', '-append');

ListenChar(0);

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
fixationSize = 48; % Size for fixation '+'
fixationCharacter = '+';
stimSize = 48; % Size for stimuli
stimStrings = {'< < < < <','> > < > >','> > > > >','< < > < <'};
stimColour = [255 255 255];
correctResponses = [1 1 2 2]; % 1:left, 2:right
textSize = 24; % Size for instructions and block messages

% Blocks, trials, trial types
nBlocks = 3; % Number of blocks
trialsPerBlock = 40; % Trials per block 41??
trialTypes = [ones(1,trialsPerBlock/4) 2*ones(1,trialsPerBlock/4) 3*ones(1,trialsPerBlock/4) 4*ones(1,trialsPerBlock/4)]; % Codes for all four trial types
% Determine each block/trial, randomized within each block
allTrialTypes = [];
for b = 1:nBlocks
    allTrialTypes = [allTrialTypes; Shuffle(trialTypes)];
end

% Instructions
instructions{1} = 'In this task, you will see a row of 5 arrows.\n\nYour task is to pay attention to the MIDDLE arrow, and press the far left button if it is pointing to the left; or press the far right button if it is pointing to the right.\n\nPress the button AS QUICKLY AS POSSIBLE.\n\n(Press the spacebar to continue)';
instructions{2} = 'For example, if you saw:\n\n> > < > >\n\nyou would press ''left''.\n\nIf you saw:\n\n> > > > >\n\nyou would press ''right''.\n\nIf you saw\n\n< < > < <\n\nyou would press ''right''.\n\nIgnore all of the arrows except the MIDDLE one!\n\n(Press the spacebar when you are ready to begin)';

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
    
    % Display instructions
    for i = 1:length(instructions)
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,[instructions{i}],'center','center',[255 255 255]);
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
        
        for trialNum = 1:trialsPerBlock
            
            thisTrialType = allTrialTypes(blockNum,trialNum);
            thisTrialString = stimStrings{thisTrialType};
            thisCorrectResponse = correctResponses(thisTrialType);
            
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',fixationSize);
            DrawFormattedText(win,fixationCharacter,'center','center',textColour);
            Screen('Flip',win);
            WaitSecs(0.5);
            
            % Clear event buffer if using the response box
            if useResponseBox
                evt = CMUBox('GetEvent', handle);
                while ~isempty(evt)
                    evt = CMUBox('GetEvent', handle);
                end
            end
            
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',stimSize);
            DrawFormattedText(win,thisTrialString,'center','center',stimColour);
            Screen('Flip',win);
            
            % Get response
            madeResponse = 0;
            responseCode = -1; % Invalid response
            responseCorrect = -1; % Invalid response
            responseTime = -1;
            startTime = GetSecs();
            while GetSecs() - startTime < 1.250 % ISI??
                
                if useResponseBox
                    evt = CMUBox('GetEvent', handle);
                    if ~isempty(evt) && evt.state
                        madeResponse = 1;
                        pressTime = evt.time;
                        srBoxCode = evt.state;
                        
%                         % Wait for button release (Is this the right
%                         % place??)
%                         evt = CMUBox('GetEvent', handle);
%                         while isempty(evt) || evt.state ~= 0
%                             evt = CMUBox('GetEvent', handle);
%                         end
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
                    
                    DrawFormattedText(win,thisTrialString,'center','center',[192 192 192]); % Change colour to silver
                    Screen('Flip',win);
                end
            end
            
            thisLine = [blockNum trialNum thisTrialType madeResponse responseCode responseTime responseCorrect];
            dlmwrite(filename,thisLine,'delimiter', '\t', '-append');
            participantData = [participantData; thisLine];
            
            % Check for escape key
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyCode(ExitKey)
                ME = MException('ct:escapekeypressed','Exiting script');
                throw(ME);
            end
        end
        
        %         % Rest break
        %         if blockNum < nBlocks
        %             Screen('TextSize',win,textSize);
        %             DrawFormattedText(win,'you will now rest for a short time before the next block begins','center','center',[255 255 255]);
        %             Screen('Flip',win);
        %             WaitSecs(4);
        %             Screen('Flip',win);
        %             WaitSecs(20);
        %             DrawFormattedText(win,'get ready to begin','center','center',[255 255 255]);
        %             Screen('Flip',win);
        %             WaitSecs(4);
        %         end
        
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