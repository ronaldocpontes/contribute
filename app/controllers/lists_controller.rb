class ListsController < InheritedResources::Base
	#load_and_authorize_resource
	#before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :destroy, :save]
	
	def sort
		@list = List.find_by_id(params[:id])
		@list.title = params[:title].to_s
		@list.save!
		
		@items = @list.items.order("position DESC")
		@items.each do |item|
			item.position = params['item'].index(item.id.to_s) + 1
			item.save
		end
		render :nothing => true
	end
	
	def update
		@list = List.find_by_id(params[:id])
		@list.kind = "#{params[:kind].gsub(/\W/, '-')}"
		@list.kind += "-#{params[:order]}" unless @list.kind == 'manual'
		@list.title = params[:title]
		@list.save!
		
		redirect_to @list.listable
	end
	
	def destroy
		@list = List.find(params[:id])
		unless @list.destroy
			flash[:error] = "Failed to delete list."
		end
		redirect_to @list.listable
	end
	
	def edit
		@list = List.find(params[:id])
		@source = []
		if !current_user.nil? and current_user.admin
			for project in Project.where("state = ? OR state = ? OR state = ?", 'active', 'funded', 'nonfunded')
				@source  << project.name
			end
		else
			for project in @list.listable.projects.where("state = ? OR state = ? OR state = ?", 'active', 'funded', 'nonfunded')
				@source  << project.name
			end
		end
	end
	
	def add_item
		@list = List.find(params[:id])
		@project = Project.find_by_name(params[:project])
		@list.items << Item.create(:itemable_id => @project.id, :itemable_type => @project.class.name)
		
		redirect_to :back
	end
	
	def show
		@list = List.find(params[:id])
		@projects = @list.get_projects_in_order #pass in the number of projects you want
		if @projects.class.name == 'Array'
			@projects = Kaminari.paginate_array(@projects).page(params[:page]).per(8)
		else
			@projects = @projects.page(params[:page]).per(8)
		end
		
	end
end