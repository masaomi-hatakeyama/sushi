#!/usr/bin/env ruby
# encoding: utf-8
Version = '20160901-112246'

require 'sushi_fabric'
require_relative 'global_variables'
include GlobalVariables

class EdgeRApp < SushiFabric::SushiApp
  def initialize
    super
    @name = 'EdgeR'
    @params['process_mode'] = 'DATASET'
    @analysis_category = 'Differential_Expression'
    @description =<<-EOS
    Empirical analysis of digital gene expression data in R<br/>
<a href='https://bioconductor.org/packages/release/bioc/html/edgeR.html'>edgeR</a><br/>
    EOS
    @required_columns = ['Name','Count', 'Species', 'refBuild', 'featureLevel', 'refFeatureFile']
    @required_params = ['grouping', 'sampleGroup', 'refGroup']
    # optional params
    @params['cores'] = '1'
    @params['ram'] = '2'
    @params['scratch'] = '10'
    @params['refBuild'] = ref_selector
    @params['refFeatureFile'] = 'genes.gtf'
    @params['featureLevel'] = ['gene', 'isoform']
    @params['testMethod'] = ['glm', 'exactTest']
    @params['grouping'] = '' ### TODO: this should be filled by a column selector that allows to select a column with the tag 'Factor'
    @params['sampleGroup'] = '' ## TODO: this should be a value from the selected column
    @params['sampleGroup', 'description'] = 'sampleGroup should be different from refGroup' 
    @params['refGroup'] = '' ## TODO: this should be a value from the selected column
    @params['refGroup', 'description'] = 'refGroup should be different from sampleGroup'
    @params['normMethod'] = ['TMM', 'RLE', 'upperquartile', 'none']
    @params['normMethod', 'description'] = "see http://www.bioconductor.org/packages/2.13/bioc/html/edgeR.html"
    @params['runGO'] = ['false', 'true']
    @params['grouping2'] = ''
    @params['grouping2', 'description'] = 'specify the column name of your secondary factor --only in case your experiment has a second factor, that should enter the linear model for differential expression!'
    @params['backgroundExpression'] = 10
    @params['backgroundExpression', "description"] = "counts to be added to shrink estimated log2 ratios"
    @params['specialOptions'] = ''
    @params['expressionName'] = ''
    @params['mail'] = ""
  end
   def preprocess
    @random_string = (1..12).map{[*('a'..'z')].sample}.join
  end
  def next_dataset
    @comparison = "#{@params['sampleGroup']}--over--#{@params['refGroup']}"
    @params['comparison'] = @comparison
    @params['name'] = @comparison
    report_file = File.join(@result_dir, "#{@name}--#{@params['name']}")
    report_link = File.join(report_file, '00index.html')
    {'Name'=>@comparison,
     'Species'=>@dataset['Species'],
     'refBuild'=>@params['refBuild'],
     'Static Report [Link]'=>report_link,
     'Live Report [Link]'=>"#{SHINY_EXPLORE_DE}?data=#{report_file}/result-#{@comparison}-#{@random_string}-EzResult.RData",
     'Report [File]'=>report_file,
    }
  end
  def set_default_parameters
    @params['refBuild'] = @dataset[0]['refBuild']
    if dataset_has_column?('refFeatureFile')
      @params['refFeatureFile'] = @dataset[0]['refFeatureFile']
    end
  end
  def commands
    run_RApp("EzAppEdger")
  end
end

if __FILE__ == $0

end

