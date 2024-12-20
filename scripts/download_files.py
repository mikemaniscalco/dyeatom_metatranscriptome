import subprocess

with open('biosample_list.txt', 'r') as f:
    biosamps = f.read().splitlines()

with open('sra_list.txt', 'r') as f:
    sra_list = f.read().splitlines()
sra_list = ["sra_files/" + i + '.sra' for i in sra_list]

# this will download the .sra files to \\\ (will create directory if not present)
for i, biosamp_id in enumerate(biosamps):
    print ("Currently downloading: " + biosamp_id)
    prefetch = "prefetch " + biosamp_id + " --output-file " + sra_list[i]
    print ("The command used was: " + prefetch + " --output-file " + sra_list[i])
    subprocess.call(prefetch, shell=True)
    
