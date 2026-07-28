# System Architecture Documentation

> Comprehensive technical documentation for the Real-Time ECG Arrhythmia Detector pipeline, including mathematical foundations, algorithm specifications, data flow, and design decisions.

---

## 1. Introduction

This document provides an in-depth technical description of every component in the ECG Arrhythmia Detection pipeline. The system is designed as a five-phase sequential processing chain, where each phase consumes the output of its predecessor and produces structured workspace data for the next stage. The architecture follows classical digital signal processing principles combined with statistical decision theory, making it both educationally rigorous and practically applicable.

The design philosophy prioritizes **traceability** — every transformation applied to the ECG signal is visualized and quantified, ensuring that the pipeline's behavior can be inspected, debugged, and validated at each stage. This is critical for biomedical signal processing where incorrect filtering or detection parameters can lead to clinically dangerous false negatives.

---

## 2. Data Source: MIT-BIH Arrhythmia Database

### 2.1 Database Overview

The MIT-BIH Arrhythmia Database is the gold-standard benchmark dataset for ECG signal analysis, maintained by PhysioNet. It contains 48 half-hour ambulatory ECG recordings from 47 subjects (records 201 and 202 come from the same patient), digitized at 360 samples per second per channel with 11-bit resolution over a 10 mV range.

### 2.2 Record 100 — Selected Patient

This project uses **Record 100**, which contains two ECG leads:
- **MLII** (Modified Lead II) — the primary lead used for analysis
- **V5** (Precordial Lead V5) — secondary lead for reference

Record 100 was specifically chosen because it predominantly contains **normal sinus rhythm** with occasional premature ventricular contractions (PVCs), making it ideal for establishing a statistical baseline and then testing anomaly detection against known deviations.

### 2.3 Data Format

The CSV file has the following structure:

| Column | Description | Range |
|--------|-------------|-------|
| `sample #` | Sequential sample index | 0 to ~649,999 |
| `MLII` | Modified Lead II amplitude | Integer ADC units |
| `V5` | Precordial V5 amplitude | Integer ADC units |

- **Sampling Frequency (fs)**: 360 Hz
- **Total Duration**: ~30 minutes (650,000 samples / 360 Hz ≈ 1805 seconds)
- **Data Type**: Integer-valued ADC samples (not yet converted to millivolts)

### 2.4 Data Loading Strategy

The system identifies ECG signal columns dynamically by searching for column names containing the character `'V'` using MATLAB's `contains()` function. This design choice makes the pipeline adaptable to different MIT-BIH records that may have different lead configurations (e.g., some records have V1 instead of V5).

```matlab
col_names = patient_data.Properties.VariableNames;
ecg_columns = contains(col_names, 'V');
ecg_signal_names = col_names(ecg_columns);
```

---

## 3. Phase 1: Data Loading & Visualization

### 3.1 Purpose

Establish data provenance, validate data integrity, and perform exploratory analysis on the raw ECG signal before any transformations are applied.

### 3.2 Operations

1. **File Discovery**: Scans the `ecg_data/` directory for all `.csv` files and lists available records
2. **Data Ingestion**: Loads the specified patient record into a MATLAB table using `readtable()`
3. **Multi-Lead Visualization**: Generates subplot figure with one panel per ECG lead (10-second window)
4. **Statistical Summary**: Computes mean, standard deviation, min, max, and total duration
5. **Noise Characterization**:
   - **Amplitude Histogram**: 50-bin histogram to observe signal amplitude distribution
   - **Power Spectral Density**: Welch's method (`pwelch`) to identify dominant frequency components and noise bands

### 3.3 Design Decisions

- **10-second plot window**: Chosen to display approximately 7-10 heartbeats, which is sufficient for visual inspection without overwhelming the display
- **V-lead column detection**: Dynamic detection rather than hardcoded column names ensures portability across different MIT-BIH records
- **Statistical summary on first lead only**: The MLII lead is the standard primary lead for arrhythmia analysis

### 3.4 Output Data

| Variable | Type | Description |
|----------|------|-------------|
| `patient_data` | Table | Full raw ECG dataset for all leads |
| `ecg_signal_names` | Cell array | Names of identified ECG lead columns |
| `fs` | Scalar (360) | Sampling frequency in Hz |

