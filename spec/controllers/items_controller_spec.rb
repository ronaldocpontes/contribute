require 'spec_helper'
require 'controller_helper'

describe ListingsController do
  include Devise::TestHelpers

  # For stubbing abilities
  # See https://github.com/ryanb/cancan/wiki/Testing-Abilities
  before do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub!(:current_ability).and_return(@ability)
  end

  describe 'DELETE destroy' do
    # TODO make sure this calls CanCan::can?
    let(:listing) { Factory :project_listing }
    before { delete :destroy, id: listing.id }

    it { should redirect_to :root }
  end
end
