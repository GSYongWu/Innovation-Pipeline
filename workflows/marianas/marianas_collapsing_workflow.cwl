#!/usr/bin/env cwl-runner

cwlVersion: v1.0

# Todo: consider making Duplex and Simplex a single workflow
class: Workflow

requirements:
  SubworkflowFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../resources/schema_defs/Sample.cwl

inputs:

  run_tools:
    type:
      type: record
      fields:
        perl_5: string
        java_7: string
        java_8: string
        marianas_path: string
        trimgalore_path: string
        bwa_path: string
        arrg_path: string
        picard_path: string
        gatk_path: string
        abra_path: string
        fx_path: string
        fastqc_path: string?
        cutadapt_path: string?

  sample: ../../resources/schema_defs/Sample.cwl#Sample

  reference_fasta: string
  reference_fasta_fai: string

  mismatches: int
  wobble: int
  min_mapping_quality: int
  min_base_quality: int
  min_consensus_percent: int

  tmp_dir: string
  reference_fasta: string
  reference_fasta_fai: string
  fci__minbq: int
  fci__minmq: int
  fci__cov: int
  fci__rf: string[]
  fci__intervals: string[]
  abra__kmers: string
  abra__scratch: string
  abra__mad: int
  fix_mate_information__sort_order: string
  fix_mate_information__create_index: boolean
  fix_mate_information__compression_level: int
  fix_mate_information__validation_stringency: string

outputs:

  output_samples:
    type: ../../resources/schema_defs/Sample.cwl#Sample
    outputSource: post_collapsing_realignment/output_sample

steps:

  first_pass:
    run: ../../cwl_tools/marianas/UMIBamToCollapsedFastqFirstPass.cwl
    in:
      run_tools: run_tools
      java_8:
        valueFrom: ${ return inputs.run_tools.java_8 }
      marianas_path:
        valueFrom: ${ return inputs.run_tools.marianas_path }

      sample: sample
      input_bam:
        valueFrom: $(inputs.sample.standard_bam)
      pileup:
        valueFrom: $(inputs.sample.normal_pileup)

      wobble: wobble
      mismatches: mismatches
      min_mapping_quality: min_mapping_quality
      min_base_quality: min_base_quality
      min_consensus_percent: min_consensus_percent
      # todo: why doesn't secondaryFiles work?
      reference_fasta: reference_fasta
      reference_fasta_fai: reference_fasta_fai
    out:
      [first_pass_output_file, alt_allele_file, first_pass_output_dir]

  sort_by_mate_position:
    # todo - can use an existing sort cwl?
    run: ../../cwl_tools/marianas-sort/marianas-sort.cwl
    in:
      first_pass_file: first_pass/first_pass_output_file
    out:
      [output_file]

  second_pass:
    run: ../../cwl_tools/marianas/UMIBamToCollapsedFastqSecondPass.cwl
    in:
      run_tools: run_tools
      java_8:
        valueFrom: ${return inputs.run_tools.java_8}
      marianas_path:
        valueFrom: ${return inputs.run_tools.marianas_path}

      sample: sample
      input_bam:
        valueFrom: $(inputs.sample.standard_bam)
      pileup:
        valueFrom: $(inputs.sample.normal_pileup)

      first_pass_file: sort_by_mate_position/output_file

      reference_fasta: reference_fasta
      reference_fasta_fai: reference_fasta_fai
      wobble: wobble
      mismatches: mismatches
      min_mapping_quality: min_mapping_quality
      min_base_quality: min_base_quality
      min_consensus_percent: min_consensus_percent
    out:
      [collapsed_fastq_1, collapsed_fastq_2]

  gzip_fastq_2:
    run: ../../cwl_tools/innovation-gzip-fastq/innovation-gzip-fastq.cwl
    in:
      input_fastq: second_pass/collapsed_fastq_2
    out:
      [output]

  gzip_fastq_1:
    run: ../../cwl_tools/innovation-gzip-fastq/innovation-gzip-fastq.cwl
    in:
      input_fastq: second_pass/collapsed_fastq_1
    out:
      [output]

  rename_fastq_1:
    run: ../../cwl_tools/innovation-rename-file/innovation-rename-file.cwl
    in:
      input_file: gzip_fastq_1/output
      new_name:
        valueFrom: $(inputs.sample.standard_bam.basename.replace('.bam', '_R1_.fastq.gz'))
    out:
      [renamed_file]

  rename_fastq_2:
    run: ../../cwl_tools/innovation-rename-file/innovation-rename-file.cwl
    in:
      input_file: gzip_fastq_2/output
      new_name:
        valueFrom: $(inputs.sample.standard_bam.basename.replace('.bam', '_R2_.fastq.gz'))
    out:
      [renamed_file]

  post_collapsing_realignment:
    run: ./collapsed_fastq_to_bam.cwl
    in:
      run_tools: run_tools
      tmp_dir: tmp_dir

      sample: sample
      fastq1: rename_fastq_1/renamed_file
      fastq2: rename_fastq_2/renamed_file

      reference_fasta: reference_fasta
      reference_fasta_fai: reference_fasta_fai
      output_suffix:
        valueFrom: ${return '_MC_'}
    out: [output_sample]
