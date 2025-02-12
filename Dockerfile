FROM condaforge/mambaforge:latest
LABEL io.github.snakemake.containerized="true"
LABEL io.github.snakemake.conda_env_hash="318e8a76452ccc0bb23697022c072c68636e0d95b73c40eb3b3cc0a3b8d6eaaa"

# Step 1: Retrieve conda environments

# Conda environment:
#   source: https://github.com/snakemake/snakemake-wrappers/raw/v3.13.5/bio/salmon/index/environment.yaml
#   prefix: /conda-envs/e4a3325e8ed88fd69ecfc27669ef70eb
#   channels:
#     - conda-forge
#     - bioconda
#     - nodefaults
#   dependencies:
#     - salmon =1.10.3
RUN mkdir -p /conda-envs/e4a3325e8ed88fd69ecfc27669ef70eb
ADD https://github.com/snakemake/snakemake-wrappers/raw/v3.13.5/bio/salmon/index/environment.yaml /conda-envs/e4a3325e8ed88fd69ecfc27669ef70eb/environment.yaml

# Conda environment:
#   source: https://github.com/snakemake/snakemake-wrappers/raw/v5.1.0/bio/salmon/quant/environment.yaml
#   prefix: /conda-envs/1193c2e35bb44028f63ef3ca20567daa
#   channels:
#     - bioconda
#     - conda-forge
#     - nodefaults
#   dependencies:
#     - salmon =1.10.3
#     - gzip =1.13
#     - bzip2 =1.0.8
RUN mkdir -p /conda-envs/1193c2e35bb44028f63ef3ca20567daa
ADD https://github.com/snakemake/snakemake-wrappers/raw/v5.1.0/bio/salmon/quant/environment.yaml /conda-envs/1193c2e35bb44028f63ef3ca20567daa/environment.yaml

# Step 2: Generate conda environments

RUN mamba env create --prefix /conda-envs/e4a3325e8ed88fd69ecfc27669ef70eb --file /conda-envs/e4a3325e8ed88fd69ecfc27669ef70eb/environment.yaml && \
    mamba env create --prefix /conda-envs/1193c2e35bb44028f63ef3ca20567daa --file /conda-envs/1193c2e35bb44028f63ef3ca20567daa/environment.yaml && \
    mamba clean --all -y
