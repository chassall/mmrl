% MSIT
% C. Hassall
% January, 2019
% Based on PsychoPy code by Cameron Craddock: http://opencoglabrepository.github.io/experiment_msit.html

%{
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
    whichResponseCodes = [1 2 4]; % Buttons 1,2,3
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
stimStrings = {'< < < < <','> > < > >','> > > > >','< < > < <'};
stimColour = [255 255 255];
correctResponses = [1 1 2 2]; % 1:left, 2:right
textSize = 24; % Size for instructions and block messages

% Blocks, trials, trial types
nBlocks = 8;
trialsPerBlock = 24;
all_control_stim=['100','020','003']; % Trials types 1,2,3
controlTypes = [1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3];
all_int_stim=['221','212','331','313','112','211','332','233','131','311','232','322']; % Trial types 1-12
interferenceTypes = [1:12 1:12];
blockType = [1 2 1 2 1 2 1 2]; % 1 = control, 2 = interference

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
instructions{1} = 'Every few seconds, a set of three numbers (1, 2, 3, or 0)\nwill appear in the center of the screen.\nOne number will always be different from the other two.\nPress the button corresponding to the identity,\nnot the position, of the differing number.\nThe values corresponding to the buttons are:\nindex finger = 1, middle finger = 2, and ring finger = 3\nAnswer as accurately and quickly as possible.';

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
            
            Screen(win,'TextFont','Arial');
            Screen(win,'TextSize',stimSize);
            DrawFormattedText(win,thisTrialString,'center','center',stimColour);
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
            while GetSecs() - startTime < 1.250 % ISI??
                [madeResponse, secs, keyCode] = KbCheck(-1);
                
                if madeResponse
                    responseTime  = GetSecs() - startTime;
                    if  keyCode(left_kb_key)
                        responseCode = 1;
                        if thisCorrectResponse == 1
                            responseCorrect = 1;
                        else
                            responseCorrect = 0;
                        end
                    elseif keyCode(right_kb_key)
                        responseCode = 2;
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

%}
