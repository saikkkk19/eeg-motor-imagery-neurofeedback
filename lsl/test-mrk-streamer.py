"""Send the trial marker sequence into LSL, for testing without the stimulus program."""

import time

from pylsl import StreamInfo, StreamOutlet


def main():
    # same stream definition as the MATLAB stimulus programs
    info = StreamInfo('si_marker', 'Markers', 1, 0, 'string', 'si_marker')
    outlet = StreamOutlet(info)

    # 4: preparation, 8: right-hand cue, 16: left-hand cue, 32: rest
    trials = [['4', '8', '32'], ['4', '16', '32']]
    pauses = [3, 3, 4]

    print("now sending markers...")
    while True:
        input("Press Enter to start a new run")
        for markers in trials:
            for marker, pause in zip(markers, pauses):
                outlet.push_sample([marker])
                time.sleep(pause)


if __name__ == '__main__':
    main()
