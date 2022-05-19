# HAI-Seq

Scripts used for submitting FASTQ files for HAI isolates prior to upload and submission to NCBI SRA and Genome databases.
Processed FASTQ and FASTA files are uploaded to NCBI BioProjects PRJNA288601 (gram-negative) and PRJNA629351 (C. diff)

## batch_HAI.pl
Batch submits the pairs of fastq files formatted YYYYEL-#####_R1.fastq.gz  

batch_HAI.pl [DIRECTORY_IN] [DIRECTORY_OUT] [EMAIL]  
[DIRECTORY_IN]: Directory containing pairs of FASTQ files for processing  
[DIRECTORY_OUT]: Directory to contain output subdirectories  
[EMAIL]: Email address for notification (optional)  



## submit.sh
Submit single jobs directly to Slurm - this is the slurm submission script 
called by batch_HAI.pl  

submit.sh [DIRECTORY_IN] [ACCESSION] [DIRECTORY_OUT]  
[DIRECTORY_IN]: Directory containing pair of FASTQ files to be processed  
[ACCESSION]: HAI ID (YYYYEL-#####) used for pair of FASTQ fles  
[DIRECTORY_OUT]: Directory to contain output  



## upload.pl
Upload files directly to NCBI ftp servers  

upload.pl [DIR_IN] [DIR_RESULTS]  
[DIR_IN]: Directory containing original FASTQ files  
[DIR_RESULTS] :Directory containing results for each isolate (default: results)  
* SSH key provided by NCBI should be located at ~/aspera.openssh  
* Upload filepath provided by NCBI should be located at ~/aspera.path  
	(ex. subasp\@upload.ncbi.nlm.nih.gov:uploads/username\@state.mn.us_Nkq3oWLD)  
  


## verify_download.pl
This program downloads FASTQ files from the SRA database using a list of SRR 
accessions and subsamples those files. Files downloaded from SRA are stored 
in directory $dir_downloads. Subsampled files are stored in directory $dir_down 
sampled.

verify_download.pl -p [SUBSAMPLE PROPORTION] -l [SRR LIST]  
-p subsample proportion expressed as percentage (optional default: 30)  
-l text file containing list of SRA accessions to be downloaded (optional)  
    * If no text file is specified the default list will be used.  
-h this helpful help  

The default list of SRA accessions used is:  
SRR14083920, 
SRR14790820, 
SRR16292061, 
SRR14083921, 
SRR14083945, 
SRR14083891, 
SRR15066362, 
SRR14083911, 
SRR14790815, 
SRR14084007, 
SRR14581016, 
SRR14083944, 
SRR16983636, 
SRR15065939, 
SRR14790813, 
SRR14790818, 
SRR16292058, 
SRR14083979, 
SRR14083935, 
SRR14083890, 
SRR15065885, 



## verify_contaminated.pl
Files used for creating synthetic contaminated FASTQ files are looked for 
in directory "downloads". Synthetic contaminated files are stored in 
directory "contaminated".

verify_contaminated.pl -l [SRR LIST]  
-l SRR LIST: Optional text file containing list of SRA accessions to be used. 
 If no text file is specified the default list will be used. Run the program 
 verify_download.pl to download the files first.  
-h This helpful help file  
