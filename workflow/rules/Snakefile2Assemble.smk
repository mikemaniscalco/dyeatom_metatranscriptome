# Load sampleNames from the config.yaml file
# "dyeatom" is spread throught this and needs to be moved to the config file
configfile: "workflow/config/config.yaml"
sampleNames = config["sampleNames"]
projectName = config["projectName"]

filtered_files1 = expand("results/fastq_files/final_{sra_id}_R1.fq.gz", sra_id=sampleNames)
filtered_files2 = expand("results/fastq_files/final_{sra_id}_R2.fq.gz", sra_id=sampleNames)
filtered_files_string1 = ",".join(filtered_files1)
filtered_files_string2 = ",".join(filtered_files2)

rule all2:
    input:
        "results/megahit/assembly/final.contigs.fa",  
        "results/megahit/assembly/" + projectName + "_final.contigs.fa",
        "results/megahit/assembly/" + projectName + "_final_orfs.faa",
        "results/megahit/assembly/" + projectName + "_final_orfs.ffn",
        "results/megahit/assembly/" + projectName + "_final_orfs.out",
        "results/megahit/assembly/" + projectName + "_final_orfs.gff"

# note that the minimum contig length is set to 200bp by defailt
rule megahit:
    input:
        r1      = filtered_files1,
        r2      = filtered_files2
    #filenames are actually being loaded into the command through params as a concatonated string, which can cause errors with inputs as that expects actual filenames
    params:
        r1      = filtered_files_string1,
        r2      = filtered_files_string2,
        dir     = "results/megahit/assembly",
        threads = config["megahitThreads"],
        mem     = config["megahitMemory"]
    # while the output name is not used in running the shell command it is needed for the workflow to identify the rule completion and the availability of the file for the next rule
    output:
        fasta   = "results/megahit/assembly/final.contigs.fa",    
    shell:
        "megahit -1 {params.r1} -2 {params.r2} -f -o {params.dir} -m {params.mem} -t {params.threads}" 
        
rule simplify_seq_names:
    input:
        "results/megahit/assembly/final.contigs.fa",
    output:
        "results/megahit/assembly/" + projectName + "_final.contigs.fa",
    shell:
        """
        reformat.sh in={input} out={output} trd=t
        """
        
rule find_orfs:
    input:
        "results/megahit/assembly/" + projectName + "_final.contigs.fa",
    output:
        aas     = "results/megahit/assembly/" + projectName + "_final_orfs.faa",
        nts     = "results/megahit/assembly/" + projectName + "_final_orfs.ffn",
        meta    = "results/megahit/assembly/" + projectName + "_final_orfs.out",
        gff     = "results/megahit/assembly/" + projectName + "_final_orfs.gff",
    params:
        error   = config["error"],
        threads = config["fgsThreads"]
    shell:
        "FragGeneScanRs -s {input} -m {output.meta} -a {output.aas} -n {output.nts} -g {output.gff} -w 1 -t {params.error} -p {params.threads}"
