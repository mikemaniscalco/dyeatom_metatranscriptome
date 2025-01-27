# dyeatom_metatranscriptome
Bioinformatic workflow used to prepare the raw data for analyses in the study .

The study focused on a series of deckboard Si-amendment incubations were conducted using surface water collected in the California Upwelling Zone near Monterey Bay. Steep concentration gradients in macronutrients in the surface ocean coupled with substantial N and Si utilization led to communities with distinctly different macronutrient states: replete (‘healthy’), low N (‘N-stressed’), and low N and Si (‘N- and Si-stressed’). Biogeochemical measurements of Si uptake combined with metatranscriptomic analysis of communities incubated with and without added Si were used to explore the underlying molecular response of diatom communities to different macronutrient availability. 
https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2023.1291294/full

Note that additional workflows will be added over the next few weeks as I collect and go back over the code from this project.

## Outline
1) workflow/config/config.yaml:
  * Contains various workflow optimization parameters amd project specific parameters such as the sample names used as inputs to download SRA files.
  * This is loaded into the various snakefiles to incorporate the configuration settings as variables and parameters.
2) workflow/SnakefileFull.smk
  * This is the primary Snakefile that incorporates the rules within the below snakefiles
3) workflow/rules/Snakefile1GetPrepReads.smk
  * Download data from SRA either as a subsample or full data files
    - fasterq-dump with prefetch is a faster option when using full files, but using without prefetch and subsetting the SRA files is fast and better for initial testing and troubleshooting 
    - this will download the .sra files (will create directory if not present)
    - workflow/scripts/download_files.py can be used for switching to prefetch fasterq-dump for file download
  * Adapters are trimmed, low quality reads are removed, and QC reports are created using fastp
  * rRNA reads are seperated from other reads prior to assembly using sortmerna tool. This step was performed within our study to maintain consistency with datasets within [related studies](https://aslopubs.onlinelibrary.wiley.com/doi/full/10.1002/lno.11431 , https://www.nature.com/articles/s41564-019-0502-x). It is beneficial to remove rRNA reads as they can map to certain coding genes which share partial sequence similarity to rRNAs. However, sortmerna is slow and computationally intensive. Newer tools may be [more efficient alternatives](https://academic.oup.com/nar/article/50/10/e60/6533611). Our study focused on differential abundance analysis where large differences in proportions of rRNA reads per sample would impact the pairwise-comparisons between samples. Ideally the samples would have very little and similar proportions of rRNA left, but that is not necessarily the case.
4) workflow/rules/Snakefile2Assemble.smk
  * Assemble reads into contigs using MEGAHIT with the preset --meta-large setting that meant for samples that are complex (i.e., bio-diversity is high, for example soil--or in our case marine-- meta-assemblies)
  * Scan for orfs within assembly contigs. This will output nucleotide and amino acid fasta files.

5) workflow/rules/Snakefile3MapReads.smk
  * Salmon index: creates an index from the assembly orf nucleotide file.
  * Salmon quant: quantifies the reads per orf/contig.
  * This relies on two Snakemake wrappers from the [Snakemake Wrappers repository](https://snakemake-wrappers.readthedocs.io/en/stable/)


## Setup

### Create conda environment

```
{bash}
# the environment name "env_snakemake" is used below but modify as desired
conda create -c conda-forge -c bioconda -n env_snakemake python=3.10 snakemake graphviz

conda activate env_snakemake  

# Install SRA toolkit
## for linux
wget "https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.1.0/sratoolkit.3.1.0-ubuntu64.tar.gz" 
tar zxf sratoolkit.3.1.0-ubuntu64.tar.gz  
export PATH=$HOME/sratoolkit.3.1.0-ubuntu64/bin:$PATH  

## for mac
cd 
mkdir bioinf_tools
cd bioinf_tools
curl --output sratoolkit.tar.gz https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-mac64.tar.gz
tar -vxzf sratoolkit.tar.gz
export PATH=$PATH:/Users/m.maniscalco/bioinf_tools/sratoolkit.3.1.1-mac-x86_64/bin

conda install bioconda::bbmap # for interleave script  
```

### Rust and FragGeneScan are installed for orf scanning

```
{bash}
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  

. "$HOME/.cargo/env" #initialize rust to use cargo install
cargo install frag_gene_scan_rs  
  
conda install bioconda::java-jdk
```

### Run 

```
{bash}
snakemake -s workflow/Snakefile --cores 2 --use-conda

# generate DAG diagram
snakemake -s workflow/Snakefile --cores 2 --use-conda --rulegraph | dot -Tpng > dag.png
```