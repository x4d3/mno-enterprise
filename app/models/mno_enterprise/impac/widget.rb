module MnoEnterprise
  class Impac::Widget < BaseResource

  	attributes :name, :width, :widget_category, :settings

    belongs_to :impac_dashboard, class_name: 'MnoEnterprise::Impac::Dashboard'
  
  end
end