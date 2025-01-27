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
        "logs/fastq_dump/get_fastqs_{sra_id}.log"
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
        "logs/interleave_reads/interleave_reads1_{sra_id}.log"
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
    log: 
        "logs/fastp/trim_qc_reads_{sra_id}.log"
    params:
        html    = "logs/fastp/fastp.html",
        json    = "logs/fastp/fastp.json"
    conda:
        "../envs/general.yaml"   
    shell:
        "fastp --interleaved_in -i {input.inter} -o {output.r1} -O {output.r2} -h {params.html} -j {params.json} 2>&1 | tee -a {log}"


rule ribodetector_rule:
    input:
        r1          = "results/intermediate_fastqs/{sra_id}_R1.fq.gz",
        r2          = "results/intermediate_fastqs/{sra_id}_R2.fq.gz",
    output:
        r1          = "results/fastq_files/final_{sra_id}_R1.fq.gz",
        r2          = "results/fastq_files/final_{sra_id}_R2.fq.gz",
        rna1          = "results/intermediate_fastqs/{sra_id}_rna_R1.fq.gz",
        rna2          = "results/intermediate_fastqs/{sra_id}_rna_R2.fq.gz"
    log: 
        "logs/ribodetector/remove_rrna_reads_{sra_id}.log"
    params:
        other       = "results/intermediate_fastqs/{sra_id}_filtered"
    conda:
        "../envs/ribodetector.yaml"
    shell:
        """
        ribodetector_cpu -t 2 \
        -l 150 \
        -i {input.r1} {input.r2} \
        -r {output.rna1} {output.rna2} \
        -e none \
        --chunk_size 256 \
        -o {output.r1} {output.r2} 2>&1 | tee -a {log}
        """
