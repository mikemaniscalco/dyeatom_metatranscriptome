# Load sampleNames from the config.yaml file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]
projectName = config["projectName"]

rule all4:
    input:
        expand("logs/salmon/{sra_id}.log", sra_id=sampleNames),
        expand("results/salmon/{sra_id}/quant.sf", sra_id=sampleNames),

rule salmon_quant_reads:
    input:
        r1      = "results/fastq_files/final_{sra_id}_R1.fq.gz",
        r2      = "results/fastq_files/final_{sra_id}_R2.fq.gz",
        index   = "results/salmon/transcriptome_index/seq.bin", #this file doesnt need to be here for it to run, but it insures that the DAG map is made correctly
    output:
        quant   = "results/salmon/{sra_id}/quant.sf",
    log:
        "logs/salmon/{sra_id}.log",
    params:
        # optional but very typical parameters are applied here. libtype "A" automatically determines the library type.
        # The library type string consists of three parts: the relative orientation of the reads, the strandedness of the library, 
        # and the directionality of the reads
        libtype = "A",
        odir = "results/salmon/{sra_id}",
        index = "results/salmon/transcriptome_index",
        # This model will attempt to correct for random hexamer priming bias, which results in the preferential 
        # sequencing of fragments starting with certain nucleotide motifs.
        extra   = "--seqBias --gcBias"
    threads: config["salmonThreads"]
    # the wrappers are prepared and downloaded via github
    conda:
        "../envs/salmon_quant.yaml"
    shell:
        """
        salmon quant -i {params.index} -l {params.libtype} -1 {input.r1} -2 {input.r2} {params.extra} -o {params.odir} -p {threads}  2>&1 | tee -a {log}
        """
