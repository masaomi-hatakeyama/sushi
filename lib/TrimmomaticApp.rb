#!/usr/bin/env ruby
# encoding: utf-8
Version = '20131010-114135'

require 'sushiApp'

class TrimmomaticApp < SushiApp
  def initialize
    super
    @name = 'Trimmomatic'
    @analysis_category = 'QC'
    @description =<<-EOS
Trimmomatic performs a variety of useful trimming tasks for illumina paired-end and single ended data.The selection of trimming steps and their associated parameters are supplied on the command line.
Refer to <a href='http://www.usadellab.org/cms/?page=trimmomatic'>http://www.usadellab.org/cms/?page=trimmomatic</a>
    EOS
    @required_columns = ['Name','Read1']
    @required_params = ['paired', 'quality_type', 'leading', 'trailing', 'slidingwindow', 'avgqual', 'minlen']
    # optional params
    @params['cores'] = '8'
    @params['ram'] = '16'
    @params['scratch'] = '100'
    @params['paired'] = false
    @params['paired', 'description'] = 'either the reads are paired-ends or single-end'
    @params['quality_type'] = ['phred33', 'phred64']
    @params['quality_type', 'description'] = 'Fastq quality score type, if you use Illumina HiSeq or MySeq, chose phred33'
    @params['illuminaclip'] = {
      'select' => '',
      'All Illumina Adapter' => '/srv/GT/reference/contaminants/illuminaContaminants.fa',
      #'Original Adapter' => 'under construction'
    }
    @params['seed_mismatchs'] = '1'
    @params['seed_mismatchs', 'description'] = 'Specifies the maximum mismatch count which will still allow a full match to be performed'
    @params['palindrome_clip_threshold'] = '30'
    @params['palindrome_clip_threshold', 'description'] = 'Specifies how accurate the match between the two _adapter ligated_ reads must be for PE palindrome read alignment'
    @params['simple_clip_threshold'] = '10'
    @params['simple_clip_threshold', 'description'] = 'Specifies how accurate the match between any adapter etc. sequence must be against a read'
    @params['leading'] = '5'
    @params['leading', 'description'] = 'Cut bases off the start of a read, if below a threshold quality'
    @params['trailing'] = '5'
    @params['trailing', 'description'] = 'Cut bases off the end of a read, if below a threshold quality'
    @params['slidingwindow'] = '5:15'
    @params['slidingwindow', 'description'] = 'Perform a sliding window trimming, cutting once the average quality within the window falls below a threshold'
    @params['avgqual'] = '20'
    @params['avgqual', 'description'] = 'Drop the read if the average quality is below the specified level'
    @params['minlen'] = '30'
    @params['minlen', 'description'] = 'Drop the read if it is below a specified length'

  end
  def preprocess
    if @params['paired']
      @required_columns << 'Read2'
    end
  end
  def next_dataset
    nds = {'Name'=>@dataset['Name'], 
     'Read1 [File]' => File.join(@result_dir, "#{File.basename(@dataset['Read1'].to_s).gsub('fastq.gz','trimmed.fastq.gz')}"),
    }
    if @params['paired'] 
      nds['Read2 [File]'] = File.join(@result_dir, "#{File.basename(@dataset['Read2'].to_s).gsub('fastq.gz','trimmed.fastq.gz')}")
    end
    nds
  end
  def se_pe
    @params['paired'] ? 'PE' : 'SE'
  end
  def commands
    command = "java -jar /usr/local/ngseq/src/Trimmomatic-0.30/trimmomatic-0.30.jar #{se_pe} -threads #{@params['cores']} -#{@params['quality_type']} #{File.join(GSTORE_DIR, @dataset['Read1'])}"
    if @params['paired']
      command << " #{File.join(GSTORE_DIR, @dataset['Read2'])}"
    end
    output_R1 = File.basename(@dataset['Read1']).gsub('fastq.gz', 'trimmed.fastq.gz')
    command << " #{output_R1}"
    if @params['paired']
      output_unpared_R1 = File.basename(@dataset['Read1']).gsub('fastq.gz', 'unpared.fastq.gz')
      command << " #{output_unpared_R1}"
    end
    if @params['paired']
      output_R2 = File.basename(@dataset['Read2']).gsub('fastq.gz', 'trimmed.fastq.gz')
      output_unpared_R2 = File.basename(@dataset['Read2']).gsub('fastq.gz', 'unpared.fastq.gz')
      command << " #{output_R2} #{output_unpared_R2}"
    end
    unless @params['illuminaclip'].to_s.empty?
      command << " ILLUMINACLIP:#{@params['illuminaclip']}:#{@params['seed_mismatchs']}:#{@params['palindrome_clip_threshold']}:#{@params['simple_clip_threshold']}"
    end
    command << " LEADING:#{@params['leading']} TRAILING:#{@params['trailing']} SLIDINGWINDOW:#{@params['slidingwindow']} AVGQUAL:#{@params['avgqual']} MINLEN:#{@params['minlen']}"
    command
  end
end

if __FILE__ == $0
  usecase = TrimmomaticApp.new

  usecase.project = "p1001"
  usecase.user = "masa"

  # set user parameter
  # for GUI sushi
  #usecase.params['process_mode'].value = 'SAMPLE'
  #usecase.params['build'] = 'TAIR10'
  usecase.params['paired'] = true
  usecase.params['cores'] = 2
  usecase.params['node'] = 'fgcz-c-048'

  # also possible to load a parameterset csv file
  # mainly for CUI sushi
  #usecase.parameterset_tsv_file = 'tophat_parameterset.tsv'
  #usecase.parameterset_tsv_file = 'test.tsv'

  # set input dataset
  # mainly for CUI sushi
  usecase.dataset_tsv_file = 'test_dataset.tsv'

  # also possible to load a input dataset from Sushi DB
  #usecase.dataset_sushi_id = 1

  # run (submit to workflow_manager)
  #usecase.run
  usecase.test_run

end
