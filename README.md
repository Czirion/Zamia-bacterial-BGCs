UNDER CONSTRUCTION

# Zamia-bacterial-BGCs

This is a description of the pipeline followed for the *Zamia furfuracea* bacterial BGC mining project (2020-2022). 
It is not the exact pipeline followed for the project, but a slightly improved and simplified version of it.

It follows the next seps:
- Download the sequencing data
- Organize the files
- Create the metadata spreadsheet
- Taxonomic assignment of the reads
	- Run Kraken and Bracken
	- Run Krona
	- Run Phyloseq in R
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
	- Run Phyloseq in R
- Genomic data base construction
	- Download genomes from NCBI
	- Clean file list and prepare RAST submition
	- Annotation with RAST
- Phylogenetic tree
	- Run Orthofinder
	- Run Ggtree in R
- BGC Mining
	- Run AntiSMASH
	- Run BiG-SCAPE
		- Make heatmap in R
	- Run CORASON

The software used is listed in `software.md` in this repository.

## Download the sequencing data

In your local machine create the necessary directories to store the raw data and quality analysis files:
~~~shell
mkdir -p zamia-dic2020/raw_data/FastQC
cd zamia-dic2020/raw_data/
~~~

Enter the server of the sequencing service that has the data stored:
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

Make directories for each sample in the server (from now on "the server" will reference the computer with high power that you will use), inside the server:
~~~shell
for i in {36..43}
do
	mkdir -p zamia-dic2020/Zf_$i
done
~~~

Copy the files to the server, in the local machine:
~~~shell
scp *.fastq.gz <serveradress>/zamia-dic2020/
~~~

Relocate files to sample folders, in the server:
~~~shell
for i in {36..43}
do
	mv *$i*.fastq.gz Zf_$i/
done
~~~

Having the scripts `kraken_reads.sh`, `metaspades.sh`, `minimap.sh` (found in this repository) in the `zamia-dic2020/` folder in the server, move them to each sample folder:
~~~shell
for directory in Zf*
do
	scp kraken_reads.sh ${directory}
	scp metaspades.sh ${directory}
	scp minimap.sh ${directory}
done
~~~

## Create the metadata spreadsheet

Type the metadata into a spreadsheet and save it as `csv`. The metadata file is located in this repository with the name `metadatos.csv`.

## Taxonomic assignment of all the reads

### Run Kraken and Bracken

Inside each sample folder in the server (example for sample Zf_36) run Kraken and Bracken:
~~~shell
sh kraken_reads.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

Once you have the Kraken and Bracken output copy the `bracken_kraken.report`s to the local machine, in the local machine:
~~~shell
mkdir zamia-dic2020/taxonomia_reads/
scp <serveradress>/zamia-dic2020/Zf*/TAXONOMY/KRAKEN/*bracken_kraken.report zamia-dic2020/taxonomia_reads/
~~~

### Run Krona

In `taxonomia_reads/` run Krona and move the outputs to a new folder:
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

In `taxonomia_reads/` use `kraken-biom` to make the `.biom` file that we need to visualize the taxonomy with Phyloseq in R. And move the resulting file to a folder named `phyloseq/`:
~~~shell
kraken-biom Zf_36_kraken_bracken.report Zf_37_kraken_bracken.report Zf_38_kraken_bracken.report Zf_39_kraken_bracken.report Zf_40_kraken_bracken.report Zf_41_kraken_bracken.report Zf_42_kraken_bracken.report Zf_43_kraken_bracken.report --fmt json -o Zf.biom

mkdir phyloseq/
mv Zf.biom phyloseq/
~~~

Copy the `metadatos.csv` file to `taxonomia_reads/` to be able to use Phyloseq. The Phyloseq script can be found in `phyloseq_reads.Rmd` in this repository. To see a Knited version of it download (click in the file name, click download, and click Ctrl+S) `phyloseq_reads.html` and open it with a browser. 

## Metagenomics assembly

### Run Metaspades

Inside each sample folder in the server (example for sample Zf_36) run metaSPAdes:
~~~shell
sh metaspades.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

Once you have the metaSPAdes output go to the local machine to copy the scaffolds files there:
~~~shell
mkdir zamia-dic2020/ensambles_metag/
scp <serveradress>/zamia-dic2020/Zf*/ASSMBLIES/*.fasta zamia-dic2020/ensambles_metag/
~~~

### Run MetaQuast

Run MetaQuast on all scaffolds and contigs files, in the local machine:
~~~shell
mkdir ensambles_metag/metaQUAST
metaquast.py -o metaQUAST --space-efficient --split-scaffolds Zf_36_metaspades_scaffolds.fasta Zf_37_metaspades_contigs.fasta Zf_37_metaspades_scaffolds.fasta Zf_38_metaspades_contigs.fasta Zf_38_metaspades_scaffolds.fasta Zf_39_metaspades_contigs.fasta Zf_39_metaspades_scaffolds.fasta Zf_40_metaspades_contigs.fasta Zf_40_metaspades_scaffolds.fasta Zf_41_metaspades_contigs.fasta Zf_41_metaspades_scaffolds.fasta Zf_42_metaspades_contigs.fasta Zf_42_metaspades_scaffolds.fasta Zf_43_metaspades_contigs.fasta Zf_43_metaspades_scaffolds.fasta
~~~

View the results with a browser and erase the heavy files about the downloaded references and corrected input.

## Binning

### Run Minimap

Inside each sample folder in the server (example for sample Zf_36), run minimap:
~~~shell
sh minimap.sh ASSEMBLIES/Zf_36_metaspades_scaffolds.fasta *R1*.fastq *R2*.fastq Zf_36
~~~

Copy the alignment files to the local machine, in the local machine:
~~~shell
mkdir zamia-dic2020/vamb/
scp <serveradress>/zamia-dic2020/Zf*/*.bam zamia-dic2020/vamb/
~~~

