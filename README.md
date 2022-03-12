UNDER CONSTRUCTION
# Zamia-bacterial-BGCs

This is a description of the pipeline followed for the *Zamia furfuracea* bacterial BGC mining project (2020-2022).
It follows the next seps:
- Download the sequencing data
- Organize the files
- Create the metadata spreadsheet
- Taxonomic assignment of the reads
	- Run Kraken and Bracken
	- Run Krona
	- Make input for Phyloseq (and Phyloseq script)
- Metagenomic assembly
	- Run Metaspades
	- Run MetaQuast
- Binning
	- Run Minimap
	- Run VAMB
	- Run Quast
	- Run CheckM
- Taxonomic assignment of the MAGs's contigs
	- Run Kraken and Bracken
	- Make input for Phyloseq (and Phyloseq script)
	

#### Notes on reading this instructions

After its creation the working directory from where the commands will be run is `zamia-dic2020/` so the used paths will be absolute from there. This is true for the local machine and the server.

The software used is listed in `software.md` in this repository.

## Download the sequencing data

Create the necessary directories to store the data:
~~~shell
mkdir -p zamia-dic2020/raw_data/FastQC
~~~

Enter the server with the data:
~~~shell
sftp -------@-----.--------.--------.--------.--------.--
(pasword: -------)
~~~

List of accessions to download:
- AC1ME2SS36
- AC1ME2SS37
- AC1ME2SS38
- AC1ME2SS39
- AC1ME2SS40
- AC1ME2SS41
- AC1ME2SS42
- AC1ME2SS43

Use command `get` to download files:
~~~shell
for i in {36..43}
do
	get *S$i*
done
~~~

## Organize the files

Move FastQC files to `FastQC/` :
~~~shell
mv *.html FastQC/
mv *.zip FastQC/
~~~

Make directories in the server.
Inside the server:
~~~shell
for i in {36..43}
do
	mkdir -p zamia-dic2020/Zf_$i
done
~~~

Copy the files to the server.
In the local machine:
~~~shell
scp *.fastq.gz <serveradress>/zamia-dic2020/
~~~

Relocate files to sample folders.
In the server:
~~~shell
for i in {36..43}
do
	mv *$i*.fastq.gz Zf_$i/
done
~~~

Copy all the scripts to each sample folder.
Having the scripts `kraken_reads.sh`, `metaspades.sh`, `minimap.sh` (found in this repository) in the `zamia-dic2020/` folder in the server move them to each sample folder with:
~~~shell
for directory in Zf*
do
	scp kraken_reads.sh ${directory}
	scp metaspades.sh ${directory}
	scp minimap.sh ${directory}
done
~~~

## Create the metadata spreadsheet

The metadata file is located in this repository with the name `metadatos.csv`.

## Taxonomic assignment of all the reads

### Run Kraken and Bracken

Inside each sample folder in the server (example for sample Zf_36):
~~~shell
sh kraken_reads.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

