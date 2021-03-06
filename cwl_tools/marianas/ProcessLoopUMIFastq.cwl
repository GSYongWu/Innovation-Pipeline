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
  InlineJavascriptRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: ../../resources/schema_defs/Sample.cwl
  InitialWorkDirRequirement:
    listing:
      - $(inputs.fastq1)
      - $(inputs.fastq2)
      - $(inputs.sample_sheet)
  ResourceRequirement:
    ramMin: 30000
    coresMin: 1

inputs:
  java_8: string
  marianas_path: string
  sample: ../../resources/schema_defs/Sample.cwl#Sample

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

  output_sample:
    name: output_sample
    type: ../../resources/schema_defs/Sample.cwl#Sample
    outputBinding:
      # Todo - We rely on the **/ because Marianas outputs to a folder
      # which is named by the parent folder of the fastq,
      # which is randomly generated by Toil
      glob: '**/*'
      outputEval: |
        ${
          var output_sample = inputs.sample;

          output_sample.clipped_fastq_1 = self.filter(function(x) {
            return x.basename === inputs.fastq1.basename.split('/').pop()
          })[0];

          output_sample.clipped_fastq_2 = self.filter(function(x){
            return x.basename === inputs.fastq1.basename.split('/').pop().replace('_R1_', '_R2_')
          })[0];

          output_sample.composite_umi_frequencies = self.filter(function(x) {
            return x.basename === 'composite-umi-frequencies.txt'
          })[0];

          output_sample.info = self.filter(function(x){
            return x.basename === 'info.txt'
          })[0];

          output_sample.output_sample_sheet = self.filter(function(x){
            return x.basename === 'SampleSheet.csv'
          })[0];

          output_sample.umi_frequencies = self.filter(function(x){
            return x.basename === 'umi-frequencies.txt'
          })[0];

          return output_sample
        }