---

## 4. Phase 2: Signal Processing & Feature Extraction

### 4.1 Purpose

Remove noise artifacts from the raw ECG and extract the clinically relevant feature — the R-R interval time series — which forms the stochastic process analyzed in subsequent phases.

### 4.2 Bandpass Filter Design

The QRS complex, which contains the R-peak used for heartbeat detection, has its primary energy concentrated between **5 Hz and 15 Hz**. The filter is designed as follows:

```
Filter Type:     2nd-order Butterworth Bandpass
Passband:        5 Hz - 15 Hz
Sampling Rate:   360 Hz
Nyquist:         180 Hz
Normalized Wn:   [5/180, 15/180] = [0.0278, 0.0833]
Implementation:  filtfilt() — Zero-phase digital filtering
```

**Why Butterworth?** The Butterworth filter provides a maximally flat passband response, meaning it introduces minimal distortion to the QRS morphology within the passband. A 2nd-order design provides sufficient roll-off (12 dB/octave) to attenuate baseline wander (< 0.5 Hz) and high-frequency noise (> 40 Hz) without excessive ringing artifacts that higher-order filters produce.

**Why filtfilt()?** Standard `filter()` introduces a phase delay that shifts the R-peak locations in time. `filtfilt()` applies the filter forward and backward, resulting in zero net phase distortion. This is critical because R-peak location accuracy directly affects R-R interval computation accuracy.

### 4.3 R-Peak Detection Algorithm

The R-peak detection uses MATLAB's `findpeaks()` with two physiologically informed constraints:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `MinPeakDistance` | 108 samples | Corresponds to 300 ms (200 bpm max heart rate). The maximum recorded human heart rate is ~220 bpm; using 200 bpm provides a safety margin |
| `MinPeakProminence` | 0.15 × peak-to-peak | Adaptive threshold: 15% of the signal's peak-to-peak amplitude. This adapts to signal quality — cleaner signals get higher thresholds, noisier signals get lower ones |

**Prominence vs. Height**: The algorithm uses prominence rather than absolute height to distinguish R-peaks from T-waves and noise. Prominence measures how much a peak stands out from the surrounding baseline, making it robust against baseline wander that would defeat a fixed-height threshold.

### 4.4 R-R Interval Extraction

After peak detection, the R-R intervals are computed as the first difference of peak locations:

```
rr_intervals_samples = diff(locs)         // In samples
rr_intervals_sec     = rr / fs           // In seconds
rr_intervals_ms      = rr_sec × 1000    // In milliseconds (clinical standard)
```

### 4.5 Output Data

| Variable | Type | Description |
|----------|------|-------------|
| `filtered_ecg` | Vector | Bandpass-filtered ECG signal |
| `locs` | Vector | Sample indices of detected R-peaks |
| `pks` | Vector | Amplitude values at detected R-peaks |
| `rr_intervals_sec` | Vector | R-R intervals in seconds |
| `rr_intervals_ms` | Vector | R-R intervals in milliseconds |
| `fs` | Scalar | Sampling frequency |

---

## 5. Phase 3: Stochastic Modeling & WSS Verification

### 5.1 Purpose

Model the R-R interval sequence as a stochastic process and verify that it satisfies the Wide Sense Stationarity (WSS) assumption required for the hypothesis testing framework in Phase 4. If the process is not WSS, the estimated mean and variance would not be reliable decision thresholds.

### 5.2 Gaussian PDF Estimation

The R-R intervals are modeled as a Gaussian (normal) random process:

```
X[n] ~ N(μ, σ²)

Point Estimates:
  μ̂  = (1/N) Σ X[n]           (Sample Mean)
  σ̂² = (1/(N-1)) Σ (X[n]-μ̂)²  (Sample Variance)
```

The 95% confidence intervals for the mean are computed using `normfit()`:

```
CI: [μ̂ - z × σ̂/√N,  μ̂ + z × σ̂/√N]    where z = 1.96
```

The empirical PDF (histogram with PDF normalization) is overlaid with the theoretical Gaussian PDF for visual validation of the normality assumption.

