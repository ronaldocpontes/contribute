require 'spec_helper'

describe ProjectList do
  # Validations
  it { should validate_presence_of :listable_id }
  it { should validate_presence_of :listable_type }
end