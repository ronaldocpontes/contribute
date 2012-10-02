class Project < ActiveRecord::Base
	MAX_NAME_LENGTH = 75
	MAX_SHORT_DESC_LENGTH = 200
	MAX_LONG_DESC_LENGTH = 20000
	MIN_FUNDING_GOAL = 5
	UNDEFINED_PAYMENT_ACCOUNT_ID = 'TEMP'

	include Rails.application.routes.url_helpers
	
	belongs_to :user
  has_many :contributions, :conditions => ["status not in (:retry_cancel, :fail, :cancelled)", {:retry_cancel => ContributionStatus::RETRY_CANCEL, :fail => ContributionStatus::FAILURE, :cancelled => ContributionStatus::CANCELLED}]
  acts_as_commentable
  has_and_belongs_to_many :groups
	has_many :comments
	has_many :updates
	has_one :category
	has_one :video
	mount_uploader :picture, PictureUploader, :mount_on => :picture_file_name
	has_many :approvals
	
	validate :validate_end_date
	validate :valid_state
	
	before_destroy :destroy_prep
	before_destroy :destroy_video

	validates :name, :presence => true, :uniqueness => { :case_sensitive => false }, :length => {:maximum => MAX_NAME_LENGTH}, :format => { :with => /\A[a-zA-Z0-9\s]+\z/, :message => "can contatin only letters, numbers, and spaces." }
	validates :short_description, :presence => true, :length => {:maximum => MAX_SHORT_DESC_LENGTH}
	validates :long_description, :presence => true, :length => {:maximum => MAX_LONG_DESC_LENGTH}
	validates_numericality_of :funding_goal, :greater_than_or_equal_to => MIN_FUNDING_GOAL, :message => "must be at least $5"
	validates_numericality_of :funding_goal, :only_integer => true, :message => "must be a whole dollar amount (no cents please)"
	validates :end_date, :presence => { :message => "must be of form 'MM/DD/YYYY'" }
	validates :payment_account_id, :presence => true
	validates :category_id, :presence => true
	validates :user_id, :presence => true
	validates :state, :presence => true

	attr_accessible :name, :short_description, :long_description, :funding_goal, :end_date, :category_id, :picture, :picture_cache
	
	def nothing
		self.name = "testing nothing"
		self.save!
	end
	
	def initialize(attributes = nil, options = {})
		super
		# self.active = true # We dont want to use this anymore.
		# self.confirmed = false # We dont want to use this anymore.
	end

	def end_date=(val)
		write_attribute(:end_date, Timeliness.parse(val, :format => "mm/dd/yyyy"))
	end
	
	def funding_goal=(val)  
		write_attribute(:funding_goal, val.to_s.gsub(/,/, ''))
	end

	def validate_end_date
		if !end_date
			return
		elsif end_date < Date.today + 1
			errors.add(:end_date, "has to be in the future")
		end
	end

	def contributions_total
		Rails.cache.fetch("#{self.id}_contributions_total") do 
			contributions.sum(:amount)
		end
	end

	def contributions_percentage
		Rails.cache.fetch("#{self.id}_contributions_percentage") do 
			((contributions_total.to_f / funding_goal.to_f) * 100).to_i
		end
	end
	
	def left_to_goal
		self.funding_goal - self.contributions_total
	end
	
	def valid_state
		errors.add(:state, "Invalid value for state var. State must be unconfirmed, inactive, active, funded, nonfunded, or canceled. Check config/enviroment.rb") unless PROJ_STATES.include?(self.state)
	end

	#Overriding to_param makes it so that whenever a url is built for a project, it substitues
	#the name of the project instead of the id of the project. This way, we can still refer
	#to params[:id] but it's actually the name. We didn't change the param to :name because
	#it was much more code that would be more error prone
	def to_param
		self.name.gsub(/\W/, '-')
	end

	def destroy_prep
		EmailManager.project_deleted_to_owner(self).deliver	

    self.contributions.each do |contribution|
			EmailManager.project_deleted_to_contributor(contribution).deliver
      contribution.destroy
    end

    self.save
	end
	
	def destroy_video
		unless self.video_id.nil?
			@video = Video.find(self.video_id)
			Video.delete_video(@video)
			self.video_id = nil
			self.save
		end
	end
	
	def update_project_video
		default_url_options[:host] = "orithena.cas.msu.edu"
		@video = Video.find(self.video_id)
		@tags = YT_TAGS
		@description = "Contribute to this project: #{project_url(self)}\n\n#{@video.description}\n\nFind more projects from MSU:\n#{root_url}\n"
		
		self.groups.each do |g|
		@tags << g.name
		@description += "\nFind more projects from #{g.name}:\n #{group_url(g)}"
		end
		
		Video.yt_session.video_update(@video.yt_video_id, :title => @video.title, :description => @description, :category => 'Tech', :keywords => @tags, :list => "allowed")
	end
	
  def public_can_view? #active, funded, or non-funded
  	self.state == 'active' or self.state == 'nonfunded' or self.state == 'funded'
  end
  
  def can_edit? #unconfirmed or inactive
  	self.state == PROJ_STATES[0] || self.state == PROJ_STATES[1]
  end
  
  def can_update? #active, funded or non-funded AND current user is project owner
  	self.state == PROJ_STATES[2] || self.state == PROJ_STATES[3] || self.state == PROJ_STATES[4]
  end
  
  def can_comment? #active, funded, or non-funded
  	self.state == PROJ_STATES[2] || self.state == PROJ_STATES[3] || self.state == PROJ_STATES[4]
  end
  
  def unconfirmed?
  	self.state == PROJ_STATES[0]
  end
  
  def inactive?
    self.state == PROJ_STATES[1]
  end
  
  def active?
		self.state == PROJ_STATES[2]
	end
  
  def funded?
    self.state == PROJ_STATES[3]
  end
  
  def nonfunded?
    self.state == PROJ_STATES[4]
  end
  
  def cancelled?
    self.state == PROJ_STATES[5]
  end
end