Move the raw data file to a single folder, in the server: 
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

mkdir zamia-dic2020/ensambles_mags/
scp vamb/Zf*/bins/*.fna zamia-dic2020/ensambles_mags/
~~~

### Run Quast

In the local machine:
~~~shell
cd zamia-dic2020/ensambles_mags/
quast.py -o quast --space-efficient <listOfMAGsFiles>
~~~

View the results with Firefox and erase the heavy files about the downloaded references and corrected input.

Copy the MAGs to the server, in the server create a folder named `zamia-dic2020/ensambles_mags` and then in the local computer:
~~~shell
scp ensambles_mags/* <serveradress>/zamia-dic2020/ensambles_mags/
~~~

### Run CheckM

Put the `checkm.sh` script (found in this repository) in `zamia-dic2020/` in the server, and run it:
~~~shell
sh checkm.sh
~~~

## Taxonomy assignment of the MAGs's contigs

### Run Kraken and Bracken

Put the `kraken_mags.sh` script (found in this repository) in `zamia-dic2020/` in the server, and run it:
~~~shell
sh kraken_mags.sh
~~~

### Run Phyloseq in R

Once you have the Kraken and Bracken output go to the local machine to copy the `bracken_kraken.report`s there:
~~~shell
mkdir zamia-dic2020/taxonomia_mags/
scp <serveradress>/zamia-dic2020/TAXONOMY_MAGS/*bracken_kraken.report ./taxonomia_mags/
~~~

In `taxonomia_mags/` use `kraken-biom` to make the `.biom` file that we need to visualize the taxonomy with Phyloseq in R. And move the resulting file to a folder named `phyloseq/` inside `taxonomia_mags/`:
~~~shell
kraken-biom <listOfMAGsKrakenBrackenReports> --fmt json -o Zf_mags.biom

mkdir phyloseq/
mv Zf_mags.biom phyloseq/
~~~
(The list of `bracken_kraken.report`s only contains the selected MAGs with high quality)

Copy the `metadatos.csv` file to `taxonomia_mags/` to be able to use Phyloseq. The Phyloseq script can be found in `phyloseq_mags.Rmd` in this repository. To see a Knited version of it download `phyloseq_mags.html` and open it with a browser. 

## Genomic data base construction

For each of the genera of interest for which MAGs were obtained (*Bacillus*, *Peribacillus*, *Rhizobium*, *Bradyrhizobium*, *Phyllobacterium*) follow the next steps.

All of the next steps are preformed in the local machine:

### Download genomes from NCBI

In the [Assembly database](https://www.ncbi.nlm.nih.gov/assembly) of the NCBI search the genus of interest.
Apply the required filters:
- Status: Latest
- Assmebly level: Complete genome
- Genomic representation: Complete
- Exclude: Exclude anomalous

Select Download Assemblies, choosing RefSeq as a source.

Move all genomes to a new folder named `zamia-dic2020/genomas/publicos/fasta/`.
And decompress them:
~~~shell
mkdir -p zamia-dic2020/genomas/publicos/fasta/
mv Downloads/ncbi-assemblies-fastas.zip zamia-dic2020/genomas/publicos/fasta/
cd zamia-dic2020/genomas/publicos/fasta/
gunzip *
~~~

Check the number of files before and after the name change:
~~~shell
ls | wc -l
~~~

Change the file names to their accesion numbers:
~~~shell
for file in *.fna 
do
    name=$(head -n1 $file | cut -d " " -f 1 | cut -c 1 --complement)
    echo $file $name.fasta
    mv $file $name.fasta
done
~~~

Make a file with the accesion numbers and genome names:
~~~shell
head -n1 *.fasta | grep -v "==" | grep ">" > genome_names.txt
~~~

### Clean the file list and prepare RAST submition

Edit with OpenRefine `genome_names.txt`:
- It shoud have the following columns: Accessions, Filenames, Species
- The Filenames column must have the `.fasta` extension
- The filenames must not have `''`, `()` or `.` symbols
- In the Filename column the genus, species and strain are separated with `_` 
- There are no `_` inside the strain code
- In the species column the genus, species and strain fields are separated with a space
- It should be saved as TSV
- Names of the species do not have be completely in lowercase (strain codes can be in uppercase)

To change the accession names for the new names using the `genome_names.tsv`:
~~~shell
cat genome_names.tsv| while read line ; do old=$(echo $line | cut -d' ' -f1); new=$( echo $line | cut -d' ' -f2) ; mv $old.fasta $new ;done
~~~

After changing the names, remove the first column of the `genome_names.tsv`, **add the information for the corresponding MAGs** and rename it to `IdsFile`.

Move the corresponding MAGs fastas to `zamia-dic2020/genomas/publicos/fasta/`.

### Anotation with RAST

#### Submit fastas to RAST

Pull the `myrast` docker distribution:
~~~shell
docker pull nselem/myrast
~~~

Enter the myrast docker and sumbit the genomes:
~~~shell
docker run -i -t -v $(pwd):/home nselem/myrast /bin/bash

cat IdsFile | while read line; do id=$(echo $line|cut -d' ' -f1); name=$(echo $line|cut -d' ' -f2-5); echo svr_submit_RAST_job -user <username> -passwd <password> -fasta $id -domain Bacteria -bioname "${name}" -genetic_code 11 -gene_caller rast; svr_submit_RAST_job -user <username> -passwd <password> -fasta $id -domain Bacteria -bioname "$name" -genetic_code 11 -gene_caller rast; done

# Wait until it has finished and exit:
exit 
~~~

Once the RAST run is finished, copy in a spreadsheet the RAST/Jobs_Overview table: 
- Keep only the JobIDs in the first column and the species names in the third column
- Make a second column with the Filename column from the `IdsFile`
- Make sure the JobId coincides with the appropriate filename
- Save it as `Rast_ID.tsv`


#### Retrieve RAST.gbk

Take back the MAGs fastas to `zamia-dic2020/ensambles_mags`.

Make a new folder named `zamia-dic2020/genomas/analizar/gbks/` and run docker to retrieve the `gbk` files:
~~~shell
mkdir -p zamia-dic2020/genomas/analizar/gbks/
cd zamia-dic2020/genomas/analizar/gbks/
mv ../fasta/Rast_ID.tsv .

docker run -i -t -v $(pwd):/home nselem/myrast /bin/bash

cut -f1 Rast_ID.tsv | while read line; do svr_retrieve_RAST_job <username> <password> $line genbank > $line.gbk ; done

# Wait until it has finished and exit:
exit
~~~

Change names from JobId to genome name with the Rast_ID.tsv:
~~~shell
cat Rast_ID.tsv| while read line ; do old=$(echo $line | cut -d' ' -f1); new=$(echo $line | cut -d' ' -f2) ; newgbk=$(echo $new | cut -d'.' -f1); mv $old.gbk $newgbk.gbk ;done
~~~

#### Retrieve RAST.faa

Make a new folder named `zamia-dic2020/genomas/analizar/aminoa/` and run docker to retrieve the `faa` files:
~~~shell
mv ../gbks/Rast_ID.tsv .

docker run -i -t -v $(pwd):/home nselem/myrast /bin/bash

cut -f1 Rast_ID.tsv | while read line; do svr_retrieve_RAST_job <username> <password> $line amino_acid > $line.faa ; done

# Wait until it has finished and exit:
exit
~~~

Change names from JobId to genome name with the Rast_ID.tsv:
~~~shell
cat Rast_ID.tsv| while read line ; do old=$(echo $line | cut -d' ' -f1); new=$(echo $line | cut -d' ' -f2) ; newfaa=$(echo $new | cut -d'.' -f1); mv $old.faa $newfaa.faa ;done
~~~

## Phylogenetic tree

### Run Orthofinder

For each genus of interest upload to the server a folder called `orthofinder/<genus>_faa/` with all of the genomes in the aminoacid `.faa` format. It must include, the constructed MAGs, the related genomes and an outgroup (a genome from one of the downloaded genera different to de genus of interest).

Put the script `orthofinder.sh` in the directory above `<genus>_faa/` and run it in the server.

### Run Ggtree in R

Download the results folder `Species_Tree/` to the local machine inside a directory called `zamia-dic2020/orthofinder/`.

Use the IdsFile to make a metadata spreadsheet with the hapitat information for each genome, obtaining this information from the NCBI entry of each
assembly. Inside the `orthofinder/` folder add the  that metadata file (`metadata_bradyrhizobium.csv` as an example here) and run the script
`ggtree.Rmd`. To see a Knited version of it download `ggtree.html` and open it with a browser. 

## BGC Mining

### Run Antismash

In the local machine, put the script `antismash.sh` (found in this repository) inside `zamia-dic2020/genomas/analizar/gbks/`.

Run `antismash.sh` in a conda environment:
~~~shell
conda activate antismash

for file in *.gbk
do
    sh antismash.sh $file
done
~~~

### Run BiG-SCAPE

Make a folder for all the BiG-SCAPE analyses:
~~~shell
mkdir -p zamia-dic2020/bigscape/bgcs_gbks/
~~~

All gbks generated by AntiSMASH should have a name with the pattern '*region*.gbk', if not, use an appropriate pattern for the next step.
Count the region gbks with:
~~~shell
ls output*/*region*gbk | wc -l
~~~