Once you have the Kraken and Bracken output go to the local machine to copy the bracken_kraken reports there:
~~~shell
mkdir taxonomia_reads
cd taxonomia_reads
scp <serveradress>/zamia-dic2020/Zf*/TAXONOMY/KRAKEN/*bracken_kraken.report .
~~~

### Run Krona

In `taxonomia_reads/` run Krona and move the outputs to a new folder.
~~~shell
for filename in *_kraken_bracken.report
do
	title=$(echo ${filename} | cut -c 1-5) 
	kreport2krona.py -r ${filename} -o ${title}.krona
	ktImportText ${title}.krona -o ${title}.krona.html
done

mkdir krona
mv *krona* krona/
~~~

Visualize the results in Firefox.

### Make input for Phyloseq

In `taxonomia_reads/` use `kraken-biom` to make the `.biom` file that we need to visualize the taxonomy with Phyloseq in R. And move the resulting file to a folder named `phyloseq`.
~~~shell
kraken-biom Zf_36_kraken_bracken.report Zf_37_kraken_bracken.report Zf_38_kraken_bracken.report Zf_39_kraken_bracken.report Zf_40_kraken_bracken.report Zf_41_kraken_bracken.report Zf_42_kraken_bracken.report Zf_43_kraken_bracken.report --fmt json -o Zf.biom

mkdir phyloseq/
mv Zf.biom phyloseq/
~~~

Copy the `metadatos.csv` file to `taxonomia_reads/` to be able to use Phyloseq.
The Phyloseq script can be found in `phyloseq_reads.Rmd` in this repository.

## Metagenomics assembly

### Run Metaspades

Inside each sample folder in the server (example for sample Zf_36):
~~~shell
sh metaspades.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

Once you have the Metaspades output go to the local machine to copy the scaffolds files there:
~~~shell
mkdir ensambles_metag/
scp <serveradress>/zamia-dic2020/Zf*/ASSMBLIES/*.fasta ./ensambles_metag/
~~~

### Run MetaQuast

Run MetaQuast on all scaffolds and contigs files. In the local machine:
~~~shell
mkdir ensambles_metag/metaQUAST
metaquast.py -o metaQUAST --space-efficient --split-scaffolds Zf_36_metaspades_scaffolds.fasta Zf_37_metaspades_contigs.fasta Zf_37_metaspades_scaffolds.fasta Zf_38_metaspades_contigs.fasta Zf_38_metaspades_scaffolds.fasta Zf_39_metaspades_contigs.fasta Zf_39_metaspades_scaffolds.fasta Zf_40_metaspades_contigs.fasta Zf_40_metaspades_scaffolds.fasta Zf_41_metaspades_contigs.fasta Zf_41_metaspades_scaffolds.fasta Zf_42_metaspades_contigs.fasta Zf_42_metaspades_scaffolds.fasta Zf_43_metaspades_contigs.fasta Zf_43_metaspades_scaffolds.fasta
~~~

View the results with Firefox and erase the heavy files about the downloaded references and corrected input.

## Binning

### Run Minimap

Inside each sample folder in the server (example for sample Zf_36):
~~~shell
sh minimap.sh ASSEMBLIES/Zf_36_metaspades_scaffolds.fasta *R1*.fastq *R2*.fastq Zf_36
~~~

### Copy the alignment files to the local machine

In the local machine:
~~~shell
mkdir vamb/
scp <serveradress>/zamia-dic2020/Zf*/*.bam ./vamb/
~~~

### Move the raw data file to a single folder

In the server: 
~~~shell
mkdir raw_data/
mv Zf*/*.fastq* raw_data/
~~~

### Run VAMB

In the local machine run vamb for each sample (example fo Zf_36):
~~~shell
cd vamb/
vamb --outdir Zf_36 --fasta ../ensambles_metag/Zf_36_metaspades_scaffolds.fasta --bamfiles Zf_36.bam --minfasta 200000 
cd ..
~~~
Remove the `bam` files.

Rename the bins to make them have the sample name and copy them to a new folder:
~~~shell
for directory in {36..43}
do 
	cd Zf_$directory/bins/
	ls | while read line
		do 
			echo $line Zf_$directory-$line 
			mv $line Zf_$directory-$line
		done
	cd ../..
done

mkdir ensambles_mags/
scp vamb/Zf*/bins/*.fna ensambles_mags/
~~~

### Run Quast

In the local machine:
~~~shell
cd ensambles_mags/
quast.py -o quast --space-efficient <listOfMAGsFiles>
~~~

View the results with Firefox and erase the heavy files about the downloaded references and corrected input.

Copy the MAGs to the server.
In the server create a folder named `zamia-dic2020/ensambles_mags` and then in the local computer:
~~~shell
scp ensambles_mags/* <serveradress>/zamia-dic2020/ensambles_mags/
~~~

### Run CheckM

Put the `checkm.sh` script (found in this repository) in `zamia-dic2020/` in the server.
And run it:
~~~shell
sh checkm.sh
~~~

## Taxonomy assignment of the MAGs's contigs

### Run Kraken and Bracken

Put the `kraken_mags.sh` script (found in this repository) in `zamia-dic2020/` in the server.
And run it:
~~~shell
sh kraken_mags.sh
~~~

### Make input for Phyloseq

Once you have the Kraken and Bracken output go to the local machine to copy the bracken_kraken reports there:
~~~shell
mkdir taxonomia_mags
scp <serveradress>/zamia-dic2020/TAXONOMY_MAGS/*bracken_kraken.report ./taxonomia_mags/
~~~

In `taxonomia_mags/` use `kraken-biom` to make the `.biom` file that we need to visualize the taxonomy with Phyloseq in R. And move the resulting file to a folder named `phyloseq` inside `taxonomia_mags/`
~~~shell
kraken-biom <listOfMAGsKrakenBrackenReports> --fmt json -o Zf_mags.biom

mkdir phyloseq/
mv Zf_mags.biom phyloseq/
~~~

Copy the `metadatos.csv` file to `taxonomia_mags/` to be able to use Phyloseq.
The Phyloseq script can be found in `phyloseq_mags.Rmd` in this repository. 
