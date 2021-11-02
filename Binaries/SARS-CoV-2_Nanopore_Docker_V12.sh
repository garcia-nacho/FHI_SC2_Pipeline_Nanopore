#!/bin/bash
# Dette skriptet er videreføring av SARS-nCov-Nanopore_medaka_v11.sh og MidNight_SARS-nCov-Nanopore_medaka_v1.sh

#### NY VERSJON V12 ######  Lagt til docker for Rscript som lager tsv-fil
						##  Lagt til docker for noise og frameshift 



# henter ut året for 2 dager siden  (ved årsskiftet vil et run kunne tilhøre året før)
year=$([ "$OSTYPE" = linux-gnu ] && date --date="2 days ago" +"%Y" || date -v-2d +"%Y")	                       
echo "Available primersets Midnight, ArticV3 and ArticV4"
startdir=$(pwd)
cd ~
homedir=$(pwd)
scriptdir=/home/docker/Scripts/
SpikeRef=/home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/V3.2/nCoV-2019.spike.fa
cd ${startdir}

if [ ${1} == "Midnight" ]; then
	primer_schemes=/home/docker/CommonFiles/artic-ncov2019/primer_schemes
	schemes_sample=nCoV-2019/MidNightV1
	SpikeRef=/home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/MidNightV1/nCoV-2019.spike.fa
	min=500
	max=1800
	cp /home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/MidNightV1/nCoV-2019.bed /home/docker/Fastq/primers.bed

fi

if [ ${1} == "ArticV3" ]; then
	primer_schemes=/home/docker/CommonFiles/artic-ncov2019/primer_schemes
	schemes_sample=nCoV-2019/V3.2
	SpikeRef=/home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/V3.2/nCoV-2019.spike.fa
	min=200
	max=700
	cp /home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/V3.2/nCoV-2019.primer.bed /home/docker/Fastq/primers.bed
fi

if [ ${1} == "ArticV4" ]; then
	primer_schemes=/home/docker/CommonFiles/artic-ncov2019/primer_schemes
	schemes_sample=nCoV-2019/V4
	SpikeRef=/home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/V3.2/nCoV-2019.spike.fa
	min=200
	max=700
	cp /home/docker/CommonFiles/artic-ncov2019/primer_schemes/nCoV-2019/V4/nCoV-2019.primer.bed /home/docker/Fastq/primers.bed
fi


if [[ ${1} ]]; then  
if [ ${1} != "ArticV3" ] && [ ${1} != "Midnight" ] && [ ${1} != "ArticV4" ]; then
       echo "
  _  _ ___ _ 
 | \| | _ ) |
 | .  | _ \_|
 |_|\_|___(_)

            NÅ SKREV DU FEIL 
            Du skrev ${1} som input istedenfor ArticV3, ArticV4 eller Midnight 
#############################################################################"
        exit 1
    else  
    echo "       
                    ################################
                  ##                                ##
                ##                                   ##
               ##   Du bruker nå primersett           ##
               ##  ${schemes_sample}             ##
               ##                                    ##
                ##                                  ##
                  ##                               ##  
                   ################################"
fi
else
   echo "
  _  _ ___ _ 
 | \| | _ ) |
 | .  | _ \_|
 |_|\_|___(_)
 
            Du har glemt å skrive ArticV3, ArticV4 eller Midnight 
#############################################################################  


"
    exit 1
   
fi



Rscript --vanilla /home/docker/Scripts/CSAK_Excel_to_tsv_docker.R "${startdir}"

cd $(ls -d */)
cd Oppsett*/

startdir2=$(pwd)

for dir in $(ls -d */)
do
	barcode=$(ls -f *.tsv)

	if [[ ! -f ${barcode} ]] 
	then
	    echo "#################################"
		echo "Finnner ikke oppsettfilen nødvendig for å rename mappene. Sjekk at filen ligger under OppsettX og avsluttes med *.tsv"
		echo "Avslutter skriptet."
		echo "#################################"
		exit 1
fi
done

cd *FA*/          
basedir=$(pwd)

