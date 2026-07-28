%%  Phase 2: Signal Processing and Feature Extraction
if exist('phase1_workspace.mat', 'file')
    load('phase1_workspace.mat');
    fprintf("Loaded variables from phase 1 workspace")
else
    %   Fallback
    data_folder = 'ecg_data';
    patient_file = '100.csv';
    patient_data = readtable(fullfile(data_folder, patient_file));
    
    % Extract the primary ECG lead (Assuming column 'V5' or the one with highest variance)
    col_names = patient_data.Properties.VariableNames;
    ecg_columns = contains(col_names, 'V');
    ecg_signal_names = col_names(ecg_columns);
    ecg_signal = patient_data.(ecg_signal_names{1}); 
    
    fs = 360; % Sampling frequency for MIT-BIH
    fprintf(' Fallback: Loaded data directly from CSV.\n');   
end

%   BandPass Filtering - Noise Removal
%   QRS complex energy is centered between 5 Hz to 15 Hz

nyquist_freq = fs / 2;
low_cutoff = 5;
high_cutoff = 15;

Wn = [low_cutoff, high_cutoff] / nyquist_freq   %   Normalization

%   Filter design
[b, a] = butter(2, Wn, 'bandpass')  % 2nd order BPF

filtered_ecg = filtfilt(b, a, patient_data.(ecg_signal_names{1}))

fprintf("BPF Applied (5 Hz - 15 Hz).\n");

%   R-R Peak Detection

%%  We must ignore T-waves and noise. 
% 1. MinPeakDistance: Human heart max rate ~220 bpm. 
%    (60 sec / 220 bpm) * 360 Hz ? 98 samples. We use 108 for safety (~200 bpm).
% 2. MinPeakProminence: The peak must stand out from the baseline.

min_distance_samples = 108; 


% Adaptive prominence: 50% of the signal's peak-to-peak amplitude
adaptive_prominence = 0.15 * (max(filtered_ecg) - min(filtered_ecg))

% Find peaks
[pks, locs] = findpeaks(filtered_ecg, ...
    'MinPeakDistance', min_distance_samples, ...
    'MinPeakProminence', adaptive_prominence);

fprintf('Detected %d R-peaks.\n', length(locs));

rr_intervals_samples = diff(locs);
rr_intervals_sec = rr_intervals_samples / fs;
rr_intervals_ms = rr_intervals_sec * 1000;   %   Clinically standard unit

% Display first 10 R-R intervals in the command window
fprintf('\nFirst 10 R-R Intervals (ms):\n');
fprintf('%.2f ', rr_intervals_ms(1:10));
fprintf('\n\n');

%%  Visualization

% --- Figure 1: Filtered ECG with Detected R-Peaks ---
figure('Name', 'Phase 2: R-Peak Detection', 'Color', 'w', 'Position', [100, 100, 1200, 800]);

subplot(2,1,1);
% Plot first 10 seconds for clear visualization
time_axis = (0:length(filtered_ecg)-1) / fs;
plot_window = 10; 
samples_to_plot = min(fs * plot_window, length(filtered_ecg));

plot(time_axis(1:samples_to_plot), filtered_ecg(1:samples_to_plot), 'b-', 'LineWidth', 1);
hold on;

% Overlay detected peaks (only those within the 10s window)
peaks_in_window = locs <= samples_to_plot;
plot(time_axis(locs(peaks_in_window)), pks(peaks_in_window), 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

hold off;
xlabel('Time (seconds)');
ylabel('Amplitude (Filtered)');
title(sprintf('Bandpass Filtered ECG (First %d seconds) with Detected R-Peaks', plot_window));
legend('Filtered ECG', 'Detected R-Peaks', 'Location', 'best');
grid on;
xlim([0 plot_window]);

% --- Figure 2: R-R Interval Random Sequence ---
subplot(2,1,2);
beat_number = 1:length(rr_intervals_ms);

stem(beat_number, rr_intervals_ms, 'filled', 'MarkerSize', 4, 'Color', 'b');
xlabel('Beat Number (n)');
ylabel('R-R Interval (ms)');
title('R-R Interval Random Sequence (Time-Domain)');
grid on;

% Add mean line for visual reference
mean_rr = mean(rr_intervals_ms);
yline(mean_rr, 'r--', sprintf('Mean: %.2f ms', mean_rr), 'LabelHorizontalAlignment', 'right');

%% Save Workspace for Phase 3
save('phase2_workspace.mat', 'filtered_ecg', 'locs', 'pks', 'rr_intervals_sec', 'rr_intervals_ms', 'fs');


fprintf('? PHASE 2 COMPLETED SUCCESSFULLY!\n');
fprintf('Variables saved to: phase2_workspace.mat\n');
