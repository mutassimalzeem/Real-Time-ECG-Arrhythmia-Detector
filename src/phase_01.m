%%  Phase 1: Data Loading and Visualization
%unzip('archive.zip', 'ecg_data');

csv_files = dir(fullfile('ecg_data', '*.csv'));

fprintf("Available ECG Records:\n");

for i = 1:length(csv_files)
    fprintf('%d. %s\n', i, csv_files(i).name);
end

fprintf("\nTotal Records: %d\n\n", length(csv_files));

patient_file = '100.csv'; 
patient_data = readtable(fullfile(csv_files(1).folder , patient_file))

fprintf('Data Structure for %s:\n', patient_file);
fprintf('Table dimensions: %d rows x %d columns\n', ...
    height(patient_data), width(patient_data));
fprintf('\nColumn names:\n');
disp(patient_data.Properties.VariableNames');

col_names = patient_data.Properties.VariableNames;

%   Find ECG signal columns
ecg_columns = contains(col_names, 'V');
ecg_signal_names = col_names(ecg_columns);  %   x_V5_
fprintf('\nECG Lead Columns Found: %s\n', strjoin(ecg_signal_names))

%   Plot RAW ECG dignals
figure('Name', 'Raw ECG Signal - Patient 100', 'Color', 'w', 'Position', [100, 100, 1200, 800]);

num_leads = length(ecg_signal_names);
for i = 1:num_leads
    subplot(num_leads, 1, i);
    
    signal = patient_data.(ecg_signal_names{i});
    
    %   Time axis - Sampling rate 360 Hz for this dataset
    fs = 360;
    time = (0:length(signal)-1) / fs;
    
    plot_window = 10;
    samples_to_plot = min(fs * plot_window, length(signal));
    
    plot(time(1:samples_to_plot), signal(1:samples_to_plot), 'b-', 'LineWidth', 1);
    xlabel('Time (seconds)');
    ylabel('Amplitude (mV)');
    %title(sprintf('Raw ECG Signal - Lead %s (First %d seconds)', ...
        %extractBetween(ecg_signal_names{i}, 'V', ''), plot_window));
    grid on;
    xlim([0 plot_window]);
    
end

sgtitle(sprintf('MIT-BIH Database - Patient 100: Raw ECG Signals (%d Leads)', num_leads), ...
    'FontSize', 14, 'FontWeight', 'bold')

fprintf('\nStatistical Summary - Lead %s:\n', ecg_signal_names{1});

first_lead = patient_data.(ecg_signal_names{1});
fprintf('Mean: %.4f mV\n', mean(first_lead));
fprintf('Standard Deviation: %.4f mV\n', std(first_lead));
fprintf('Min: %.4f mV\n', min(first_lead));
fprintf('Max: %.4f mV\n', max(first_lead));
fprintf('Total Samples: %d\n', length(first_lead));
fprintf('Duration: %.2f seconds\n', length(first_lead)/fs);

%% Step 8: Visualize noise characteristics
figure('Name', 'Noise Analysis - Raw Signal', 'Color', 'w', 'Position', [100, 100, 1000, 600]);

subplot(2,1,1);
histogram(first_lead, 50, 'FaceColor', 'blue', 'EdgeColor', 'black');
xlabel('Amplitude (mV)');
ylabel('Frequency');
title('Histogram of ECG Amplitude Values');
grid on;

subplot(2,1,2);
% Plot power spectral density to see frequency components
pwelch(first_lead, [], [], [], fs);
title('Power Spectral Density - Identifying Noise Frequencies');

%% Step 9: Save variables to workspace for next phase
% Save the loaded data for use in Phase 2
save('phase1_workspace.mat', 'patient_data', 'ecg_signal_names', 'fs');
