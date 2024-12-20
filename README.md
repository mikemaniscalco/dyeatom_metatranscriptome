# dyeatom_metatranscriptome


# using bbtools script  
```
reformat.sh in=final.contigs.fa out=final.contigs_renamed.fa trd=t  
  
```

  
  
### create conda environment
```{bash}

conda create -c conda-forge -c bioconda -n env_snakemake python=3.10 snakemake wget pigz install fastp sortmerna bbmap megahit==1.2.8
  salmon==1.10.3
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

### If removing rRNA seqs then install Rust and FragGeneScanR

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  

. "$HOME/.cargo/env" #initialize rust to use cargo install
cargo install frag_gene_scan_rs  
  
  
  
conda install bioconda::java-jdk
conda install bioconda::salmon
```
  