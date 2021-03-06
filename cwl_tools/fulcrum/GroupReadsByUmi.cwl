#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

arguments:
- $(inputs.java)
- -jar
- $(inputs.fulcrum)
- --tmp-dir=/scratch
- GroupReadsByUmi

requirements:
  InlineJavascriptRequirement: {}
  ResourceRequirement:
    ramMin: 30000
    coresMin: 1

doc: |
  None

inputs:
  java: string
  fulcrum: string

  input_bam:
    type: File
    inputBinding:
      prefix: -i

  strategy:
    type: string
    inputBinding:
      prefix: -s

  min_mapping_quality:
    type: int
    inputBinding:
      prefix: -m

  tag_family_size_counts_output:
    type: string
    inputBinding:
      prefix: -f

  output_bam_filename:
    type: ['null', string]
    default: $( inputs.input_bam.basename.replace(".bam", "_fulcGRBU.bam") )
    inputBinding:
      prefix: -o
      valueFrom: $( inputs.input_bam.basename.replace(".bam", "_fulcGRBU.bam") )

outputs:
  output_bam:
    type: File
    outputBinding:
      glob: $( inputs.input_bam.basename.replace(".bam", "_fulcGRBU.bam") )