#########################################
##Sjekker at sequencing_summary er i riktig path##
#########################################

for dir in $(ls -d */)
do
	summary=$(ls -f sequencing_summary* )
	if [[ ! -f ${summary} ]] ; then
		echo 'Finnner ikke sequencing_summary filen og avslutter skriptet.'
		exit 1
	fi
done

##########################################################
##Bruker *.tsv filen til å endre mappenavn fra barcodeX til LabwareKey##
##########################################################

echo "Endrer mappenavn ...."  
cd ./fastq_pass/
fastq_pass=$(pwd)
awk -F'\t'  'system("mv " $2 " " $1)' ${startdir2}/*.tsv

##########################
##Starter guppylex analysene##
#########################
source activate artic
echo "Kjører gyppyplex....."
for dir in $(ls -d */)
do
	cd ${dir}
	artic guppyplex --skip-quality-check --min-length ${min} --max-length ${max} --directory ./  --prefix ${dir%/}; 
	cd "${fastq_pass}"
done

cd "${basedir}"
summary=$(ls -f sequencing_summary*.txt) 
cd "${fastq_pass}"

###########################
##Starter Artic minion analyser###
###########################

echo $primer_schemes
echo $schemes_sample
echo " Kjører artic minion..."
for dir in $(ls -d */)
do
	cd ${dir} 
	
	artic minion --medaka --medaka-model r941_min_high_g351 --normalise 200 --threads 8 --scheme-directory ${primer_schemes} --read-file ${dir%/}_.fastq --sequencing-summary ${basedir}/${summary} ${schemes_sample} ${dir%/}
	#artic minion --medaka --medaka-model r941_min_high_g434 --normalise 200 --threads 8 --scheme-directory ${primer_schemes} --read-file ${dir%/}_.fastq --sequencing-summary ${basedir}/${summary} ${schemes_sample}  ${dir%/}
	cd "${fastq_pass}"

done

cd "${startdir2}"

conda deactivate


