#!/usr/bin/env cwl-runner

cwlVersion: v1.0

class: CommandLineTool

arguments:
- $(inputs.java)
- -Xmx4g
- -Djava.io.tmpdir=$(inputs.tmp_dir)
- -jar
# Todo: consolidate?
- $(inputs.gatk)
- -T
- PrintReads

requirements:
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../resources/schema_defs/Sample.cwl
  ResourceRequirement:
    ramMin: 10000
    coresMin: 8

doc: |
  None

inputs:
  tmp_dir: string
  java: string
  gatk: string

  out:
    type:
    - 'null'
    - string
    doc: Write output to this BAM filename instead of STDOUT
    inputBinding:
      prefix: --out

  input_file:
    type: File
    doc: Input file containing sequence data (SAM or BAM)
    inputBinding:
      prefix: --input_file

  reference_sequence:
    type: string
    inputBinding:
      prefix: --reference_sequence

  baq:
    type:
    - 'null'
    - string
    - type: array
      items: string
    doc: Type of BAQ calculation to apply in the engine (OFF| CALCULATE_AS_NECESSARY|
      RECALCULATE)
    inputBinding:
      prefix: --baq

  BQSR:
    type:
    - 'null'
    - string
    - File
    doc: Input covariates table file for on-the-fly base quality score recalibration
    inputBinding:
      prefix: --BQSR

  nct:
    type: int
    inputBinding:
      prefix: -nct

  EOQ:
    type: boolean
    inputBinding:
      prefix: -EOQ

outputs:

  output_sample:
    name: output_samples
    type: ../../resources/schema_defs/Sample.cwl#Sample
    outputBinding:
      glob: '*_BR.bam'
      # Todo: confirm that IR bams are matched correctly
      outputEval: |
        ${
          var output_sample = inputs.sample;

          for (var i = 0; i < output_samples.length; i++) {
            output_samples.bams[i].br_bam = self[i];
          }

          return output_samples
        }
