
#!/bin/bash
prefix=$1 # Sample ID, it will be appended to the beginning of the files
root=$(pwd) # Your working directory must be the one where you have the required files and where the outputs will be created  
sign='$'

cat > runTaxonomy_${prefix}.sh <<E0F

#PBS -N taxonomy_${prefix}
#PBS -q default
#PBS -l nodes=1:ppn=8,mem=32g,vmem=32g,walltime=100:00:00
#PBS -e $root/TAXONOMY_MAGS/LOGS/taxonomy_${prefix}.error
#PBS -o $root/TAXONOMY_MAGS/LOGS/taxonomy_${prefix}.output
#PBS -V

module load kraken/2.0.7
module load Braken/2.0

cd $root

mkdir TAXONOMY_MAGS

ls ensambles_mags/*.fna | while read line; do file=${sign}(echo ${sign}line | cut -d'/' -f2);
kraken2 --db kraken-db --threads 8 -input ${sign}line --output TAXONOMY_MAGS/${sign}file-kraken.kraken --report TAXONOMY_MAGS/${sign}file-kraken.report;
bracken -d kraken-db -i TAXONOMY_MAGS/${sign}file-kraken.report -o TAXONOMY_MAGS/${sign}file.bracken; done

E0F

qsub runTaxonomy_${prefix}.sh