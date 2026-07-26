# lsl-epoching

# Usage

Once it starts running, it will wait for the new icom connection.

After connection is established, it will fetch the marker and EEG streams that were specified in the config.toml.

After that, it will start epoching for specified markers. Epoched data will be sent via icom and saved to the directories with filenames that are speciefied in config.toml.

# Arguments

| arg    | desc                                     | type | default    |
| ------ | ---------------------------------------- | ---- | ---------- |
| ip     | ip address for pyicom                    | str  | localhost  |
| port   | port for pyicom                          | int  | 49155      |
| marker | name of marker stream to be fetched      | str  | scab-c     |
| signal | name of signal(EEG) stream to be fetched | str  | jarvis-erp |


# config.toml
| item | description |
| ---- | ----------- |
| length_header   | length of header of pyicom           |
| directories.log | base directory for saving log files. |
| markers.epochs  | markers to be epoched                |

