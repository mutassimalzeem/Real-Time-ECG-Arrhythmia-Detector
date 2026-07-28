# User Manual & Tutorial

> A complete step-by-step guide to setting up, running, and understanding the Real-Time ECG Arrhythmia Detector pipeline.

---

## 1. Prerequisites Check

Before starting, ensure you have the following:

### 1.1 Software Requirements

| Software | Minimum Version | Recommended |
|----------|----------------|-------------|
| MATLAB | R2020b | R2023b or later |

### 1.2 Required Toolboxes

Open MATLAB and verify the toolboxes are installed:

```matlab
% Check Signal Processing Toolbox
ver('signal')

% Check Statistics and Machine Learning Toolbox
ver('stats')
```

If either toolbox is missing, install it via:
- **Home tab → Add-Ons → Get Add-Ons** → Search for the toolbox name

### 1.3 Download the Repository

```bash
git clone https://github.com/mutassimalzeem/Real-Time-ECG-Arrhythmia-Detector.git
```

Or download the ZIP and extract it to your preferred location.

---

## 2. Setting Up Your Workspace

### 2.1 Navigate to the Source Directory

Launch MATLAB and navigate to the `src/` folder:

```matlab
cd('path/to/Real-Time-ECG-Arrhythmia-Detector/src');
```

Or use the MATLAB Current Folder browser to navigate visually.

### 2.2 Verify Data Availability

Confirm that the ECG data file is accessible:

```matlab
% Check if data exists
if exist('../data/ecg_data/100.csv', 'file')
    disp('✓ ECG data file found.');
else
    error('✗ ECG data file NOT found. Check your data directory.');
end
```

### 2.3 Clean Previous Workspace (Optional)

If you are re-running the pipeline from scratch, clear previous workspace files:

```matlab
% Remove old workspace files from src/ directory
delete('phase1_workspace.mat');
delete('phase2_workspace.mat');
delete('phase3_workspace.mat');
delete('phase4_workspace.mat');
close all;
clc;
```

---

## 3. Running the Pipeline — Phase by Phase

### Phase 1: Data Loading & Visualization

**What it does**: Loads the MIT-BIH Record 100 CSV file, plots raw ECG signals from all leads, and generates noise characteristic analysis.

**How to run**:

```matlab
run('phase_01.m');
```

**Expected output in the Command Window**:

```
Available ECG Records:
1. 100.csv

Total Records: 1

Data Structure for 100.csv:
Table dimensions: 650000 rows x 3 columns

Column names:
    'sample #'    'MLII'    'V5'

ECG Lead Columns Found: V5

Statistical Summary - Lead V5:
Mean: 1010.xxxx mV
Standard Deviation: xxx.xxxx mV
Min: xxx.xxxx mV
Max: xxxx.xxxx mV
Total Samples: 650000
Duration: 1805.56 seconds
```

