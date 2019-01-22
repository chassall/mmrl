% Lexical Decision
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
    whichResponseCodes = [1 2]; % Buttons A and B
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
    filename = strcat('lexicaldecision_', rundate, '_', p_number, '.txt');
    mfilename = strcat('lexicaldecision_', rundate, '_', p_number, '.mat');
    age = '99';
    handedness = 'LR';
else
    while 1
        clc;
        p_number = input('Enter the participant number:\n','s');  % get the subject name/number
        rundate = datestr(now, 'yyyymmdd-HHMMSS');
        filename = strcat('lexicaldecision_', rundate, '_', p_number, '.txt');
        mfilename = strcat('lexicaldecision_', rundate, '_', p_number, '.mat');
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
dlmwrite('lexicaldecisionparticipants.txt',run_line,'delimiter','', '-append');

%% Run parameters
bgColour = [0 0 0];
textColour = [255 255 255];
fixationSize = 96; % Size for fixation '+'
fixationCharacter = '+';
stimSize = 96; % Size for stimuli
practiceWords = {'garage',1; 'neefle',2};
experimentWords{1} = {'cities',	1;...
    'hestory',	2;...
    'offace',	2;...
    'trees',	1;...
    'forpe',	2;...
    'dictor',	2;...
    'niture',	2;...
    'college',	1;...
    'fither',	2;...
    'unian',	2;...
    'degree',	1;...
    'design',	1;...
    'sulport',	2;...
    'nabion',	2;...
    'persol',	2;...
    'truth',	1;...
    'record',	1;...
    'points',	1;...
    'repert',	2;...
    'words',	1};

experimentWords{2} = {'surface',	1;...
    'ranje',	2;...
    'hours',	1;...
    'example',	1;...
    'result',	1;...
    'narket',	2;...
    'island',	1;...
    'spirit',	1;...
    'student',	1;...
    'palice',	2;...
    'seption',	2;...
    'leater',	2;...
    'south',	1;...
    'method',	1;...
    'weefs',	2;...
    'velume',	2;...
    'sammer',	2;...
    'mouth',	1;...
    'attack',	1;...
    'trian',	2};


experimentWords{3} = {'husband',	1;...
    'sciense',	2;...
    'centre',	1;...
    'manth',	2;...
    'future',	1;...
    'siries',	2;...
    'plant',	1;...
    'pross',	2;...
    'seesan',	2;...
    'windal',	2;...
    'front',	1;...
    'encome',	2;...
    'music',	1;...
    'class',	1;...
    'seltion',	2;...
    'teath',	2;...
    'corner',	1;...
    'pappern',	2;...
    'months',	1;...
    'effort',	1};

textSize = 48; % Size for instructions and block messages

% Blocks, trials, trial types
nBlocks = 3; % Number of blocks
trialsPerBlock = 20; % Trials per block

