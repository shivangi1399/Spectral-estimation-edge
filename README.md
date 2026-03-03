# Spectral Estimation at the Edge

Code accompanying the paper:

> **Spectral estimation at the edge**
> Shivangi Patel, Eleni Psarou, Gregor Mönke, Pascal Fries
> *bioRxiv* (2024). DOI: [10.1101/2024.10.02.616083](https://doi.org/10.1101/2024.10.02.616083)

## Overview

This repository contains the implementation of the AR Fourier method for phase estimation at the edge of data epochs, along with comparisons to previously established methods. The comparison was done using both simulated and empirical datasets. We systematically compared AR Fourier to previously established techniques by generating simulated datasets with varying phase diffusion and noise coefficients. We also compared the method to other methods using a real-world dataset from visual cortex of awake macaque monkey while the monkey was performing a detection task.

## Requirements

- **MATLAB** (tested with R2021b or later)
- **[FieldTrip](https://www.fieldtriptoolbox.org/)** — EEG/MEG analysis toolbox
- **[slurmfun](https://github.com/esi-neuroscience/slurmfun)** — for parallel computing on SLURM clusters (optional)
- **Python 3** with the following packages (only for data generation):
  - numpy
  - matplotlib
  - pandas
  - [syncopy](https://syncopy.org/)
  - [pyplnoise](https://pypi.org/project/pyplnoise/)

## Data Availability

Data files (`.mat`) are not included in this repository due to their size. The data required to reproduce the results will be made available on Zenodo/OSF/Figshare (link to be added).

## Folder Structure

```
├── code/
│   ├── ARFourier_implement/
│   │   ├── AR_Fourier_method.m        # Standalone AR Fourier implementation on simulated data
│   │   └── functions/                 # Supporting functions (includes AR_fourier_imp.m with path config)
│   ├── implement_compare/
│   │   ├── simulated_data/
│   │   │   ├── extrapolation_methods.m    # Extrapolation-based phase estimation methods
│   │   │   ├── filter_based_methods.m     # Filter-based phase estimation methods
│   │   │   ├── echt_simdata.m             # ecHT method on simulated data
│   │   │   ├── simdata_comparison.m       # PLV-based comparison of methods
│   │   │   ├── statistical_analysis.m     # Statistical analysis for simulated data
│   │   │   └── result_figures.m           # Recreate manuscript figures
│   │   ├── empirical_data/
│   │   │   ├── methods_implementation.m   # All phase estimation methods on macaque V4 data
│   │   │   ├── echt_empdata.m             # ecHT method on empirical data
│   │   │   └── empdata_comparison.m       # PLV comparison and statistical analysis
│   │   └── functions/                     # Shared functions (some contain path config)
│   └── data_generation/
│       └── data_gen_n.py                  # Generate simulated datasets
├── data/
│   ├── simulated_data/                    # CSV files for simulated data (example: freq46_11)
│   └── empirical_data/                    # Recorded data from macaque area V4 (see below)
├── results/
│   ├── simulated_data/                    # Phase estimates in FieldTrip format (see below)
│   └── empirical_data/                    # Processed monkey data and phase estimation results
├── comparison/
└── plotting/
```

### Data Details

**Simulated data** (`data/simulated_data/`): Contains CSV files with simulated data. Data corresponding to all phase diffusion and noise coefficient values for 4 Hz and 6 Hz frequencies in 1:1 ratio is provided as an example in the folder `freq46_11`.

**Empirical data** (`data/empirical_data/`): Contains a MAT file with recorded data from macaque area V4. The `trialinfo` field contains information about each trial in the session:
| Column | Description |
|--------|-------------|
| 1 | Trial number within session |
| 2 | X coordinate of the target |
| 3 | Y coordinate of the target |
| 4 | Difficulty level |
| 5 | Outcome of the trial (e.g., correct, incorrect) |

**Simulated results** (`results/simulated_data/`): Contains data files in FieldTrip format and phase estimates for each dataset. One example dataset is provided in the folder `freq46_11/0.251/0.5`, corresponding to frequencies 4 Hz and 6 Hz in a 1:1 ratio, phase diffusion of 0.251, and noise coefficient of 0.5. Detailed phase estimate components are provided only for this dataset due to space constraints.

**Empirical results** (`results/empirical_data/`): Contains processed monkey data, phase estimation results, and intermediate data needed to run AR Fourier.

## Instructions

### Quick Start (AR Fourier standalone)

1. Download [FieldTrip](https://www.fieldtriptoolbox.org/) and add it to your MATLAB path
2. Open `code/ARFourier_implement/AR_Fourier_method.m`
3. Update the paths in `code/ARFourier_implement/functions/AR_fourier_imp.m` for FieldTrip and (optionally) SLURM
4. Run `AR_Fourier_method.m`

### Reproducing Paper Results

1. **Setup**: Add the `code/` folder (with subfolders) to the MATLAB path
2. **Modify paths**: Update the FieldTrip and SLURM paths in the `functions/` folders. Replace `/add/path/to/your/folder/` with your local path to this repository
3. **Generate simulated data** (optional): Run `code/data_generation/data_gen_n.py`
4. **Run phase estimation methods on simulated data**:
   - `extrapolation_methods.m`
   - `filter_based_methods.m`
   - `echt_simdata.m`
5. **Analyze simulated data results** (run in order):
   - `simdata_comparison.m`
   - `statistical_analysis.m`
   - `result_figures.m`
6. **Run phase estimation methods on empirical data**:
   - `methods_implementation.m`
   - `echt_empdata.m`
7. **Analyze empirical data results**:
   - `empdata_comparison.m`

### Without SLURM

If SLURM is not available, modify the code to run iterations locally. Alternatives for local execution are provided in the comments of `AR_fourier_imp.m`. Note that running locally can be time-consuming and memory-intensive.

### Using with Your Own Data

This code can be used on any dataset after converting it to [FieldTrip format](https://www.fieldtriptoolbox.org/faq/how_are_the_various_data_structures_defined/).

## Parameters

The following parameters can be adjusted in `AR_Fourier_method.m`:
- **Number of Iterations**: How many autoregressive extrapolation iterations are performed
- **Number of Extrapolated Samples**: How many samples to extrapolate beyond the edge
- **Number of Cycles for Spectral Estimation**: Cycles used during spectral estimation

## Notes

- **Running locally**: If SLURM is unavailable, executing the AR extrapolation iterations locally can be very time-consuming and may require significant memory.
- **Simulated data**: The example data consists of two sinusoids at 4 Hz and 6 Hz, with known phase values for these frequencies. Use `data_gen_n.py` to generate similar datasets.

## Citation

If you use this code, please cite:

```bibtex
@article{patel2024spectral,
  title={Spectral estimation at the edge},
  author={Patel, Shivangi and Psarou, Eleni and M{\"o}nke, Gregor and Fries, Pascal},
  journal={bioRxiv},
  year={2024},
  doi={10.1101/2024.10.02.616083}
}
```

## Contact

For questions, please contact Shivangi Patel at shivangi.patel@esi-frankfurt.de

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
