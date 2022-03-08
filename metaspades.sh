#!/bin/bash

#This program requies that the user specify 3 things in order. The first one is the name of the reads file with the forward sequences
#The sencond one is the name of the reads file with the reverse sequences. The third one is a the prefix that will be added at the begenning of each output file
#If the reads files are not in the same directory as this script, please provide it   

FILE1=$1 #Reads file with the forward sequences 
FILE2=$2 #Reads file with the reverse sequences 
prefix=$3 #Suffix to be appended at the begenning of the files 

root=$(pwd) #Gets the path to the directory of this file, on which the outputs ought to be created 
sign='$'    

#Creates the outputs directories 
mkdir ASSEMBLIES
mkdir ASSEMBLIES/ASSEMBLY_LOGS
mkdir ASSEMBLIES/ASSEMBLY_LOGS/OUTPUTS
mkdir ASSEMBLIES/ASSEMBLY_LOGS/SCRIPTS

#Creates the script to run metaspades
cat > runMETASPADES.sh <<EOF
#PBS -N ${prefix}_METASPADES
#PBS -q default
#PBS -l nodes=1:ppn=8,mem=40g,vmem=40g,walltime=100:00:00
#PBS -e ${root}/ASSEMBLIES/ASSEMBLY_LOGS/OUTPUTS/${prefix}_METASPADES.error
#PBS -o ${root}/ASSEMBLIES/ASSEMBLY_LOGS/OUTPUTS/${prefix}_METASPADES.output
#PBS -V

module load SPAdes/3.10.1

cd $root

metaspades.py --pe1-1 $FILE1 --pe1-2 $FILE2 -o METASPADES

scp METASPADES/scaffolds.fasta ASSEMBLIES/${prefix}_metaspades_scaffolds.fasta 2>>/dev/null
scp METASPADES/contigs.fasta ASSEMBLIES/${prefix}_metaspades_contigs.fasta 2>>/dev/null
EOF

#Submit the scripts to the cluster:

qsub runMETASPADES.sh


#Move the TAXONOMY script to the corresponding sub-folder:
mv runMETASPADES.sh ASSEMBLIES/ASSEMBLY_LOGS/SCRIPTS/