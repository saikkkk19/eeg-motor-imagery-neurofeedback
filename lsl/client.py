import os
import sys
import traceback

import socket
import json
import msgpack

import pyicom as icom

#sys.path.append(os.path.join(os.path.expanduser('~'), "git", "pyerp", "src"))
#import pyerp

#SERVER = socket.gethostbyname(socket.gethostname())
#IPADDR = "127.0.0.1"
#IPADDR = SERVER
#PORT = 49153
#header = 64
#FORMAT = ''

ip = "localhost"
port = 49153

client = icom.client(ip = ip,
                     port = port)
client.connect()
#cl = socket.socket(socket.AF_INET)
#cl.connect((IPADDR, PORT))
print("connected.")

json_save_dir = os.path.join(os.path.expanduser('~'), "Documents", "eeg", "lsl-online")

epochs = list()
events = list()

json_save = dict()
cnt = 0
while True:
    #input("Press Any Keys to Start.")

    try:
        data = client.recv()
        cnt += 1
        data = msgpack.unpackb(data)
        print("%d: data received '%s'"%(cnt, str(data['events'])))
    except:
        print(traceback.format_exc())
        break

    """        
    if msg_json['type'] == 'info':
        if msg_json['info'] == 'end-trial':
            pyerp.utils.save_json(os.path.join(json_save_dir, "oddball.json"), json_save)
    """ 
    
        

    

    
    
