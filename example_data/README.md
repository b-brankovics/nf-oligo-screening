# Example data

## Target sequence for testing

As an example sequence rDNA locus and 3 protein coding gene regions of _Fusarium oxysporum_ strain F11 were included.

## Commonly used primer sets

[Primers for Aspergillus](asp.csv) were collected from https://doi.org/10.1016/j.simyco.2014.07.004 plus the commonly used LSU primer set.

Primers for Fusarium were collected from the [Fusarium.org](https://www.fusarium.org/page/Protocols) (Molecular studies tab contains primer information)

### rDNA operon amlification for fungi

The commonly used primers for fungal samples are NS1-NS4 for SSU, ITS1-ITS4 for ITS locus and LR0R-LR5 for LSU.
A combination of NS1 and LR5 could be used to span the regions that are commonly used for identification in a single reaction.

## Notes

Here is one way to generate a YAML file for the PCR reactions based on a TSV table.

```bash
cat fusarium.csv | cut -f1,3,5 | perl -MYAML -ne 'next if /^Locus/ || /^\s*$/; s/\R//g; ($l, $p, $o) = split/\t/; $h{$l}->{$o} = $p; END {print Dump(\%h)}' > fus.yaml
```
