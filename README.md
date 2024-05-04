# build_hmms

This workflow lets you build a profile HMM database from a multifasta file of sequences. 

The sequences will first be clustered using mmseqs, then an HMM for each cluster will be built. 

## Usage

```
build_hmms.sh -f file.fasta -n db_name
```

## Dependencies
- mmseqs
- hmmer
