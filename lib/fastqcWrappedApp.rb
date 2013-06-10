#!/usr/bin/env ruby
# encoding: utf-8

require 'sushiApp'

class FastqcWrappedApp<  SushiApp
  def initialize
    super
    @name = 'Fastqc Wrapped'
    @params['process_mode'] = 'DATASET'
    @analysis_category = 'QC'
    @required_columns = ['Sample','Read1','Species']
    @required_params = ['name', 'paired']
    @params['paired'] = false
    # optional params
    @output_files = ['Report']
  end
  def preprocess
    if @params['paired']
      @required_columns<<  'Read2'
    end
  end
  def next_dataset
    {'Sample'=>@params['name'],
     'Report'=>File.join(@result_dir, @params['name']),
    }
  end
  def commands
    command = "/usr/local/ngseq/bin/R --vanilla --slave<<  EOT\n"
    command<<  "source('/usr/local/ngseq/sushi_scripts/init.R')\n"
    command<<  "config = list()\n"
    config = @params
    config.each do |key, value|
      command<<  "config[['#{key}']] = '#{value}'\n"
    end
    command<<  "inputDatasetFile = '#{@input_dataset_tsv_path}'\n"
    command<<  "output = '#{File.basename(next_dataset['Report'])}'\n"
    command<<  "fastqcApp(input=inputDatasetFile, output=output, config=config)\n"
    command<<  "EOT\n"
    command
  end
end

if __FILE__ == $0
  usecase = FastqcWrappedApp.new

  usecase.project = "p1001"
  usecase.user = "masa"

  # set user parameter
  # for GUI sushi
  #usecase.params['process_mode'].value = 'SAMPLE'
  #usecase.params['build'] = 'TAIR10'
  #usecase.params['paired'] = true
  #usecase.params['cores'] = 2
  #usecase.params['node'] = 'fgcz-c-048'

  # also possible to load a parameterset csv file
  # mainly for CUI sushi
  usecase.parameterset_tsv_file = 'tophat_parameterset.tsv'
  usecase.params['name'] = 'name'

  # set input dataset
  # mainly for CUI sushi
  usecase.dataset_tsv_file = 'tophat_dataset.tsv'

  # also possible to load a input dataset from Sushi DB
  #usecase.dataset_sushi_id = 1

  # run (submit to workflow_manager)
  usecase.run
  #usecase.test_run

end

