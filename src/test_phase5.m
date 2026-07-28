% Phase 5: Real-Time GUI Simulation & Visualization
% EEE 4407 - Real-Time ECG Arrhythmia Detector
% Objective: Simulate real-time data streaming and visualize state transitions.

clear; clc; close all;

% Step 0: Load Data from Phase 4
if exist('phase4_workspace.mat', 'file')
    load('phase4_workspace.mat');
    fprintf('? Loaded detection parameters from Phase 4 workspace.\n');
else
    error('Error: phase4_workspace.mat not found. Please run Phases 1-4 first.');
end

% Data to stream
data_stream = test_data_simulated; 
states_stream = detected_states;
N = length(data_stream);

% Step 1: Build the GUI Interface with Improved Layout
fig = uifigure('Name', 'Real-Time ECG Arrhythmia Detector | EEE 4407', ...
    'Position', [100, 100, 1200, 800], 'Color', [0.95 0.95 0.95]);

% Title and Subtitle
uilabel(fig, 'Text', 'Real-Time ECG Arrhythmia Detector', ...
    'FontName', 'Arial', 'FontSize', 22, 'FontWeight', 'bold', ...
    'Position', [400, 720, 450, 30], 'HorizontalAlignment', 'center');

uilabel(fig, 'Text', 'EEE 4407: Random Signals and Processes - Stochastic Arrhythmia Detection', ...
    'FontName', 'Arial', 'FontSize', 12, ...
    'Position', [350, 695, 550, 20], 'HorizontalAlignment', 'center');

% ECG Axes
ax = uiaxes(fig, 'Position', [50, 350, 1100, 320]);
title(ax, 'Live R-R Interval Stream', 'FontSize', 14, 'FontWeight', 'bold');
xlabel(ax, 'Beat Index (n)', 'FontSize', 12);
ylabel(ax, 'R-R Interval (ms)', 'FontSize', 12);
grid(ax, 'on');
hold(ax, 'on');

y_min = min([lower_bound - 150, min(data_stream)]);
y_max = max([upper_bound + 150, max(data_stream)]);
ylim(ax, [y_min, y_max]);
xlim(ax, [0, N]);

% Threshold Lines
yline(ax, lower_bound, 'g--', sprintf('Lower 95%% CI: %.0f ms', lower_bound), ...
    'Color', 'g', 'LineWidth', 2);
yline(ax, upper_bound, 'g--', sprintf('Upper 95%% CI: %.0f ms', upper_bound), ...
    'Color', 'g', 'LineWidth', 2);
yline(ax, mu_train, 'k-', sprintf('Mean: %.0f ms', mu_train), ...
    'Color', 'k', 'LineWidth', 1.5);

% Status Panel
statusPanel = uipanel(fig, 'Title', 'System Status Dashboard', ...
    'Position', [50, 180, 1100, 150], 'BackgroundColor', 'w', ...
    'FontWeight', 'bold', 'FontSize', 12);

uilabel(statusPanel, 'Text', 'Status:', 'Position', [20, 90, 60, 25], 'FontWeight', 'bold');
lamp = uilamp(statusPanel, 'Position', [80, 85, 50, 50], 'Color', [0.8 0.8 0.8]);
status_text = uilabel(statusPanel, 'Text', 'SYSTEM READY', 'Position', [140, 95, 300, 25], ...
    'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');

uilabel(statusPanel, 'Text', 'Current R-R Interval:', 'Position', [480, 100, 140, 25], 'FontWeight', 'bold');
rr_label = uilabel(statusPanel, 'Text', '--- ms', 'Position', [630, 100, 100, 25], ...
    'FontSize', 16, 'FontWeight', 'bold');

uilabel(statusPanel, 'Text', 'Detected State:', 'Position', [480, 60, 140, 25], 'FontWeight', 'bold');
state_label = uilabel(statusPanel, 'Text', 'Waiting...', 'Position', [630, 60, 200, 25], ...
    'FontSize', 14, 'FontWeight', 'bold');

statsText = sprintf('Training Mean: %.1f ms\n95%% CI: [%.1f, %.1f] ms\nTest Beats: %d', ...
    mu_train, lower_bound, upper_bound, N);
uilabel(statusPanel, 'Text', statsText, 'Position', [850, 60, 230, 70], ...
    'FontSize', 11, 'HorizontalAlignment', 'left');

% Control Buttons
btn_start = uibutton(fig, 'Text', '? Start Real-Time Simulation', ...
    'Position', [50, 100, 280, 50], 'BackgroundColor', [0 0.6 0], ...
    'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold');

btn_reset = uibutton(fig, 'Text', ' Reset Simulation', ...
    'Position', [350, 100, 200, 50], 'BackgroundColor', [0.8 0.2 0.2], ...
    'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold');

uilabel(fig, 'Text', ['Simulation Speed: ~20 beats/sec | Red stars indicate arrhythmia detection | ', ...
    'Based on MIT-BIH Database Patient 100'], ...
    'Position', [50, 50, 800, 20], 'FontSize', 10);

