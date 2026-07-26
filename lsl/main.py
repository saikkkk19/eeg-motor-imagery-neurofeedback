import os
import copy
import argparse
import threading
import datetime
import multiprocessing
import logging
import time
import traceback
import msgpack
import numpy as np
import pyicom as icom
import acquisition
from utils import log
from pylsl import StreamInlet, resolve_streams, proc_ALL
from utils.std import mkdir

try:
    import tomllib
except:
    import toml as tomllib
    
def pop_list_indexes(list, indexes_to_remove):
    list = copy.copy(list)
    indexes_to_remove = copy.copy(indexes_to_remove)
    for index in sorted(indexes_to_remove, reverse=True):
        list.pop(index)
    return list
    
def pack_and_send(icom, epochs, events):
    dict_data = {'type':'epochs', 'events':events.tolist(), 'epochs':epochs.tolist()}
    icom.send(msgpack.packb(dict_data))

def callback_epoching(epochs, events, data):
    """
    proc = multiprocessing.Process(target = pack_and_send,
                                   kwargs = {"icom":data["icom"],
                                             "epochs": epochs,
                                             "events": events})
    proc.start()
    """
    data['icom'].send(msgpack.packb({'type':'epochs', 'events':events.tolist(), 'epochs':epochs.tolist()}))
    #logger = logging.getLogger(__name__)
    #logger.debug("callback_epoching was called for '%s'"%(str(events)))
    

def get_ch_names_LSL(inlet):

    ch_names = list()

    info = inlet.info()
    ch = info.desc().child("channels").child("channel")
    for k in range(info.channel_count()):
        ch_names.append(ch.child_value('label'))
        ch = ch.next_sibling()
    
    return ch_names

def conns_send(conns, data):
    logger = logging.getLogger(__name__)
    idx_conn_remove = list()
    for idx, conn in enumerate(conns):
        try:
            conn.send(data)
        except Exception as e:
            #logger.debug("")
            idx_conn_remove.append(idx)
    if len(idx_conn_remove) != 0:
        for m in sorted(idx_conn_remove, reverse=True):
            conns.pop(m)
        logger.debug("some lost connection was closed.")


def main(icom_server,
         length_buffer,
         name_marker_stream,
         name_eeg_stream,
         channels,
         markers,
         tmin,
         tmax,
         filter_freq,
         filter_order,
         #markers_new_trial,
         #markers_end_trial,
         callback,
         data_callback,
         #data_dir,
         #data_fname,
         processing_flags):

    
    try:
        with open("config.toml", "r") as f:
            config = tomllib.load(f)
    except:
        with open("config.toml", "rb") as f:
            config = tomllib.load(f)

    logger = logging.getLogger(__name__)

    logger.debug("channels for acquisition: %s"%str(channels))

    # ------------------------------------------------------------------------------------------------
    # find/connect eeg outlet
    logger.debug("looking for an EEG stream...")
    is_searching = True
    while is_searching:
        streams = resolve_streams(wait_time = 1)
        for stream in streams:
            if stream.name() == name_eeg_stream:
                eeg_inlet = StreamInlet(stream, 
                                        max_buflen = 10,
                                        max_chunklen = 1,
                                        recover = True,
                                        processing_flags = processing_flags)
                fs = stream.nominal_srate()
                logger.debug("EEG Stream : %s" %stream.name())
                is_searching = False

    # create a new inlet to read from the stream
    ch_names = get_ch_names_LSL(eeg_inlet)
    logger.debug("ch_names_LSL : %s" %str(ch_names))
    
    for ch in channels:
        if not ch in ch_names:
            logger.error("channel '%s' is not in LSL EEG stream."%(ch))

    channels_to_acquire = list()
    for idx, ch in enumerate(ch_names):
        if ch in channels:
            channels_to_acquire.append(idx)
    channels_to_acquire = np.array(channels_to_acquire)
    logger.debug("channels_to_acquire (idx) : %s" %str(channels_to_acquire))
    logger.debug("channels_to_acquire : %s" %str(np.array(ch_names)[channels_to_acquire]))

    n_ch = len(channels_to_acquire)
    logger.debug("n_ch for online session : %d" %n_ch)

    # ------------------------------------------------------------------------------------------------
    # find/connect marker outlet

    logger.debug("looking for a marker stream...")
    
    is_searching = True
    while is_searching:
        streams = resolve_streams(wait_time = 1)
        for stream in streams:
            if stream.name() == name_marker_stream:
                marker_inlet = StreamInlet(stream,
                                           max_buflen = 10,
                                           max_chunklen = 1,
                                           recover = True,
                                           processing_flags = processing_flags)
                logger.debug("Marker Stream : %s" %stream.name())
                is_searching = False

    """
    while True:
        data_chunk, time_chunk = marker_inlet.pull_chunk(timeout = 0.0)
        t = time.time()
        print("t, data: %s"%(str(t)))
    """

    logger.debug("Configuration was Done.")  
    
    epochs = acquisition.Epochs(n_ch = n_ch,
                                fs = fs,
                                markers_to_epoch = markers,
                                tmin = tmin,
                                tmax = tmax,
                                callback = callback,
                                data_callback = data_callback,
                                baseline=None,
                                ch_names = channels,
                                ch_types = 'eeg',
                                #file_data=file_data,
                                icom_server=icom_server)
    
    acq = acquisition.OnlineDataAcquire(epochs = epochs,
                                        eeg_inlet = eeg_inlet,
                                        channels_to_acquire = channels_to_acquire,
                                        length_buffer = length_buffer,
                                        nch_eeg = n_ch,
                                        fs_eeg = fs,
                                        marker_inlet = marker_inlet,
                                        filter_freq = filter_freq,
                                        filter_order = filter_order)
                                        #new_trial_markers = markers_new_trial,
                                        #end_markers = markers_end_trial)
 

    acq.start()
    #time.sleep(config['pause']['between_acq_epochs'])
    #epochs.start()
    
    pause = config['pause']['main_loop']
    while True:
        time.sleep(pause)
        """
        try:
            time.sleep(0.01)
        except KeyboardInterrupt:
            break
        """
        
    #file_data.close()
    print("terminate")
    
