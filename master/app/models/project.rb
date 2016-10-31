class Project < ActiveRecord::Base
#  attr_accessible :number
  has_many :data_sets
  serialize :data_set_tree, Hash

  def saved?
    flag = false
    self.data_sets.each do |data_set|
      if data_set.saved?
        flag = true
        break
      end
    end
    flag
  end
  def register_bfabric(op = 'new')
    base = "public/register_sushi_dataset_into_bfabric"
    check = "public/check_dataset_bfabric"
    if SushiFabric::Application.config.fgcz? and File.exist?(base) and File.exist?(check)
      self.data_sets.each do |data_set|
        unless data_set.data_set # if it is the top node dataset (== suppose raw dataset)
          data_set.register_bfabric(op)
        end
      end
    end
  end
  def make_tree_node(data_set)
      project_dataset_ids = Hash[*(self.data_sets.map{|data_set| [data_set.id, true]}.flatten)]
      data_set_name = if data_set.name.length > 20
                        data_set.name[0,20] + "..."
                      else
                        data_set.name
                      end
      #"text" => data_set.data_sets.length.to_s+" "+data_set_name+" <small><font color='gray'>"+data_set_comment.to_s+"</font></small>",
      full_text = data_set.name.to_s+" "+data_set.comment.to_s
      node = {"id" => data_set.id,
              "text" => data_set.data_sets.length.to_s+" "+data_set_name,
              "a_attr" => {"href"=>"/data_set/p#{self.number}/#{data_set.id}",
                           "onclick"=>"$('#container_main').load('/data_set/p#{self.number}/#{data_set.id}');",
                           "class"=>"show_tooltip", "title"=>full_text}
              }
      if parent = data_set.data_set and project_dataset_ids[parent.id]
        node["parent"] = parent.id
      else
        node["parent"] = "#"
      end
      node
  end
  def construct_data_set_tree
    tree = {}
    self.data_sets.each do |data_set|
      node = make_tree_node(data_set)
      tree[data_set.id] = node
    end
    self.data_set_tree = tree
    self.save
  end
  def add_tree_node(data_set)
    node = make_tree_node(data_set)
    self.data_set_tree[data_set.id] = node
    self.save
  end
end
