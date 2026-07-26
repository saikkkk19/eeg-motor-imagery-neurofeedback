%　HG帯域検出のための比較用刺激提示
% 刺激提示までの時間一定

% Ver.2 : TrialDuration 　8　→　9  
% Ver.3 : fixation cross +0.5[s]

% HITACHI NIRS Experiment control program
% Revised version of Reini's code
 

%% PARADIGM DEFINITION

% 実験条件
NoTrial           = 2;              % number of trials per class,試行回数
Classlabel        = [1 2];        % index number of classes,矢印の向きの指定（1が左2が右3が下）,[1 2 3]で全て
Label             = 'ABC';          % index label of classes
RandomizedOrder   = 0;              % 1: randomize, 0: not random,矢印の向きをランダムにするかどうか,1:random,0:not random
DelayBefore       = 5;              % delay time before session [s],最初のタスクの前の安静時間
DelayAfter        = 5;              % delay time after session [s], すべて終わってから消えるまでの時間
PreparationLen    = 3;
TaskLen           = 3;
RestLen           = 4;
RandomPeriod      = 0;              % maximum ITI (random) [s],セッション間のインターバル
CrossPeriod       = [0 6]; % period of presenting corss [s s],十字が大きくなっている時間
CuePeriod         = [3 4.25]; % period of presenting cue [s s],矢印が表示されている時間

% 
UseSerialPort     = -1;             % 1: serial port, -1: NIDAQ card, 0: None , 出力場所、シールドルームのディスプレイは-1
SerialPort        = 'COM5';         % serial port id
BaudRate          = 9600;           % Buad rate

DAQAdaptor        = 'Dev1';         % DAQ card index

%% LSLの設定
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

inst = instrfind('Type', 'serial');
if ~isempty(inst)
    fclose(inst);
end

rand('state',sum(100*clock))

Fs = 8192;
beep = sin(0:2*pi*1000/Fs:2*pi*1000*0.1)*0.2;
p = audioplayer(beep, Fs);

% classlabels
% -------------

classlabel = repmat(Classlabel, 1, NoTrial);
if RandomizedOrder
    classlabel = classlabel(randperm(length(classlabel)));
end

save 'Label.mat' classlabel

% figure,図の作成
% ------
hFig = figure('menubar', 'none', 'units', 'normalized', 'position', [0 0 1 1], 'color', 'k'); % 黒の平面作成
axes('position', [0, 0, 1, 1], 'color', 'k')
axis off % 軸は非表示
xlim([-1 1]);
ylim([-1 1]);

% create arrows
% -------------
ArrowLen    = 0.5;
AspectRatio = 2560/1440; % ディスプレイとの比率

