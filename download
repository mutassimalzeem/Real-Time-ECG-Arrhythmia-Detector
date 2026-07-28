%%  Phase 3: Stochastic Modeling & WSS Verification
% Load Data from Phase 2
if exist('phase2_workspace.mat', 'file')
    load('phase2_workspace.mat');
    fprintf('Loaded R-R intervals from Phase 2 workspace.\n');
else
    error('Error: phase2_workspace.mat not found. Please run Phase 2 first.');
end

rr_data = rr_intervals_ms;
N = length(rr_data);
fprintf('Total R-R Interval extracted: %d\n', N)

%   Point Estimates and PDF Estimations
mu_hat = mean(rr_data);
var_hat = var(rr_data);
sigma_hat = std(rr_data);

%   Empirical PDF vs theoretical gaussian pdf
figure('Name', 'Phase 3: PDF Estimation', 'Color', 'w', 'Position', [100, 100, 1000, 600]);

empirical_pdf = histogram(rr_data, 'Normalization', 'pdf', 'FaceColor', [0.8 0.8 1], 'EdgeColor', 'b', 'BinWidth', 20);
hold on;

x_range = linspace(min(rr_data), max(rr_data), 1000);
gaussian_pdf = normpdf(x_range, mu_hat, sigma_hat);
plot(x_range, gaussian_pdf, 'r-', 'LineWidth', 2);

%   Confidence Level Intervals
alpha = 0.05;   %   95% CI
[mu_fit, sigma_fit, mu_ci, sigma_ci] = normfit(rr_data, alpha)

fprintf('\n--- 95%% Confidence Intervals ---\n');
fprintf('Mean CI: [%.4f, %.4f] ms\n', mu_ci(1), mu_ci(2));

% Add CI bounds to the PDF plot
xline(mu_ci(1), 'g--', sprintf('95%% CI Lower: %.2f', mu_ci(1)), 'LabelHorizontalAlignment', 'right', 'LineWidth', 1.5);
xline(mu_ci(2), 'g--', sprintf('95%% CI Upper: %.2f', mu_ci(2)), 'LabelHorizontalAlignment', 'left', 'LineWidth', 1.5);
xline(mu_hat, 'k-', sprintf('Mean: %.2f', mu_hat), 'LabelHorizontalAlignment', 'center', 'LineWidth', 1.5);

hold on;
xlabel('R-R Interval (ms)');
ylabel('Probability Density');
title('Empirical PDF vs. Theoretical Gaussian Distribution with 95% CI');
legend('Empirical PDF (Histogram)', 'Theoretical Gaussian', 'Location', 'best');
grid on;

%   Tesitng for WSS
k = 10;
window_size = floor(N / k);
window_means = zeros(1, k);

for i = 1:k
    start_idx = (i - 1) * window_size + 1;
    end_idx = i * window_size;
    window_means(i) = mean(rr_data(start_idx : end_idx));
end

figure('Name', 'WSS Verification (Constant Mean)', 'Color', 'w', 'Position', [100, 100, 1000, 500]);
plot(1:k, window_means, 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
yline(mu_hat, 'r--', sprintf('Global Mean: %.2f ms', mu_hat), 'LabelHorizontalAlignment', 'right', 'LineWidth', 1.5);
yline(mu_ci(1), 'g:', 'Lower CI', 'LabelHorizontalAlignment', 'right');
yline(mu_ci(2), 'g:', 'Upper CI', 'LabelHorizontalAlignment', 'right');
hold off;

xlabel('Time Window Index (k)');
ylabel('Mean R-R Interval (ms)');
title(sprintf('WSS Test 1: Mean Stability Across %d Time Windows', k));
grid on;
ylim([mu_hat - 3*sigma_hat, mu_hat + 3*sigma_hat]); % Zoom in to see variations

fprintf('WSS Test 1 (Constant Mean)');
fprintf('Max deviation from global mean: %.4f ms\n', max(abs(window_means - mu_hat)));

%   WSS Test 2- Autocorrelation
max_lag = 50;
zero_mean_rr = rr_data - mu_hat;

[acf, lags] = xcorr(zero_mean_rr, max_lag, 'normalized') ;   %   normalized Autocorrelation

figure('Name', 'WSS Verification (Autocorrelation)', 'Color', 'w', 'Position', [100, 100, 1000, 500]);
stem(lags, acf, 'filled', 'MarkerSize', 4, 'Color', 'b');
hold on;
yline(0, 'k-', 'LineWidth', 1);


% Add 95% confidence bounds for white noise (approx 1.96/sqrt(N))
noise_bound = 1.96 / sqrt(N);
yline(noise_bound, 'r--', '95% Noise Bound');
yline(-noise_bound, 'r--');
hold off;

xlabel('Lag (k beats)');
ylabel('Normalized Autocorrelation R_X[k]');
title('WSS Test 2: Autocorrelation Function of R-R Intervals');
grid on;
xlim([-max_lag max_lag]);

%   Save workspace
save('phase3_workspace.mat', 'rr_data', 'mu_hat', 'sigma_hat', 'var_hat', 'mu_ci', 'k', 'window_means');

fprintf('Variables saved to: phase3_workspace.mat');
fprintf('Statistical baseline established.');
fprintf('Ready to proceed to Phase 4: Hypothesis Testing & Markov Chains');
