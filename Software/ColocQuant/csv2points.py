import argparse
import sys
import os
import pandas as pd
import numpy as np



def csv2points(input_folder, out_folder, is3D):
    
    
    #check if points folder exists
    if not os.path.exists(out_folder):
        os.mkdir(out_folder)
        
    
    #list all csv files
    list_csv = os.listdir(input_folder)
    list_csv.sort()
    #used for cancatination
    frames = []
    
    #iterate through all csv files
    for i in list_csv:
    
        data_path = input_folder +'/'+i
        read_out  = pd.read_csv(data_path,header=None)
        if is3D is True:
            #drop all information; use only time point and x,y information
            read_out = read_out.drop(read_out.columns[np.array(list(range(4,read_out.shape[1])))], axis=1)
            #set track ID
            read_out[5] = i
        else:  
            #drop all information; use only time point and x,y information
            read_out = read_out.drop(read_out.columns[np.array(list(range(3,read_out.shape[1])))], axis=1)
            #set Z=0
            read_out[4] = int(0)
            #set track ID
            read_out[5] = i
        frames.append(read_out)
    
    
    #concat data frames
    detections = pd.concat(frames,axis=0)
    
    #find max time step
    max_t = int(max(detections[0]))
    
    #iterate over all timepoints and write out csv file with detection coordinates
    for i in range(0,(max_t+1)):
    
        detection_t = detections[detections[0] == i]
        #drop time in data frame
        detection_t = detection_t.drop(detection_t.columns[[0]],axis=1)
        #write to csv file in output folder
        name = out_folder+'/'+'trackingResults_t'+str(i)+'.csv'
        detection_t.to_csv(name,index=False,header=False)
        
        

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('input_folder', help='input folder with tracks (CSV)')
    parser.add_argument('out_folder', help='output folder with detections (CSV)')
    parser.add_argument("--is3D", help="is 3D data", action="store_true")
    
    args         = parser.parse_args()
    input_folder = args.input_folder
    out_folder   = args.out_folder
    is3D         = args.is3D
    
    #TOOL    
    csv2points(input_folder, out_folder, is3D)
    
    
    
    
    
    
    
   