% Instructions
instructions{1} = 'In the following task, you will be making judgments about\nsingle words.\n\nGroups of 5 to 7 letters will appear in the centre of the\nscreen and remain there for several seconds.  Your job is\nto decide as quickly as you can whether these letters,\nin the shown order, make up a real English word or not.\n\nIf they do make up a real English word, then you should\npress the left (''yes'') button to indicate "YES, they do".  If they\nsimply make up a nonsense word or something that looks\nlike a real word but is badly miss-spelled, you would\npress the right (''no'') button to indicate "NO, they don''t.\n\nPress any key to continue.';
instructions{2} = 'Once we start, the words and non-words will keep\ncoming non-stop, with a short delay between each\nitem.  After 20 items, the computer will  halt and\nsignal a rest.  Try to respond as  quickly as you\ncan while still remaining accurate.\n\nThe general sequence will be like this:\n  1. The screen will be blank.\n 2. As quickly as you can, determine if the letters form a\nreal word or not.\n 3. As quickly as you can, press ''yes'' if they make a real word\nor ''no'' if they do not.\n 4. The computer responds with "correct" or "no", meaning\nthat your response was either correct or incorrect.\n 5. The letters linger for a moment then the screen goes\nblank and you go back to step #1.\nIf you feel ready, press any key to try a few examples ...';
instructions{3} = 'Here are 2 sample questions.\nPress ''yes'' if the letters make up a real English word.\nPress ''no'' if the letters do not.\n\nPress any key to continue.';

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
    
    % Practice trials
    for p = 1:length(practiceWords)
        thisWord = practiceWords{p,1};
        thisCorrectResponse = practiceWords{p,2};
        
        KbReleaseWait(-1);
        
        Screen('Flip',win);
        WaitSecs(0.75);
        
        Screen(win,'TextFont','Arial');
        Screen(win,'TextSize',fixationSize);
        DrawFormattedText(win,fixationCharacter,'center','center',textColour);
        Screen('Flip',win);
        WaitSecs(0.75);
        
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
        DrawFormattedText(win,thisWord,'center','center',textColour);
        Screen('Flip',win);
        
        % Get response
        madeResponse = 0;
        responseCode = -1; % Invalid response
        responseCorrect = -1; % Invalid response
        responseTime = -1;
        startTime = GetSecs();
        while ~madeResponse && GetSecs() - startTime < 5 % ISI of 5??
            
            if ~madeResponse
                if useResponseBox
                    evt = CMUBox('GetEvent', handle);
                    if ~isempty(evt) && evt.state
                        madeResponse = 1;
                        pressTime = evt.time;
                        srBoxCode = evt.state;
                        
                        %                     % Wait for button release (Is this the right
                        %                     % place??)
                        %                     evt = CMUBox('GetEvent', handle);
                        %                     while isempty(evt) || evt.state ~= 0
                        %                         evt = CMUBox('GetEvent', handle);
                        %                     end
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
                        if thisCorrectResponse == 2
                            responseCorrect = 1;
                        else
                            responseCorrect = 0;
                        end
                    end
                    
                end
            end
        end
        
        if responseCorrect == -1
            DrawFormattedText(win,'invalid response','center','center',textColour);
        elseif responseCorrect == 0
            DrawFormattedText(win,'no','center','center',textColour);
        elseif responseCorrect == 1
            DrawFormattedText(win,'correct','center','center',textColour);
        end
        Screen('Flip',win);
        WaitSecs(2);
        
    end
    
    % Block/trial loop
    for blockNum = 1:nBlocks
        
        Screen('TextSize',win,textSize);
        DrawFormattedText(win,'Let''s begin! \n\nWhen you are ready, press any key to continue.','center','center',textColour);
        Screen('Flip',win);
        KbReleaseWait(-1);
        KbPressWait(-1);
        
        for trialNum = 1:trialsPerBlock
            
            thisWord = experimentWords{blockNum}{trialNum,1};
            thisCorrectResponse = experimentWords{blockNum}{trialNum,2};
            
            KbReleaseWait(-1);
            
            Screen('Flip',win);
            WaitSecs(0.75);
            
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',fixationSize);
            DrawFormattedText(win,fixationCharacter,'center','center',textColour);
            Screen('Flip',win);
            WaitSecs(0.75);
            
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
            DrawFormattedText(win,thisWord,'center','center',textColour);
            Screen('Flip',win);
            
            % Get response
            madeResponse = 0;
            responseCode = -1; % Invalid response
            responseCorrect = -1; % Invalid response
            responseTime = -1;
            startTime = GetSecs();
            while ~madeResponse && GetSecs() - startTime < 5 % ISI of 5??
                if ~madeResponse % Redundant
                    if useResponseBox
                        evt = CMUBox('GetEvent', handle);
                        if ~isempty(evt) && evt.state
                            madeResponse = 1;
                            pressTime = evt.time;
                            srBoxCode = evt.state;
                            
                            % Wait for button release (Is this the right
                            % place??)
                            evt = CMUBox('GetEvent', handle);
                            while isempty(evt) || evt.state ~= 0
                                evt = CMUBox('GetEvent', handle);
                            end
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
                            if thisCorrectResponse == 2
                                responseCorrect = 1;
                            else
                                responseCorrect = 0;
                            end
                        end
                        
                    end
                end
            end
            
            if responseCorrect == -1
                DrawFormattedText(win,'invalid response','center','center',textColour);
            elseif responseCorrect == 0
                DrawFormattedText(win,'no','center','center',textColour);
            elseif responseCorrect == 1
                DrawFormattedText(win,'correct','center','center',textColour);
            end
            Screen('Flip',win);
            WaitSecs(2);
            
            thisLine = [blockNum trialNum thisCorrectResponse madeResponse responseCode responseTime responseCorrect];
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
            KbReleaseWait(-1);
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
