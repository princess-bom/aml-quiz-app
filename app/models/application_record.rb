class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  include FirebaseAuth
end
