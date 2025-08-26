#!/usr/bin/env nextflow

/*
 * pipeline input parameters
 */
params.csv = "example_data/primers.tsv"
params.yaml = "example_data/fus.yaml"
params.target = "example_data/Fo_F11_regions.fas"
params.outdir = "nf-results"

process MAPPRIMERS {    
    publishDir params.outdir, mode: 'copy', pattern: "primers.fas"
    
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
    publishDir params.outdir, mode: 'copy', pattern: "iupac.sam"

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
    publishDir params.outdir, mode: 'copy', pattern: "result.tsv"

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
    publishDir params.outdir, mode: 'copy', pattern: 'amplicons.fas'
    
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
