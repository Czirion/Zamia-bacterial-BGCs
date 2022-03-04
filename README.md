# Zamia-bacterial-BGCs

This is a description of the pipeline followed for the *Zamia furfuracea* bacterial BGC mining project (2020-2022).

### Notes on reading this instructions

After its creation the working directory from where the commands will be run is `Documentos/genomas/zamia-dic202/` so the used paths will be absolute from there.

## Download the sequencing data

Create the necessary directories to store the data:
~~~
mkdir -p zamia-dic2020/raw_data/FastQC
~~~

Enter the server with the data:
~~~
sftp *******@*****.mazorkita.labsergen.langebio.cinvestav.mx
(pasword: ******)
~~~

List of accestions to download:
- AC1ME2SS36
- AC1ME2SS37
- AC1ME2SS38
- AC1ME2SS39
- AC1ME2SS40
- AC1ME2SS41
- AC1ME2SS42
- AC1ME2SS43

Use command 'get' to download files:
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

