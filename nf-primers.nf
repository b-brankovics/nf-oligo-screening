#!/usr/bin/env nextflow

/*
 * pipeline input parameters
 */
params.csv = "$projectDir/example_data/primers.tsv"
params.yaml = "$projectDir/example_data/fus.yaml"
params.target = "$projectDir/example_data/Fo_F11_regions.fas"

params.out = "nf-results"

// Adding log file
def runLog = file(params.out + "/run.log")
// start log
runLog.text = "=== Pipeline started: ${new Date()} ===\n"
runLog << "Command line invocation: ${workflow.commandLine}\n"
runLog << "Nextflow version: ${nextflow.version}\n"
runLog << "Workflow file: ${workflow.scriptFile}\n"
runLog << "Config file(s): ${workflow.configFiles}\n"
runLog << "Launch directory: ${workflow.launchDir}\n"
runLog << "Git repository: ${workflow.repository}\n"
// runLog << "Output directory: ${workflow.outputDir}\n"
runLog << "Profile(s): ${workflow.profile}\n"
// params
params.each { k, v -> runLog << "PARAM $k = $v\n" }


process MAPPRIMERS {    
    publishDir params.out, mode: 'copy', pattern: "primers.fas"
    
    input:
    path csv
    path target

    output:
    path 'lastal.sam', emit: sam
    path 'primers.fas', emit: fasta

    script:
    """
    cat $csv | cut -f2,3 | perl -ne 'next if /^Name\\t/; s/\\t/\\n/; print ">\$_"' > primers.fas
    perl -ne 'next if /^(\\S+)\\tName\\t/; s/\\R//g; @t = split/\\t/; \$id = \$t[1]; \$len = length \$t[2]; print "\\@SQ\\tSN:\$id\\tLN:\$len\\n"' $csv  > lastal.sam
    lastdb lastaldb primers.fas
    lastal lastaldb $target -f MAF | maf-convert sam >>lastal.sam
    """
}

process IUPACSAM {    
    publishDir params.out, mode: 'copy', pattern: "iupac.sam"

    input:
    path lastal
    path primers

    output:
    path 'iupac.sam'

    script:
    """
    sam-update-iupac.pl $lastal $primers >iupac.sam
    """
}

process PARSEPRIMERS {
    publishDir params.out, mode: 'copy', pattern: "result.tsv"

    input:
    path sam
    path yaml

    output:
    path 'result.tsv'

    script:
    """
    sam-primers-and-probes.pl $sam $yaml >result.tsv
    """
}


process EXTRACTAMPLICONS {
    publishDir params.out, mode: 'copy', pattern: 'amplicons.fas'
    
    input:
    path target
    path tsv

    output:
    path 'amplicons.fas'

    script:
    """
    cat $tsv | awk -F'\\t' '{print \$2 "\\t" \$1}' | tail -n +2 >regions
    fasta_get_regions $target -tab=regions > amplicons.fas
    """
}

workflow {
    last=MAPPRIMERS(Channel.fromPath(params.csv),Channel.fromPath(params.target))
    iupac=IUPACSAM(last.sam, last.fasta)
    results=PARSEPRIMERS(iupac, Channel.fromPath(params.yaml))
    EXTRACTAMPLICONS(Channel.fromPath(params.target), results)
}

workflow.onComplete {
    runLog << "=== Pipeline finished: ${new Date()} ===\n"
    // runLog << "Pipeline completed at: $workflow.complete\n"
    runLog << "Execution status: ${ workflow.success ? 'OK' : 'failed' }\n"
}
