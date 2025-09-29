import pandas as pd 
import numpy as np 
import os 
excel=pd.read_excel("dataset.xlsx")
mri=pd.read_csv("MRI3META.csv")
demog=pd.read_csv("PTDEMOG.csv")
diag=pd.read_csv("DXSUM.csv")
amy=pd.read_csv("UCBERKELEY_AMY.csv")
mmse=pd.read_csv("MMSE.csv")
moca=pd.read_csv("MOCA.csv")
wmh=pd.read_csv("UCD_WMH.csv")
excel[["Diagnosis"]]=excel[["Diagnosis"]].astype(str)
excel[["Age"]]=excel[["Age"]].astype(float)
for i in range(excel.Subject.size):
    subject=excel.Subject.array[i]
    visit_code=excel.Visit.array[i]
    ## MRI SITE ID
    mri_subject_index=np.where(mri.PTID.array==subject)
    if visit_code=="bl":
        mri_visit_index=np.where(mri.VISCODE.array=="sc")
        visit_code2="bl"
    else:
        mri_visit_index=np.where(mri.VISCODE.array==visit_code)
    mri_index=np.intersect1d(mri_subject_index,mri_visit_index)
    if len(mri_index)==1:
        if not(visit_code=="bl"):
            visit_code2=mri.VISCODE2.array[mri_index[0]]
        if len(mri_index)==1:
            excel.SiteID.array[i]=mri.SITEID.array[mri_index[0]]
        ## MMSE
        mmse_subject_index=np.where(mmse.PTID.array==subject)
        if visit_code=="bl":
            mmse_visit_index=np.where(mmse.VISCODE2.array=="sc")
        else:
            mmse_visit_index=np.where(mmse.VISCODE2.array==visit_code2)
        mmse_index=np.intersect1d(mmse_subject_index,mmse_visit_index)
        if len(mmse_index)==1:
            excel.MMSE.array[i]=mmse.MMSCORE.array[mmse_index[0]]    
    else:
        ## MMSE
        mmse_subject_index=np.where(mmse.PTID.array==subject)
        if visit_code=="bl":
            mmse_visit_index=np.where(mmse.VISCODE.array=="sc")
        else:
            mmse_visit_index=np.where(mmse.VISCODE.array==visit_code)
            
        mmse_index=np.intersect1d(mmse_subject_index,mmse_visit_index)
        visit_code2=mmse.VISCODE2.array[mmse_index[0]]
        if len(mmse_index)==1:
            excel.MMSE.array[i]=mmse.MMSCORE.array[mmse_index[0]]

    ## PT EDUCATION YEARS
    edu_subject_index=np.where(demog.PTID.array==subject)
    edu_visit_index=np.where(demog.VISCODE2.array=="sc")
    edu_index=np.intersect1d(edu_subject_index,edu_visit_index)
    if len(edu_index)>0:
        excel.PTEDUCAT.array[i]=demog.PTEDUCAT.array[edu_index[0]]

    # DIAGNOSIS
    diag_subject_index=np.where(diag.PTID.array==subject)
    diag_visit_index=np.where(diag.VISCODE2.array==visit_code2)
    diag_index=np.intersect1d(diag_subject_index,diag_visit_index)
    if len(diag_index)==1:
        if diag.DIAGNOSIS.values[diag_index[0]]==1:
            excel.Diagnosis.array[i]="CN"
        if diag.DIAGNOSIS.values[diag_index[0]]==2:
            excel.Diagnosis.array[i]="MCI"
        if diag.DIAGNOSIS.values[diag_index[0]]==3:
            excel.Diagnosis.array[i]="Dementia"

    ## CENTILOID VALUE
    amy_subject_index=np.where(amy.PTID.array==subject)
    amy_visit_index=np.where(amy.VISCODE.array==visit_code)
    amy_index=np.intersect1d(amy_subject_index,amy_visit_index)
    if len(amy_index)==1:
        excel.PET_CENTILOID.array[i]=amy.CENTILOIDS.array[amy_index[0]]
    
    ## MOCA
    moca_subject_index=np.where(moca.PTID.array==subject)
    moca_visit_index=np.where(moca.VISCODE2.array==visit_code2)
    moca_index=np.intersect1d(moca_subject_index,moca_visit_index)
    if len(moca_index)==1:
        excel.MOCA.array[i]=moca.MOCA.array[moca_index[0]]

    # WMH and volumes    
    mri_subject_index=np.where(wmh.PTID.array==subject)
    if visit_code=="bl":
        mri_visit_index=np.where(wmh.VISCODE.array=="sc")
    else:
        mri_visit_index=np.where(wmh.VISCODE.array==visit_code)
    mri_index=np.intersect1d(mri_subject_index,mri_visit_index)
    if len(mri_index)==1:
        excel.CEREBRUM_TCV.array[i]=wmh.CEREBRUM_TCV.array[mri_index[0]]
        excel.TOTAL_WHITE.array[i]=wmh.TOTAL_WHITE.array[mri_index[0]]
        excel.TOTAL_WMH.array[i]=wmh.TOTAL_WMH.array[mri_index[0]]
        excel.WMH_WM.array[i]=wmh.TOTAL_WMH.array[mri_index[0]]/wmh.TOTAL_WHITE.array[mri_index[0]]*100

excel.to_csv("dataset.csv")
