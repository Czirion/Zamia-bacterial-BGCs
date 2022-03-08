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

mkdir TAXONOMY 
mkdir TAXONOMY/TAXONOMY_LOGS
mkdir TAXONOMY/TAXONOMY_LOGS/OUTPUTS
mkdir TAXONOMY/TAXONOMY_LOGS/SCRIPTS



#Create taxonomy script

cat  > txnmKRAKEN_BRACKEN.sh <<EOF

#PBS -N ${prefix}_KRAKEN&BRACKEN
#PBS -q default
#PBS -l nodes=1:ppn=8,mem=32g,vmem=32g
#PBS -e ${root}/TAXONOMY/TAXONOMY_LOGS/OUTPUTS/${prefix}_KRAKEN_BRACKEN.error
#PBS -o ${root}/TAXONOMY/TAXONOMY_LOGS/OUTPUTS/${prefix}_KRAKEN_BRACKEN.output
#PBS -V

module load kraken/2.0.7
module load Braken/2.0

cd $root

mkdir TAXONOMY/KRAKEN

kraken2 --db kraken-db --threads 8 --paired --fastq-input $FILE1 $FILE2 --output TAXONOMY/KRAKEN/${prefix}_kraken.kraken --report TAXONOMY/KRAKEN/${prefix}_kraken.report
bracken -d kraken-db -i TAXONOMY/KRAKEN/${prefix}_kraken.report -o TAXONOMY/KRAKEN/${prefix}.bracken

EOF


#Submit the scripts to the cluster:

qsub txnmKRAKEN_BRACKEN.sh


#Move the TAXONOMY script to the corresponding sub-folder:
mv txnmKRAKEN_BRACKEN.sh TAXONOMY/TAXONOMY_LOGS/SCRIPTS

