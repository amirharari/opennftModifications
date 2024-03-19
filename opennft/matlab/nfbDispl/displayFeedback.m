function displayFeedback(displayData)
% Function to display feedbacks using PTB functions
%
% input:
% displayData - input data structure
%
% Note, synchronization issues are simplified, e.g. sync tests are skipped.
% End-user is advised to configure the use of PTB on their own workstation
% and justify more advanced configuration for PTB.
%__________________________________________________________________________
%
% Written by Yury Koush, Artem Nikonorov
global keyCounts; % Declare global variable
tDispl = tic;

P = evalin('base', 'P');
Tex = evalin('base', 'Tex');
KbName('UnifyKeyNames');
% Note, don't split cell structure in 2 lines with '...'.
fieldNames = {'feedbackType', 'condition', 'dispValue', 'Reward', 'displayStage','displayBlankScreen', 'iteration', 'run'};
defaultFields = {'', 0, 0, '', '', '', 0, 0};
% disp(displayData)
eval(varsFromStruct(displayData, fieldNames, defaultFields))

if ~strcmp(feedbackType, 'DCM')
    dispColor = [255, 255, 255];
    instrColor = [155, 150, 150];
end
filename = P.MentalStragFile;
fid = fopen(filename);
line = fgetl(fid);
strategies = {};
while ischar(line)
    strategies{end + 1} = line;
    line = fgetl(fid);
end
fclose(fid);
buttonsPressedFile = fullfile(P.WorkFolder, sprintf('NF_Data_%d', P.NFRunNr), sprintf('buttons_pressed_file_%d.txt', P.NFRunNr));
successEvaluationFile = fullfile(P.WorkFolder, sprintf('NF_Data_%d', P.NFRunNr), sprintf('success_evaluation_file_%d.txt', P.NFRunNr));
successConfidentFile = fullfile(P.WorkFolder, sprintf('NF_Data_%d', P.NFRunNr), sprintf('success_confident_file_%d.txt', P.NFRunNr));

% Use persistent variables for state across function calls
persistent rank last_condition

firstTime = false;

% Initialize persistent variables only once
if isempty(rank)
    rank = 4; % Example initialization, replace 4 with a meaningful default if applicable
end

if isempty(last_condition)
    last_condition = -1; % Initial state, replace -1 with a meaningful default if applicable
end

% Check if the condition has changed since the last run
if last_condition ~= condition
    disp('restart rank'); % Display a message indicating rank is being restarted
    rank = 4; % Reset rank
    last_condition = condition; % Update the last_condition
    firstTime = true; % Indicate this is the first run with the new condition
