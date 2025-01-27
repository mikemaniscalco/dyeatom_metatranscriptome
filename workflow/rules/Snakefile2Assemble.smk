# Load sampleNames from the config.yaml file
# "dyeatom" is spread throught this and needs to be moved to the config file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]
projectName = config["projectName"]
megahit_path = Path("results/megahit/assembly")

megahit_assembly_fa = megahit_path / f"{projectName}_final.contigs.fa"
megahit_orfs_faa_fname = megahit_path / f"{projectName}_final_orfs.faa"
megahit_orfs_ffn_fname = megahit_path / f"{projectName}_final_orfs.ffn"
megahit_orfs_out_fname = megahit_path / f"{projectName}_final_orfs.out"
megahit_orfs_gff_fname = megahit_path / f"{projectName}_final_orfs.gff"


filtered_files1 = expand("results/fastq_files/final_{sra_id}_R1.fq.gz", sra_id=sampleNames)
filtered_files2 = expand("results/fastq_files/final_{sra_id}_R2.fq.gz", sra_id=sampleNames)
filtered_files_string1 = ",".join(filtered_files1)
filtered_files_string2 = ",".join(filtered_files2)

rule all2:
    input:
        "results/megahit/assembly/final.contigs.fa",  
        megahit_assembly_fa,
        megahit_orfs_faa_fname,
        megahit_orfs_ffn_fname,
        megahit_orfs_out_fname,
        megahit_orfs_gff_fname

# note that the minimum contig length is set to 200bp by defailt
rule megahit:
    input:
        r1      = filtered_files1,
        r2      = filtered_files2
    #filenames are actually being loaded into the command through params as a concatonated string, which can cause errors with inputs as that expects actual filenames
    params:
        r1      = filtered_files_string1,
        r2      = filtered_files_string2,
        dir     = "results/megahit/assembly/",
        threads = config["megahitThreads"],
        mem     = config["megahitMemory"],
        presets = config["megahitPresets"]
    # while the output name is not used in running the shell command it is needed for the workflow to identify the rule completion and the availability of the file for the next rule
    output:
        fasta   = "results/megahit/assembly/final.contigs.fa",
    log: 
        "logs/megahit.log"
    conda:
        "../envs/megahit.yaml"    
    shell:
        """
        mkdir -p {params.dir}
        megahit -1 {params.r1} -2 {params.r2} -f -o {params.dir} -m {params.mem} -t {params.threads} --presets {params.presets} 2>&1 | tee -a {log}
        """ 

rule simplify_seq_names:
    input:
        "results/megahit/assembly/final.contigs.fa",
    output:
        megahit_assembly_fa,
    log: 
        "logs/simplify_seq_names.log"
    conda: 
        "../envs/general.yaml"
    shell:
        """
        reformat.sh in={input} out={output} trd=t  2>&1 | tee -a {log}
        """
        
rule find_orfs:
    input:
        megahit_assembly_fa,
    output:
        aas     = megahit_orfs_faa_fname,
        nts     = megahit_orfs_ffn_fname,
        meta    = megahit_orfs_out_fname,
        gff     = megahit_orfs_gff_fname,
    log: 
        "logs/find_orfs.log"
    params:
        error   = config["error"],
        threads = config["fgsThreads"]
    conda:
        "../envs/general.yaml"
    shell:
        "FragGeneScanRs -s {input} -m {output.meta} -a {output.aas} -n {output.nts} -g {output.gff} -w 1 -t {params.error} -p {params.threads}  2>&1 | tee -a {log}"
