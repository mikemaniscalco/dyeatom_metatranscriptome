# Load sampleNames from the config.yaml file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]

rule all1:
    input:
        expand("results/fastq_files/final_{sra_id}_R1.fq.gz", sra_id=sampleNames),
        expand("results/fastq_files/final_{sra_id}_R2.fq.gz", sra_id=sampleNames),

# fasterq-dump with prefetch is faster option when using full files, but for troubleshooting workflow the below is great for subsetting reads
# this will download the .sra files (will create directory if not present)
# scripts/download_files.py included for modifying to prefetch fasterq-dump 
# output names cannot be designated with fastq-dump
rule get_fastqs:
    output:
        "results/intermediate_fastqs/{sra_id}_1.fastq",
        "results/intermediate_fastqs/{sra_id}_2.fastq"
    log: 
        "logs/get_fastqs_{sra_id}.log"
    conda:
        "../envs/general.yaml"   
    shell:
        "fastq-dump --outdir results/intermediate_fastqs -X 10000 --skip-technical --split-3 {wildcards.sra_id} 2>&1 | tee -a {log}"

rule compress_files:
    input:
        actual1 = "results/intermediate_fastqs/{sra_id}_1.fastq",
        actual2 = "results/intermediate_fastqs/{sra_id}_2.fastq",

    output:
        out1 = "results/fastq_files/{sra_id}_R1.fastq.gz",
        out2 = "results/fastq_files/{sra_id}_R2.fastq.gz",

    log: 
        log1 = "logs/compress_files_{sra_id}_R1.log",
        log2 = "logs/compress_files_{sra_id}_R2.log",

    conda:
        "../envs/general.yaml"   
    shell:
        """
        pigz -p 2 {input.actual1} 2>&1 | tee -a {log.log1}
        mv {input.actual1}.gz {output.out1} 2>&1 | tee -a {log.log1}
        pigz -p 2 {input.actual2} 2>&1 | tee -a {log.log2}
        mv {input.actual2}.gz {output.out2} 2>&1 | tee -a {log.log2}
        """

rule interleave_reads1:
    input:
        r1  = "results/fastq_files/{sra_id}_R1.fastq.gz",
        r2  = "results/fastq_files/{sra_id}_R2.fastq.gz"
    output:
        "results/fastq_files/{sra_id}_inter.fastq.gz"
    log: 
        "logs/interleave_reads1_{sra_id}.log"
    conda:
        "../envs/general.yaml"    
    shell:
        "bbmerge.sh in1={input.r1} in2={input.r2} out={output} 2>&1 | tee -a {log}"

rule trim_qc_reads:
    input:
        inter    = "results/fastq_files/{sra_id}_inter.fastq.gz",
    output:
        r1      = "results/intermediate_fastqs/{sra_id}_R1.fq.gz",
        r2      = "results/intermediate_fastqs/{sra_id}_R2.fq.gz",
        # "results/intermediate_fastqs/{sra_id}_inter.fq.gz"
    log: 
        "logs/fastp/trim_qc_reads_{sra_id}.log"
    params:
        html    = "logs/fastp/fastp.html",
        json    = "logs/fastp/fastp.json"
    conda:
        "../envs/general.yaml"   
    shell:
        "fastp --interleaved_in -i {input.inter} -o {output.r1} -O {output.r2} -h {params.html} -j {params.json} 2>&1 | tee -a {log}"

# I think sortmerna runs into problems when its not run in interleave mode
rule sortmerna_prep_rule:
    output:
        "results/sortmerna/rRNA_databases_v4/smr_v4.3_default_db.fasta",
        "results/sortmerna/rRNA_databases_v4/smr_v4.3_fast_db.fasta",
        "results/sortmerna/rRNA_databases_v4/smr_v4.3_sensitive_db.fasta",
        "results/sortmerna/rRNA_databases_v4/smr_v4.3_sensitive_db_rfam_seeds.fasta"
    log: 
        "logs/sortmerna_prep_rule.log"
    conda:
        "../envs/general.yaml"    
    shell:"""
    mkdir -p results/sortmerna/
    mkdir -p results/sortmerna/rRNA_databases_v4
    cd results/sortmerna/rRNA_databases_v4
    wget https://github.com/biocore/sortmerna/releases/download/v4.3.4/database.tar.gz
    tar -zxvf database.tar.gz
    rm database.tar.gz
    """

rule remove_rrna_reads:
    input:
        ref1        = "results/sortmerna/rRNA_databases_v4/smr_v4.3_default_db.fasta",
        ref2        = "results/sortmerna/rRNA_databases_v4/smr_v4.3_fast_db.fasta",
        ref3        = "results/sortmerna/rRNA_databases_v4/smr_v4.3_sensitive_db.fasta",
        ref4        = "results/sortmerna/rRNA_databases_v4/smr_v4.3_sensitive_db_rfam_seeds.fasta",
        infile      = "results/intermediate_fastqs/{sra_id}_inter.fq.gz",
    output:
        aligned     = "results/intermediate_fastqs/{sra_id}_aligned.fq.gz",
        filtered    = "results/intermediate_fastqs/{sra_id}_filtered.fq.gz"
    log: 
        "results/sortmerna/{sra_id}_rrna.log" #there is no option to redirect or designate log file
    params:
        aligned     = "results/intermediate_fastqs/{sra_id}_aligned",
        other       = "results/intermediate_fastqs/{sra_id}_filtered"
    # sortmerna has an unorthodox wildcard usage
    conda:
        "../envs/sortmerna.yaml"
    shell:
        """
        sortmerna \
        --ref results/sortmerna/rRNA_databases_v4/smr_v4.3_default_db.fasta \
        --reads {input.infile} \
        --aligned {params.aligned} \
        --other {params.other} \
        --log
        --paired \
        --paired_in \
        --fastx \
        -threads 2 \
        -workdir results/sortmerna/run_{wildcards.sra_id} \
        -v
        [ -d results/sortmerna/run_{wildcards.sra_id} ] && rm -r results/sortmerna/run_{wildcards.sra_id}
        """







# # the first line of this rule will remove index files created by sortmerna. They are kind of large and there is no need to keep them.
# rule deinterleave_reads:
#     input:
#         "results/intermediate_fastqs/{sra_id}_filtered.fq.gz"
#     output:
#         r1  = "results/fastq_files/final_{sra_id}_R1.fq.gz",
#         r2  = "results/fastq_files/final_{sra_id}_R2.fq.gz"
#     log: 
#         "logs/deinterleave_reads_{sra_id}.log"
#     conda:
#         "../envs/general.yaml"   
#     shell:
#         """
#         seqtk seq {input} | \
#         tee >(seqtk seq -1 - | pigz -c > {output.r1}) | \
#         seqtk seq -2 - | pigz -c > {output.r2}
#         """
