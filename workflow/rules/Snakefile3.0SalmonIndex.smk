import os

# Load sampleNames from the config.yaml file
configfile: "workflow/config/config.yaml"
projectName = config["projectName"]
megahit_path = Path("results/megahit/assembly")

megahit_orfs_ffn_fname = megahit_path / f"{projectName}_final_orfs.ffn"

rule salmon_index:
    input:
        sequences=megahit_orfs_ffn_fname,
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
    threads: 2
    # params:
    #     # optional parameters
    #     extra="",
    wrapper:
        "v5.1.0/bio/salmon/index"
