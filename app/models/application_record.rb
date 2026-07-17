# Base record model from which all other database models inherit.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