% fixation cross
% --------------
fixCrossLen = 0.05;
fixCross1 = line([-fixCrossLen/AspectRatio +fixCrossLen/AspectRatio], [0 0], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');
fixCross2 = line([0 0], [-fixCrossLen +fixCrossLen], 'Color', [.5 .5 .5], ...
    'LineWidth', 1, 'visible', 'on');

x = [ 0  .9 .9 1 .9 .9 0 0] * ArrowLen;
y = [.02  .02 .04 0 -.04 -.02 -.02 .02];                   
% 矢印の向きの設定
hArrow(1) = patch(-x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');      % visible offだから表示はせずメモリに保存
hArrow(2) = patch( x/AspectRatio,  y, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(3) = patch( y/AspectRatio,  -x, 'r', 'EdgeColor', 'none', 'visible', 'off');
hArrow(4) = patch(-x/AspectRatio,  y, 'b', 'EdgeColor', 'none', 'visible', 'off');
hArrow(5) = patch( x/AspectRatio,  y, 'b', 'EdgeColor', 'none', 'visible', 'off');
hArrow(6) = patch( y/AspectRatio,  -x, 'b', 'EdgeColor', 'none', 'visible', 'off');

% fixation cross
% --------------
CrossLen = 0.2;
hCross(1) = line([-CrossLen/AspectRatio +CrossLen/AspectRatio], [0 0], 'Color', 'w', ...
    'LineWidth', 3, 'visible', 'off');
hCross(2) = line([0 0], [-CrossLen +CrossLen], 'Color', 'w', ...
    'LineWidth', 3, 'visible', 'off');

%ランダムの部分
% --------------
num_A = NoTrial/2;  % Half of total trials for each class
num_B = NoTrial/2;  % Half of total trials for each class

% Aを1、Bを0で表現
labels = [repmat(1, num_A, 1); repmat(0, num_B, 1)];

% ランダムにシャッフル
shuffled_labels = labels(randperm(length(labels)));
T = shuffled_labels;

% Create alternating sequence of 1 and 2 for the specified number of trials
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
 
    % lsl marker 4 (g.stim 11 -> string 4)
    outlet.push_sample({'4'});
    
    if UseSerialPort == 1
        fprintf(ser, '%c \r', Label(classlabel(n)));
    elseif UseSerialPort == -1
        % Removed gSTIMbox trigger
    end

    pause(0.1);
       
    pause(PreparationLen-0.1)
    
    %% Task Period
if shuffled_labels(1,:) == 1
%右手首%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%righthand%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%A8
targetDuration = CuePeriod(2)-CuePeriod(1);  %途中で矢印を消す

    % lsl marker 4 (g.stim 12 -> string 8)
    outlet.push_sample({'8'});

    if UseSerialPort == 1
        fprintf(ser, '%c \r', Label(classlabel(n)));
    elseif UseSerialPort == -1
        % Removed gSTIMbox trigger
        end
   
    set(hArrow(classlabel(2)), 'Visible', 'on');
    startTime = tic;    
    counter = 0;
    
    while toc(startTime) < targetDuration
        % Removed tactile stimulation
        pause(0.01);
        counter = counter + 1;
    end
    

 targetDuration = CrossPeriod(2)-CuePeriod(2);  % ループを回す秒数（例：10秒）
    set(hArrow(classlabel(2)), 'Visible', 'off');  
            
    startTime = tic;    
    counter = 0;
    while toc(startTime) < targetDuration 
        % Removed tactile stimulation
        pause(0.01);
    end

  
elseif shuffled_labels(1,:) == 2
% 左手首%%%%%%%%%%%%%%%%lefthand%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%B16

targetDuration = CuePeriod(2)-CuePeriod(1);  %途中で矢印を消す

    % lsl marker 4 (g.stim 13 -> string 16)
    outlet.push_sample({'16'});

    if UseSerialPort == 1
        fprintf(ser, '%c \r', Label(classlabel(n)));
    elseif UseSerialPort == -1
        % Removed gSTIMbox trigger
        end
   
    set(hArrow(classlabel(1)), 'Visible', 'on');
    startTime = tic;    
    counter = 0;
    
    while toc(startTime) < targetDuration
        % Removed tactile stimulation
        pause(0.01);
        counter = counter + 1;
    end
    

 targetDuration = CrossPeriod(2)-CuePeriod(2);  % ループを回す秒数（例：10秒）

    set(hArrow(classlabel(1)), 'Visible', 'off');  
            
    startTime = tic;    
    counter = 0;
    while toc(startTime) < targetDuration 
        % Removed tactile stimulation
        pause(0.01);
    end
end

shuffled_labels(1,:) = [];

    %% Rest Period
    set(hCross, 'Visible', 'off');

    % lsl marker 4 (g.stim 14 -> string 32)
    outlet.push_sample({'32'});
    
    if UseSerialPort == 1
        fprintf(ser, '%c \r', Label(classlabel(n)));
    elseif UseSerialPort == -1
        % Removed gSTIMbox trigger
    end

    pause(0.1);
    
    pause(RestLen+RandomPeriod-0.1);

    %% giving feedback
    
    a = "feedback"
    [mrks,ts] = inlet.pull_chunk();
    mrks

    % Feedback visualization setup
    feedbackCrossLen = 0.1;
    % Calculate position 7cm from top right corner
    % Assuming screen is 2560x1440 pixels (from AspectRatio)
    % Convert 7cm to normalized coordinates
    screenWidth_cm = 60; % Assuming 60cm screen width
    screenHeight_cm = 33.75; % Assuming 33.75cm screen height (maintaining 16:9 aspect ratio)
    x_offset = 25/screenWidth_cm; % Convert 7cm to normalized x coordinate
    y_offset = 25/screenHeight_cm; % Convert 7cm to normalized y coordinate
    
    % Position feedback elements 7cm from top right corner
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

    % Process feedback marker
    if ~isempty(mrks)
        feedback_marker = mrks;  % Directly use the scalar value
        disp(['Feedback marker received: ' num2str(feedback_marker)]);
        
        % Show feedback based on marker
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