import os
import traceback


import numpy as np
import msgpack
import pyicom as icom

import joblib

ip = "localhost"
port = 49153



def load_pretrained_model():
    csp = joblib.load("finalcspmodel.pkl")
    clf = joblib.load("Ensembleclfmodel.pkl")
    return csp, clf

if __name__ == "__main__":

    csp, clf = load_pretrained_model()
    client = icom.client(ip = ip,
                     port = port)
    client.connect()
    print("connected.")

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
            print(np.array(data["epochs"]).shape)

            # data is contained in...
            # data["epochs"]

            # trigger number is contained in...
            # data["events"]

            data = np.array(data["epochs"])
            data = np.transpose(np.atleast_3d(data), axes = [2, 0, 1])
            data_csp = csp.transform(data)
            preds = clf.predict(data_csp)
            print(preds)

        except:
            print(traceback.format_exc())
            break

    
        

    

    
    
