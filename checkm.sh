#!/bin/bash
#Script for running CheckM (with VAMB results)
prefix=$1 # Sample ID, it will be appended to the beginning of the files
root=$(pwd) # Your working directory must be the one where you have the required files and where the outputs will be created  

cat > runCheckmVAMB_${prefix}.sh <<E0F
#PBS -N runCheckm_${prefix}
#PBS -q default
#PBS -l nodes=1:ppn=8,mem=48g,vmem=48g,walltime=100:00:00
#PBS -e ${root}/LOGS/checkm_${prefix}.error
#PBS -o ${root}/LOGS/checkm_${prefix}.output
#PBS -V

module load CheckM/1.1.3
module load hmmer/3.1b2
module load Prodigal/2.6.2

cd $root/
mkdir CHECKM
checkm lineage_wf -r ensambles_mags/ CHECKM/
checkm qa CHECKM/lineage.ms CHECKM/ --file CHECKM/quality_${prefix}.tsv --tab_table -o 2

E0F

qsub runCheckmVAMB_${prefix}.sh