# Load sampleNames from the config.yaml file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]
projectName = config["projectName"]

rule all3:
    input:
        "results/salmon/transcriptome_index/complete_ref_lens.bin",
        "results/salmon/transcriptome_index/ctable.bin",
        "results/salmon/transcriptome_index/ctg_offsets.bin",
        "results/salmon/transcriptome_index/duplicate_clusters.tsv",
        "results/salmon/transcriptome_index/info.json",
        "results/salmon/transcriptome_index/mphf.bin",
        "results/salmon/transcriptome_index/pos.bin",
        "results/salmon/transcriptome_index/pre_indexing.log",
        "results/salmon/transcriptome_index/rank.bin",
        "results/salmon/transcriptome_index/refAccumLengths.bin",
        "results/salmon/transcriptome_index/ref_indexing.log",
        "results/salmon/transcriptome_index/reflengths.bin",
        "results/salmon/transcriptome_index/refseq.bin",
        "results/salmon/transcriptome_index/seq.bin",
        "results/salmon/transcriptome_index/versionInfo.json",
        expand("logs/salmon/{sra_id}.log", sra_id=sampleNames),
        expand("results/salmon/{sra_id}/quant.sf", sra_id=sampleNames),

rule salmon_index:
    input:
        sequences="results/megahit/assembly/" + projectName + "_final_orfs.ffn",
    output:
        multiext(
            "results/salmon/transcriptome_index/",
            "complete_ref_lens.bin",
            "ctable.bin",
            "ctg_offsets.bin",
            "duplicate_clusters.tsv",
            "info.json",
            "mphf.bin",
            "pos.bin",
            "pre_indexing.log",
            "rank.bin",
            "refAccumLengths.bin",
            "ref_indexing.log",
            "reflengths.bin",
            "refseq.bin",
            "seq.bin",
            "versionInfo.json",
        ),
    log:
        "logs/salmon/transcriptome_index.log",
    threads: config["salmonThreads"]
    wrapper:
        "v3.13.5/bio/salmon/index"

rule salmon_quant_reads:
    input:
        r1      = "results/fastq_files/final_{sra_id}_R1.fq.gz",
        r2      = "results/fastq_files/final_{sra_id}_R2.fq.gz",
        index   = "results/salmon/transcriptome_index",
        extra   = "results/salmon/transcriptome_index/seq.bin", #this file doesnt need to be here for it to run, but it insures that the DAG map is made correctly
    output:
        quant   = "results/salmon/{sra_id}/quant.sf",
        lib     = "results/salmon/{sra_id}/lib_format_counts.json",
    log:
        "logs/salmon/{sra_id}.log",
    params:
        # optional but very typical parameters are applied here. libtype "A" automatically determines the library type.
        # The library type string consists of three parts: the relative orientation of the reads, the strandedness of the library, 
        # and the directionality of the reads
        libtype = "A",
        # This model will attempt to correct for random hexamer priming bias, which results in the preferential 
        # sequencing of fragments starting with certain nucleotide motifs.
        extra   = "seqBias",
    threads: config["salmonThreads"]
    # the wrappers are prepared and downloaded via github
    wrapper:
        "v5.1.0/bio/salmon/quant"

