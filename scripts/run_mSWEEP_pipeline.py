import os
import argparse
import subprocess
import tempfile
import shutil
from collections import defaultdict

THEMISTO_ALIGN = "themisto pseudoalign"
ALIGNMENT_WRITER = "alignment-writer"
MSWEEP = "mSWEEP"
MGEMS = "mGEMS"
SHOVILL = "shovill"
SEROBA = "seroba"

def get_options():
    import argparse

    description = 'Run the mSWEEP algorithm on deep sequenced samples using a themisto index reference.'
    parser = argparse.ArgumentParser(description=description,
                                     prog='run-mSWEEP')

    io_opts = parser.add_argument_group('Input/output')

    io_opts.add_argument(
        "--r1",
        dest="read1",
        required=True,
        type=str,
        help="forward reads (fastq)")

    io_opts.add_argument(
        "--r2",
        dest="read2",
        required=True,
        type=str,
        help="reverse reads (fastq)")

    io_opts.add_argument(
        "-n",
        dest="ref_num",
        required=True,
        type=int,
        help="number of references")
    
    io_opts.add_argument(
        "-r",
        dest="read_num",
        required=True,
        type=int,
        help="number of reads")
        
    io_opts.add_argument("-o",
                         "--out_dir",
                         dest="output_dir",
                         required=True,
                         type=str,
                         help="location of an output directory")

    io_opts.add_argument(
        "-a",
        "--min_abundance",
        dest="min_abundance",
        default=0.001,
        type=float,
        help="minimum abundance to perform deconvolution and assembly")

    # Other options
    parser.add_argument(
        "--index",
        dest="index",
        required=True,
        default=None,
        help=("location of mSWEEP index folder. Set to a prebuilt one on the farm by default."))

    parser.add_argument(
        "--group_column",
        dest="group_column",
        required=True,
        default=None,
        help=("location of file containing single column with group allocation (must match index and is set to the default on the farm)."))

    parser.add_argument(
        "--seroba_db",
        dest="seroba_db",
        required=True,
        default=None,
        help=("Location of the seroba database."))    
    
    parser.add_argument(
        "--mem",
        dest="max_mem",
        type=int,
        default=10000,
        help=("maximum memory usage in Mb."))

    parser.add_argument(
        "-t",
        "--threads",
        dest="ncpu",
        type=int,
        default=5,
        help=("number of threads to use."))

    args = parser.parse_args()

    return (args)


