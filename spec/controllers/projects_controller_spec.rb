require 'spec_helper'
require 'controller_helper'

describe ProjectsController do
  include Devise::TestHelpers
  render_views

  # For stubbing abilities
  # See https://github.com/ryanb/cancan/wiki/Testing-Abilities
  before do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub!(:current_ability).and_return(@ability)
  end

  let(:user) { create :user }
  let!(:project) { create :project }

  context "GET index" do
    before { @ability.stub!(:can?).with(:index, Project).and_return(true) }
    before { get :index }

    it { should respond_with :success }
    it { should render_template :index }
    it { should assign_to :projects }
  end

  describe 'POST update' do
    context 'with permission' do
      let(:project) { create :project }
      before { sign_in user }
      before { @ability.stub!(:can?).with(:update, project).and_return(true) }
      before { post :update, id: project.name, project: attributes_for(:project) }

      it { should set_the_flash.to(/Successfully updated project/) }
    end
  end

  describe 'PUT activate' do
    context 'with permission' do
      let(:project) { create :project }
      before { @ability.stub!(:can?).with(:activate, project).and_return(true) }

      it 'sets project state to active if project has payment_account_id' do
        # TODO extract this into a fake Amazon API
        project.payment_account_id = 'ABCD'
        project.save
        put :activate, id: project.to_param
        expect(project.reload.state).to eq :active
      end

      it "doesn't activate project without a payment_account_id" do
        expect { put :activate, id: project.to_param }.to raise_error
        expect(project.reload.state).to_not eq :active
      end
    end

    context 'without permission' do
      let(:project) { create :project }
      before { @ability.stub!(:can?).with(:activate, project).and_return(false) }
      before { put :activate, id: project.to_param }

      it 'sets project state to active' do
        expect(project.reload.state).to_not eq :active
      end
    end
  end

  describe 'GET new' do
    context 'when not signed in' do
      it "can't create a project" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      context 'with permission' do
        before do
          @ability.should_receive(:can?) { |arg1, arg2|
            arg1.should eq :new
            arg2.should be_instance_of Project
            true
          }
        end

        it 'can create a project' do
          get :new
          expect(response).to be_success
        end
      end
    end
  end

  describe 'GET show' do
    context 'with permission' do
      before { @ability.stub!(:can?).and_return(true) }
      before { @ability.stub!(:can?).with(:show, project).and_return(true) }

      it 'CAN view project' do
        get :show, id: project.name
        expect(response).to be_success
      end
    end

    context 'without permission' do
      before { @ability.stub!(:can?).with(:show, project).and_return(false) }

      it 'can NOT view project' do
        get :show, id: project.name
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET edit' do
    context 'without permission' do
      before { @ability.stub!(:can?).with(:edit, project).and_return(false) }

      it "can't edit a project" do
        get :edit, id: project.name
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'with permission' do
      before { sign_in user }
      before { @ability.stub!(:can?).with(:edit, project).and_return(true) }

      it "CAN edit the project" do
        get :edit, id: project.name
        expect(response).to be_success
      end
    end
  end

  describe 'POST create' do
    render_views

    context 'user is signed in' do
      before { sign_in user }

      before { UUIDTools::UUID.stub(:random_create){} }
      before do
        @ability.stub!(:can?) { |arg1, arg2|
          arg1.should eq :create
          arg2.should be_instance_of Project
          true
        }
      end

      it "succeeds for valid attributes" do
        p = build(:project).attributes.symbolize_keys
        expect{ post :create, project: p }.to change{ Project.count }.by 1

        request = Amazon::FPS::RecipientRequest.new(save_project_url)
        expect(response).to redirect_to(request.url)
      end

      it "handles errors for invalid attributes" do
        invalid_attributes = attributes_for(:project, funding_goal: -5)
        expect{post :create, project: invalid_attributes}.to_not change{ Project.count }

        expect(response).to be_success
        expect(response.body.inspect).to include("error")
        expect(Project.find_by_name(invalid_attributes[:name])).to be_nil
      end
    end
  end

  describe 'DELETE destroy' do
    context 'with permission' do
      before { sign_in user }
      before { @ability.stub!(:can?).with(:destroy, project).and_return(true) }

      it "CAN destroy a project" do
        expect { get :destroy, id: project.name }.to change { Project.count }.by(-1)
        expect(flash[:notice]).to include "successfully deleted"
        expect(response).to redirect_to(root_path)
      end

      it "should succeed destroy" do
        expect{ delete :destroy, id: project.name }.to change{ Project.count }.by(-1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include "successfully deleted"
      end

      it "should handle failure" do
        Project.any_instance.stub(:destroy) {false}

        expect{ delete :destroy, id: project.name }.to_not change{ Project.count }

        expect(response).to redirect_to(project_path(project))
        expect(flash[:alert]).to include "could not be deleted"
      end
    end

    context 'without permission' do
      before { @ability.stub!(:can?).with(:destroy, project).and_return(false) }

      it "can't destroy a project" do
        expect {get :destroy, id: project.name}.to_not change{ Project.count }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PUT block' do
    context 'with permission' do
      let(:project) { create :project }
      before { @ability.stub!(:can?).with(:block, project).and_return(true) }
      before { put :block, id: project.to_param }

      it 'blocks project' do
        expect(project.reload.state).to eq :blocked
      end
    end

    context 'without permission' do
      let(:project) { create :project }
      before { @ability.stub!(:can?).with(:block, project).and_return(false) }
      before { put :block, id: project.to_param }

      it 'does not block project' do
        expect(project.reload.state).to_not eq :blocked
      end
    end
  end

  describe 'PUT unblock' do
    context 'with permission' do
      let(:project) { create :project, state: :blocked }
      before { @ability.stub!(:can?).with(:unblock, project).and_return(true) }
      before { put :unblock, id: project.to_param }

      it 'unblocks project' do
        expect(project.reload.state).to_not eq :blocked
      end
    end

    context 'without permission' do
      let(:project) { create :project, state: :blocked }
      before { @ability.stub!(:can?).with(:unblock, project).and_return(false) }
      before { put :unblock, id: project.to_param }

      it 'sets project state to active' do
        expect(project.reload.state).to eq :blocked
      end
    end
  end

  context "save action" do
    let(:project) { create(:project, state: 'unconfirmed') }
    let(:params) { {"tokenID"=>"C5Q3L4H4UL4U18BA1IE12MXSDDAGCEBV1A56A5T243XF8QTDJQZ1JD9RFQW5CCWG", "status"=>"SR"} }

    context "user is signed in" do
      before { sign_in user }

      before { @ability.stub!(:can?).with(:save, project).and_return(true) }

      before do
        Amazon::FPS::AmazonValidator.stub(:valid_cbui_response?){true}
      end

      it "should succeed with valid input" do
        session[:project_id] = project.id
        get :save, params
        expect(response).to redirect_to(project)
        expect(flash[:notice]).to include "saved successfully"
      end

      it "should handle unsuccessful input" do
        session[:project_id] = project.id
        params["status"] = "NP"

        get :save, params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include "error"
      end

      it "should handle unsuccessful input case: 2" do
        Project.any_instance.stub(:save){false}
        session[:project_id] = project.id

        get :save, params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include "error"
      end
    end
  end
end
