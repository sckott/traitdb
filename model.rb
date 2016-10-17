class TDBDatasets < ActiveRecord::Base
  self.table_name = 'metadata'
  def self.endpoint(params)
    select('id,doi,ref_title,dim_rows,dim_cols,no_spp')
  end
end

class TDBDataset < ActiveRecord::Base
  self.table_name = 'metadata'
  def self.endpoint(params)
  	where(id: params[:id])
    	.select('id,doi,ref_title,dim_rows,dim_cols,no_spp')
  end
end

class TDBFields < ActiveRecord::Base
  self.table_name = 'fields'
  def self.endpoint(params)
    where(id: params[:id])
      .select('field,description')
  end
end
