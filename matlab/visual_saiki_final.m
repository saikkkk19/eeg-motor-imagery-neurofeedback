%% PARADIGM DEFINITION
NoTrial           = 2;              % number of trials per class
Classlabel        = [1 2];          % index number of classes (1: left, 2: right)
RandomizedOrder   = 0;              % 1: randomize, 0: not random
DelayBefore       = 5;              % delay time before session [s]
DelayAfter        = 5;              % delay time after session [s]
PreparationLen    = 3;
RestLen           = 4;
RandomPeriod      = 0;              % maximum ITI (random) [s]
CrossPeriod       = [0 6];          % period of presenting cross [s s]
CuePeriod         = [3 4.25];       % period of presenting cue [s s]

%% LSL setup
disp('Loading library...');
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'si_marker','Markers',1,0,'cf_string','si_marker');

disp('Opening an outlet...');
outlet = lsl_outlet(info);

streams = lsl_resolve_bypred(lib, 'name=''clfresults''', 1, 10.0);
inlet = lsl_inlet(streams{1});
[mrks,ts] = inlet.pull_chunk();

%% INIT
rng('shuffle');

classlabel = repmat(Classlabel, 1, NoTrial);
if RandomizedOrder
    classlabel = classlabel(randperm(length(classlabel)));
end

save 'Label.mat' classlabel

%% Figure Setup for Visual Stimulation
hFig = figure('menubar', 'none', 'units', 'normalized', 'position', [0 0 1 1], 'color', 'k');
axes('position', [0, 0, 1, 1], 'color', 'k')
axis off
xlim([-1 1]);
ylim([-1 1]);

ArrowLen    = 0.5;
AspectRatio = 2560/1440;

% Small fixation cross
fixCrossLen = 0.05;
fixCross1 = line([-fixCrossLen/AspectRatio +fixCrossLen/AspectRatio], [0 0], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');
fixCross2 = line([0 0], [-fixCrossLen +fixCrossLen], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');

% Cue arrows (1: left, 2: right, 3: down; 4-6: same in blue)
x = [ 0  .9 .9 1 .9 .9 0 0] * ArrowLen;
y = [.02  .02 .04 0 -.04 -.02 -.02 .02];
hArrow(1) = patch(-x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(2) = patch( x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(3) = patch( y/AspectRatio,  -x, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(4) = patch(-x/AspectRatio,  y, 'b', 'EdgeColor', 'none', 'visible', 'off');
hArrow(5) = patch( x/AspectRatio,  y, 'b', 'EdgeColor', 'none', 'visible', 'off');
hArrow(6) = patch( y/AspectRatio,  -x, 'b', 'EdgeColor', 'none', 'visible', 'off');

% Large cross shown during the trial
CrossLen = 0.2;
hCross(1) = line([-CrossLen/AspectRatio +CrossLen/AspectRatio], [0 0], 'Color', 'w', ...
    'LineWidth', 3, 'visible', 'off');
hCross(2) = line([0 0], [-CrossLen +CrossLen], 'Color', 'w', ...
    'LineWidth', 3, 'visible', 'off');

%% Trial Sequence
% Alternating sequence of right (1) and left (2) cues
shuffled_labels = [];
for n = 1:NoTrial
   shuffled_labels = [shuffled_labels 1 2];
end
shuffled_labels = shuffled_labels';

disp(['Number of trials: ' num2str(length(shuffled_labels))])

%% RUN PARADIGM
pause(DelayBefore);

for n = 1:length(classlabel)
    %% Preparation Period
    set(hCross, 'Visible', 'on');

    outlet.push_sample({'4'});
    pause(0.1);
    pause(PreparationLen-0.1)

    %% Task Period
    if shuffled_labels(1,:) == 1
        % Right hand
        outlet.push_sample({'8'});

        set(hArrow(classlabel(2)), 'Visible', 'on');
        startTime = tic;
        while toc(startTime) < (CuePeriod(2)-CuePeriod(1))
            pause(0.01);
        end
        set(hArrow(classlabel(2)), 'Visible', 'off');

        startTime = tic;
        while toc(startTime) < (CrossPeriod(2)-CuePeriod(2))
            pause(0.01);
        end

    elseif shuffled_labels(1,:) == 2
        % Left hand
        outlet.push_sample({'16'});

        set(hArrow(classlabel(1)), 'Visible', 'on');
        startTime = tic;
        while toc(startTime) < (CuePeriod(2)-CuePeriod(1))
            pause(0.01);
        end
        set(hArrow(classlabel(1)), 'Visible', 'off');

        startTime = tic;
        while toc(startTime) < (CrossPeriod(2)-CuePeriod(2))
            pause(0.01);
        end
    end

    shuffled_labels(1,:) = [];

    %% Rest Period
    set(hCross, 'Visible', 'off');

    outlet.push_sample({'32'});
    pause(0.1);
    pause(RestLen+RandomPeriod-0.1);

    %% Feedback Period - Visual Feedback
    [mrks,ts] = inlet.pull_chunk();

    % Feedback is drawn towards the top right of the screen.
    % Offsets assume a 60 cm x 33.75 cm (16:9) display.
    feedbackCrossLen = 0.1;
    screenWidth_cm = 60;
    screenHeight_cm = 33.75;
    x_offset = 25/screenWidth_cm;
    y_offset = 25/screenHeight_cm;

    fCross(1) = line([1-x_offset-feedbackCrossLen/AspectRatio 1-x_offset+feedbackCrossLen/AspectRatio], ...
        [1-y_offset 1-y_offset], 'Color', 'w', 'LineWidth', 3);
    fCross(2) = line([1-x_offset 1-x_offset], ...
        [1-y_offset-feedbackCrossLen 1-y_offset+feedbackCrossLen], ...
        'Color', 'w', 'LineWidth', 3);

    % Feedback arrows
    fArrowLen = 0.2;
    x = [0  .9 .9 1 .9 .9 0 0] * fArrowLen;
    y = [.02  .02 .04 0 -.04 -.02 -.02 .02];
    fArrow(1) = patch(1-x_offset-x/AspectRatio, 1-y_offset+y, 'r', 'EdgeColor', 'none', 'Visible', 'off');
    fArrow(2) = patch(1-x_offset+x/AspectRatio, 1-y_offset+y, 'r', 'EdgeColor', 'none', 'Visible', 'off');

    % Feedback text
    feedbackText = text(1-x_offset, 1-y_offset+0.1, '', 'Color', 'w', 'HorizontalAlignment', 'center', 'FontSize', 20);

    if ~isempty(mrks)
        feedback_marker = mrks;
        disp(['Feedback marker received: ' num2str(feedback_marker)]);

        if feedback_marker == 1 % Right hand
            set(fCross, 'Color', 'g');
            set(fArrow(2), 'Visible', 'on', 'FaceColor', 'g');
            set(feedbackText, 'String', 'Right Hand Feedback', 'Color', 'g');
        else % Left hand
            set(fCross, 'Color', 'g');
            set(fArrow(1), 'Visible', 'on', 'FaceColor', 'g');
            set(feedbackText, 'String', 'Left Hand Feedback', 'Color', 'g');
        end
    else
        disp('No feedback marker received');
        set(feedbackText, 'String', 'No Feedback Received', 'Color', 'r');
    end

    % Reset feedback display
    pause(0.5);
    set(fArrow, 'Visible', 'off');
    set(fCross, 'Color', 'w');
    set(feedbackText, 'String', '');
end

pause(DelayAfter);

close(hFig);
