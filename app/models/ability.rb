# The Ability class defines what a user can or cannot do throughout the site.
#
# The class includes the CanCan::Ability module, defined in Ryan Bates' CanCan gem.
# The CanCan gem can be found at http://github.com/ryanb/cancan
class Ability
  include CanCan::Ability

  # Sets up user permissions (abilities)
  def initialize(user)
    user ||= User.new

    # Projects
    can [:create, :save, :upload], Project
    can [:activate, :destroy], Project, user: user
    can :read, Project do |p|
      p.public_can_view? or p.user == user or p.confirmation_approver?
    end
    # Note: this 'update' refers to the Update and Edit actions of ProjectsController,
    # not the ability to create Update objects associated with a project
    can :update, Project, user: user, can_edit?: true
    # This 'create_update_for' refers to the ability to create an Update associated
    # with a Project.
    can :create_update_for, Project, user: user

    can :destroy, Video do |v|
      v.project.user = user
    end

    # Comments
    can :comment_on, Project if user.id
    can :destroy, Comment, user: user

    # Contributions
    # Make sure the user isn't a project owner and doesn't have a contribution already
    can :contribute, Project do |project|
      !user.id.nil? and project.user != user and
      project.contributions.find_by_user_id(user.id).nil? and
      project.end_date >= Time.zone.today
    end
    # If the user is logged in, doesn't own the project,  and has a contribution on this project,
    # they can edit
    can :edit_contribution, Project do |project|
      !user.id.nil? and !project.contributions.find_by_user_id(user.id).nil?
    end

    # Groups
    can [:read, :create, :new_add, :submit_add], Group
    can :remove_project, Group # had to move check for admin or project owner to controller

    can [:edit, :update, :admin, :add_list, :destroy], Group, admin_user: user

    #Aprovals
    can [:approve, :reject], Approval do |a|
      a.group.admin_user == user
    end

    #Lists
    can :read, List
    can [:destroy, :edit, :update, :sort, :add_item], List do |l|
      if l.listable_type == "Group"
        l.listable.admin_user == user
      elsif l.listable_type == "User"
        l.listable.id == user.id
      else
        false
      end
    end

  end
end
