class ApplicationRecord < ActiveRecord::Base
  include MintsUuidV7
  include PrefixedId

  primary_abstract_class
end
