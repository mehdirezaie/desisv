'''
    Systematics of SV ELG



'''
import matplotlib.pyplot as plt
import fitsio as ft
import healpy as hp
import numpy  as np
import pandas as pd
import seaborn as sn
import sys
import os

sys.path.append('/home/mehdi/github/LSSutils')
import LSSutils.utils as ut
from LSSutils.catalogs.combinefits import hd5_2_fits
from LSSutils.catalogs.datarelease import cols_dr8




data = pd.read_hdf('/home/mehdi/data/dr8_combined256.h5')
ngal = hp.read_map('/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits', verbose=False)
frac = hp.read_map('/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits', verbose=False)
data['ngal'] = ngal
data['nran'] = frac



version  = '0.1'
path     = '/home/mehdi/data/formehdi/' + version + '/'
if not os.path.isdir(path):os.makedirs(path)
mysample = data.dropna()
mysample = mysample[mysample['nran']> 0]
hd5_2_fits(mysample, cols_dr8,  
                          fitname= path + 'dr8_elgsv.fits',
                          hpmask = path + 'dr8_elgsv_mask.hp.256.fits',
                          hpfrac = None,
                          fitnamekfold=path + 'dr8_elgsv_5r.npy',
                          res=256,
                          k=5)
print(mysample.shape)

                 
                 
ut.split_mask(path + 'dr8_elgsv_mask.hp.256.fits',
              path + 'dr8_elgsv_mask_ngc.hp.256.fits',
              path + 'dr8_elgsv_mask_sgc.hp.256.fits')