% Step 2: Define Callbacks and Final Print Statements
% Assign callbacks
btn_start.ButtonPushedFcn = @(src, event) startSimulation();
btn_reset.ButtonPushedFcn = @(src, event) resetSimulation();

% IMPORTANT: All executable script code MUST end here. 
% Local functions MUST be at the very bottom of the file.
fprintf('\n===========================================\n');
fprintf('? PHASE 5 GUI LAUNCHED SUCCESSFULLY!\n');
fprintf('===========================================\n');
fprintf('The GUI is now open. Click "Start Real-Time Simulation" to begin.\n');

% Step 3: Local Functions (MUST BE AT THE VERY END OF THE FILE)

function startSimulation()
    btn_start.Enable = 'off';
    btn_reset.Enable = 'off';
    status_text.Text = 'STREAMING DATA...';
    status_text.Color = 'b';
    
    cla(ax);
    hold(ax, 'on');
    
    yline(ax, lower_bound, 'g--', sprintf('Lower 95%% CI: %.0f ms', lower_bound), 'Color', 'g', 'LineWidth', 2);
    yline(ax, upper_bound, 'g--', sprintf('Upper 95%% CI: %.0f ms', upper_bound), 'Color', 'g', 'LineWidth', 2);
    yline(ax, mu_train, 'k-', sprintf('Mean: %.0f ms', mu_train), 'Color', 'k', 'LineWidth', 1.5);
    
    h_normal = plot(ax, NaN, NaN, 'b.', 'MarkerSize', 15, 'DisplayName', 'Normal (H_0)');
    h_anomaly = plot(ax, NaN, NaN, 'r*', 'MarkerSize', 18, 'LineWidth', 2, 'DisplayName', 'Arrhythmia (H_1)');
    legend(ax, 'show', 'Location', 'best');
    
    x_data = []; 
    y_norm = []; 
    y_anom = [];
    anomaly_count = 0;
    
    for i = 1:N
        current_rr = data_stream(i);
        current_state = states_stream(i);
        
        x_data = [x_data, i];
        rr_label.Text = sprintf('%.2f ms', current_rr);
        
        if current_state == 1
            y_norm = [y_norm, current_rr];
            lamp.Color = [0 0.85 0]; 
            status_text.Text = '? NORMAL SINUS RHYTHM';
            status_text.Color = [0 0.6 0];
            state_label.Text = 'State 1: Normal (H_0 Accepted)';
            state_label.Color = 'b';
        else
            y_anom = [y_anom, current_rr];
            lamp.Color = [0.95 0 0]; 
            status_text.Text = ' ARRHYTHMIA DETECTED!';
            status_text.Color = [0.9 0 0];
            state_label.Text = 'State 2: Anomaly (H_1 - REJECTED)';
            state_label.Color = 'r';
            anomaly_count = anomaly_count + 1;
            drawnow;
            pause(0.3);
        end
        
        set(h_normal, 'XData', x_data, 'YData', y_norm);
        set(h_anomaly, 'XData', x_data, 'YData', y_anom);
        
        if i > 50
            xlim(ax, [i-50, i]);
        end
        
        drawnow; 
        pause(0.05); 
    end
    
    status_text.Text = '? SIMULATION COMPLETE';
    status_text.Color = 'k';
    lamp.Color = [0.8 0.8 0.8];
    rr_label.Text = sprintf('Total: %d beats', N);
    state_label.Text = sprintf('Arrhythmias Detected: %d (%.1f%%)', anomaly_count, (anomaly_count/N)*100);
    btn_start.Enable = 'on';
    btn_reset.Enable = 'on';
    
    fprintf('\n===========================================\n');
    fprintf('? SIMULATION COMPLETE\n');
    fprintf('===========================================\n');
    fprintf('Total beats processed: %d\n', N);
    fprintf('Arrhythmias detected: %d\n', anomaly_count);
end

function resetSimulation()
    cla(ax);
    hold(ax, 'on');
    
    yline(ax, lower_bound, 'g--', sprintf('Lower 95%% CI: %.0f ms', lower_bound), 'Color', 'g', 'LineWidth', 2);
    yline(ax, upper_bound, 'g--', sprintf('Upper 95%% CI: %.0f ms', upper_bound), 'Color', 'g', 'LineWidth', 2);
    yline(ax, mu_train, 'k-', sprintf('Mean: %.0f ms', mu_train), 'Color', 'k', 'LineWidth', 1.5);
    
    lamp.Color = [0.8 0.8 0.8];
    status_text.Text = 'SYSTEM READY';
    status_text.Color = [0 0.5 0];
    rr_label.Text = '--- ms';
    state_label.Text = 'Waiting...';
    state_label.Color = 'k';
    
    xlim(ax, [0, N]);
    ylim(ax, [y_min, y_max]);
    
    btn_start.Enable = 'on';
    btn_reset.Enable = 'on';
    
    fprintf('System reset. Ready for new simulation.\n');
end