# FHI's SARS-CoV-2 Nanopore Pipeline
Bioinformatic pipeline for SARS-CoV-2 sequence analysis used at the [Folkehelseinstituttet](https://www.fhi.no)

## Description
Docker-based solution for sequence analysis of SARS-CoV-2 Nanopore samples 

## Primer schemes supported
[ArticV3](https://github.com/artic-network/artic-ncov2019/tree/master/primer_schemes/nCoV-2019/V3)   
[ArticV4](https://github.com/artic-network/artic-ncov2019/tree/master/primer_schemes/nCoV-2019/V4)
[Midnight](https://www.protocols.io/view/sars-cov2-genome-sequencing-protocol-1200bp-amplic-bwyppfvn)

## Installation
<code>git clone https://github.com/garcia-nacho/FHI_SC2_Pipeline_Nanopore</code>  
<code> cd FHI_SC2_Pipeline_Nanopore</code>   
<code> docker build -t garcianacho/fhisc2:Nanopore . </code>
 
*Note that building the image for the first time can take up to two hours.* 
 
Alternativetly, it is posible to *pull* updated builds from [Dockerhub](https://hub.docker.com/repository/docker/garcianacho/fhisc2):

<code>docker pull garcianacho/fhisc2:Nanopore</code>

## Running the pipeline
*ArticV4:*   
<code>docker run -it --rm -v $(pwd):/home/docker/Fastq garcianacho/fhisc2:Nanopore SARS-CoV-2_Nanopore_Docker_V12.sh ArticV4</code>    
   
*ArticV3:*   
<code>docker run -it --rm -v $(pwd):/home/docker/Fastq garcianacho/fhisc2:Nanopore SARS-CoV-2_Nanopore_Docker_V12.sh ArticV3</code>

*Midnight:*   
<code>docker run -it --rm -v $(pwd):/home/docker/Fastq garcianacho/fhisc2:Nanopore SARS-CoV-2_Nanopore_Docker_V12.sh Midnight</code>

*Note that older versions of docker might require the flag --privileged and that multiuser systems might require the flag -u 1000 to run*

The script expects the following folder structure where the *fastq.gz* files are placed inside independent folders for each Sample
   
<pre>
./_   
  |-ExperimentXX.xlsx
  |-GridXXX
     |-OppsettXXX
           |-XXXXXXXXFAXXXXXXXXXX
               |-sequencing_summary_FAXXXXX.txt
               |-fastq_pass
                     |-barcode1
                            |-XXXX_pass_barcode01_XXXX.fastq
                            |-YYYY_pass_barcode01_YYYY.fastq
                     |-barcode2
                     |-barcode3
                     |-....

</pre>
   
The script also expects a *.xlsx* file, that contains information about the position of the samples on a 96-well-plate, the links between *Barcodes* and *sequenceID* and the DNA concentration (alternatively this column can be used for the Ct-values). 
It is possible to download a template of the xlsx file [here](https://github.com/folkehelseinstituttet/FHI_SC2_Pipeline_Nanopore/blob/master/Template.xlsx?raw=true)

## Outputs
-Summary including mutations found, pangolin lineage, number of reads, coverage, depth, etc...   
-Bam files   
-Consensus sequences   
-Aligned consensus sequences   
-Consensus nucleotide sequence for gene *S*   
-*Indels* and frameshift identification run against FHIs frameshift-database   
-Quality-control plot for the plate to detect possible contaminations   
-Phylogenetic-tree plot of the samples   
-Noise during variant calling across the genome   
-Quality-control for contaminations/low-quality samples   
-Amplicon efficacy of the selected primer-set for all the samples   

 