Add the name of the genome to the bgc filenames so they do not overwrite if names are duplicates:
~~~shell
ls -1 output*/*region*gbk | while read line; do dir=$(echo $line | cut -d'/' -f1); file=$(echo $line | cut -d'/' -f2); for directory in $dir; do cd $directory; pwd ; newfile=$(echo $dir-$file |cut -d'_' -f1 --complement); echo $file $newfile ; mv $file $newfile ; cd .. ; done; done
~~~

Copy all AntiSMASH-generated gbks to the `bgcs_gbks/` folder:
~~~shell
scp antismash/output_*/*region*.gbk bigscape/bgcs_gbks/ 
~~~

Make sure the count is the same as before:
~~~shell
ls bigscape/bgcs_gbks/*region*gbk | wc -l
~~~

Go to the `bigscape/` folder:
~~~shell
cd bigscape
~~~

We need the `--hybrids-off` flag to avoid the same BGC to be analysed in different Classes (because there are BGCs that may fit in different classes)
Optional: The `--mix` flag is to make an extra analysis with all the BGCs together (i.e. not separated in classes)
Optional: The `--cutoffs` flag is to make the entire analysis several times with different cutoff values (the default is 0.3)

Run BiG-SCAPE:
~~~shell
run_bigscape bgcs_gbks/ output_<date> --hybrids-off --mix --cutoffs 0.1 0.2 0.3 0.5 0.7 0.9
~~~

When it finishes open the results in a browser to explore them:
~~~shell
firefox output_<date>/index.html
~~~

### Make heatmap with BiG-SCAPE results

After exploring all the results and choosing the results from a certain cutoff value to report, select that cutoff value in the `index.html` displayed in
the browser and download the absence/presence table for each class of BGC. As shown in the image below, the values for "Cluster GCF based on:" must be
"Genomes Absence/Presence", the value for "Cluster Genomes based on:" must be "Family Absence/Presence" and the value for "Show" must be "All". Then
click on "Absence/Presnece table (tsv)" to download the table.

![image](https://user-images.githubusercontent.com/75807915/168332832-70019e88-daa1-4148-8ff8-ecec043522b5.png)

FIXME 

### Run Corason

According to the BiG-SCAPE results we can choose a BGC of interest and choose one of the genomes where it is found.

Make a folder for the CORASON analyses:
~~~shell
mkdir zamia-dic2020/corason/
cd corason

firefox ../antismash/output_<genome_of_interest>/index.html
~~~

Click on region (BGC) of interest to open its complete BGC view
Choose a gene to make the Corason from: Most likely the core gene, or one of the core genes
Click on it and on AA sequence: Copy to clipboard
Open a new empty plain text editor and add a line with the following info:
- `>` 
- cds gene code (as in the Gene details box withtin antismash web)
- additional gene name if there is one
- region name (as shown in antismash web)
- additional bgc name if there is one
- name of genome of origin
Then paste the sequence and save it in the corason folder with `.fasta` extension

If the genomes are in gbk format you need the `-g` flag.

Run CORASON:
~~~shell
run_corason core_gene.fasta path/my_genomes/gbks/ path/my_genomes/gbks/genome_of_interest -g
~~~

Check the .BLAST file in the corason output to see in the bitscores are on a very broad range, if they are choose an appropriate cutoff to maintain only the highest bitscores
Re-run corason with the same command but adding the bit score cutoff with the flag `-b <cutoff_value>`