### 5.3 WSS Verification — Test 1: Mean Stability

The data is divided into k=10 equal-length time windows. The mean of each window is computed and plotted against the global mean:

```
window_means[i] = mean(rr_data[(i-1)×W + 1 : i×W])

where W = floor(N/k)
```

**Pass Criterion**: All window means should fall within ±2σ of the global mean, indicating that the mean is approximately constant over time — a necessary condition for WSS.

### 5.4 WSS Verification — Test 2: Autocorrelation Function

The normalized autocorrelation function (ACF) is computed using `xcorr()`:

```
R_X[k] = (1/N) Σ (X[n] - μ̂)(X[n+k] - μ̂)

Normalized: ρ_X[k] = R_X[k] / R_X[0]
```

The ACF is computed up to lag 50 beats. The 95% white noise confidence bounds are plotted at ±1.96/√N:

```
If |ρ_X[k]| < 1.96/√N for all k > 0  →  Process resembles white noise
If ρ_X[k] shows slow decay              →  Process has memory/autocorrelation
```

For healthy cardiac rhythm, the ACF typically shows a gradual decay, indicating short-term heart rate variability (a known physiological phenomenon).

### 5.5 Output Data

| Variable | Type | Description |
|----------|------|-------------|
| `rr_data` | Vector | R-R intervals in milliseconds |
| `mu_hat` | Scalar | Sample mean of R-R intervals |
| `sigma_hat` | Scalar | Sample standard deviation |
| `var_hat` | Scalar | Sample variance |
| `mu_ci` | Vector [2×1] | 95% confidence interval bounds |
| `window_means` | Vector [1×10] | Mean of each time window for WSS test |

---

## 6. Phase 4: Hypothesis Testing & Markov Chains

### 6.1 Purpose

Implement the core decision-making engine that classifies each incoming heartbeat as either Normal (H₀ accepted) or Arrhythmia (H₀ rejected), then model the state transition dynamics using a Markov chain.

### 6.2 Train/Test Split

The data is split 80/20 to simulate a realistic deployment scenario:

```
split_idx = floor(N × 0.8)
train_data = rr_data[1 : split_idx]
test_data  = rr_data[split_idx+1 : end]
```

All statistical parameters (mean, std, confidence bounds) are derived **exclusively from the training set** to prevent data leakage and ensure that the decision thresholds represent a true prior knowledge baseline.

### 6.3 Decision Threshold Computation

Using the training statistics, the 95% confidence interval defines the "normal" range:

```
Lower Bound = μ_train - 1.96 × σ_train
Upper Bound = μ_train + 1.96 × σ_train
```

Any R-R interval falling outside this range is flagged as anomalous. The choice of 95% CI (α = 0.05) represents a balance:
- **Too narrow** (e.g., 90% CI) → Higher sensitivity but more false positives
- **Too wide** (e.g., 99% CI) → Lower false positives but may miss genuine arrhythmias

### 6.4 Synthetic Arrhythmia Injection

Since Record 100 is predominantly normal, three synthetic arrhythmias are injected into the test set to validate detection:

| Injection Point | Value (ms) | Type | Clinical Description |
|----------------|------------|------|---------------------|
| Index 10 | 400 | PVC | Premature Ventricular Contraction — abnormally short R-R |
| Index 25 | 1500 | Sinus Pause | Bradycardia — abnormally long R-R |
| Index 40 | 350 | PVC | Another PVC — even more extreme |

These values were chosen to be clearly outside normal physiological ranges:
- **Normal resting R-R**: 600–1000 ms (60–100 bpm)
- **PVCs**: Typically 300–500 ms (extremely short coupling interval)
- **Sinus Pause**: > 1200 ms (heart rate < 50 bpm)

### 6.5 Binary Hypothesis Testing

For each beat in the test stream, the following decision rule is applied:

```
H₀: R-R interval is normal     (Lower Bound ≤ X[n] ≤ Upper Bound)
H₁: R-R interval is anomalous  (X[n] < Lower Bound OR X[n] > Upper Bound)

Decision Rule:
  If X[n] ∈ [LB, UB] → Accept H₀ (State 1: Normal)
  If X[n] ∉ [LB, UB] → Reject H₀ (State 2: Arrhythmia)
```

