# Save variable of rRNA databases
# Save the location of all the databases into one folder
sortmernaREF=sortmerna/rRNA_databases_v4/smr_v4.3_default_db.fasta

# Run SortMeRNA
#paired_in option for sortmerna... in the case that one read matches rrna and the other is not keep both reads as mrna
for filename in fastq_files/*{_R1,_R2}.fq.gz; do
    # Extract the base name
    base=${filename%_R[12].fq.gz}
    echo "${base}_filtered.fq.gz" 
    # Check if files with the same basename and ending in "_filtered.fq.gz" are present
    if [ -e "fastq_files/${base}_filtered.fq.gz" ]; then
        echo "Skipping $filename because ${base}_filtered.fq.gz exists"
    else
        # Process the file as needed
        echo "Processing $filename"
        echo "Base name: $base"

        sortmerna \
        --ref $sortmernaREF \
        --reads ${base}_R1.fq.gz \
        --reads ${base}_R2.fq.gz \
        --paired_in \
        --fastx \
        -threads 2 \
        -workdir sortmerna/run_${base} \
        -v
    fi
done 
