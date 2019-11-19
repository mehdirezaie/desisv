'''
    Systematics of SV ELG


    Nov 11, 2019 : perform regression on the NGC / SGC separately
                   only on the eBOSS footprint
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


prepare_regression = False


if prepare_regression:
    # path
    version  = '0.2'
    path     = '/home/mehdi/data/formehdi/' + version + '/'
    if not os.path.isdir(path):os.makedirs(path)
    
    # read
    data = pd.read_hdf('/home/mehdi/data/dr8_combined256.h5')
    mask = hp.read_map('/home/mehdi/data/formehdi/dr8_mask_eBOSS.hp256.fits',          verbose=False).astype('bool')
    data['ngal'] = hp.read_map('/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits', verbose=False)
    data['nran'] = hp.read_map('/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits', verbose=False)

    # split into NGC and SGC
    caps = ['ngc', 'sgc']
    ngc, sgc = ut.split2caps(mask)        
    for i,cap in enumerate([ngc, sgc]):    
        mysample = data[(data['nran']> 0) & cap[data.index]]
        mysample = mysample.dropna()
        hd5_2_fits(mysample, cols_dr8,  
                                  fitname= path + 'dr8_elgsv_'+caps[i]+'.fits',
                                  hpmask = path + 'dr8_elgsv_mask_'+caps[i]+'.hp.256.fits',
                                  hpfrac = None,
                                  fitnamekfold=path + 'dr8_elgsv_'+caps[i]+'_5r.npy',
                                  res=256,
                                  k=5)
        print(mysample.shape)