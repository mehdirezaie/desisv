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

export PYTHONPATH=${HOME}/github/LSSutils:${PYTHONPATH}
export NUMEXPR_MAX_THREADS=2

# 0.0 : TS templates all sky
# 0.1 : CCD all sky
# 0.2 : CCD eboss NGC/SGC
# 0.3 : TS bmzls, decalsn decalss with dec > -30
# 0.4 : colorbox selection, everything else as 0.3

version=0.4


# scripts
ablation=${HOME}/github/LSSutils/scripts/analysis/ablation_tf_old.py
nnfit=${HOME}/github/LSSutils/scripts/analysis/nn_fit_tf_old.py
docl=${HOME}/github/LSSutils/scripts/analysis/run_pipeline.py
multfit=${HOME}/github/LSSutils/scripts/analysis/mult_fit.py


# define output names
nside=256
lmax=512




# for tsi in ts ccd
# do
#     for cap in decals decaln bmzls
#     do
    
#         if [ ${tsi} == "ts" ]
#         then 
#             axfit='0 1 2 3 4 5 6 7'  ## Anand's maps version 0.0
#         elif [ ${tsi} == "ccd" ]
#         then 
#             axfit='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20'
#         fi
        
        
#         # ===================
#         # feature selection
#         # ===================
#         # took 130m
#         echo $cap $tsi
        
#         # define out dirs
#         oudir_ab=/home/mehdi/data/formehdi/${version}/ablation_${cap}_${tsi}/
#         oudir_reg=/home/mehdi/data/formehdi/${version}/regression_${cap}_${tsi}/
#         oudir=/home/mehdi/data/formehdi/${version}/clustering_${cap}_${tsi}/
        
#         ngal_features_5fold=/home/mehdi/data/formehdi/dr8_elgsv_${tsi}_${cap}_5r.npy
#         drfeat=/home/mehdi/data/formehdi/dr8_elgsv_${tsi}_${cap}.fits
#         log_ablation=d8elgsv_${tsi}_${cap}.log
#         nn1=nn_ablation_${tsi}_${cap}
#         nn2=nn_plain_${tsi}_${cap}
#         mult1=mult_${tsi}_${cap}


        
#         du -h $galmap
#         du -h $ranmap
#         du -h $ngal_features_5fold
#         du -h $drfeat
#         for rank in 0 1 2 3 4
#         do
#            echo "feature selection on " $rank
#            mpirun -np 16 python $ablation --data $ngal_features_5fold \
#                           --output $oudir_ab --log $log_ablation \
#                         --rank $rank --axfit $axfit
#         done              
#         echo 'regression on ' $cap $tsi $axfit
#         mpirun -np 5 python $nnfit --input $ngal_features_5fold \
#                           --output ${oudir_reg}${nn1}/ \
#                           --ablog ${oudir_ab}${log_ablation} --nside $nside            
        
#         mpirun -np 5 python $nnfit --input $ngal_features_5fold \
#                  --output ${oudir_reg}${nn2}/ --nside $nside --axfit $axfit  

#         python $multfit --input $ngal_features_5fold \
#                         --output ${oudir_reg}${mult1}/ \
#                         --split --nside $nside --axfit $axfit
#     done
# done        


oudir=/home/mehdi/data/formehdi/0.4/clustering/
path2data=${HOME}/data/
galmap=${path2data}formehdi/dr8_elgsv_ngal_pix_0.32.0-colorbox.hp.${nside}.fits
ranmap=${path2data}formehdi/dr8_frac_pix_0.32.0-colorbox.hp.${nside}.fits
templates=${path2data}templates/dr8pixweight-0.32.0_combined${nside}.h5

#--- indices of the templates
# option 1
#axfit='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28'
# option 2
axfit=({0..28})


# loop over survey
for survey in eboss desi
do

    # loop over region
    for region in decaln decals bmzls
    do
        mask=${path2data}formehdi/dr8_mask_${survey}_${region}_pix_0.32.0-colorbox.hp.${nside}.fits
        pathw=${path2data}formehdi/${version}/
        
        # loop over template-based weights
        for wtag in ts ccd
        do
        
            # loop over regression models
            for model in nn nn-ab lin quad uni
            do

                wmap=${pathw}${model}-weights-${wtag}-v${version}hp${nside}.fits
                nnbar=nnbar_${survey}_${region}_${wtag}_${model}.npy 
                logfile=log_${survey}_${region}_${wtag}_${model}.txt
                
                echo $survey $region $wtag ${axfit[@]} ${oudir} ${nnbar} ${logfile}                
                #du -h $mask $galmap $ranmap $templates $wmap

                mpirun -np 16 python $docl --galmap ${galmap} \
                                           --ranmap ${ranmap} \
                                           --wmap ${wmap} \
                                           --photattrs ${templates} \
                                           --mask ${mask} \
                                           --oudir ${oudir} \
                                           --axfit ${axfit[@]} \
                                           --nnbar ${nnbar} \
                                           --log ${logfile}
                                               
            done
        done
    done
