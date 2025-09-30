#!/bin/bash
# The script generetes the structural connectomes using MRtrix3
# Requirements: ANTs, FSL, Anima, MRtrix3, Python3 with the environment_preprocessing_and_metrics.yaml environment
#import Anima bins
Anima_dir=/path_to_anima_folder/.anima/
export PATH=$PATH:/${Anima_dir}/Anima-Binaries-4.2/
export PATH=$PATH:/${Anima_dir}/Anima-Scripts-Public/

#import ANTS bins
ANTS_dir=/path_to_ANTS_folder/ANTS
export ANTSPATH=${ANTS_dir}/install/bin/
export PATH=${ANTSPATH}:$PATH
#import FSL bins
FSL_dir=/path_to_fsl_folder/fsl
. ${FSL_dir}/etc/fslconf/fsl.sh
PATH=${FSL_dir}/bin:${PATH}
export FSL_dir PATH
## activate env for mrtrix
module load conda
conda activate environment_preprocessing_and_metrics


Parcellation_dir="/path_to_parcellation_folder/PARCELLATION/"
Template_dir="/path_to_template_folder/TEMPLATE/"
DATASET_dir="/path_to_dataset_folder/Nifti/"


Patients=("sub-001" "sub-002" "sub-003")

for Patient in "${Patients[@]}" 
do
    echo "Processing patient: $Patient"
    Parcellation=${Parcellation_dir}Schaefer/Cortex-Subcortex/Schaefer2018_400Parcels_7Networks_order_Tian_Subcortex_S1_MNI152NLin2009cAsym_1mm.nii.gz
    Parcellation_T1_space_MNI=${DATASET_dir}${Patient}/anat/${Patient}_space-orig_atlas-Schaefer2018-400Parcels-7Networks-Tian_Subcortex_S1
    Parcellation_T1_space_MIITRA=${DATASET_dir}${Patient}/anat/${Patient}_space-orig_atlas-Schaefer2018-400Parcels-7Networks-Tian_Subcortex_S1_MIITRA
    Template_Space="MNI152NLin2009cAsym"
    Template_Space2="MIITRA"
    cd ${DATASET_dir}${Patient}/anat/

    T1_Template_dir=${Template_dir}${Template_Space}/
    T1_Template=${T1_Template_dir}${Template_Space}_T1_1mm.nii.gz
    T1_Template_brain=${T1_Template_dir}${Template_Space}_T1_1mm_brain.nii.gz
    Template_brain_mask=${T1_Template_dir}${Template_Space}_mask.nii.gz
    
    T1_Template_dir2=${Template_dir}${Template_Space2}/
    T1_Template2=${T1_Template_dir2}${Template_Space2}_T1_1mm.nii.gz
    T1_Template_brain2=${T1_Template_dir2}${Template_Space2}_T1_1mm_brain.nii.gz
    Template_brain_mask2=${T1_Template_dir2}${Template_Space2}_mask.nii.gz

    T1_subject_brain=${Patient}_T1w_masked
    T1_subject=${Patient}_T1w_reorient.nii.gz
    T1_subject_brain_mask=${Patient}_T1w_brainMask.nii.gz 
    

 
    #USING ANTS for non linear registration to template space 
    echo " =>"
    echo "Non linear registration to template space ($Template_Space2) [ANTS: antsRegistration (Rigid+Affine+NonLinear)]"
    antsRegistration -d 3 --float 0 -o [ ${Patient}_T1to${Template_Space2}_ , ${Patient}_T1to${Template_Space2}.nii.gz] -n Linear -w [ 0.005 , 0.995] -u 0 -r [ $T1_Template_brain2, ${T1_subject_brain}.nii.gz, 1] -t Rigid[0.1] -m MI[$T1_Template_brain2, ${T1_subject_brain}.nii.gz, 1, 32, Regular, 0.25] -c [ 1000x500x250x100, 1e-7, 10]  -f 8x4x2x1 -s 3x2x1x0vox -t Affine[0.1] -m MI[ $T1_Template_brain2, ${T1_subject_brain}.nii.gz, 1, 32, Regular, 0.25] -c [ 1000x500x250x100, 1e-7,10] -f 8x4x2x1 -s 3x2x1x0vox -t SyN[ 0.1, 3, 0] -m CC[ $T1_Template_brain2, ${T1_subject_brain}.nii.gz, 1, 4] -c [ 200x200x200x200, 1e-7, 10] -f 8x4x2x1 -s 3x2x1x0vox 
    echo " =>"
    echo "Registering Parcellation to subject space [ANTS: antsApplyTransforms] MNI to MIITRA TO SUBJECT SPACE"
    antsApplyTransforms -d 3 --float 0 -i $Parcellation  -r ${T1_subject_brain}.nii.gz -n NearestNeighbor -t [ ${Patient}_T1to${Template_Space2}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space2}_1InverseWarp.nii.gz -t [ ${T1_Template_dir2}Transformation_to_ICBM2009b/Transformation_to_ICBM2009b/MIITRA_to_ICBM2009b_1Affine.txt,1] -t ${T1_Template_dir2}Transformation_to_ICBM2009b/Transformation_to_ICBM2009b/MIITRA_to_ICBM2009b_2InverseWarp.nii.gz -t [ ${T1_Template_dir2}Transformation_to_ICBM2009b/Transformation_to_ICBM2009b/MIITRA_to_ICBM2009b_3Affine.txt,1] -t ${T1_Template_dir2}Transformation_to_ICBM2009b/Transformation_to_ICBM2009b/MIITRA_to_ICBM2009b_4InverseWarp.nii.gz  -o ${Parcellation_T1_space_MIITRA}.nii.gz 
    echo " =>"
    echo "Registering Template mask to subject space [ANTS: antsApplyTransforms]"
    antsApplyTransforms -d 3 --float 0 -i $Template_brain_mask2  -r ${T1_subject_brain}.nii.gz -n NearestNeighbor  -t [ ${Patient}_T1to${Template_Space2}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space2}_1InverseWarp.nii.gz  -o ${Patient}_T1w_brainMask_tight_${Template_Space2}.nii.gz 
    fslmaths $T1_subject_brain_mask -mul ${Patient}_T1w_brainMask_tight_${Template_Space2}.nii.gz ${Patient}_T1w_brainMask_tight_${Template_Space2}.nii.gz

    ## registering MIITRA priors to subject space and ensuring they are between 0 and 1
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir2}${Template_Space2}_csf.nii.gz  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space2}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space2}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_csf_priors_${Template_Space2}.nii.gz 
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir2}${Template_Space2}_wm.nii.gz  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space2}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space2}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_wm_priors_${Template_Space2}.nii.gz 
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir2}${Template_Space2}_gm.nii.gz  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space2}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space2}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_gm_priors_${Template_Space2}.nii.gz

    ## registering MNI priors to subject space and ensuring they are between 0 and 1
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir}${Template_Space}_csf.nii  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_csf_priors_${Template_Space}.nii.gz 
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir}${Template_Space}_wm.nii  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_wm_priors_${Template_Space}.nii.gz 
    antsApplyTransforms -d 3 --float 0 -i ${T1_Template_dir}${Template_Space}_gm.nii  -r ${T1_subject_brain}.nii.gz -n Linear -t [ ${Patient}_T1to${Template_Space}_0GenericAffine.mat, 1 ] -t ${Patient}_T1to${Template_Space}_1InverseWarp.nii.gz  -o ${T1_subject_brain}_gm_priors_${Template_Space}.nii.gz
    
    cd ${DATASET_dir}${Patient}/dwi/
    ##MIITRA
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_csf_priors_${Template_Space2}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space2}_coreg.nii.gz -force
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_wm_priors_${Template_Space2}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space2}_coreg.nii.gz -force
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_gm_priors_${Template_Space2}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space2}_coreg.nii.gz -force
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space2}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space2}_coreg_axial.nii.gz -R AXIAL
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space2}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space2}_coreg_axial.nii.gz -R AXIAL
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space2}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space2}_coreg_axial.nii.gz -R AXIAL
    mrtransform -linear  ${Patient}_DWI2T1_mrtrix.txt -inverse ${Parcellation_T1_space_MIITRA}.nii.gz ${Parcellation_T1_space_MIITRA}_coreg.nii.gz -interp nearest -force
    animaConvertImage -i ${Parcellation_T1_space_MIITRA}_coreg.nii.gz  -o ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz -R AXIAL

    ##MNI
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_csf_priors_${Template_Space}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space}_coreg.nii.gz -force
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_wm_priors_${Template_Space}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space}_coreg.nii.gz -force
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse ${DATASET_dir}${Patient}/anat/${T1_subject_brain}_gm_priors_${Template_Space}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space}_coreg.nii.gz -force
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space}_coreg_axial.nii.gz -R AXIAL
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space}_coreg_axial.nii.gz -R AXIAL
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space}_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space}_coreg_axial.nii.gz -R AXIAL
    mrtransform -linear  ${Patient}_DWI2T1_mrtrix.txt -inverse ${Parcellation_T1_space_MNI}.nii.gz ${Parcellation_T1_space_MNI}_coreg.nii.gz -interp nearest -force
    animaConvertImage -i ${Parcellation_T1_space_MNI}_coreg.nii.gz  -o ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz -R AXIAL


    #coregister T1w brain mask to dwi space
    mrtransform -linear ${Patient}_DWI2T1_mrtrix.txt -inverse -interp nearest ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg.nii.gz -force
    animaConvertImage -i ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg.nii.gz  -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg_axial.nii.gz -R AXIAL

    cd ${DATASET_dir}${Patient}/anat/
    #tractography 
    T1=${Patient}_T1w_masked_coreg_axial
    fivett_file=${DATASET_dir}${Patient}/anat/${T1}_5tt
    seeding_mask=${DATASET_dir}${Patient}/anat/${T1}_5tt2gmwmi

    echo " "
    echo " => Generating 5tt image from T1 at 1mm resolution "
    5ttgen fsl ${T1}.nii.gz ${fivett_file}.nii.gz -premasked -nocrop -force
    animaConvertImage -i ${fivett_file}.nii.gz -o ${fivett_file}.nii.gz -R AXIAL
    5tt2gmwmi ${fivett_file}.nii.gz ${seeding_mask}.nii.gz -force

    cd ${DATASET_dir}${Patient}/dwi/
    dwi_file=${Patient}_dwi_preprocessed

    N_tracks=10M
    echo " "
    echo " => TCKGEN act fsl"
    tckgen ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_act.tck -algorithm iFOD2 -maxlength 600 -seed_gmwmi ${seeding_mask}.nii.gz -cutoff 0.05 -angle 60 -select $N_tracks -backtrack -act ${fivett_file}.nii.gz -force
    tcksift2 ${Patient}_wm_tracks_${N_tracks}_act.tck ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_weights_act.txt -act ${fivett_file}.nii.gz -force

    echo " "
    echo " => Connectome act fsl"
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_act_MNI.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_act.txt
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_act_MNI.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_act.txt -scale_invnodevol
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_act_MNI.txt -force -zero_diagonal -symmetric
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_act_MNI.txt -force -zero_diagonal -symmetric -scale_invnodevol
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_act_MIITRA.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_act.txt
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_act_MIITRA.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_act.txt -scale_invnodevol
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_act_MIITRA.txt -force -zero_diagonal -symmetric
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_act_MIITRA.txt -force -zero_diagonal -symmetric -scale_invnodevol

    seeding_mask=${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg_axial 
    
    echo " "
    echo " => TCKGEN no act fsl"
    tckgen ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_no_act.tck -algorithm iFOD2 -maxlength 600 -seed_image ${seeding_mask}.nii.gz -angle 60 -cutoff 0.05 -select $N_tracks -force
    tcksift2 ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_weights_no_act.txt  -force

    echo " "
    echo " => Connectome no act fsl"
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_no_act_MNI.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_no_act.txt
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_no_act_MNI.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_no_act.txt -scale_invnodevol
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_no_act_MNI.txt -force -zero_diagonal -symmetric
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_no_act_MNI.txt -force -zero_diagonal -symmetric -scale_invnodevol
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_no_act_MIITRA.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_no_act.txt
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_no_act_MIITRA.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_no_act.txt -scale_invnodevol 
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_no_act_MIITRA.txt -force -zero_diagonal -symmetric 
    tck2connectome ${Patient}_wm_tracks_${N_tracks}_no_act.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_no_act_MIITRA.txt -force -zero_diagonal -symmetric -scale_invnodevol 

    cd ${DATASET_dir}${Patient}/anat/
    ## Tractography with ants segmentation 
    fslroi ${fivett_file}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_02.nii.gz 1 1
    fslroi ${fivett_file}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_05.nii.gz 4 1
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space2}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_04.nii.gz
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space2}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_03.nii.gz
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space2}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_01.nii.gz
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_csf_priors_${Template_Space}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_04.nii.gz
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_wm_priors_${Template_Space}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_03.nii.gz
    cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_gm_priors_${Template_Space}_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_01.nii.gz
    fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_01.nii.gz -sub ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_02.nii.gz -thr 0 ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_01.nii.gz
    fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_01.nii.gz -sub ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_02.nii.gz -thr 0 ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_01.nii.gz
    

    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_02.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_02.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_05.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_05.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_03.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_03.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_04.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_04.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_01.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_01.nii.gz 1 1 1
    
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_02.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_02.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial_label_05.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_05.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_03.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_03.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_04.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_04.nii.gz 1 1 1
    CopyImageHeaderInformation ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_01.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_01.nii.gz 1 1 1
    

    cd ${DATASET_dir}${Patient}/dwi/

    echo " "

    echo " => TCKGEN act ants MNI"
    for thr in $(seq 0.25 0.05 0.5); do
        echo "THR= $thr_suf"
        thr_suf=$(printf "%.0f" $(echo "$thr * 100" | bc))


        antsAtroposN4.sh -d 3 -a ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz -x ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg_axial.nii.gz -c 4 -p ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_%02d.nii.gz -w $thr -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_

        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 1 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_01.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 2 -thr 2 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_02.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 3 -thr 3 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_03.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 4 -thr 4 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_04.nii.gz
        #fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation.nii.gz -thr 5 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz
        cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_label_05.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz


        fivett_file=${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_5tt_ants
        seeding_mask=${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_5tt2gmwmi_ants
        fslmerge -t ${fivett_file}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_01.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_02.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_03.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_04.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz
        5tt2gmwmi ${fivett_file}.nii.gz ${seeding_mask}.nii.gz -force

        N_tracks=10M
        echo " "
        echo " => TCKGEN "
        tckgen ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck -algorithm iFOD2 -maxlength 600 -seed_gmwmi ${seeding_mask}.nii.gz -cutoff 0.05 -angle 60 -select $N_tracks -backtrack -act ${fivett_file}.nii.gz -force
        tcksift2 ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space}.txt -act ${fivett_file}.nii.gz -force

        echo " "
        echo " => Connectome "
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_${thr_suf}_${Template_Space}.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space}.txt 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_${thr_suf}_${Template_Space}.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space}.txt -scale_invnodevol 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_${thr_suf}_${Template_Space}.txt -force -zero_diagonal -symmetric 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space}.tck ${Parcellation_T1_space_MNI}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_${thr_suf}_${Template_Space}.txt -force -zero_diagonal -symmetric -scale_invnodevol 
    done
    echo " => TCKGEN act ants MNI"
    for thr in $(seq 0.25 0.05 0.5); do

        thr_suf=$(printf "%.0f" $(echo "$thr * 100" | bc))
        echo "THR= $thr_suf"

        antsAtroposN4.sh -d 3 -a ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_coreg_axial.nii.gz -x ${DATASET_dir}${Patient}/anat/${Patient}_T1w_brainMask_coreg_axial.nii.gz -c 4 -p ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_%02d.nii.gz -w $thr -o ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_

        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 1 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_01.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 2 -thr 2 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_02.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 3 -thr 3 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_03.nii.gz
        fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation.nii.gz -uthr 4 -thr 4 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_04.nii.gz
        #fslmaths ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation.nii.gz -thr 5 -bin ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz
        cp ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_label_05.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz


        fivett_file=${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_5tt_ants
        seeding_mask=${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_5tt2gmwmi_ants
        fslmerge -t ${fivett_file}.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_01.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_02.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_03.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_04.nii.gz ${DATASET_dir}${Patient}/anat/${Patient}_T1w_masked_${Template_Space2}_coreg_axial_${thr_suf}_Segmentation_05.nii.gz
        5tt2gmwmi ${fivett_file}.nii.gz ${seeding_mask}.nii.gz -force

        N_tracks=10M
        echo " "
        echo " => TCKGEN "
        tckgen ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck -algorithm iFOD2 -maxlength 600 -seed_gmwmi ${seeding_mask}.nii.gz -cutoff 0.05 -angle 60 -select $N_tracks -backtrack -act ${fivett_file}.nii.gz -force
        tcksift2 ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck ${dwi_file}_out_wmfod.nii.gz ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space2}.txt -act ${fivett_file}.nii.gz -force

        echo " "
        echo " => Connectome "
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_${thr_suf}_${Template_Space2}.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space2}.txt 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_${thr_suf}_${Template_Space2}.txt -force -zero_diagonal -symmetric -tck_weights_in ${Patient}_wm_tracks_${N_tracks}_weights_${thr_suf}_${Template_Space2}.txt -scale_invnodevol 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_unweighted_${thr_suf}_${Template_Space2}.txt -force -zero_diagonal -symmetric 
        tck2connectome ${Patient}_wm_tracks_${N_tracks}_${thr_suf}_${Template_Space2}.tck ${Parcellation_T1_space_MIITRA}_coreg_axial.nii.gz connectome_${N_tracks}_density_unweighted_${thr_suf}_${Template_Space2}.txt -force -zero_diagonal -symmetric -scale_invnodevol 
    done
done