# Real-Time ECG Arrhythmia Detector

> A MATLAB-based biomedical signal processing system that detects cardiac arrhythmias in real-time using stochastic process modeling, statistical hypothesis testing, and Markov chain state transition analysis.

<div align="center">

![MATLAB](https://img.shields.io/badge/MATLAB-R2023b-blue?logo=mathworks&logoColor=white)
![MIT-BIH](https://img.shields.io/badge/Dataset-MIT--BIH_Arrhythmia-green)
![Course](https://img.shields.io/badge/Course-EEE_4407-orange)
![Signal Processing](https://img.shields.io/badge/Domain-Biomedical_Signal_Processing-red)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Pipeline Walkthrough](#pipeline-walkthrough)
- [Results & Outputs](#results--outputs)
- [Documentation](#documentation)
- [Future Improvements](#future-improvements)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Overview

Cardiac arrhythmias are abnormal heart rhythms that can lead to serious medical conditions, including stroke and sudden cardiac arrest. Early and accurate detection of these anomalies is critical in clinical settings. This project implements a **complete, end-to-end ECG arrhythmia detection pipeline** in MATLAB, applying rigorous mathematical frameworks from the EEE 4407 (Random Signals and Processes) curriculum to real-world physiological data from the internationally recognized **MIT-BIH Arrhythmia Database**.

The system processes raw ECG signals through five sequential phases: data ingestion and visualization, noise filtering and R-peak detection, stochastic modeling with Wide Sense Stationary (WSS) verification, statistical hypothesis testing with Markov chain state tracking, and finally a real-time interactive GUI that simulates live cardiac monitoring with instant anomaly flagging.

## Key Features

- **Raw ECG Signal Processing**: Loads and visualizes multi-lead ECG recordings from the MIT-BIH database at native 360 Hz sampling rate
- **Adaptive Bandpass Filtering**: 2nd-order Butterworth bandpass filter (5-15 Hz) to isolate QRS complex energy while suppressing baseline wander and high-frequency noise
- **Robust R-Peak Detection**: Adaptive peak detection with physiologically informed parameters (min distance ~108 samples for ~200 bpm safety margin)
- **Stochastic Modeling**: Gaussian PDF estimation with 95% confidence intervals for R-R interval distributions
- **WSS Verification**: Two-test framework for Wide Sense Stationarity — mean stability across time windows and normalized autocorrelation analysis
- **Real-Time Hypothesis Testing**: Binary decision engine classifying each incoming heartbeat as Normal (H₀) or Arrhythmia (H₁)
- **Markov Chain Analysis**: Empirical transition probability matrix computation modeling cardiac state transitions
- **Interactive GUI**: Real-time streaming simulation with live status dashboard, color-coded alerts, and auto-scrolling visualization

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SYSTEM PIPELINE ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │  MIT-BIH     │───▶│  Bandpass    │───▶│  R-Peak Detection    │  │
│  │  Database    │    │  Filter      │    │  (findpeaks)          │  │
│  │  (360 Hz)    │    │  (5-15 Hz)   │    │  R-R Intervals       │  │
│  └──────────────┘    └──────────────┘    └──────────┬───────────┘  │
│                                                       │              │
│  Phase 1: Data Load     Phase 2: Preprocessing         │              │
│                                                       ▼              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐  │
│  │  Hypothesis  │◀───│  Gaussian    │◀───│  WSS Verification     │  │
│  │  Testing     │    │  PDF Fitting │    │  (Mean + ACF Tests)   │  │
│  │  H₀ vs H₁   │    │  normfit()   │    │                      │  │
│  └──────┬───────┘    └──────────────┘    └──────────────────────┘  │
│         │                                                        │
│         ▼                                                        │
│  ┌──────────────┐    ┌──────────────────────────────────────┐  │
│  │  Markov      │───▶│  Real-Time GUI Simulation            │  │
│  │  Chain TPM   │    │  Live Streaming · Status Dashboard   │  │
│  │  State Track │    │  Arrhythmia Alerts · Auto-Scroll    │  │
│  └──────────────┘    └──────────────────────────────────────┘  │
│                                                                     │
│  Phase 4: Decision Logic          Phase 5: Visualization          │
└─────────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
Real-Time-ECG-Arrhythmia-Detector/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── src/                               # MATLAB source code
│   ├── phase_01.m                     # Phase 1: Data Loading & Visualization
│   ├── phase_02.m                     # Phase 2: Signal Processing & Feature Extraction
│   ├── phase_03.m                     # Phase 3: Stochastic Modeling & WSS Verification
│   ├── phase_04.m                     # Phase 4: Hypothesis Testing & Markov Chains
│   ├── phase5_realtime_gui.m          # Phase 5: Real-Time GUI Simulation (function)
│   └── test_phase5.m                  # Phase 5: GUI Test Script (script variant)
├── data/                              # ECG data directory
│   └── ecg_data/
│       └── 100.csv                    # MIT-BIH Record 100 (MLII & V5 leads)
├── docs/                              # Documentation
│   ├── ARCHITECTURE.md                # Detailed system architecture documentation
│   ├── TUTORIAL.md                    # Step-by-step user manual & tutorial
│   ├── ROADMAP.md                     # Future improvements & development roadmap
│   ├── Project Proposal and Plan_Real-Time ECG Arrhythmia Detector.docx
│   └── ECG Arrhythmia Detection Outline.pdf
└── figures/                           # Output figures directory (generated)
    ├── raw_ecg_signals.fig            # Phase 1 output
    ├── noise_analysis.fig             # Phase 1 noise characteristics
    ├── rr_peak_detection.fig          # Phase 2 filtered signal with peaks
    ├── pdf_estimation.fig             # Phase 3 empirical vs theoretical PDF
    ├── wss_mean_test.fig              # Phase 3 WSS mean stability
    ├── wss_autocorrelation.fig        # Phase 3 WSS autocorrelation
    ├── hypothesis_testing.fig          # Phase 4 detection results & TPM
    └── gui_simulation.fig             # Phase 5 GUI screenshots
```

## Getting Started

### Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| MATLAB | R2020b or later | R2023b recommended |
| Signal Processing Toolbox | Latest | For `butter()`, `filtfilt()`, `findpeaks()`, `pwelch()` |
| Statistics and Machine Learning Toolbox | Latest | For `normfit()`, `normpdf()` |

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/mutassimalzeem/Real-Time-ECG-Arrhythmia-Detector.git
cd Real-Time-ECG-Arrhythmia-Detector
```

2. **Ensure data directory structure**

The `data/ecg_data/100.csv` file is included. If using additional MIT-BIH records, place them in the `data/ecg_data/` directory.

3. **Open MATLAB and set the working directory**

```matlab
cd('path/to/Real-Time-ECG-Arrhythmia-Detector/src');
```

4. **Run the pipeline sequentially**

Execute phases in order — each phase generates a `.mat` workspace file consumed by the next:

```matlab
run('phase_01.m')     % Step 1: Load and visualize raw ECG
run('phase_02.m')     % Step 2: Filter and detect R-peaks
run('phase_03.m')     % Step 3: Stochastic modeling & WSS tests
run('phase_04.m')     % Step 4: Hypothesis testing & Markov chains
phase5_realtime_gui()  % Step 5: Launch interactive GUI simulation
```

> **Note**: The pipeline is sequential by design. Each phase saves its output to a `.mat` file (`phase1_workspace.mat` through `phase4_workspace.mat`). However, Phase 2-5 include built-in fallback mechanisms that reload data directly from the CSV if workspace files are missing.

### Quick Start (Single Phase)

To run any individual phase independently (after Phase 1 has been executed at least once):

```matlab
% Phase 2 has a built-in fallback to load from CSV
run('phase_02.m')
```

## Pipeline Walkthrough

### Phase 1: Data Loading & Visualization

Loads the MIT-BIH Record 100 CSV file, identifies all ECG lead columns, and generates:
- Multi-lead raw ECG signal plots (first 10 seconds)
- Statistical summary (mean, std, min, max, duration)
- Noise characteristics analysis (amplitude histogram + power spectral density via `pwelch`)

**Output**: `phase1_workspace.mat` — contains `patient_data`, `ecg_signal_names`, `fs`

### Phase 2: Signal Processing & Feature Extraction

Applies a 2nd-order Butterworth bandpass filter (5–15 Hz) using zero-phase filtering (`filtfilt`) to preserve signal morphology. Then performs adaptive R-peak detection with physiologically constrained parameters:
- **MinPeakDistance**: 108 samples (~200 bpm safety margin)
- **MinPeakProminence**: 15% of peak-to-peak amplitude (adaptive to signal strength)

Extracts R-R intervals and converts to milliseconds for clinical standard representation.

**Output**: `phase2_workspace.mat` — contains `filtered_ecg`, `locs`, `pks`, `rr_intervals_sec`, `rr_intervals_ms`, `fs`

### Phase 3: Stochastic Modeling & WSS Verification

Estimates the Gaussian PDF of R-R intervals with point estimates and 95% confidence intervals using `normfit()`. Validates the Wide Sense Stationarity assumption through two tests:
1. **Mean Stability Test**: Divides data into 10 windows and verifies mean remains within confidence bounds
2. **Autocorrelation Test**: Computes normalized ACF up to lag 50 and checks for white noise bounds (1.96/sqrt(N))

**Output**: `phase3_workspace.mat` — contains `rr_data`, `mu_hat`, `sigma_hat`, `var_hat`, `mu_ci`, `window_means`

### Phase 4: Hypothesis Testing & Markov Chains

Splits data 80/20 into training and test sets. Defines decision thresholds from training statistics (Z-score = 1.96 for 95% CI). Injects three synthetic arrhythmias into the test set to validate detection:
- **PVC (Premature Ventricular Contraction)**: 400 ms and 350 ms intervals
- **Bradycardia/Sinus Pause**: 1500 ms interval

Performs real-time binary hypothesis testing on each beat, then computes the 2x2 Markov Chain Transition Probability Matrix to model cardiac state dynamics.

**Output**: `phase4_workspace.mat` — contains `test_data_simulated`, `detected_states`, `P`, `mu_train`, `sigma_train`, `lower_bound`, `upper_bound`

### Phase 5: Real-Time GUI Simulation

An interactive MATLAB App Designer-style GUI (built with `uifigure`) that simulates real-time ECG monitoring:
- **Live R-R Interval Stream**: Auto-scrolling plot with trend line, normal beats (blue dots), and anomaly markers (red stars)
- **Status Dashboard**: Color-coded lamp indicator (green = normal, red = arrhythmia), current R-R value, detected state label
- **Control Panel**: Start and Reset buttons for simulation control
- **Threshold Overlays**: 95% CI bounds and training mean displayed on the plot

**Output**: Interactive GUI window + console statistics summary

## Results & Outputs

Each phase produces both MATLAB figure windows and workspace files:

| Phase | Figure Outputs | Key Metrics |
|-------|---------------|-------------|
| 1 | Raw ECG signals (multi-lead), Noise histogram, PSD | Signal statistics, Sampling rate: 360 Hz |
| 2 | Filtered ECG with R-peaks, R-R interval sequence | Number of R-peaks, Mean R-R interval |
| 3 | Empirical vs Gaussian PDF (with 95% CI), WSS mean test, ACF plot | Mean, Std, 95% CI bounds, Max mean deviation |
| 4 | Detection results with thresholds, TPM heatmap, State sequence | Detected anomalies, Transition probabilities |
| 5 | Interactive GUI with live streaming | Total beats, Anomaly count, Detection percentage |

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Detailed system architecture, algorithm descriptions, mathematical derivations |
| [TUTORIAL.md](docs/TUTORIAL.md) | Step-by-step user manual with screenshots and troubleshooting |
| [ROADMAP.md](docs/ROADMAP.md) | Future improvements, planned features, and development roadmap |

## Future Improvements

See the full development roadmap in [docs/ROADMAP.md](docs/ROADMAP.md). Key planned improvements include:

- **Multi-patient database support** — extend beyond Record 100 to the full 48-record MIT-BIH dataset
- **Adaptive thresholding** — implement sliding-window statistics for non-stationary signal handling
- **Multi-class arrhythmia classification** — distinguish PVC, APC, bradycardia, tachycardia individually
- **Deep learning integration** — CNN/LSTM hybrid models for feature extraction and classification
- **Real-time hardware interface** — MATLAB Support Package for Arduino/STM32 for live ECG input
- **Performance benchmarking** — sensitivity, specificity, accuracy metrics with confusion matrices

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **MIT-BIH Arrhythmia Database** — PhysioNet, Goldberger AL, et al. (2000)
- **EEE 4407: Random Signals and Processes** — Course curriculum and theoretical framework
- **MATLAB Signal Processing Toolbox** — MathWorks documentation and reference examples
- **PhysioNet** — For providing free, open-access physiological signal databases

---

<div align="center">

**Built with MATLAB** | Course Project — EEE 4407 Random Signals and Processes

</div>
