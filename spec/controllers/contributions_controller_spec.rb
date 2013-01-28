require 'spec_helper'
require 'controller_helper'

describe ContributionsController do
  include Devise::TestHelpers

  let(:user) { Factory :user }
  let!(:project) { Factory :project, state: :active }

  describe 'GET new' do
    context 'when user is not signed in' do
      before { get :new, project: project.id }

      it { should redirect_to(new_user_session_path) }
      it { should set_the_flash.to(/sign in/) }
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'after project end date' do
        before do
          Timecop.freeze(project.end_date + 2)
          get :new, project: project.name
        end

        it { should redirect_to project_path(project) }
        it { should set_the_flash.to(/may not contribute/) }
      end

      context 'one day after project end date' do
        before do
          Timecop.freeze(project.end_date + 1)
          get :new, project: project.name
        end

        it { should redirect_to project_path(project) }
        it { should set_the_flash.to(/may not contribute/) }
      end

      context 'on project end date' do
        before do
          Timecop.freeze(project.end_date)
          get :new, project: project.name
        end

        it { should respond_with :success }
        it { should_not set_the_flash }
      end

      context 'before project end date' do
        before do
          Timecop.freeze(project.end_date - 1)
          get :new, project: project.name
        end

        it { should respond_with :success }
        it { should_not set_the_flash }
      end
    end

    context 'when project owner is signed in' do
      before { sign_in project.user }
      before { get :new, project: project.name }

      it { should redirect_to project_path(project) }
      it { should set_the_flash.to(/may not contribute/) }
    end
  end

  describe 'GET edit' do
    context 'when contribution owner is signed in' do
      let(:contribution) { Factory :contribution, project: project, user: user }

      before { sign_in user }
      before { get :edit, id: contribution.id }

      it { should respond_with :success }
    end

    context "when user doesn't own contribution" do
      let(:contribution) { Factory :contribution, project: project }

      before { sign_in user }
      before { get :edit, id: contribution.id }

      it { should redirect_to project_path(project) }
      it { should set_the_flash.to(/may not edit this contribution/) }
    end

    it "handles invalid contribution" do
      sign_in user
      get :edit, {id: 1 }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include "error"
    end
  end

  describe 'POST save' do
    let(:contribution) { Factory :contribution, user: user }
    let(:params) { {"tokenID"=>"I6TRJVI1ARAHBNCZFJII35UPJXJCXMD5ID9RHMMIUJ6DAJAZDSDEKDAEVBDPQBB3",
                    "status"=>"SC" } }

    before(:each) do
      sign_in user
      Amazon::FPS::AmazonValidator.stub(:valid_cbui_response?){true}
    end

    it "succeeds for valid input" do
      session[:contribution_id] = contribution.id

      get :save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "submitted"
    end

    it "displays an error for a nil contribution" do
      session[:contribution_id] = nil

      get :save, params
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include "error"
    end

    it "handles invalid parameters" do
      session[:contribution_id] = contribution.id
      params["tokenID"] = nil

      get :save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "error"
    end

    it "shows an error if contribution doesn't save" do
      Contribution.any_instance.stub(:save){false}

      session[:contribution_id] = contribution.id

      get :save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "error"
    end
  end

  describe 'POST update_save' do
    let(:contribution) { Factory :contribution, user: user }
    let(:editing_contribution) { Factory :contribution, user: user, project: contribution.project }
    let(:params) { {"tokenID"=>"I4TRCVA1ATAFBN1ZJJI634UP4XQCX9DDIDNR1MM7UF6DDJ6ZDDD7KD9E4BDVQIBF",
                    "status"=>"SC"} }

    before(:each) do
      sign_in user
      Amazon::FPS::AmazonValidator.stub(:valid_cbui_response?){true}
      Amazon::FPS::CancelTokenRequest.stub(:send)
    end

    it "succeeds with valid input" do
      session[:contribution] = contribution #new contribution
      session[:editing_contribution_id] = editing_contribution.id #old contribution
      get :update_save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "successfully updated"
    end

    it "fails if there is no contribution in session" do
      session[:contribution] = nil
      session[:editing_contribution_id] = editing_contribution.id

      get :update_save, params
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include "error"
    end

    it "fails when given invalid params" do
      session[:contribution] = contribution
      session[:editing_contribution_id] = editing_contribution.id
      params["tokenID"] = nil

      get :update_save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "error"
    end

    it "displays error message if the contribution can't save" do
      Contribution.any_instance.stub(:save){false}

      session[:contribution] = contribution
      session[:editing_contribution_id] = editing_contribution.id

      get :update_save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "error"
    end

    it "displays error message if editing contribution can't cancel" do
      Contribution.any_instance.stub(:cancel){false}
      Contribution.any_instance.stub(:save){true} #if you remove this, you will get a stack overflow error at contribution.save.  The previous test and this one will run in isolation, but not one after another *shrugs*

      session[:contribution] = contribution
      session[:editing_contribution_id] = editing_contribution.id

      get :update_save, params
      expect(response).to redirect_to(contribution.project)
      expect(flash[:alert]).to include "error"
    end
  end

  describe "method validate_project" do
    let(:project_1) { Factory :project, active: 0 }
    let(:project_2) { Factory :project, confirmed: 0 }

    before(:each) { sign_in user }

    it "handles invalid project" do
      get :new, project: project_1.name
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include "error"
    end

    it "handles invalid project case: 2" do
      get :new, project: project_2.name
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include "error"
    end
  end
end
