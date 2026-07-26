%% PARADIGM DEFINITION
NoTrial           = 4;              % number of trials
DelayBefore       = 5;              % delay time before session [s]
DelayAfter        = 5;              % delay time after session [s]
PreparationLen    = 3;
TaskLen           = 3;
RestLen           = 4;
RandomPeriod      = 0;              % maximum ITI (random) [s]
CuePeriod         = [3 4.25];       % period of presenting cue [s s]

% Tactile Feedback Parameters
feedbackDuration  = 0.5;            % Duration of feedback pulse
numFeedbackPulses = 3;              % Number of feedback pulses
feedbackInterval  = 0.2;            % Interval between feedback pulses

%% gSTIMboxの設定
clc
com = 13;

handle = gSTIMboxinit(com, 256, 8, 1);
gSTIMboxsetMode(handle, [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16], [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]);
gSTIMboxreset(handle);

%% LSLの設定
disp('Loading library...');
lib = lsl_loadlib();
info = lsl_streaminfo(lib,'si_marker','Markers',1,0,'cf_string','si_marker');
outlet = lsl_outlet(info);
streams = lsl_resolve_bypred(lib, 'name=''clfresults''', 1, 10.0);
inlet = lsl_inlet(streams{1});

%% Figure Setup for Visual Stimulation
hFig = figure('menubar', 'none', 'units', 'normalized', 'position', [0 0 1 1], 'color', 'k');
axes('position', [0, 0, 1, 1], 'color', 'k')
axis off
xlim([-1 1]);
ylim([-1 1]);

% Create arrows
ArrowLen    = 0.5;
AspectRatio = 2560/1440;

% Fixation cross
fixCrossLen = 0.05;
fixCross1 = line([-fixCrossLen/AspectRatio +fixCrossLen/AspectRatio], [0 0], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');
fixCross2 = line([0 0], [-fixCrossLen +fixCrossLen], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');

% Create arrows
x = [ 0  .9 .9 1 .9 .9 0 0] * ArrowLen;
y = [.02  .02 .04 0 -.04 -.02 -.02 .02];                   
hArrow(1) = patch(-x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(2) = patch( x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');

%% Trial Sequence
% Generate trials with equal number of left and right cues
shuffled_labels = repmat([1 2], 1, NoTrial/2);
shuffled_labels = shuffled_labels(randperm(length(shuffled_labels)))';

pause(DelayBefore);

for n = 1:NoTrial
    %% Preparation Period
    set(fixCross1, 'Visible', 'on');
    set(fixCross2, 'Visible', 'on');
    
    outlet.push_sample({'4'});
    gSTIMboxsetPortState(handle, 11, 1);
    pause(0.1);
    gSTIMboxsetPortState(handle, 11, 0);
    pause(PreparationLen-0.1)
    
    %% Task Period - Visual Stimulation Only
    if shuffled_labels(n) == 1  % Right hand
        outlet.push_sample({'8'});
        gSTIMboxsetPortState(handle, 12, 1);
        pause(0.1);
        gSTIMboxsetPortState(handle, 12, 0);
        
        % Show right arrow
        set(hArrow(2), 'Visible', 'on');
        startTime = tic;    
        while toc(startTime) < (CuePeriod(2)-CuePeriod(1))
            pause(0.01);
        end
        set(hArrow(2), 'Visible', 'off');
        
    else  % Left hand
        outlet.push_sample({'16'});
        gSTIMboxsetPortState(handle, 13, 1);
        pause(0.1);
        gSTIMboxsetPortState(handle, 13, 0);
        
        % Show left arrow
        set(hArrow(1), 'Visible', 'on');
        startTime = tic;    
        while toc(startTime) < (CuePeriod(2)-CuePeriod(1))
            pause(0.01);
        end
        set(hArrow(1), 'Visible', 'off');
    end

    %% Rest Period
    set(fixCross1, 'Visible', 'off');
    set(fixCross2, 'Visible', 'off');
    
    outlet.push_sample({'32'});
    gSTIMboxsetPortState(handle, 14, 1);
    pause(0.1);
    gSTIMboxsetPortState(handle, 14, 0);
    pause(RestLen+RandomPeriod-0.1);

    %% Feedback Period - Tactile Feedback Only
    [mrks,ts] = inlet.pull_chunk();
    
    if ~isempty(mrks)
        feedback_marker = mrks;
        disp(['Feedback marker received: ' num2str(feedback_marker)]);
        
        if feedback_marker == 1 % Right hand
            % Patterned tactile feedback for right hand (port 1)
            for pulse = 1:numFeedbackPulses
                gSTIMboxsetPortState(handle, 1, 1);
                pause(feedbackDuration);
                gSTIMboxsetPortState(handle, 1, 0);
                if pulse < numFeedbackPulses
                    pause(feedbackInterval);
                end
            end
        else % Left hand
            % Patterned tactile feedback for left hand (port 2)
            for pulse = 1:numFeedbackPulses
                gSTIMboxsetPortState(handle, 2, 1);
                pause(feedbackDuration);
                gSTIMboxsetPortState(handle, 2, 0);
                if pulse < numFeedbackPulses
                    pause(feedbackInterval);
                end
            end
        end
    else
        disp('No feedback marker received');
    end
end

pause(DelayAfter);

%% Cleanup
gSTIMboxreset(handle);
gSTIMboxclose(handle);
close(hFig);