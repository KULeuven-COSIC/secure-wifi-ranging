# Custom functions

This folder contains the repository-specific MATLAB code used in the physical-layer analysis of the paper. These files are not a standalone implementation. They are intended to be used together with the MathWorks [802.11az waveform generation example](https://www.mathworks.com/help/wlan/ug/802-11az-waveform-generation.html), as explained in the main repository README.

## Relation to the paper

The files in this folder support the following parts of the paper:

- `OFDM_Baysian_estimation.m`  
  Supports the HE-LTF estimation study in Sect. 5.2.

- `partial_HELTF_advance.m`  
  Supports the distance-reduction attack evaluation in Sect. 5.3.

- `PSD_estimation.m`  
  Supports the zero-power guard interval and spectral-mask analysis in Sect. 5.4.

## Integration into the MathWorks workflow

These files provide only our original code additions and should be integrated into the corresponding MathWorks workflow.

- `OFDM_Baysian_estimation.m` is a standalone simulation script.
- `partial_HELTF_advance.m` should be incorporated into `HERangingPositioningExample.mlx`, as indicated in the file comments.
- `PSD_estimation.m` should be incorporated into `heRangingWavGenPlot.m`, as indicated in the file comments.

## Brief description of the files

- `OFDM_Baysian_estimation.m` studies estimation of a secure HE-LTF OFDM symbol from a partial time-domain observation.
- `partial_HELTF_advance.m` implements the waveform modification used to evaluate partial HE-LTF advancement attacks.
- `PSD_estimation.m` evaluates PSD and spectral-mask behaviour for legacy and secure HE-LTF waveforms, including transmitter nonlinearity.

## Note on reproducibility

This folder contains only the custom MATLAB code used in our analysis. MathWorks source code is not redistributed. Board-specific code, firmware, and configuration files used for measurements and waveform acquisition are also not included in this repository due to non-disclosure agreement restrictions.
