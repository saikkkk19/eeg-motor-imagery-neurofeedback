# Real time LSL pipeline

Epochs the incoming EEG stream on stimulus markers and classifies each epoch.

## Usage

1. Start `main.py`. It opens a `pyicom` server and waits for a client to connect.
2. Start `client_clf.py`. It connects to the server and loads the trained CSP and
   classifier models.
3. `main.py` then resolves the EEG and marker streams named in `config.toml`,
   bandpass filters the EEG (8–30 Hz), and cuts an epoch (−1 to 3 s) around each
   marker listed under `markers.epochs`.
4. Each epoch is sent to the client, which prints the predicted class.

`run-epoching.ps1` and `run-classifier.ps1` start the two programs on Windows.

## Arguments of `main.py`

| arg    | description                        | type | default                          |
| ------ | ---------------------------------- | ---- | -------------------------------- |
| ip     | IP address of the `pyicom` server  | str  | localhost                        |
| port   | port of the `pyicom` server        | int  | 49155                            |
| marker | name of the marker stream          | str  | `default_stream.marker` in config |
| signal | name of the EEG stream             | str  | `default_stream.signal` in config |
| log    | directory for log files            | str  | `~/<directories.log>` in config  |

## config.toml

| item                    | description                                  |
| ----------------------- | -------------------------------------------- |
| directories.log         | log directory, relative to the home directory |
| default_stream.marker   | default marker stream name                   |
| default_stream.signal   | default EEG stream name                      |
| signal.channels         | channels to acquire from the EEG stream      |
| signal.length_buffer    | length of the EEG ring buffer in seconds     |
| markers.epochs          | markers to epoch on                          |
| lsl.processing_flags    | pylsl post-processing flags                  |
| pause.main_loop         | sleep time of the main loop in seconds       |

## Other files

- `64ch_eog.cfg`, `64ch_eog_250Hz.cfg` — channel configurations for the BrainVision
  LSL connector.
- `test-streamer.py` — sends a random multi-channel stream, for testing without an
  amplifier.
- `test-mrk-streamer.py` — sends the trial marker sequence, for testing without the
  stimulus program.