**Figures generated**:
1. **Raw ECG Signal** — Multi-panel plot showing first 10 seconds of each ECG lead
2. **Noise Analysis** — Amplitude histogram + Power Spectral Density (Welch's method)

**What to look for**:
- The ECG should show periodic QRS complexes (sharp spikes) at regular intervals
- The PSD should show dominant energy in the 5-15 Hz band (QRS complex frequency range)
- The histogram should be approximately bell-shaped around the baseline

**Workspace file saved**: `phase1_workspace.mat`

---

### Phase 2: Signal Processing & Feature Extraction

**What it does**: Applies a bandpass filter to remove noise, detects R-peaks in the filtered signal, and extracts R-R intervals.

**How to run**:

```matlab
run('phase_02.m');
```

**Expected output in the Command Window**:

```
Loaded variables from phase 1 workspace
BPF Applied (5 Hz - 15 Hz).
Detected XXX R-peaks.

First 10 R-R Intervals (ms):
812.45 805.56 798.33 810.00 ...

✓ PHASE 2 COMPLETED SUCCESSFULLY!
Variables saved to: phase2_workspace.mat
```

**Figures generated**:
1. **Filtered ECG with R-Peaks** — Bandpass-filtered signal with red markers on detected R-peaks (first 10 seconds)
2. **R-R Interval Sequence** — Stem plot of all R-R intervals with mean reference line

**What to look for**:
- The filtered signal should be cleaner than the raw signal with baseline wander removed
- Red triangle markers should align precisely with the QRS peaks
- R-R intervals should cluster around 700-900 ms (normal resting heart rate)
- The mean line should be around 750-850 ms for Record 100

**Workspace file saved**: `phase2_workspace.mat`

---

### Phase 3: Stochastic Modeling & WSS Verification

**What it does**: Estimates the Gaussian probability density function of R-R intervals, computes confidence intervals, and verifies the Wide Sense Stationarity assumption through two statistical tests.

**How to run**:

```matlab
run('phase_03.m');
```

**Expected output in the Command Window**:

```
Loaded R-R intervals from Phase 2 workspace.
Total R-R Interval extracted: XXXX

--- 95% Confidence Intervals ---
Mean CI: [xxx.xxxx, xxx.xxxx] ms

WSS Test 1 (Constant Mean)
Max deviation from global mean: x.xxxx ms

Variables saved to: phase3_workspace.mat
```

**Figures generated**:
1. **PDF Estimation** — Empirical histogram vs. theoretical Gaussian curve with 95% CI bounds
2. **WSS Mean Test** — Mean R-R across 10 time windows with global mean and CI reference lines
3. **WSS Autocorrelation** — Normalized ACF with 95% noise bounds

**What to look for**:
- The histogram should roughly follow the theoretical Gaussian curve
- In the WSS mean test, all window means should be close to the global mean (within ±2σ)
- The ACF should show a gradual decay from lag 0, indicating short-term heart rate variability
- The ACF values should mostly stay within the noise bounds for higher lags

**Workspace file saved**: `phase3_workspace.mat`

---

### Phase 4: Hypothesis Testing & Markov Chains

**What it does**: Splits data into training/test sets, injects synthetic arrhythmias into the test set, performs real-time binary hypothesis testing, and computes the Markov Chain transition probability matrix.

**How to run**:

```matlab
run('phase_04.m');
```

**Expected output in the Command Window**:

```
Loaded statistical baseline from phase 3 workspace
XXXX

mu_train = xxx.xxxx
sigma_train = xx.xxxx

Real-Time Decision Thresholds (95% CI)
Lower Bound: xxx.xx ms
Upper Bound: xxx.xx ms
Injected 3 synthetic arrhythmias into the test stream.

Hypothesis Testing Results
Total beats tested: XXX
Arrhythmias detected: X
Detected at indices: 10 25 40

Markov Chain Transition Probability Matrix (P)
         To:     Normal   Arrhythmia
From Normal:    [0.xxxx,  0.xxxx]
From Arrhythm:  [0.xxxx,  0.xxxx]

Variables saved to: phase4_workspace.mat
```

**Figures generated (single 2x2 subplot figure)**:
1. **Detection Results** — Stem plot with blue (normal) and red (anomaly) markers, plus threshold lines
2. **Transition Matrix Heatmap** — 2×2 color-coded TPM with probability values annotated
3. **State Sequence** — Staircase plot showing State 1/State 2 transitions over time

**What to look for**:
- Anomalies should be detected at indices 10, 25, and 40 (matching injected PVCs and bradycardia)
- The TPM should show P(1,1) close to 1.0 and P(2,1) close to 1.0 for healthy patient data
- The state sequence plot should show brief excursions to State 2 at the anomaly locations

**Workspace file saved**: `phase4_workspace.mat`

---

### Phase 5: Real-Time GUI Simulation

**What it does**: Launches an interactive GUI that simulates real-time ECG monitoring with live beat-by-beat arrhythmia detection.

**How to run** (two options):

```matlab
% Option A: Function variant (RECOMMENDED)
phase5_realtime_gui()

% Option B: Script variant (for debugging)
run('test_phase5.m');
```

**Using the GUI**:

1. When the GUI opens, you will see:
   - A large plot area (top) showing threshold lines and an empty R-R interval stream
   - A status dashboard (middle) showing system status, current R-R interval, and detection state
   - A start button (green) and a reset button (red) at the bottom

2. Click the **Start Real-Time Simulation** button to begin

3. Watch the simulation:
   - Blue dots appear for normal beats
   - Red stars appear with a brief pause for detected arrhythmias
   - The status lamp turns green for normal rhythm and red for anomalies
   - The plot auto-scrolls to show the most recent 50 beats

4. When the simulation completes, the status dashboard shows a summary:
   - Total beats processed
   - Number of arrhythmias detected
   - Detection percentage

5. Click **Reset** to clear the plot and run the simulation again

**Expected final console output**:

```
===========================================
✓ SIMULATION COMPLETE
===========================================
Total beats processed: XXX
Arrhythmias detected: X
```

---

## 4. Troubleshooting

### Common Issues and Solutions

#### Issue 1: `phase2_workspace.mat not found`

```
Error: phase2_workspace.mat not found. Please run Phase 2 first.
```

**Solution**: Run the phases in sequential order (Phase 1 → 2 → 3 → 4 → 5). Each phase depends on the workspace file generated by the previous phase.

#### Issue 2: `butter` or `filtfilt` undefined

```
Undefined function 'butter' for input arguments of type 'double'.
```

**Solution**: Install the **Signal Processing Toolbox** from the Add-Ons explorer.

#### Issue 3: `normfit` undefined

```
Undefined function 'normfit' for input arguments of type 'double'.
```

**Solution**: Install the **Statistics and Machine Learning Toolbox** from the Add-Ons explorer.

#### Issue 4: CSV file not found

```
Error using readtable: Unable to open file 'ecg_data/100.csv'.
```

**Solution**: Ensure you are running the scripts from the `src/` directory, and that the `data/ecg_data/100.csv` file exists. You may need to adjust the file path in `phase_01.m` or copy the CSV into the correct location.

#### Issue 5: GUI does not display properly

**Solution**: 
- Ensure you are using MATLAB R2020b or later (uifigure requires it)
- Close all existing figure windows before running: `close all`
- If the function variant fails, try the script variant: `run('test_phase5.m')`

#### Issue 6: Fewer R-peaks detected than expected

**Possible causes**:
- The CSV data may have different column names than expected
- The signal quality may be poor in certain segments

**Solution**: Check the column names by printing `patient_data.Properties.VariableNames` and verify the ECG signal looks correct in the Phase 1 plots.

---

## 5. Modifying Parameters

### 5.1 Changing the Patient Record

To use a different MIT-BIH record, modify `phase_01.m`:

```matlab
% Change this line:
patient_file = '100.csv';

% To (for example):
patient_file = '101.csv';
```

Place the new CSV file in the `data/ecg_data/` directory.

### 5.2 Adjusting Filter Parameters

In `phase_02.m`, modify the bandpass filter cutoff frequencies:

```matlab
low_cutoff = 5;   % Lower cutoff (Hz) — increase to remove more baseline wander
high_cutoff = 15;  % Upper cutoff (Hz) — decrease to remove more high-freq noise
```

### 5.3 Changing Detection Sensitivity

In `phase_04.m`, modify the confidence level:

```matlab
% More sensitive (more detections, more false positives):
z_score = 1.645;   % 90% CI

% Standard (recommended):
z_score = 1.96;    % 95% CI

% Less sensitive (fewer detections, fewer false positives):
z_score = 2.576;   % 99% CI
```

### 5.4 Changing Injection Points

In `phase_04.m`, modify the synthetic arrhythmia injections:

```matlab
% Change the index and value to test different scenarios
test_data_simulated(10) = 400;    % Index 10, PVC at 400ms
test_data_simulated(25) = 1500;   % Index 25, Bradycardia at 1500ms
test_data_simulated(40) = 350;    % Index 40, PVC at 350ms
```

---

## 6. Understanding the Output

### 6.1 Key Performance Indicators

After running Phase 4, evaluate the detection performance:

| Metric | How to Compute | Expected Value |
|--------|---------------|----------------|
| Detection Rate | detected anomalies / injected anomalies | 3/3 = 100% |
| False Positive Rate | false alarms / total normal beats | Should be < 5% (matches α = 0.05) |
| P(Normal → Normal) | P(1,1) from TPM | Should be > 0.95 |
| P(Arrhythmia → Normal) | P(2,1) from TPM | Should be > 0.90 (recovery) |

### 6.2 Interpreting the Markov Chain TPM

```
         To:     Normal    Arrhythmia
From Normal:    [ 0.9834,   0.0166   ]
From Arrhythm:  [ 1.0000,   0.0000   ]
```

- **P(1,1) = 0.98**: 98% of normal beats are followed by another normal beat (high stability)
- **P(1,2) = 0.02**: 2% chance of transitioning from normal to arrhythmia per beat
- **P(2,1) = 1.00**: 100% recovery rate — every arrhythmia is followed by a normal beat
- **P(2,2) = 0.00**: No sustained arrhythmia events (expected for injected single-point anomalies)

---

## 7. Tips for Best Results

1. **Always run phases in order** — Each phase depends on workspace data from the previous one
2. **Close figures between runs** — Use `close all` before re-running to prevent memory buildup
3. **Inspect each phase's output** — Don't skip ahead; verify each stage produces reasonable results
4. **Use the fallback mechanism** — If workspace files are lost, Phase 2-4 can reload from CSV automatically
5. **Save your figures** — Right-click on any figure → Save As → PNG/PDF for reports
6. **Document modifications** — Keep track of any parameter changes for reproducibility
