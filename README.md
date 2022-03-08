# Zamia-bacterial-BGCs

UNDER CONSTRUCTION
This is a description of the pipeline followed for the *Zamia furfuracea* bacterial BGC mining project (2020-2022). 

### Notes on reading this instructions

After its creation the working directory from where the commands will be run is `Documentos/genomas/zamia-dic2020/` so the used paths will be absolute from there.

## Download the sequencing data

Create the necessary directories to store the data:
~~~
mkdir -p zamia-dic2020/raw_data/FastQC
~~~

Enter the server with the data:
~~~
sftp -------@-----.--------.--------.--------.--------.--
(pasword: -------)
~~~

List of accetions to download:
- AC1ME2SS36
- AC1ME2SS37
- AC1ME2SS38
- AC1ME2SS39
- AC1ME2SS40
- AC1ME2SS41
- AC1ME2SS42
- AC1ME2SS43

Use command `get` to download files:
~~~
for i in {36..43}
do
	get *S$i*
done
~~~

Move FastQC files to `FastQC/` :
~~~
mv *.html FastQC/
mv *.zip FastQC/
~~~

Make directories in the server.
Inside the server:
~~~
for i in {36..43}
do
	mkdir -p zamia-dic2020/Zf_$i
done
~~~

Copy the files to the server.
In the local machine:
~~~
scp *.fastq.gz <serveradress>/zamia-dic2020/
~~~

Relocate files to sample folders.
In the server:
~~~
for i in {36..43}
do
	mv *$i*.fastq.gz Zf_$i/
done
~~~

## Create the metadata spreadsheet

The metadata file is located in the `metadata` folder in this repository with the name `metadatos.csv`.

## Taxonomic assignment of all the reads

Having the script `kraken_reads.sh` (can be found in the `taxonomy` folder in this repository) in the `zamia-dic2020/` folder in the server move it to each sample folder with:
~~~
for directory in Zf*
do
	scp kraken_reads.sh ${directory}
done
~~~

### Run Kraken and Bracken

Inside each sample folder in the server (example for sample Zf_36):
~~~
sh kraken_reads.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

Once you have the Kraken and Bracken output go to the local machine to copy the bracken_kraken reports there:
~~~
mkdir taxonomia_reads
cd taxonomia_reads
scp <serveradress>/zamia-dic2020/Zf*/TAXONOMY/KRAKEN/*bracken_kraken.report .
~~~

### Run Krona

In `taxonomia_reads/` run Krona and move the outputs to a new folder.
~~~
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

In `taxonomia_reads/` use `kraken-biom` to make the `.biom` file that we need to visualize the taxonomy with Phyloseq in R. And more the resulting file to a folder named `phyloseq`.
~~~
kraken-biom Zf_36_kraken_bracken.report Zf_37_kraken_bracken.report Zf_38_kraken_bracken.report Zf_39_kraken_bracken.report Zf_40_kraken_bracken.report Zf_41_kraken_bracken.report Zf_42_kraken_bracken.report Zf_43_kraken_bracken.report --fmt json -o Zf.biom

mkdir phyloseq/
mv Zf.biom phyloseq/
~~~

Copy the `metadatos.csv` file to `taxonomia_reads/` to be able to use Phyloseq.
The Phyloseq script can be found in: `taxonomy/phyloseq_reads.md` in this repository.

## Metagenomics assembly

Having the script `metaspades.sh` (can be found in the `assembly` folder in this repository) in the `zamia-dic2020/` folder in the server move it to each sample folder with:
~~~
for directory in Zf*
do
	scp metaspades.sh ${directory}
done
~~~

### Run Metaspades

Inside each sample folder in the server (example for sample Zf_36):
~~~
sh metaspades.sh *R1*.fastq *R2*.fastq Zf_36/
~~~

