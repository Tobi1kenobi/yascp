#!/usr/bin/env python


__date__ = '2022-10-20'
__author__ = 'M.Ozols'
__version__ = '0.0.1'

import argparse
import pandas as pd
def main():
    """Run CLI."""
    parser = argparse.ArgumentParser(
        description="""
            Joins all the outputs from the GT match in an expected input format for subsequent relatedness estimation.
            """
    )

    parser.add_argument(
        '-v', '--version',
        action='version',
        version='%(prog)s {version}'.format(version=__version__)
    )

    parser.add_argument(
        '-f', '--files',
        action='store',
        dest='stats_files',
        required=True,
        help='All_stats_files'
    )
    
    parser.add_argument(
        '-dr', '--drop',
        action='store',
        dest='drop',
        required=False,
        default=None,
        help='Sometimes we may want to drop the cohort.'
    )
        
    options = parser.parse_args()
    stats_files = options.stats_files.split(' ')
    Dataset=[]
    dr1 = options.drop
    
    for s1 in stats_files:
        # print(s1)
        # break
        experiment_id=s1.replace('stats_','').replace('_gt_donor_assignments.csv','')
        Data= pd.read_csv(s1)
        if dr1:
           Data= Data[Data.final_panel!=dr1]
        d1 = list(filter(lambda val: val !=  'NONE', list(Data['donor_gt'].astype(str))) )
        
        donor_vcf_ids = ','.join(d1)
        Dataset.append({'experiment_id':experiment_id,'donor_vcf_ids':donor_vcf_ids})
    All_Infered_Expected = pd.DataFrame(Dataset)
    All_Infered_Expected.to_csv('All_Infered_Expected.csv',index=False,sep='\t')


if __name__ == '__main__':
    main()

