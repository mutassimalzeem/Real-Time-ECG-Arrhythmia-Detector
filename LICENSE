%%  Phase 4: Hypothesis Testing & Markov Chains
%   Real-time anomaly detection via hypothesis testing and model cardiac
% state transitions using Markov Chains. - My Real Game Begins

if exist('phase3_workspace.mat', 'file')
    load('phase3_workspace.mat');
    fprintf('Loaded statistical baseline from phase 3 workspace')
else
    error('Error: phase3_workspace.mat not found. Please run phase 3 first');
end

%   Split Data - 80% for training and 20% for testing
length(rr_data)
split_idx = floor(length(rr_data) * 0.8);
train_data = rr_data(1:split_idx);
test_data = rr_data(split_idx + 1 : end );

mu_train = mean(train_data)
sigma_train = std(train_data)

% Define 95% Confidence Interval Bounds (Z-score = 1.96 for large N)
z_score = 1.96;
lower_bound = mu_train - (z_score * sigma_train);
upper_bound = mu_train + (z_score * sigma_train);

fprintf('Real-Time Decision Thresholds (95%% CI)\n');
fprintf('Lower Bound: %.2f ms', lower_bound);
fprintf('Upper Bound: %.2f ms', upper_bound);

%   Simulate Real-Time Arrythmia injection
%   Since patient 100 is healthy- we inject synthetic arrythmias into the
%   test set to validate our detection algorithm

test_data_simulated = test_data;

% Inject 3 anomalies:

% 1. Premature Ventricular Contraction (PVC) - Very short interval
test_data_simulated(10) = 400; 

% 2. Sinus Pause / Bradycardia - Very long interval
test_data_simulated(25) = 1500; 

% 3. Another PVC
test_data_simulated(40) = 350; 

fprintf('Injected 3 synthetic arrhythmias into the test stream.');

%%% Hypothesis Testing (Real-Time Detection) - For each incoming beat, test H0 (Normal) vs H1 (Arrhythmia).
% We classify each beat into State 1 (Normal) or State 2 (Arrhythmia).

num_test_beats = length(test_data_simulated)
detected_states = ones(1, num_test_beats);          % Initialize all as State 1 (Normal)
anomaly_indices = [];

for i = 1:num_test_beats
    current_rr = test_data_simulated(i);
    
    % Decision Rule: Reject H0 if outside bounds
    if current_rr < lower_bound || current_rr > upper_bound
        detected_states(i) = 2; % Flag as State 2 (Arrhythmia)
        anomaly_indices = [anomaly_indices, i];
    end
end

fprintf('Hypothesis Testing Results');
fprintf('Total beats tested: %d\n', num_test_beats);
fprintf('Arrhythmias detected: %d\n', length(anomaly_indices));
fprintf('Detected at indices: %s\n', num2str(anomaly_indices));

%   Markov Chain Transition Matrix Calculation
%   Calculate the empirical Transition Probability Matrix (TPM). - States: 1 = Normal, 2 = Arrhythmia
num_states = 2;
transition_counts = zeros(num_states, num_states); %    2x2

for i = 1:(num_test_beats - 1)
    from_state = detected_states(i);
    to_state = detected_states(i+1);
    transition_counts(from_state, to_state) = transition_counts(from_state, to_state) + 1;
end

% Normalize rows to get probabilities (P_ij)
% Note: If a row sum is 0 (e.g., we never entered State 2), handle division by zero
transition_counts
row_sums = sum(transition_counts, 2)
P = transition_counts ./ row_sums;
P(isnan(P)) = 0;                    % Replace NaN with 0 if a state was never exited - onno dataset er test case

fprintf('Markov Chain Transition Probability Matrix (P)');
fprintf('         To:     Normal   Arrhythmia\n');
fprintf('From Normal:    [%.4f,  %.4f]\n', P(1,1), P(1,2));
fprintf('From Arrhythm:  [%.4f,  %.4f]\n', P(2,1), P(2,2));

figure('Name', 'Hypothesis Testing & Markov Chains', 'Color', 'w', 'Position', [100, 100, 1400, 900]);

%   Plot 1: R-R Intervals with Detected Anomalies
subplot(2,2,[1, 3]);
beat_num = 1:num_test_beats;
normal_mask = detected_states == 1;
anomaly_mask = detected_states == 2;

%   Normal beats
stem(beat_num(normal_mask), test_data_simulated(normal_mask), 'b', 'filled', 'MarkerSize', 6);
hold on;

% Plot Anomalous beats
stem(beat_num(anomaly_mask), test_data_simulated(anomaly_mask), 'r', 'filled', 'MarkerSize', 8, 'LineWidth', 2);


%   Threshold Lines
yline(lower_bound, 'g--', sprintf('Lower 95%% CI: %.0f ms', lower_bound), 'LabelHorizontalAlignment', 'right');
yline(upper_bound, 'g--', sprintf('Upper 95%% CI: %.0f ms', upper_bound), 'LabelHorizontalAlignment', 'right');
yline(mu_train, 'k-', sprintf('Mean: %.0f ms', mu_train), 'LabelHorizontalAlignment', 'center');

hold off;
xlabel('Test Beat Index (n)');
ylabel('R-R Interval (ms)');
title('Real-Time Hypothesis Testing: Normal vs. Arrhythmia Detection');
legend('Normal (H_0)', 'Arrhythmia (H_1)', 'Location', 'best');
grid on;

%   Markov Chain Transition matrix
subplot(2, 2, 2);
imagesc(P);
colormap(flipud(hot));
colorbar;
title('Markov Chain Transition Probability Matrix');
xlabel('Next State')
ylabel('Current State')
set(gca, 'XTick', 1:2, 'XTickLabel', {'Normal', 'Arrhythmia'});
set(gca, 'YTick', 1:2, 'YTickLabel', {'Normal', 'Arrhythmia'});


for i = 1:2
    for j = 1:2
        text(j, i, sprintf('%.3f', P(i,j)), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold', ...
            'Color', 'k');
    end
end

% Plot 3: State Sequence Over Time
subplot(2,2,4);
stairs(beat_num, detected_states, 'b', 'LineWidth', 2);
hold on;
yline(1.5, 'k--', 'State Boundary');
hold off;
ylim([0.5 2.5]);
yticks([1, 2]);
yticklabels({'State 1: Normal', 'State 2: Arrhythmia'});
xlabel('Test Beat Index (n)');
ylabel('Physiological State');
title('Markov Chain State Transitions Over Time');
grid on;

%   Save Workspace
%% Step 5: Save Workspace for Phase 5
save('phase4_workspace.mat', 'test_data_simulated', 'detected_states', 'P', 'mu_train', 'sigma_train', 'lower_bound', 'upper_bound');

fprintf('Variables saved to: phase4_workspace.mat');
