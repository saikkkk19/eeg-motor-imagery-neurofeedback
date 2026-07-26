import os
import socket
from pylsl import proc_none, proc_clocksync, proc_dejitter, proc_monotonize, proc_threadsafe, proc_ALL

ip_address = socket.gethostbyname(socket.gethostname())
port = 49153
length_header = 64

log_dir = os.path.join(os.path.expanduser('~'), "log", "lsl-epoching")
data_dir = os.path.join(os.path.expanduser('~'), "Documents", "eeg", "epochs")
data_fname = "epochs.txt"
    
default_name_marker_stream = "scab-c"
#name_eeg_stream = "BrainAmpSeries"
default_name_sig_stream = "jarvis-erp"

icom_clients = None

channels = ["F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4"]

markers = dict()
markers['nontarget'] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15']
markers['target'] = ['101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115'] 
markers['trial-start'] = ['200', '201', '202', '203', '204', '205', '206', '207', '208', '209', '210', '211', '212', '213', '214', '215']
markers['trial-end'] = ['255']

#markers = dict()
#markers['new-trial'] = ['200']
#markers['target'] = ['11']
#markers['nontarget'] = ['1']
#markers['end'] = ['255']

#markers_to_epoch = markers['nontarget'] + markers['target']
markers_to_epoch = list()
for m in range(1, 200):
    markers_to_epoch.append(str(m))

#markers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '101', '102', '103', '104', '105', '106', '107', '108', '109']

# length of the buffer in seconds
length_buffer = 10

"""
From pylsl.py...

# Post processing flags
proc_none = 0  # No automatic post-processing; return the ground-truth time stamps for manual post-processing.
proc_clocksync = 1  # Perform automatic clock synchronization; equivalent to manually adding the time_correction().
proc_dejitter = 2  # Remove jitter from time stamps using a smoothing algorithm to the received time stamps.
proc_monotonize = 4  # Force the time-stamps to be monotonically ascending. Only makes sense if timestamps are dejittered.
proc_threadsafe = 8  # Post-processing is thread-safe (same inlet can be read from by multiple threads).
proc_ALL = (
    proc_none | proc_clocksync | proc_dejitter | proc_monotonize | proc_threadsafe
) -> 15
"""
default_processing_flags = proc_ALL