end
switch feedbackType
    %% Continuous PSC
    case 'bar_count'
        dispValue  = dispValue*(floor(P.Screen.h/2) - floor(P.Screen.h/10))/100;
        switch condition
            case 1 % Baseline
                % Text "+"
                Screen('TextSize', P.Screen.wPtr , floor(P.Screen.h/10));
                Screen('DrawText', P.Screen.wPtr, '+', ...
                    floor(P.Screen.w/2-P.Screen.h/12), ...
                    floor(P.Screen.h/2-P.Screen.h/12), instrColor);
           case 2 % Regulation
                % Fixation Point
                Screen('FillOval', P.Screen.wPtr, [255 255 255], ...
                    [floor(P.Screen.w/2-P.Screen.w/200), ...
                    floor(P.Screen.h/2-P.Screen.w/200), ...
                    floor(P.Screen.w/2+P.Screen.w/200), ...
                    floor(P.Screen.h/2+P.Screen.w/200)]);

                % Draw activity bar
                Screen('DrawLines', P.Screen.wPtr, ...
                    [floor(P.Screen.w/2-P.Screen.w/20), ...
                    floor(P.Screen.w/2+P.Screen.w/20); ...
                    floor((P.Screen.h/2-dispValue)*0.9), ...
                    floor((P.Screen.h/2-dispValue)*0.9)], P.Screen.lw, [0 255 0]);

                % Define a static frame that covers the entire possible range of the activity bar
                framePadding = 10; % This can be adjusted based on how much border you want around the activity bar
                maxBarLength = (P.Screen.h/2)*0.9;
                frameRect = [floor(P.Screen.w/2-P.Screen.w/20)-framePadding, ... % left edge
                             floor(P.Screen.h/2-maxBarLength)-framePadding, ... % top edge
                             floor(P.Screen.w/2+P.Screen.w/20)+framePadding, ... % right edge
                             floor(P.Screen.h/2+maxBarLength)+framePadding]; % bottom edge

                % Draw the static frame
                frameColor = [255 255 255]; % Red color for the frame, change as needed
                frameWidth = 4; % Pen width of the frame, adjust as needed
                Screen('FrameRect', P.Screen.wPtr, frameColor, frameRect, frameWidth);

            case 3 % mental strategies chooser
                run = run + 1;
                option_1 = strcat(' 1-- ', strategies{1});
                option_2 = strcat(' 2-- ', strategies{2});
                option_3 = strcat(' 3-- ', strategies{3});
                option_4 = strcat(' 4-- ', strategies{4});
                Screen('TextSize', P.Screen.wPtr , floor(P.Screen.h/20));
                Screen('DrawText', P.Screen.wPtr, 'Choose your mental strategy', ...
                    floor(P.Screen.w/1-P.Screen.h/1), ...
                    floor(P.Screen.h/5-P.Screen.h/10), [200 200 200]);
                    Screen('DrawText', P.Screen.wPtr, option_1, ...
                    floor(P.Screen.w/3-P.Screen.h/3), ...
                    floor(P.Screen.h/3-P.Screen.h/10), [200 200 200]);
                Screen('DrawText', P.Screen.wPtr, option_2, ...
                    floor(P.Screen.w/3-P.Screen.h/3), ...
                    floor(P.Screen.h/2.4-P.Screen.h/10), [200 200 200]);
                Screen('DrawText', P.Screen.wPtr, option_3, ...
                    floor(P.Screen.w/3-P.Screen.h/3), ...
                    floor(P.Screen.h/2-P.Screen.h/10), [200 200 200]);
                Screen('DrawText', P.Screen.wPtr, option_4, ...
                    floor(P.Screen.w/3-P.Screen.h/3), ...
                    floor(P.Screen.h/1.7-P.Screen.h/10), [200 200 200]);
                    keys = keyCounts.keys;
                    % If the user is pressing a key, then display its code number and name.
                    if length(keys)~=0
                        numericPart = regexp(keys{1}, '\d+', 'match');
                        keyPressed = str2double(numericPart{1}); % Convert the first key to integer
                        fprintf('The pressed key is: %d \n', keyPressed);
                        fwid = fopen(buttonsPressedFile, 'a+');
                        fprintf(fwid, 'Pressed: Button %d at %d seconds\n',keyPressed, iteration);
                        fclose(fwid);.
                        Screen('DrawText', P.Screen.wPtr, strcat('you picked: ',num2str(keyPressed)), ...
                            floor(P.Screen.w/3-P.Screen.h/3), ...
                            floor(P.Screen.h/1.3-P.Screen.h/10), [200 200 200]);
                    end
                case 4 % Strategy reminder
                    strategyNumber = getStrategyNumberFromFile(buttonsPressedFile);
                    strategy = strategies{strategyNumber}
                    Screen('TextSize', P.Screen.wPtr, floor(P.Screen.h/20)); % Adjust text size as needed
                    Screen('DrawText', P.Screen.wPtr, strategy, ...
                       floor(P.Screen.w/2 - length(strategy) * P.Screen.w/100), ... % Adjust text position as needed
                       floor(P.Screen.h/2), [255, 255, 255]); % White color
                case 5 % Rank your success
                % Reset keyCounts (simulate restarting the data structure)
                    rank = drawCustomScale(P, 'How well did you perform?', successEvaluationFile, rank);
                case 6 % Rank your confident
                    rank = drawCustomScale(P, 'How confident are you in your ranking?', successConfidentFile, rank);
        end
        keyCounts = containers.Map('KeyType', 'char', 'ValueType', 'double');
        P.Screen.vbl = Screen('Flip', P.Screen.wPtr, ...
            P.Screen.vbl + P.Screen.ifi/2);

    %% Continuous PSC with task block
    case 'bar_count_task'
        dispValue  = dispValue*(floor(P.Screen.h/2) - floor(P.Screen.h/10))/100;
        switch condition
            case 1 % Baseline
                % Text "COUNT"
                Screen('TextSize', P.Screen.wPtr , P.Screen.h/10);
                Screen('DrawText', P.Screen.wPtr, 'COUNT', ...
                    floor(P.Screen.w/2-P.Screen.h/4), ...
                    floor(P.Screen.h/2-P.Screen.h/10), instrColor);

                 P.Screen.vbl = Screen('Flip', P.Screen.wPtr, ...
                     P.Screen.vbl + P.Screen.ifi/2);

            case 2 % Regualtion
                % Fixation Point
                Screen('FillOval', P.Screen.wPtr, [255 255 255], ...
                    [floor(P.Screen.w/2-P.Screen.w/200), ...
                    floor(P.Screen.h/2-P.Screen.w/200), ...
                    floor(P.Screen.w/2+P.Screen.w/200), ...
                    floor(P.Screen.h/2+P.Screen.w/200)]);
                % draw target bar
                Screen('DrawLines', P.Screen.wPtr, ...
                    [floor(P.Screen.w/2-P.Screen.w/20), ...
                    floor(P.Screen.w/2+P.Screen.w/20); ...
                    floor(P.Screen.h/10), floor(P.Screen.h/10)], ...
                    P.Screen.lw, [255 0 0]);
                % draw activity bar
                Screen('DrawLines', P.Screen.wPtr, ...
                    [floor(P.Screen.w/2-P.Screen.w/20), ...
                    floor(P.Screen.w/2+P.Screen.w/20); ...
                    floor(P.Screen.h/2-dispValue), ...
                    floor(P.Screen.h/2-dispValue)], P.Screen.lw, [0 255 0]);

                    P.Screen.vbl = Screen('Flip', P.Screen.wPtr, ...
                        P.Screen.vbl + P.Screen.ifi/2);
            case 3
                % ptbTask sequence called seperetaly in python

        end

    %% Intermittent PSC

