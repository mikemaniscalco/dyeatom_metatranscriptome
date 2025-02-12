# Load sampleNames from the config.yaml file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]
projectName = config["projectName"]
data_path = Path("results/data")

merged_counts_fname = data_path / f"{projectName}_counts.csv"

rule merge_counts:
    input:
        expand("results/salmon/{sra_id}/quant.sf", sra_id=sampleNames)
    output:
        merged_counts_fname,
    log:
        "logs/merge_counts.log",
    conda:
        "../envs/general.yaml"
    shell:
        """
        Rscript workflow/scripts/SalmonQuantMerge.R -p dyeatom_inc 2>&1 | tee -a {log}
        """
