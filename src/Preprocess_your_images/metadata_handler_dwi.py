import os
import sys
print(sys.path)
import numpy as np
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument('-dir', '--dataset_dir', type=str, required=True, help='Dataset Directory')
parser.add_argument('-p', '--patient', type=str, required=True, help='patient id string')
parser.add_argument('-m', '--manufacturer', type=str, required=True, help='Scanner Manufacturer') 
parser.add_argument('-dd', '--dwell_dwi', type=float, required=True, help='dwell time dwi')
parser.add_argument('-rotd', '--readout_time_dwi', type=float, required=True, help='REad out time dwi ')
parser.add_argument('-ped', '--phase_encoding_dwi', type=str, required=True, help='Phase encoding dwi')
args = parser.parse_args()

os.chdir(os.path.join(args.dataset_dir,args.patient))

matrix = np.loadtxt(os.path.join("dwi",args.patient + "_dwi.bvec"), dtype='f', delimiter=' ')
matrix[1,:]=-matrix[1,:]
np.savetxt(os.path.join("dwi",args.patient + "_dwi_real.bvec"),matrix ,fmt='%.8f')

config_dwi=np.zeros((2,4))
#print(args.phase_encoding_dwi)
#print(args.phase_encoding_dwi=='"j"')
#print(args.phase_encoding_dwi=='"j-"')
if args.phase_encoding_dwi=='"j"':
    config_dwi[0,1]=1
    config_dwi[1,1]=-1
elif args.phase_encoding_dwi=='"j-"':
    config_dwi[0,1]=-1
    config_dwi[1,1]=1
elif args.phase_encoding_dwi=='"i"':
    config_dwi[0,0]=1
    config_dwi[1,0]=-1
elif args.phase_encoding_dwi=='"i-"':
    config_dwi[0,0]=-1
    config_dwi[1,0]=1
elif args.phase_encoding_dwi=='"k"':
    config_dwi[0,2]=1
    config_dwi[1,2]=-1
elif args.phase_encoding_dwi=='"k-"':
    config_dwi[0,2]=-1
    config_dwi[1,2]=1
config_dwi[0,3]=args.readout_time_dwi
config_dwi[1,3]=args.readout_time_dwi
np.savetxt("config_dwi.txt", config_dwi, fmt='%.8f', delimiter=' ')