case 'value_fixation'
        indexSmiley = round(dispValue);
        if indexSmiley == 0
            indexSmiley = 1;
        end
        switch condition
            case 1  % Baseline
                for i = 1:2
                    % fixation
                    Screen('FillOval', P.Screen.wPtr, ...
                        [randi([50,200]) 0 0], P.Screen.fix+[0 0 0 0]);
                    % dots
                    Screen('DrawDots', P.Screen.wPtr, P.Screen.xy, ...
                        P.Screen.dsize, P.Screen.dotCol,P.Screen.db,0);
                    % display
                    P.Screen.vbl = Screen('Flip', P.Screen.wPtr, ...
                        P.Screen.vbl + P.Screen.ifi/2);
                    % flickering
                    if 1
                        pause(randi([30,100])/1000)
                    end
                end

            case 2  % Regualtion
                for i = 1:2
                    % arrow
                    Screen('FillRect',P.Screen.wPtr, instrColor, ...
                        P.Screen.arrow.rect + [0 0 0 0]);
                    Screen('FillPoly',P.Screen.wPtr, instrColor, ...
                        P.Screen.arrow.poly_right + [0 0; 0 0; 0 0]);
                    Screen('FillPoly',P.Screen.wPtr, instrColor, ...
                        P.Screen.arrow.poly_left + [0 0; 0 0; 0 0]);
                    % fixation
                    Screen('FillOval', P.Screen.wPtr, ...
                        [randi([50,200]) 0 0], P.Screen.fix+[0 0 0 0]);
                    % dots
                    Screen('DrawDots', P.Screen.wPtr, P.Screen.xy, ...
                        P.Screen.dsize, P.Screen.dotCol, P.Screen.db,0);
                    % display
                    P.Screen.vbl=Screen('Flip', P.Screen.wPtr, ...
                        P.Screen.vbl + P.Screen.ifi/2);
                    % basic flickering given TR
                    if 1
                        pause(randi([30,100])/1000);
                    end
                end

            case 3 % NF
                % feedback value
                Screen('DrawText', P.Screen.wPtr, mat2str(dispValue), ...
                    P.Screen.w/2 - P.Screen.w/30+0, ...
                    P.Screen.h/2 - P.Screen.h/4, dispColor);
                % smiley
                Screen('DrawTexture', P.Screen.wPtr, ...
                    Tex(indexSmiley), ...
                    P.Screen.rectSm, P.Screen.dispRect+[0 0 0 0]);
                % display
                P.Screen.vbl = Screen('Flip', P.Screen.wPtr, ...
                    P.Screen.vbl + P.Screen.ifi/2);
        end

    %% Trial-based DCM
    case 'DCM'
        nrP = P.nrP;
        nrN = P.nrN;
        imgPNr = P.imgPNr;
        imgNNr = P.imgNNr;
        switch condition
            case 1 % Neutral textures
                % Define texture
                nrP = 0;
                nrN = nrN + 1;
                if (nrN == 1) || (nrN == 5) || (nrN == 9)
                    imgNNr = imgNNr + 1;
                    disp(['Neut Pict:' mat2str(imgNNr)]);
                end
                if nrN < 5
                    basImage = Tex.N(imgNNr);
                elseif (nrN > 4) && (nrN < 9)
                    basImage = Tex.N(imgNNr);
                elseif nrN > 8
                    basImage = Tex.N(imgNNr);
                end
                % Draw Texture
                Screen('DrawTexture', P.Screen.wPtr, basImage);
                P.Screen.vbl=Screen('Flip', P.Screen.wPtr, ...
                    P.Screen.vbl+P.Screen.ifi/2);

            case 2 % Positive textures
                % Define texture
                nrN = 0;
                nrP = nrP + 1;
                if (nrP == 1) || (nrP == 5) || (nrP == 9)
                    imgPNr = imgPNr + 1;
                    disp(['Posit Pict:' mat2str(imgPNr)]);
                end
                if nrP < 5
                    dispImage = Tex.P(imgPNr);
                elseif (nrP > 4) && (nrP < 9)
                    dispImage = Tex.P(imgPNr);
                elseif nrP > 8
                    dispImage = Tex.P(imgPNr);
                end
                % Draw Texture
                Screen('DrawTexture', P.Screen.wPtr, dispImage);
                P.Screen.vbl=Screen('Flip', P.Screen.wPtr, ...
                    P.Screen.vbl+P.Screen.ifi/2);

            case 3 % Rest epoch
                % Black screen case is called seaprately in Python to allow
                % using PTB Matlab Helper process for DCM model estimations

            case 4 % NF display
                nrP = 0;
                nrN = 0;
                % red if positive, blue if negative
                if dispValue >0
                    dispColor = [255, 0, 0];
                else
                    dispColor = [0, 0, 255];
                end
                % instruction reminder
                Screen('DrawText', P.Screen.wPtr, 'UP', ...
                    P.Screen.w/2 - P.Screen.w/15, ...
                    P.Screen.h/2 - P.Screen.w/8, [255, 0, 0]);
                % feedback value
                Screen('DrawText', P.Screen.wPtr, ...
                    ['(' mat2str(dispValue) ')'], ...
                    P.Screen.w/2 - P.Screen.w/7, ...
                    P.Screen.h/2 + P.Screen.w/200, dispColor);
                % monetary reward value
                Screen('DrawText', P.Screen.wPtr, ['+' Reward 'CHF'], ...
                    P.Screen.w/2 - P.Screen.w/7, ...
                    P.Screen.h/2 + P.Screen.w/7, dispColor);
                P.Screen.vbl=Screen('Flip', P.Screen.wPtr, ...
                    P.Screen.vbl + P.Screen.ifi/2);
                % basic flickering given TR
                if 1
                    pause(randi([600,800])/1000);
                    P.Screen.vbl=Screen('Flip', P.Screen.wPtr, ...
                        P.Screen.vbl + P.Screen.ifi/2);
                end
        end
        P.nrP = nrP;
        P.nrN = nrN;
        P.imgPNr = imgPNr;
        P.imgNNr = imgNNr;
