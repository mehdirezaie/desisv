#!/bin/bash
# [c] Mehdi  -- Oct 31, 2019
# ELG SV
#
# history
# 
#-------
# Oct 31: 
# run the ablation and regression
# > time bash analyze.bash regression
# 21 m for ablation


#
# initialize the env.
#
if [ -f "~/.bash_profile" ]
then
	source ~/.bash_profile
fi

if [ $HOST == "lakme" ]
then 
    eval "$(/home/mehdi/miniconda3/bin/conda shell.bash hook)"
fi
conda activate py3p6


#axfit='0 1 2 3 4 5 6 7'  ## Anand's maps version 0.0
version=0.2
axfit='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20'


# scripts
ablation=/home/mehdi/github/LSSutils/scripts/analysis/ablation_tf_old.py
nnfit=/home/mehdi/github/LSSutils/scripts/analysis/nn_fit_tf_old.py
docl=/home/mehdi/github/LSSutils/scripts/analysis/run_pipeline.py


# define output names
nside=256
lmax=512


# define out dirs
oudir_ab=/home/mehdi/data/formehdi/${version}/ablation/
oudir_reg=/home/mehdi/data/formehdi/${version}/regression/  
oudir=/home/mehdi/data/formehdi/${version}/clustering/


# files

galmap=/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits
ranmap=/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits






for cap in ngc sgc
do
    # ===================
    # feature selection
    # ===================
    # took 130m

    ngal_features_5fold=/home/mehdi/data/formehdi/${version}/dr8_elgsv_${cap}_5r.npy
    drfeat=/home/mehdi/data/formehdi/${version}/dr8_elgsv_${cap}.fits
    log_ablation=d8elgsv_${cap}.log
    nn1=nn_ablation_${cap}
    nn2=nn_plain_${cap}

    du -h $galmap
    du -h $ranmap
    du -h $ngal_features_5fold
    du -h $drfeat
    #for rank in 0 1 2 3 4
    #do
    #    echo "feature selection on " $rank
    #    mpirun -np 16 python $ablation --data $ngal_features_5fold \
    #                 --output $oudir_ab --log $log_ablation \
    #                 --rank $rank --axfit $axfit
    #done              
    #echo 'regression on ' $rank $capzcut
    #mpirun -np 5 python $nnfit --input $ngal_features_5fold \
    #                   --output ${oudir_reg}${nn1}/ \
    #                   --ablog ${oudir_ab}${log_ablation} --nside $nside            
    #mpirun -np 5 python $nnfit --input $ngal_features_5fold \
    #          --output ${oudir_reg}${nn2}/ --nside $nside --axfit $axfit             

    # ===================
    # Angular Clustering
    # ===================

    # systematics --- need to run once
    maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
    du -h $maskc
    if [ $1 != "debug" ]
    then
        mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
                      --photattrs $drfeat --mask $maskc --oudir $oudir \
                      --verbose --wmap none --clsys cl_${cap}_sys --corsys xi_${cap}_sys \
                      --nside ${nside} --lmax $lmax --axfit $axfit --nbin 8
    fi
    # # galaxies
    for wtag in uni ${nn1} ${nn2}
    do
       wmap=${oudir_reg}${wtag}/nn-weights.hp256.fits
       du -h $wmap
       maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
       du -h $maskc
       if [ $1 != "debug" ]
       then
           mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
                        --photattrs $drfeat --mask $maskc --oudir $oudir \
                        --verbose --clfile cl_${cap}_${wtag} \
                        --nnbar nnbar_${cap}_${wtag} --nside $nside \
                        --lmax $lmax --axfit $axfit --corfile xi_${cap}_${wtag} \
                        --nbin 8 --wmap $wmap
       fi
    done                
done
