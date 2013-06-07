class ProjectConfirmation < ActiveRecord::Base
  belongs_to :project
  attr_accessible :payment_account_id
end