end

% EventRecords for PTB
% Each event row for PTB is formatted as
% [t9, t10, displayTimeInstruction, displayTimeFeedback]
t = posixtime(datetime('now','TimeZone','local'));
tAbs = toc(tDispl);
if strcmp(displayStage, 'instruction')
    P.eventRecords(1, :) = repmat(iteration,1,4);
    P.eventRecords(iteration + 1, :) = zeros(1,4);
    P.eventRecords(iteration + 1, 1) = t;
    P.eventRecords(iteration + 1, 3) = tAbs;
elseif strcmp(displayStage, 'feedback')
    P.eventRecords(1, :) = repmat(iteration,1,4);
    P.eventRecords(iteration + 1, :) = zeros(1,4);
    P.eventRecords(iteration + 1, 2) = t;
    P.eventRecords(iteration + 1, 4) = tAbs;
end
recs = P.eventRecords;
save(P.eventRecordsPath, 'recs', '-ascii', '-double');

assignin('base', 'P', P);

function rank = drawCustomScale(P, questionText, buttonsPressedFile, rank)
    global keyCounts; % Accessing global variable keyCounts

    % Scale parameters initialization
    scaleStart = floor(P.Screen.w * 0.1);
    scaleEnd = floor(P.Screen.w * 0.9);
    scaleYPos = floor(P.Screen.h * 0.8);
    scaleHeight = 10;
    numberScalePositions = 7;

    % Drawing the scale's main line
    Screen('DrawLine', P.Screen.wPtr, [255, 255, 255], scaleStart, scaleYPos, scaleEnd, scaleYPos, scaleHeight);

    % Draw marks and numbers
    for i = 1:numberScalePositions
        xPos = scaleStart + (i-1) * (scaleEnd - scaleStart) / (numberScalePositions - 1);
        Screen('DrawLine', P.Screen.wPtr, [255 255 255], xPos, scaleYPos - 20, xPos, scaleYPos + 20, scaleHeight);
        Screen('TextSize', P.Screen.wPtr, 20);
        DrawFormattedText(P.Screen.wPtr, num2str(i), 'center', 'center', [255 255 255], [], [], [], [], [], [xPos - 10, scaleYPos + 25, xPos + 10, scaleYPos + 45]);
    end


    % Highlighting the current rank with a red line
    rankPos = scaleStart + (rank - 1) * (scaleEnd - scaleStart) / (numberScalePositions - 1);
    Screen('DrawLine', P.Screen.wPtr, [255, 0, 0], rankPos, scaleYPos - 30, rankPos, scaleYPos + 30, scaleHeight);

    % Displaying the question text
    Screen('TextSize', P.Screen.wPtr, 24);
    DrawFormattedText(P.Screen.wPtr, questionText, 'center', scaleYPos - 100, [255, 255, 255]);
    keys = keyCounts.keys;
    values = keyCounts.values;
    % Adjusting rank based on key presses
    if ~isempty(keys)
        numericPart = regexp(keys{1}, '\d+', 'match');
        keyPressed = str2double(numericPart{1}); % Convert the key to an integer

        % Adjusting rank based on the pressed key
        if keyPressed == 1
            rank = max(1, rank - values{1}); % Avoid going below 1
        elseif keyPressed == 4
            rank = min(numberScalePositions, rank + values{1}); % Avoid going above the max position
            while KbCheck; end % Ensuring key release before proceeding
        end
        % Display updates on screen
    Screen('Flip', P.Screen.wPtr);
    end


    % Logging the button press
    fid = fopen(buttonsPressedFile, 'a+');
    fprintf(fid, 'Value selected: %d at %f seconds\n', rank, GetSecs);
    fclose(fid);


function strategyNumber = getStrategyNumberFromFile(fileName)
    % Open the file for reading
    fid = fopen(fileName, 'r');
    if fid == -1
        error('Failed to open the file.');
    end

    % Initialize an empty cell array to hold lines from the file
    lines = {};

    % Read all lines from the file
    while true
        line = fgetl(fid); % Read one line from the file
        if ~ischar(line) % If line is not a character array, we've reached the end of the file
            break;
        end
        lines{end + 1} = line; % Append the line to the lines array
    end
    fclose(fid); % Close the file

    % Extract the strategy number from the last line
    if isempty(lines)
        error('The file is empty.');
    end
    lastLine = lines{end}; % Get the last line
    tokens = regexp(lastLine, 'Button (\d+)', 'tokens'); % Extract the number after 'Button'
    if isempty(tokens)
        error('Could not parse the last line for a strategy number.');
    end

    % Convert the extracted number to a double
    strategyNumber = str2double(tokens{1}{1});

    if isnan(strategyNumber)
        error('The extracted strategy number is not a valid number.');
    end