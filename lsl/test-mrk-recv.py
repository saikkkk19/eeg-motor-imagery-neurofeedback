from pylsl import StreamInlet, resolve_stream, resolve_streams, proc_ALL
import time

name_marker_stream = "scab-c"
name_eeg_stream = "jarvis-erp"

is_searching = True
while is_searching:
    streams = resolve_streams(wait_time = 1)
    for stream in streams:
        if stream.name() == name_eeg_stream:
            eeg_inlet = StreamInlet(stream, 
                                    max_buflen = 10,
                                    max_chunklen = 1,
                                    recover = True,
                                    processing_flags = 1)
            fs = stream.nominal_srate()
            is_searching = False

is_searching = True
while is_searching:
    streams = resolve_streams(wait_time = 1)
    for stream in streams:
        if stream.name() == name_marker_stream:
            marker_inlet = StreamInlet(stream,
                                       max_buflen = 10,
                                       max_chunklen = 1,
                                       recover = True,
                                       processing_flags = 1)
            is_searching = False

while True:
    data_chunk, time_chunk = marker_inlet.pull_chunk(timeout = 0.0)
    t = time.time()
    print("t, data: %s"%(str(t)))

    """
    if time_chunk:
        t = time.time()
        print("t, data: %s, %s"%(str(t), str(data_chunk)))
        #logger.debug("markers '%s' were received"%str(data_chunk))
    """