"""
def server(ip, port, conns):
    logger = logging.getLogger(__name__)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((conf.ip_address, conf.port))
    print("server info. ip: %s, port: %s"%(str(conf.ip_address), str(conf.port)))
    
    #server.settimeout(10)
    while True:
        server.listen()
        conn, addr = server.accept()
        conns.append(conn)
        #print("connected : %s" %str(addr))
        logger.debug("New socket connection was established. '%s'"%str(addr))
"""


if __name__ == "__main__":

    #import conf
    
    try:
        with open("config.toml", "r") as f:
            config = tomllib.load(f)
    except:
        with open("config.toml", "rb") as f:
            config = tomllib.load(f)

    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', type = str, default = "localhost")
    parser.add_argument('--port', type = int, default = 49155)
    parser.add_argument('--marker', type=str, default=config['default_stream']['marker'])
    parser.add_argument('--signal', type=str, default=config['default_stream']['signal'])
    parser.add_argument("--log", type=str)
    args = parser.parse_args()
        
    home_dir = os.path.expanduser("~")

    log_strftime = "%y-%m-%d_%H-%M-%S"
    datestr =  datetime.datetime.now().strftime(log_strftime) 
    log_fname = "lsl-epoching_%s.log"%datestr
    
    if args.log is not None:
        log_dir = args.log
    else:
        log_dir = os.path.join(os.path.expanduser("~"), config["directories"]["log"])

    mkdir(log_dir)
    log.set_logger(os.path.join(log_dir, log_fname), True)

    logger = logging.getLogger(__name__)
    
    logger.debug("log file will be saved in %s"%str(os.path.join(log_dir, log_fname)))
    
    for key in vars(args).keys():
        val = vars(args)[key]
        logger.debug("%s: %s"%(str(key), str(val)))
    
    processing_flags = config['lsl']['processing_flags']
    logger.debug("processing_flags for lsl streams: %s"%str(processing_flags))
    
    server = icom.server(ip = args.ip,
                         port = args.port,
                         timeout=None)
    server.start()
    server.wait_for_connection()

    #icom_buffer = IcomBuffer(server)
    #icom_buffer.start()

    #data_callback = {"icom": icom_buffer}
    data_callback = {"icom": server}
    
    main(icom_server=server,
         name_marker_stream = args.marker, 
         name_eeg_stream = args.signal,
         channels = config['signal']['channels'],
         markers = config['markers']['epochs'],
         length_buffer = config['signal']['length_buffer'],
         tmin = -1,
         tmax = 3,
         filter_freq = [8, 30],
         filter_order = 2,
         callback = callback_epoching,
         data_callback = data_callback,
         #markers_new_trial = config['markers']['new_trial'],
         #markers_end_trial = config['markers']['end'],
         #data_dir = os.path.join(os.path.expanduser('~'), config['directories']['data']),
         #data_fname = config['filenames']['epochs'],
         processing_flags=processing_flags)