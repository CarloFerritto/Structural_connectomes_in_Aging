(This is the template README.md for this template project sharing repository; please see [HOWTO.md](HOWTO.md) for usage guidelines for this repo.)

# Structural connectoms in Aging (Ferritto et al.)

<Project description>
  
## Table of contents
   * [How to cite?](#how-to-cite)
   * [Contents overview](#contents-overview)
   * [Reproducing figures and tables](#reproducing-figures-and-tables)
      * [Table 1](#table-1)
      * [Fig. 1](#fig-1)
      * [Fig. 2](#fig-2)
   * [Reproducing full analysis](#reproducing-full-analysis)

## How to cite?

See [CITATION](CITATION).

# Contents overview
In this repository you can find instructions and scripts to reproduce our results. <br>
There's no mean to reproduce the exact same results, as we can't provide the subject ID's and visits used in this study.
Nevertheless, we provide specific instruction on how to select the set of subjects.



## Reproducing full analysis
### Building your Dataset 
In this section we provide istruction on how to build your dataset. All the Excel file can be downloaded [here](https://ida.loni.usc.edu).
Before dowloading the images we suggest to:
- filter the patients through the advance search tool and select: ADNI3 as cohort, "Prisma" and "Prisma fit" as scanner models.
- filter the patients through the "Mayo(Jack Lab) - ADNI 3 MRI QC" file, selecting only the patients the have the T1w, DWI (multishell) and field map which passed the quality check.
- filter the patients through "Diagnosis", using the "Diagnosti summary" file and selecting the subjects classified as control (1) at the time of the visit.

Once you have all the possible subjects we suggest to build an excel file similar dataset.xlsx. In order to fill it you can use the Excel_manager.py script and the following excel files: MRI3META, PTDEMOG, DXSUM, UCBERKELEY_AMY,MMSE, MOCA,UCD_WMH. 
Based on the resulting Excel file, only one visit per patient should be selected, and only visits with WMH values available. 
To reduce the dataset to 50 patients, one can use the script patients_selection.py that aims to balance the gender of the patients and select those with the most uniform distribution of WMHB values.

### Images Download and organization
Images can be download  [here](https://ida.loni.usc.edu).
Once you download the images, one should:
- convert the images in Nifti format 
- organize the folder as follow





## Reproducing figures and tables

<Instructions on how to use summary/derived data in the `results` directory to create figures and tables>

<Specify precise steps, including any datasets that need to be downloaded and path variables that need to be set>

### Table 1

### Fig. 1

### Fig. 2
