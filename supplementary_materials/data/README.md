# Supplementary Data

This directory contains all the data and results generated from comparing
COATi to other aligners.

## Description of Methods

Please see [https://www.github.com/jgarciamesa/coati-testing](https://www.github.com/jgarciamesa/coati-testing)
or Materials and Methods section.

## Description of Data

### `raw_data`

 - `gorilla_geneId.tsv`: list of human and gorilla homologous gene IDs.
 - 16800 gene pairs downloaded from ENSEMBL.

### `tri-mg`, `tri-ecm`, `mar-mg`, `mar-ecm`
  Each file contains the results for running the pipeline with the specified
  coati model:

#### `data`
 - `filtered.csv`: names of sequence pairs that passed filtering (combined length < 6000).
 - `gaps.csv`: initial alignments with gaps.
 - `nogaps.csv`: initial alignments without gaps.
 - `gaps_cigar.csv`: gap patterns encoded as CIGAR strings, where the gap was
    extracted from and the aligner.
 - `ref_alignments`: folder with generated data set of true alignments.
 - `ref_alignments.csv`: log with the gap pattern and its origin for each generated
    alignment.
 - `no_gaps_ref`: folder with true alignments without gaps, ready to be aligned.

#### `aln`
 - `tri-mg`, `prank`, `mafft`, `clustalo`, `macse`: initial alignments by each method.
 - `ref`: alignment of generated alignments by each method.

#### `results`
 - `results_summary.csv`: detailed summary of the results for each inferred alignment.
    Includes gap pattern for the reference alignment, distance, and coefficient
    of selection.

## Usage

To partially run the pipeline with any of this data, copy the files generated
up to that point then continue. Steps can be found in
[https://www.github.com/jgarciamesa/coati-testing/blob/main/pipeline.sh](https://www.github.com/jgarciamesa/coati-testing/blob/main/pipeline.sh).
The data is generated in the following order:

 - Download sequences from ENSEMBL in `raw_data`.
 - Filter sequences and write those that pass on `data/filtered`.
 - Initial alignment of sequences with all methods, output on `aln/{aligner-name}`.
 - Check what alignments have gaps and write names to `data/gaps.csv`.
 - Check what alignments do not habe gaps and write names to `data/nogaps.csv`.
 - Encode gap patterns as CIGAR strings and store in `data/gaps_cigar.csv`.
 - Generate data set of true alignments to `data/ref_alignments`.
 - Remove gaps of true alignments `data/no_gaps_ref`.
 - Align generated data set, output on `aln/ref/{aligner-name}`.
 - Calculate $d_{seq}$ `results/results_summary.csv`.
 - Knit Rmd to generate report with supplementary information.