### 6.6 Markov Chain Transition Probability Matrix

The sequence of detected states (Normal/Arrhythmia) is modeled as a discrete-time Markov chain with 2 states. The transition probability matrix (TPM) is computed empirically:

```
P(i,j) = count(transitions from state i to state j) / count(transitions from state i)

            To: Normal    Arrhythmia
From:
  Normal    [ P(1,1)      P(1,2)    ]
  Arrhythm  [ P(2,1)      P(2,2)    ]
```

Where:
- **P(1,1)**: Probability of staying in Normal rhythm
- **P(1,2)**: Probability of transitioning from Normal to Arrhythmia
- **P(2,1)**: Probability of recovering from Arrhythmia to Normal
- **P(2,2)**: Probability of consecutive Arrhythmia events

**Clinical Interpretation**: For a healthy patient with injected anomalies, we expect:
- P(1,1) ≈ 1.0 (high probability of staying normal)
- P(2,1) ≈ 1.0 (high probability of recovery after anomaly)
- P(2,2) ≈ 0.0 (low probability of sustained arrhythmia in healthy patient)

### 6.7 Output Data

| Variable | Type | Description |
|----------|------|-------------|
| `test_data_simulated` | Vector | Test data with injected arrhythmias |
| `detected_states` | Vector | Binary state labels (1=Normal, 2=Arrhythmia) |
| `P` | Matrix [2×2] | Markov Chain Transition Probability Matrix |
| `mu_train` | Scalar | Training set mean |
| `sigma_train` | Scalar | Training set standard deviation |
| `lower_bound` | Scalar | Lower 95% CI threshold |
| `upper_bound` | Scalar | Upper 95% CI threshold |

---

## 7. Phase 5: Real-Time GUI Simulation

### 7.1 Purpose

Provide an interactive, visual demonstration of the real-time arrhythmia detection system. While the processing is simulated (pre-computed data streamed beat-by-beat), the GUI faithfully represents how a real-time system would behave when processing live ECG input.

### 7.2 GUI Architecture

The GUI is built using MATLAB's `uifigure` framework with the following layout:

```
┌──────────────────────────────────────────────────┐
│     Real-Time ECG Arrhythmia Detector            │
│     EEE 4407: Stochastic Arrhythmia Detection    │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │                                            │  │
│  │     Live R-R Interval Stream               │  │
│  │     (Auto-scrolling plot)                  │  │
│  │     ● Normal   ★ Anomaly                  │  │
│  │     --- Lower CI  --- Upper CI  --- Mean   │  │
│  │                                            │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌──── System Status Dashboard ─────────────┐   │
│  │ 🟢 Status: NORMAL SINUS RHYTHM           │   │
│  │    Current R-R: 812.45 ms                │   │
│  │    Detected State: State 1: Normal       │   │
│  │    Training Mean: 810.2 ms               │   │
│  │    95% CI: [720.5, 899.9] ms             │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  [▶ Start Simulation]  [↺ Reset]                 │
│                                                  │
│  Simulation Speed: ~20 beats/sec                  │
└──────────────────────────────────────────────────┘
```

### 7.3 Component Specifications

#### 7.3.1 Status Lamp (uilamp)
- **Gray** `[0.8, 0.8, 0.8]` — System idle / ready
- **Green** `[0, 0.85, 0]` — Normal rhythm detected
- **Red** `[0.95, 0, 0]` — Arrhythmia detected

#### 7.3.2 Plot Elements
- **Blue dots** (h_normal): Normal beats, `MarkerSize=15`
- **Red stars** (h_anomaly): Detected arrhythmias, `MarkerSize=18`
- **Gray trend line**: Continuous signal for visual context
- **Green dashed lines**: 95% CI thresholds
- **Black solid line**: Training mean

#### 7.3.3 Auto-Scroll Behavior
```matlab
if i > 50
    xlim(ax, [i-50, i]);   % Show last 50 beats
end
```
The plot shows the most recent 50 beats, creating a moving-window effect that mimics real-time patient monitoring displays.

