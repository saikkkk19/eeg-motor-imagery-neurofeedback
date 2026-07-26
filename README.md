# EEG Motor Imagery Neurofeedback BCI

A closed loop Brain Computer Interface that classifies **left hand vs right hand
motor imagery** from EEG in real time and returns the decision to the participant as
**neurofeedback**, delivered through two modalities — **visual** (on screen) and
**tactile** (a g.STIMbox vibrotactile stimulator) — so the two can be compared.

It was developed as a Research Internship project by Saikishore. S, part of a motor imagery neurofeedback study at Shibaura Institute of Technology
(Tokyo), 2025 under Prof. Shin'ichiro Kanoh. 

## How it works

```
Offline:  BrainVision MI recordings ──> train CSP + ensemble classifier ──> model files
                                                                                │
Online:   EEG amp ──LSL(EEG)──> epoching ──> CSP + classifier ──LSL(clfresults)──┐
          stimulus PC ──LSL(markers)──> epoching                                  │
                    ▲──── visual arrow / tactile pulse feedback ◄─────────────────┘
```

1. **Offline training** — record cued motor imagery, train a decoder, save it.
2. **Real time inference** — stream EEG over Lab Streaming Layer (LSL), epoch on
   stimulus markers, and classify each epoch live.
3. **Feedback** — the live prediction drives a visual or tactile cue, closing the loop.

## Repository layout

| Path | Contents |
| --- | --- |
| `notebooks/` | Offline analysis in Python/MNE — classifier training and per session review |
| `lsl/` | Real time LSL pipeline: stream acquisition, epoching, and live classification |
| `matlab/` | Stimulus presentation and feedback programs (visual and tactile paradigms) |

### Key files

- `notebooks/07_04_final_clf_model.ipynb` — trains the decoder: MNE epoching,
  8–30 Hz bandpass, **CSP** (Common Spatial Patterns) features, and a soft voting
  **ensemble** (Random Forest + SVM + Logistic Regression).
- `lsl/main.py` + `lsl/acquisition.py` — resolve the EEG and marker LSL streams and
  epoch incoming data.
- `lsl/client_clf.py` — load the pretrained CSP + classifier and predict in real time.
- `lsl/config.toml` / `lsl/conf.py` — channels, streams, buffers, and marker settings.
- `matlab/visual_saiki_final.m`, `matlab/tactile_saiki_final.m` — the two feedback
  paradigms; both send markers and read the `clfresults` stream over LSL.
- `notebooks/Visual_neurofeedback_.ipynb`, `notebooks/Tactile_neurofeedback.ipynb` —
  load and analyze the online sessions (XDF via `pyxdf`).

## Decoder details

- Signal: 64 channel EEG (BrainVision / BrainAmp), resampled to 250 Hz.
- Band: 8 – 30 Hz (sensorimotor mu/beta rhythms).
- Features: CSP (log-variance), 8 components.
- Classifier: soft voting ensemble, each base model tuned with GridSearchCV.
- Task: binary, left-hand (marker 8) vs right-hand (marker 16) motor imagery.

## Dependencies

Python (see `requirements.txt`): `mne`, `numpy`, `pandas`, `scipy`, `scikit-learn`,
`matplotlib`, `seaborn`, `joblib`, `pyxdf`, `pylsl`, `msgpack`, `toml`.

> The real time client also uses `pyicom` (an internal messaging library) and MATLAB
> needs the **LSL** library plus g.tec's **g.STIMbox** toolbox — none of which are on
> PyPI/this repo.

## Data availability

**No EEG data is included in this repository.** The recordings are human subjects
data and are kept private. The notebooks expect BrainVision (`.vhdr/.vmrk/.eeg`) and
XDF files that you supply locally and point the paths to. The trained model files
(`.pkl`) are likewise not committed — regenerate them from the training notebook.
