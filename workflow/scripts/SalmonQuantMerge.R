# List of packages for session
.packages = c("dplyr", "argparse", "purrr")

# Installing CRAN packages (if not already installed)
.inst <- .packages %in% installed.packages()
if(length(.packages[!.inst]) > 0) install.packages(.packages[!.inst])

# Loading packages into session 
lapply(.packages, library, character.only = TRUE, quietly=TRUE)
# setwd("/Users/m.maniscalco/dyeatom_metatranscriptome")

# Add command line arguments
parser <- argparse::ArgumentParser(description = "Merge Salmon quant.sf  files together and use input project name to name output file")

parser$add_argument("-p", 
                    "--project_string", 
                    dest ="proj_str", 
                    default = "",
                    nargs=1, 
                    help="Input project name (-p) to include in output filename.")

args <- parser$parse_args()

proj_str <- args$proj_str



samples <- read.csv( "SRAnameLUT.csv", header = TRUE)

files <- file.path("results/salmon", samples$SRA_id, "quant.sf")

# Extract the portion of the file path for naming (e.g., "SRR17287625")
names <- sub(".*/salmon/([^/]+)/.*", "\\1", files)

# Create a named list
named_list <- setNames(as.list(files), names)

# read files, rename columns, remove TMP and EffectiveLength columns
df_list <- purrr::imap(named_list, ~read.delim(.x)%>%
                      dplyr::select(-TPM,-EffectiveLength) %>%
                      dplyr::rename(transcript = Name, 
                                    !!paste0(.y) := NumReads))

dataset <- purrr::reduce(df_list, full_join) %>%
  dplyr::rename_at(vars(samples$SRA_id), ~ samples$sampleName) %>%
  dplyr::mutate(dplyr::across(where(is.numeric), 
                ~replace(., is.na(.), 0)))
  

#drop transcript ID column in prep for summing
dataset <-  dataset %>% tibble::column_to_rownames("transcript")
# 
# #change character columns to numeric
# dataset <- data.frame(sapply(dataset, as.numeric), row.names = data_names$transcript)
# dataset[is.na(dataset)] <- 0
# 
# 
# #write counts file for table with individual lanes
# dataset <-  tibble::rownames_to_column(dataset, "transcript")
out_name <- paste0("results/data/",proj_str,"_counts.csv")

readr::write_csv(dataset, out_name,col_names = T)
# dataset <-  tibble::column_to_rownames(dataset, "transcript")
# 
# data.frame(sapply(dataset, class))
# head(dataset)
# 
# patterns <- unique(substr(colnames(dataset), 1, nchar(colnames(dataset))-5))  # store patterns in a vector
# dataset <- sapply(patterns, function(xx) rowSums(dataset[,grep(xx, names(dataset)), drop=FALSE]))  # loop through
# 
# #turn matrix back into dataframe
# dataset <- data.frame(dataset)
# 
# colnames(dataset)<- c("Si2control1_S94", "Si2control2_S95", "Si2control3_S96",
#                       "Si2plusSi1_S97",  "Si2plusSi2_S98",  "Si3control1_S82",
#                       "Si3control2_S83", "Si3control3_S84", "Si3plusSi1_S85", 
#                       "Si3plusSi2_S86",  "Si3plusSi3_S87",  "Si8control1_S88",
#                       "Si8control2_S89", "Si8control3_S90", "Si8plusSi1_S91", 
#                       "Si8plusSi2_S92",  "Si8plusSi3_S93")
# 
# # write counts file table with corresponding lanes summed
# dataset <-  tibble::rownames_to_column(dataset, "transcript")
# write_csv(dataset, "2019_01_07_DYEatom_Inc_MM_counts.csv")