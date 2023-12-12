
include {AZIMUTH;REMAP_AZIMUTH} from "$projectDir/modules/nf-core/modules/azimuth/main"
include {CELLTYPIST} from "$projectDir/modules/nf-core/modules/celltypist/main"
include {SPLIT_BATCH_H5AD} from "$projectDir/modules/nf-core/modules/split_batch_h5ad/main"
include {KERAS_CELLTYPE} from "$projectDir/modules/nf-core/modules/keras_celltype/main"
include {CELLTYPE_FILE_MERGE} from "$projectDir/modules/nf-core/modules/cell_type_assignment/functions"
include {SCPRED} from "$projectDir/modules/nf-core/modules/scpred/main"

workflow celltype{
    
    take:
        file__anndata_merged
        
    main:

        log.info '---Splitting the assignment for each batch---'
        file__anndata_merged.map{val1 -> tuple('full_ct', val1)}.set{out1}
        SPLIT_BATCH_H5AD(file__anndata_merged,params.split_ad_per_bach)

        // Here we may want to not split it and just pass in an entire h5ad file for annotations.
        // We need a combined h5ad file with all donors to perform further data integrations

        SPLIT_BATCH_H5AD.out.sample_file
            .splitCsv(header: true, sep: "\t", by: 1)
            .map{row -> tuple(row.experiment_id, file(row.h5ad_filepath))}.set{ch_experiment_filth5}
        SPLIT_BATCH_H5AD.out.az_sample_file
            .splitCsv(header: true, sep: "\t", by: 1)
            .map{row -> tuple(row.experiment_id, file(row.h5ad_filepath))}.set{az_ch_experiment_filth5}

        SPLIT_BATCH_H5AD.out.files_anndata_batch.flatMap().set{ch_batch_files}


        // Keras celltype assignemt
        if (params.celltype_assignment.run_keras){
            KERAS_CELLTYPE(ch_experiment_filth5,params.celltype_prediction.keras.keras_model,params.celltype_prediction.keras.keras_weights_df) 
            all_extra_fields = KERAS_CELLTYPE.out.predicted_celltype_labels.collect()
        }else{
            all_extra_fields = Channel.from("$projectDir/assets/fake_file.fq")
        }
        
        // AZIMUTH
        if (params.celltype_assignment.run_azimuth){
            AZIMUTH(params.outdir,ch_batch_files)
            REMAP_AZIMUTH(AZIMUTH.out.predicted_celltype_labels,params.mapping_file)
            az_out = REMAP_AZIMUTH.out.predicted_celltype_labels.collect()
        }else{
            az_out = Channel.from("$projectDir/assets/fake_file.fq")
        }
        
        // CELLTYPIST
        if (params.celltype_assignment.run_celltypist){
            Channel.fromList(params.celltypist.models)
                .set{ch_celltypist_models}
            CELLTYPIST(az_ch_experiment_filth5.combine(ch_celltypist_models))
            ct_out = CELLTYPIST.out.predicted_labels.collect()
        }else{
            ct_out = Channel.from("$projectDir/assets/fake_file.fq")
        }

        // SCPRED
        // if (params.celltype_assignment.run_scpred){
        //     SCPRED(params.outdir,ch_batch_files)
        //     // sc_out = SCPRED.out.predicted_celltype_labels.collect()
        // }else{
        //     sc_out = Channel.from("$projectDir/assets/fake_file.fq")
        //     sc_out = 't'
        // }        
        
        
        CELLTYPE_FILE_MERGE(az_out,ct_out,all_extra_fields,SPLIT_BATCH_H5AD.out.keras_outfile)       
        file__anndata_merged2=CELLTYPE_FILE_MERGE.out.file__anndata_merged2
        file__anndata_merged2.view()

    emit:
        file__anndata_merged2
}