#!/usr/bin/env/cwl-runner

cwlVersion: v1.0

class: CommandLineTool

arguments:
- $(inputs.java_8)
- -server
- -Xms8g
- -Xmx8g
- -cp
# todo: which Marianas for this step?
- $(inputs.marianas_path)
- org.mskcc.marianas.umi.duplex.fastqprocessing.ProcessLoopUMIFastq

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.fastq1)
      - $(inputs.fastq2)
      - $(inputs.sample_sheet)
  - class: ResourceRequirement
    ramMin: 30000
    coresMin: 1

inputs:
  java_8: string
  marianas_path: string

  fastq1:
    type: File
    inputBinding:
      position: 1

  fastq2:
    type: File

  sample_sheet:
    type: File

  umi_length:
    type: int
    inputBinding:
      position: 2

  output_project_folder:
    type: string
    inputBinding:
      position: 3

outputs:

  # Todo - We rely on the **/ because Marianas outputs to a folder
  # which is named by the parent folder of the fastq,
  # which is randomly generated by Toil
  processed_fastq_1:
    type: File
    outputBinding:
      glob: ${ return "**/" + inputs.fastq1.basename.split('/').pop() }
      # Todo: might be cleaner:
#      glob: ${ return "**/" + inputs.fastq1.basename }

  processed_fastq_2:
    type: File
    outputBinding:
      glob: ${ return "**/" + inputs.fastq1.basename.split('/').pop().replace('_R1_', '_R2_') }
#      glob: ${ return "**/" + inputs.fastq1.basename.replace('_R1_', '_R2_') }

  composite_umi_frequencies:
    type: File
    outputBinding:
      glob: ${ return "**/composite-umi-frequencies.txt" }

  info:
    type: File
    outputBinding:
      glob: ${ return "**/info.txt" }

  output_sample_sheet:
    type: File
    outputBinding:
      glob: ${ return "**/SampleSheet.csv" }

  umi_frequencies:
    type: File
    outputBinding:
      glob: ${ return "**/umi-frequencies.txt" }
