import matplotlib.pyplot as plt
import fitsio as ft
import healpy as hp
import numpy  as np
import pandas as pd
import seaborn as sn
import sys
sys.path.append('/home/mehdi/github/LSSutils')
from LSSutils.catalogs.combinefits import hd5_2_fits








def anand():
    dr8_elg = ft.read('/home/mehdi/data/formehdi/pixweight_ar-dr8-0.32.0-elgsv.fits')
    nside   = 256 
    npix    = 12*nside*nside

    ss     = ['GALDEPTH_R',
              'GALDEPTH_G',
              'GALDEPTH_Z',
              'PSFSIZE_R',
              'PSFSIZE_G',
              'PSFSIZE_Z',
              'EBV',
              'STARDENS']

    sysmaps = {}

    sysmaps['HPIX'] = np.arange(npix)#.astype('i8')
    for ss_i in ss:
        sysmaps[ss_i] = hp.reorder(dr8_elg[ss_i], n2r=True)


    sysmaps['nran']  = hp.reorder(dr8_elg['FRACAREA'], n2r=True)
    sysmaps['ngal']  = hp.reorder(dr8_elg['SV'], n2r=True) * sysmaps['nran'] * hp.nside2pixarea(256, degrees=True)

    dataframe = pd.DataFrame(sysmaps)
    dataframe.replace([np.inf, -np.inf], value=np.nan, inplace=True) # replace inf
    
    dataframe.to_hdf('/home/mehdi/data/formehdi/dr8_elgsv.h5', 'data', overwrite=True)
    
    hp.write_map('/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits', dataframe.ngal, 
             fits_IDL=False, dtype=np.float64)
    
    mysample = dataframe[dataframe['nran']>0]
    mysample.dropna(inplace=True)
    mysample.shape    
    hd5_2_fits(mysample, ss,  
                          fitname='/home/mehdi/data/formehdi/dr8_elgsv.fits',
                          hpmask='/home/mehdi/data/formehdi/dr8_elgsv_mask.hp.256.fits',
                          hpfrac='/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits',
                          fitnamekfold='/home/mehdi/data/formehdi/dr8_elgsv_5r.npy',
                          res=256,
                          k=5)
    return 0



def mehdi(data,
          version='0.1',
          nside=256):
          
    dtframe = pd.read_hdf(data) 

    npix    = 12*nside*nside

    ss     = ['GALDEPTH_R',
              'GALDEPTH_G',
              'GALDEPTH_Z',
              'PSFSIZE_R',
              'PSFSIZE_G',
              'PSFSIZE_Z',
              'EBV',
              'STARDENS']

    sysmaps = {}

    sysmaps['HPIX'] = np.arange(npix)#.astype('i8')
    for ss_i in ss:
        sysmaps[ss_i] = hp.reorder(dr8_elg[ss_i], n2r=True)


    sysmaps['nran']  = hp.reorder(dr8_elg['FRACAREA'], n2r=True)
    sysmaps['ngal']  = hp.reorder(dr8_elg['SV'], n2r=True) * sysmaps['nran'] * hp.nside2pixarea(256, degrees=True)

    dataframe = pd.DataFrame(sysmaps)
    dataframe.replace([np.inf, -np.inf], value=np.nan, inplace=True) # replace inf
    
    dataframe.to_hdf('/home/mehdi/data/formehdi/dr8_elgsv.h5', 'data', overwrite=True)
    
    hp.write_map('/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits', dataframe.ngal, 
             fits_IDL=False, dtype=np.float64)
    
    hd5_2_fits(mysample, ss,  fitname='/home/mehdi/data/formehdi/dr8_elgsv.fits',
                          hpmask='/home/mehdi/data/formehdi/dr8_elgsv_mask.hp.256.fits',
                          hpfrac='/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits',
                          fitnamekfold='/home/mehdi/data/formehdi/dr8_elgsv_5r.npy',
                          res=256,
                          k=5)
    return 0