#### 7.3.4 Simulation Speed
```matlab
pause(0.05);    % ~20 beats/second base rate
pause(0.3);     # Extra pause on anomaly detection for visual emphasis
```

### 7.4 Function vs. Script Architecture

Two variants of the Phase 5 code are provided:

| File | Type | Notes |
|------|------|-------|
| `phase5_realtime_gui.m` | **Function** | Encapsulated — uses nested functions sharing workspace. Recommended. |
| `test_phase5.m` | **Script** | Uses local functions at file end. For testing/debugging. |

The function variant (`phase5_realtime_gui`) is the recommended version because:
1. **Encapsulation**: Variables are scoped to the function, preventing workspace pollution
2. **Nested Functions**: Callback functions share the parent's workspace, avoiding global variable dependency
3. **Robustness**: Includes `isvalid()` checks to prevent crashes if the GUI is closed during simulation

---

## 8. Mathematical Reference

### 8.1 Key Formulas

**Butterworth Bandpass Filter:**
```
H(s) = 1 / (1 + (√2)(s/ωc) + (s/ωc)²)
Normalized: Wn = [f_low, f_high] / (fs/2)
```

**Gaussian PDF:**
```
f(x | μ, σ²) = (1/σ√2π) × exp(-(x-μ)² / 2σ²)
```

**95% Confidence Interval:**
```
CI = μ̂ ± z_{0.025} × (σ̂/√N) = μ̂ ± 1.96 × (σ̂/√N)
```

**Normalized Autocorrelation:**
```
ρ_X[k] = R_X[k] / R_X[0]
R_X[k] = (1/N) Σ (X[n] - μ̂)(X[n+k] - μ̂)
```

**Markov Chain TPM:**
```
P(i,j) = N(i→j) / Σ_j N(i→j)
```

### 8.2 Syllabus Mapping (EEE 4407)

| Course Topic | Phase | Application |
|-------------|-------|-------------|
| Random Variables & PDFs | Phase 3 | Gaussian modeling of R-R intervals |
| Expected Value & Variance | Phase 3 | Point estimation of cardiac rhythm parameters |
| Confidence Intervals | Phase 3, 4 | Decision threshold computation |
| Hypothesis Testing | Phase 4 | Binary H₀/H₁ arrhythmia classification |
| Wide Sense Stationarity | Phase 3 | Validation of statistical assumptions |
| Autocorrelation Functions | Phase 3 | Heart rate variability analysis |
| Markov Chains | Phase 4 | Cardiac state transition modeling |

---

## 9. Design Principles

1. **Sequential Dependency**: Each phase is self-contained but builds on prior outputs. Workspace files (.mat) serve as the data contract between phases.
2. **Fallback Mechanisms**: Phases 2-5 include fallback code that can reload data from the raw CSV if workspace files are missing, ensuring robustness.
3. **Physiological Constraints**: All detection parameters are informed by clinical knowledge (max heart rate, typical R-R ranges, QRS frequency content).
4. **Visualization at Every Stage**: Every transformation produces a figure for visual inspection and debugging.
5. **Separation of Concerns**: Signal processing, statistical modeling, decision logic, and visualization are in separate files with clear input/output contracts.

---

## 10. Dependencies & Toolboxes

| Toolbox | Functions Used | Required? |
|---------|---------------|-----------|
| Signal Processing Toolbox | `butter()`, `filtfilt()`, `findpeaks()`, `pwelch()`, `xcorr()` | **Yes** |
| Statistics and Machine Learning Toolbox | `normfit()`, `normpdf()` | **Yes** |
| MATLAB Core | `readtable()`, `plot()`, `histogram()`, `stem()`, `uifigure()` | **Yes** (built-in) |

---

## 11. Limitations

1. **Single-patient evaluation**: Currently validated on Record 100 only
2. **Single-lead analysis**: Uses only the first V-type lead; multi-lead fusion could improve accuracy
3. **Synthetic arrhythmias**: Detection validated against injected anomalies, not naturally occurring ones
4. **No clinical validation**: Performance metrics (sensitivity, specificity) not yet computed against expert annotations
5. **Batch processing only**: No true real-time input; the GUI streams pre-computed data
6. **Static thresholds**: Decision bounds are fixed from training; no online adaptation