def main():
    args = get_options()

    # make sure trailing forward slash is present
    args.output_dir = os.path.join(os.path.abspath(args.output_dir), "")

    # get prefix and create output sub-directory
    prefix = os.path.basename(args.read1).split(".")[0]
    if prefix[-2:]=="_1": 
        prefix = prefix[:-2]
    elif prefix[-2:]=="_2":
        prefix = prefix[:-2]

    if not os.path.exists(args.output_dir + prefix):
        os.mkdir(args.output_dir + prefix)
    args.output_dir = args.output_dir + prefix + "/"

    # make temp directory
    temp_dir = args.output_dir + "tmp/"
    if not os.path.exists(temp_dir):
        os.mkdir(temp_dir)

    # run pseudoalignment
    print("running pseudoalignment (Themisto)")
    
    # create temporary input files
    query_list = temp_dir + "query_list.txt"
    with open(query_list, 'w') as outfile:
        outfile.write(args.read1 + "\n")
        outfile.write(args.read2 + "\n")

    out_list = temp_dir + "out_list.txt"
    #aln1_txt = temp_dir + "pseudoalignments_1.txt"
    #aln2_txt = temp_dir + "pseudoalignments_2.txt"
    aln1 = temp_dir + "pseudoalignments_1.aln"
    aln2 = temp_dir + "pseudoalignments_2.aln"
    with open(out_list, 'w') as outfile:
        outfile.write(aln1 + "\n")
        outfile.write(aln2 + "\n")

    # generate align command and run for pair 1
    cmd = THEMISTO_ALIGN + " "
    cmd += "--index-prefix " + args.index + " "
    cmd += "--rc --temp-dir " + temp_dir + " "
    cmd += "--n-threads " + str(args.ncpu) + " "
    cmd += "--query-file " + args.read1 + " "
    #cmd += "--sort-output "
    #cmd += "--out-file " + aln1_txt
    cmd += "--out-file >("
    #cmd += "| "
    cmd += ALIGNMENT_WRITER + " "
    #cmd += "-f " + aln1_txt + " "
    cmd += "-n " + str(args.ref_num) + " "
    cmd += "-r " + str(args.read_num) + " "
    cmd += "> " + aln1
    cmd += ")"

    subprocess.run(['/bin/bash', '-c', cmd], check=True)
    
    # generate align command and run for pair 2
    cmd = THEMISTO_ALIGN + " "
    cmd += "--index-prefix " + args.index + " "
    cmd += "--rc --temp-dir " + temp_dir + " "
    cmd += "--n-threads " + str(args.ncpu) + " "
    cmd += "--query-file " + args.read2 + " "
    #cmd += "--sort-output "
    #cmd += "--out-file " + aln2_txt
    cmd += "--out-file >("
    #cmd += "| "
    cmd += ALIGNMENT_WRITER + " "
    #cmd += "-f " + aln1_txt + " "
    cmd += "-n " + str(args.ref_num) + " "
    cmd += "-r " + str(args.read_num) + " "
    cmd += "> " + aln2
    cmd += ")"
    
    subprocess.run(['/bin/bash', '-c', cmd], check=True)

    # run mSWEEP
    print("running mSWEEP")
    cmd = MSWEEP + " "
    cmd += "--themisto-1 " + aln1 + " "
    cmd += "--themisto-2 " + aln2 + " "
    cmd += "-i " + args.group_column + " "
    cmd += "--write-probs "
    cmd += "-t " + str(args.ncpu) + " "
    cmd += "-o " + args.output_dir + "mSWEEP"
    
    subprocess.run(cmd, shell=True, check=True)

    # get groups from mSWEEP run with sufficient support
    sig_groups = []
    with open(args.output_dir + "mSWEEP_abundances.txt", 'r') as infile:
        for line in infile:
            if line[0]=="#": continue
            line = line.strip().split()
            if float(line[1]) >= args.min_abundance:
                sig_groups.append(line[0])
    
    # Convert tsv to csv
    subprocess.run("sed 's/\t/,/g' " + args.output_dir + "mSWEEP_probs.tsv > " + args.output_dir + "mSWEEP_probs.csv", shell=True, check=True)

    # run mGEMS
    print("running mGEMS")
    cmd = MGEMS + " "
    cmd += "-r " + args.read1 + "," + args.read2 + " "
    cmd += "--themisto-alns " + aln1 + "," + aln2 + " "
    cmd += "-i " + args.group_column + " "
    cmd += "-o " + args.output_dir + " "
    cmd += "--index " + args.index + " "
    cmd += "--probs " + args.output_dir + "mSWEEP_probs.csv "
    cmd += "-a " + args.output_dir + "mSWEEP_abundances.txt "
    cmd += "--groups " + ",".join(sig_groups)

    subprocess.run(cmd, shell=True, check=True)

    # remove temporary directory and probablities
    # shutil.rmtree(temp_dir)
    # os.remove(args.output_dir + "mSWEEP_probs.csv")

    # assemble genomes using Shovill
    print("running Shovill")
    for group in sig_groups:
        assem_out = args.output_dir + group + '/'
        cmd = SHOVILL + " "
        cmd += "--outdir " + assem_out + " "
        cmd += "--R1 " + args.output_dir + group + "_1.fastq.gz "
        cmd += "--R2 " + args.output_dir + group + "_2.fastq.gz"
        subprocess.call(cmd, shell=True)
    
    # run seroba
    print("running seroba")
    cwd = os.getcwd()
    for group in sig_groups:
        assem_out = args.output_dir + group + '/'
        os.chdir(assem_out)
        cmd = SEROBA + " runSerotyping "
        cmd += args.seroba_db + " "
        cmd += args.output_dir + group + "_1.fastq.gz "
        cmd += args.output_dir + group + "_2.fastq.gz "
        cmd += group + "_seroba"

        subprocess.check_call(cmd, shell=True)
    os.chdir(cwd)

    with open(args.output_dir + "seroba_calls.tab", 'w') as outfile:
        for group in sig_groups:
            with open(args.output_dir + group + '/' + group + "_seroba/pred.tsv", 'r') as infile:
                for line in infile:
                    outfile.write(prefix + "\t" + line)

    return


if __name__ == '__main__':
    main()
