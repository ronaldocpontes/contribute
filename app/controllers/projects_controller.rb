require 'amazon/fps/recipient_request'

class ProjectsController < InheritedResources::Base
	actions :all, :except => [ :create, :destroy ]

	before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :save ]
	#This allows us to use project names instead of ids for the routes
	before_filter :set_current_project_by_name, :only => [ :show, :edit, :update ]
	#This is authorization through CanCan. The before_filter handles load_resource
	authorize_resource

	def index
		@projects = Project.limit(9).where("active = 1").order("end_date ASC")
		@projects1 = @projects.slice(0..2) || []
		@projects2 = @projects.slice(3..5) || []
		@projects3 = @projects.slice(6..8) || []
		index!
	end

	def create
		@project = Project.new(params[:project])
		@project.user_id = current_user.id
		@project.payment_account_id = 'temp'
	
		#We still want to validate payment_account_id, but not at create since it doesn't exist yet	
		if @project.valid? 
			session[:project] = @project
			request = Amazon::FPS::RecipientRequest.new(save_project_url)
			redirect_to request.url()
		else
			render :action => :new
		end
	end

	def save
		#puts 'project_save params', params
		#puts 'save_project_url', save_project_url
		#Amazon::FPS::AmazonHelper::valid_response(params, save_project_url)
			#flash[:alert] = "An error occured saving your project.  Please try again (Signature did not validate)"
			#redirect_to root_path
		#end

		if !session[:project].nil? and !params[:tokenID].nil?
			@project = session[:project]
			session[:project] = nil
			@project.payment_account_id = params[:tokenID]
			if @project.save and @project.payment_account_id != 'temp'
				flash[:alert] = "Project saved successfully. Here's to getting funded!"
				redirect_to root_path
			else
				flash[:alert] = "An error occurred saving your project. Please try again."
				redirect_to root_path
			end
		end
	end
end
