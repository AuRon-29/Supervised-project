# command lines for the OBITools tutorial:

# 0. FIRST OF ALL:

# 0.1. connect to the cluster:
ssh fleur@genobioinfo.toulouse.inrae.fr #replace the login by yours
# enter your password

# 0.2. prepare folders and download data:
cd ~/work/
# download and unzip the raw data:
wget https://pythonhosted.org/OBITools/_downloads/wolf_tutorial.zip
unzip wolf_tutorial.zip
# delete the zip file:
rm wolf_tutorial.zip
# create sub-folders:
mkdir wolf_tutorial/data wolf_tutorial/results
# move the raw data files in the sub-folder data/:
cd wolf_tutorial/
mv *.fast? *.txt embl_r117.?dx data/
# have a look at the forward reads:
less data/wolf_F.fastq

# 0.3. get an interactive session:
srun --mem=4G --pty bash
# load modules:
module load devel/Miniconda/Miniconda3 # miniconda has to be loaded before
module load bioinfo/OBITools/1.2.11


## 1. ALIGN READS:

# 1.1. align reads (~2 minutes):
illuminapairedend --score-min=40 -r data/wolf_R.fastq data/wolf_F.fastq > results/wolf.fastq
# ?--> have a look at the help page of the illuminapairedend command: https://pythonhosted.org/OBITools/scripts/illuminapairedend.html. Explain what the --score-min option does.

# 1.2. keep aligned sequences:
obigrep -p 'mode!="joined"' results/wolf.fastq > results/wolf.ali.fastq

# you can also keep the unaligned sequences by running the following command line:
## obigrep -p 'mode=="joined"' results/wolf.fastq > results/wolf.noali.fastq

# 1.3. explore results file:
obihead --without-progress-bar results/wolf.ali.fastq # display the first 10 sequence records
obihead --without-progress-bar -n 1 results/wolf.ali.fastq # display only the first sequence record
# ?--> which attribute contains the alignment score?
# attributes are described at the end of this page: https://pythonhosted.org/OBITools/scripts/illuminapairedend.html
# ?--> how many sequences were kept at this step?
# have a look at the obicount command (https://pythonhosted.org/OBITools/scripts/obicount.html#module-obicount) to answer this question. You can also use the grep bash command (https://www.gnu.org/software/grep/manual/grep.html).


## 2. DEMULTIPLEX:

# ?--> Have a look at the ngsfilter file. What informations does it contain?

# 2.1. demultiplex (~1 minute):
ngsfilter -t data/wolf_diet_ngsfilter.txt -u results/wolf.ali.unidentified.fastq results/wolf.ali.fastq > results/wolf.ali.assigned.fastq
# ?--> what are the options -t and -u used for?
# the answer is here: https://pythonhosted.org/OBITools/scripts/ngsfilter.html#module-ngsfilter

# 2.2. explore results file:
obihead -n 1 results/wolf.ali.assigned.fastq
# ?--> which attribute contains the assigned sample?


## 3. DEREPLICATE:

# 3.1. dereplicate:
obiuniq -m sample results/wolf.ali.assigned.fastq > results/wolf.ali.assigned.uniq.fasta
# ?--> what is the option -m used for?

# 3.2. explore results file:
obihead --without-progress-bar -n 1 results/wolf.ali.assigned.uniq.fasta
# ?--> which attribute contains the assigned sample(s)?

# 3.3. compare number of sequences before and after dereplication:
obicount results/wolf.ali.assigned.fastq
obicount results/wolf.ali.assigned.uniq.fasta


## 4. DENOISE:

# 4.1. denoise:
obigrep -l 80 -s '^[acgt]+$' -p 'count>1' results/wolf.ali.assigned.uniq.fasta > results/wolf.ali.assigned.uniq.c1.l80.fasta

# ?--> explain the purpose of each option.

# 4.2. display number of sequences after denoising:
obicount results/wolf.ali.assigned.uniq.c1.l80.fasta


## 5. CLUSTERING:

# 5.1. cluster:
obiclean -s merged_sample -r 0.05 -H results/wolf.ali.assigned.uniq.c1.l80.fasta > results/wolf.ali.assigned.uniq.c1.l80.clean.fasta


## 6. TAXONOMIC ASSIGNATION

# !!!!! DO NOT RUN THE COMMENTED LINES BELOW:

# 6.1. download the sequences (~3 days):
# mkdir EMBL
# cd EMBL
# wget -nH --cut-dirs=4 -A rel_std_\*.dat.gz -m ftp://ftp.ebi.ac.uk/pub/databases/embl/release/
# cd ..

# 6.2. download the taxonomy:
# mkdir TAXO
# cd TAXO
# wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
# tar -zxvf taxdump.tar.gz
# cd ..

# 6.3. format the database:
# obiconvert --embl -t ./TAXO --ecopcrDB-output=embl_last ./EMBL/*.dat

# 6.4. In silico PCR to extract the reference database:
# ecoPCR -d ./ECODB/embl_last -e 3 -l 50 -L 150 TTAGATACCCCACTATGC TAGAACAGGCTCCTCTAG > v05.ecopcr
# + clean the db (cf. https://pythonhosted.org/OBITools/wolves.html)

# 6.5. taxonomic annotation:
ecotag -d data/embl_r117 -R data/db_v05_r117.fasta results/wolf.ali.assigned.uniq.c1.l80.clean.fasta > results/wolf.ali.assigned.uniq.c1.l80.clean.tag.fasta

# 6.6. explore results file:
obihead -n 1 results/wolf.ali.assigned.uniq.c1.l80.clean.tag.fasta
# ?--> what attributes are added? what information do they contain?
# ?--> Which species were eaten by the wolves?

## 7. EXPORT DATA AS MOTUS TABLE:

# 7.1. before we remove some attributes for clarity (but I recommend not to do it IRL to keep track of all attributes values):
obiannotate -k scientific_name -k merged_sample results/wolf.ali.assigned.uniq.c1.l80.clean.tag.fasta > results/wolf.ali.assigned.uniq.c1.l80.clean.tag.ann.fasta

# 7.2. export data as table:
obitab -o results/wolf.ali.assigned.uniq.c1.l80.clean.tag.ann.fasta > results/wolf.ali.assigned.uniq.c1.l80.clean.tag.ann.tab