done




# #     systematics --- need to run once
# #     maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
# #     du -h $maskc
# #     if [ $1 != "debug" ]
# #     then
# #         mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
# #                       --photattrs $drfeat --mask $maskc --oudir $oudir \
# #                       --verbose --wmap none --clsys cl_${cap}_sys --corsys xi_${cap}_sys \
# #                       --nside ${nside} --lmax $lmax --axfit $axfit --nbin 8
# #     fi
# #     # # galaxies
# #     for wtag in uni ${nn1} ${nn2}
# #     do
# #        wmap=${oudir_reg}${wtag}/nn-weights.hp256.fits
# #        du -h $wmap
# #        maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
# #        du -h $maskc
# #        if [ $1 != "debug" ]
# #        then
# #            mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
# #                         --photattrs $drfeat --mask $maskc --oudir $oudir \
# #                         --verbose --clfile cl_${cap}_${wtag} \
# #                         --nnbar nnbar_${cap}_${wtag} --nside $nside \
# #                         --lmax $lmax --axfit $axfit --corfile xi_${cap}_${wtag} \
# #                         --nbin 8 --wmap $wmap
# #       fi
# #     done                
# #done






# # # define out dirs
# # oudir_ab=/home/mehdi/data/formehdi/${version}/ablation/
# # oudir_reg=/home/mehdi/data/formehdi/${version}/regression/  
# # oudir=/home/mehdi/data/formehdi/${version}/clustering/


# # # files

# # galmap=/home/mehdi/data/formehdi/dr8_elgsv_ngal.hp.256.fits
# # ranmap=/home/mehdi/data/formehdi/dr8_elgsv_frac.hp.256.fits






# # # for cap in ngc sgc
# # # do
# # #     # ===================
# # #     # feature selection
# # #     # ===================
# # #     # took 130m

# # #     ngal_features_5fold=/home/mehdi/data/formehdi/${version}/dr8_elgsv_${cap}_5r.npy
# # #     drfeat=/home/mehdi/data/formehdi/${version}/dr8_elgsv_${cap}.fits
# # #     log_ablation=d8elgsv_${cap}.log
# # #     nn1=nn_ablation_${cap}
# # #     nn2=nn_plain_${cap}
# # #     mult1=mult_${cap}

# # #     du -h $galmap
# # #     du -h $ranmap
# # #     du -h $ngal_features_5fold
# # #     du -h $drfeat
# # #     for rank in 0 1 2 3 4
# # #     do
# # #        echo "feature selection on " $rank
# # #        mpirun -np 16 python $ablation --data $ngal_features_5fold \
# # #                     --output $oudir_ab --log $log_ablation \
# # #                     --rank $rank --axfit $axfit
# # #     done              
# # #     echo 'regression on ' $rank $capzcut
# # #     mpirun -np 5 python $nnfit --input $ngal_features_5fold \
# # #                       --output ${oudir_reg}${nn1}/ \
# # #                       --ablog ${oudir_ab}${log_ablation} --nside $nside            
# # #     mpirun -np 5 python $nnfit --input $ngal_features_5fold \
# # #              --output ${oudir_reg}${nn2}/ --nside $nside --axfit $axfit  
    
# # #     python $multfit --input $ngal_features_5fold --output ${oudir_reg}${mult1}/ --split --nside $nside --axfit $axfit

# #     # ===================
# #     # Angular Clustering
# #     # ===================

# #     # systematics --- need to run once
# # #     maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
# # #     du -h $maskc
# # #     if [ $1 != "debug" ]
# # #     then
# # #         mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
# # #                       --photattrs $drfeat --mask $maskc --oudir $oudir \
# # #                       --verbose --wmap none --clsys cl_${cap}_sys --corsys xi_${cap}_sys \
# # #                       --nside ${nside} --lmax $lmax --axfit $axfit --nbin 8
# # #     fi
# # #     # # galaxies
# # #     for wtag in uni ${nn1} ${nn2}
# # #     do
# # #        wmap=${oudir_reg}${wtag}/nn-weights.hp256.fits
# # #        du -h $wmap
# # #        maskc=/home/mehdi/data/formehdi/${version}/dr8_elgsv_mask_${cap}.hp.256.fits
# # #        du -h $maskc
# # #        if [ $1 != "debug" ]
# # #        then
# # #            mpirun -np 16 python $docl --galmap $galmap --ranmap $ranmap \
# # #                         --photattrs $drfeat --mask $maskc --oudir $oudir \
# # #                         --verbose --clfile cl_${cap}_${wtag} \
# # #                         --nnbar nnbar_${cap}_${wtag} --nside $nside \
# # #                         --lmax $lmax --axfit $axfit --corfile xi_${cap}_${wtag} \
# # #                         --nbin 8 --wmap $wmap
# # #       fi
# # #     done                
# # # done
# # 
