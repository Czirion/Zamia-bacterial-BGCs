#!/bin/bash
SCAFFOLDS=$1 #Metaspades scaffolds file
FILE1=$2 # Forward reads, a fastq.gz file
FILE2=$3 # Reverse reads, a fastq.gz file
prefix=$4 # Sample ID, it will be appended to the beginning of the files
root=$(pwd) # Your working directory must be the one where you have the required files and where the outputs will be created  


cat > runMinimap_${prefix}.sh <<E0F

#PBS -N minimap_${prefix}
#PBS -q default
#PBS -l nodes=1:ppn=8,mem=32g,vmem=32g,walltime=100:00:00
#PBS -e ${root}/LOGS/minimap_${prefix}.error
#PBS -o ${root}/LOGS/minimap_${prefix}.output
#PBS -V
 
module load samtools/1.9
module load minimap2/2.12 

cd $root
minimap2 -ax sr $SCAFFOLDS $FILE1 $FILE2 > $prefix.sam 
samtools view -S -b $prefix.sam > $prefix.bam
rm $prefix.sam

E0F

qsub runMinimap_${prefix}.sh