######################### 
##Starter coverageanalyser###
#########################
echo "Kjører coverageanalyser..."
script_name1=`basename $0`
runname=${startdir2##*/}
cd ${fastq_pass} 

for dir in $(ls -d */)
do
	cd ${dir}
	bamfil1=$(ls -f *.primertrimmed.rg.sorted.bam)
	weeSAMv1.6 --bam ${bamfil1} --out ${bamfil1%.primertrimmed.rg.sorted.bam}_QualitySummary.txt
	#wee1114=$(sort -t$'\t' -k3 -nr *_QualitySummary.txt | grep -m1 "" | cut -f5) #ny versjon av weeSAM gir 100% dekning uansett
	wee1115=$(sort -t$'\t' -k3 -nr *_QualitySummary.txt | grep -m1 "" | cut -f8)
	mappedafter=$(sort -t$'\t' -k3 -nr *_QualitySummary.txt | grep -m1 "" | cut -f3)

# bedtools genomecov -ibam ${bamfil1} -bga > ${bamfil1%.bam}_aln.bam 
   # LengthBelowDepth1=$(awk '$4 <1' *_aln.bam | awk '{a=$3-$2;print $0,a+1;}' | awk '{print $5}' | paste -sd+ | bc) #dette blir feil
   # LengthBelowDepth10=$(awk '$4 <10' *_aln.bam | awk '{a=$3-$2;print $0,a+1;}' | awk '{print $5}' | paste -sd+ | bc) #dette blir feil
   # LengthBelowDepth20=$(awk '$4 <20' *_aln.bam | awk '{a=$3-$2;print $0,a+1;}' | awk '{print $5}' | paste -sd+ | bc) #dette blir feil
    
    #RefLength=29903
    RefLength=$(awk 'FNR == 2 {print $2}' *_QualitySummary.txt)

    coverage_breath=$(seqkit fx2tab -C A,C,T,G,N *.consensus.fasta | awk '{print ($7+$4+$5+$6)/29903*100}') #NB illumina og nanopore er ikke like her 
	#coverage_breath fixed by nacho 01112021

	wee1114=$(echo "scale=5;(($RefLength-$LengthBelowDepth1)/$RefLength)*100" |bc) 
    PercCovAboveDepth9=$(echo "scale=5;(($RefLength-$LengthBelowDepth10)/$RefLength)*100" |bc) 
    PercCovAboveDepth19=$(echo "scale=5;(($RefLength-$LengthBelowDepth20)/$RefLength)*100" |bc)    
   	 
	echo "Parameters, ${dir%/}" >> ${dir%/}_summary.csv
	echo "2, i.a." >> ${dir%/}_summary.csv
	echo "3, i.a." >> ${dir%/}_summary.csv
	echo "4, i.a." >> ${dir%/}_summary.csv
	echo "5, i.a." >> ${dir%/}_summary.csv
	echo "Total_mapped_Corona_reads_after_trim:, ${mappedafter}" >> ${dir%/}_summary.csv
	echo "Percent_covered:, n.a." >> ${dir%/}_summary.csv
	echo "Average_depth:, ${wee1115}" >> ${dir%/}_summary.csv
	echo "Percent_covered_above_depth=19:, ${coverage_breath}" >> ${dir%/}_summary.csv
	echo "Percent_covered_above_depth=9:, n.a." >> ${dir%/}_summary.csv
	echo "Script_name:, ${script_name1}" >> ${dir%/}_summary.csv

	cd ${fastq_pass}
done

mappe="$(pwd)"
log "Jeg er nå ferdig med dypde del 1 og står i" $mappe

cd "${startdir2}"
mkdir "./${runname}_summaries/"
mkdir "./${runname}_summaries/fasta"
mkdir "./${runname}_summaries/bam"
cd ${fastq_pass} 

for d in $(ls -d 25*/)
do 
	cd ${d}		
	cp ${d%/}_summary.csv "${startdir2}/${runname}_summaries/"
	cp ${d%/}.consensus.fasta "${startdir2}/${runname}_summaries/fasta"
	cp ${d%/}.primertrimmed.rg.sorted.bam "${startdir2}/${runname}_summaries/bam"
	cp ${d%/}.primertrimmed.rg.sorted.bam.bai "${startdir2}/${runname}_summaries/bam"

cd "${startdir2}/${runname}_summaries"

	cd  ${fastq_pass}
done

cd "${startdir2}/${runname}_summaries"

	for f in $(ls *.csv) 
	do
		sed 's/\./,/g' $f | awk 'BEGIN {OFS=","} {print $2}' > $f-5.tmp
    done


echo "Parameters:" >> parameters                            # Lager en fil parameteres hvor alle oversikriftene legges 
echo "2" >> parameters
echo "3" >> parameters
echo "4" >> parameters
echo "5" >> parameters
echo "Total of mapped Corona reads after trim:" >> parameters
echo "Percent covered:" >> parameters
echo "Average depth:" >> parameters
echo "Percent covered above depth=19:" >> parameters
echo "Percent covered above depth=9:" >> parameters
echo "Script name:" >> parameters

paste parameters *.tmp >> ${runname}_summaries.csv    # verdiene og overskriftene limes inn i en og samme fil

find . -type f -name "*.tmp" -exec rm -f {} \;
find . -type f -name "parameters" -exec rm -f {} \; # sletter de midlertidige filene
rm *summary.csv

mappe="$(pwd)"
echo "Jeg er nå ferdig og skal starte og står i " $mappe

cd "${startdir2}"

### Lager samlet fasta for hele runnet
cd "${startdir2}/${runname}_summaries/fasta"
cat *.fasta  > ${runname}.fa
cd "${startdir2}"


source activate pangolin
pangolin --update
pangolin ${startdir2}/${runname}_summaries/fasta/${runname}.fa --outfile ${startdir2}/${runname}_summaries/fasta/${runname}_pangolin_out.csv
conda deactivate

nextclade --input-fasta ${startdir2}/${runname}_summaries/fasta/${runname}.fa --output-csv ${startdir2}/${runname}_summaries/${runname}_Nextclade.results.csv
nextalign  --sequences=${startdir2}/${runname}_summaries/fasta/${runname}.fa --reference=/home/docker/CommonFiles/reference_nc.fasta \
 --genemap=/home/docker/CommonFiles/genemap.gff --genes=E,M,N,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S --output-dir=/home/docker/Fastq --output-basename=${runname}


mv ${startdir2}/${runname}_summaries/fasta/${runname}_pangolin_out.csv ${startdir2}/${runname}_summaries/

cd "${startdir2}/${runname}_summaries/"

nextclade_output_converter.py ${runname}_Nextclade.results.csv >> ${runname}_Nextclade.results2.csv

awk -F ',' '{print $1 "," $2 "," $4}' ${runname}_pangolin_out.csv > pangolin_out.csv
awk -F ';' '{print $1 "," $2}' ${runname}_Nextclade.results.csv > nextclade_out2.csv

cat nextclade_out2.csv | sed "s/, /\//g" > nextclade_out3.csv && mv nextclade_out3.csv nextclade_out2.csv #ny fra 22.06.21 Kamilla&Nacho

(head -n 1 pangolin_out.csv && tail -n +2 pangolin_out.csv | sort) > pangolin_out_sorted.csv
(head -n 1 nextclade_out2.csv && tail -n +2 nextclade_out2.csv | sort) > nextclade.out2_sorted.csv
(head -n 1 ${runname}_Nextclade.results2.csv && tail -n +2 ${runname}_Nextclade.results2.csv | sort) > ${runname}_Nextclade.results2_sorted.csv

paste -d, ${runname}_Nextclade.results2_sorted.csv pangolin_out_sorted.csv > NextcladeAndPangolin.out.csv
paste -d, NextcladeAndPangolin.out.csv nextclade.out2_sorted.csv > NextcladeAndPangolin.out2.csv

sed 's/,/\t/g' NextcladeAndPangolin.out2.csv | sed 's/ORF10/ORF10\t/g' > ${runname}_NextcladeAndPangolin.csv

rm *results*
rm *out*

echo "Pangolin og Nextclade ferdig"
cd "${startdir2}"
####### Pangolin og Nextclade  ##### SLUTT #####


####### Ekstrahere Spike fra fasta-sekvens #######	START ######
#input spike ref og fasta-fil

cd "${startdir2}/${runname}_summaries/fasta"
Rscript /home/docker/Scripts/CSAK_Spike_Extractor_docker.R "${runname}.fa"
cd "${startdir2}"
####### Ekstrahere Spike fra fasta-sekvens #######	SLUTT ######


###### Merge, Framshift og Noise ####################
startdir2=$(pwd)
runname=${startdir2##*/}
cd "${startdir2}/${runname}_summaries"
Rscript /home/docker/Scripts/CSAK_csv_merger_Nanopore_docker.R
Rscript /home/docker/Scripts/CSAK_NoiseExtractor_docker.R c8
# input filer *NextcladeAndPangolin.csv og *_summaries.csv output *summaries_and_Pangolin.csv

mkdir Frameshift
cp ${startdir2}/${runname}_summaries/fasta/${runname}.fa Frameshift/${runname}.fa
cd Frameshift
Rscript /home/docker/Scripts/CSAK_Frameshift_Finder_docker.R c8
mv *.xlsx ${startdir2}/${runname}_summaries
cd ..
rm -f Frameshift

cd "${startdir2}"
Rscript /home/docker/Scripts/CSAK_QCPlotter_Nanopore_docker.R
Rscript /home/docker/Scripts/CoronaTree.R

mv /home/docker/Fastq/*aligned.fasta ${startdir2}/${runname}_summaries/

mv /home/docker/Fastq/Tree.pdf ${startdir2}/${runname}_summaries/${runname}_tree.pdf
Rscript /home/docker/Scripts/CoverageCalculator.R


rm /home/docker/Fastq/*.fasta
rm /home/docker/Fastq/*.csv
rm /home/docker/Fastq/primers.bed
rm -r /home/docker/Fastq/temp/
rm  ${startdir2}/${runname}/Rplots.pdf
conda deactivate
###################
##Avslutter skriptet ###
##################
