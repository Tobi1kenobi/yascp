process PSEUDOBULK_AGREGATION {
  publishDir  path: "${outdir}/aggregated_counts",mode: "${params.copy_mode}",
              overwrite: "true"
    label 'process_low'
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "${params.eQTL.eqtl_container}"
        
    } else {
        container "quay.io/biocontainers/multiqc:1.10.1--py_0"
    }

  input:
    path(adata) // lists input files per donor
    val(agg_column)
    val(n_cells_min)
    val(n_donors_min)

  output:
    path("*phenotype_file.tsv", emit:phenotype_file)
    path("*genotype_phenotype_mapping.tsv", emit:genotype_phenotype_mapping)
    path('*.tsv')

  script:
  outdir = params.outdir
  """
    echo 'Lets aggregate the cells in the andata: ${adata} object is pseudobulk'
    aggregate_sc_data.py --agg_column '${agg_column}' --n_cells ${n_cells_min} -n_individ ${n_donors_min} -h5ad ${adata} --method ${params.eQTL.aggregation_method}
  """
}