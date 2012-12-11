class ProjectDecorator < Draper::Base
  decorates :project

  @@color_classes = {'unconfirmed' => 'warning', 'inactive' => 'warning',
    'active' => 'success', 'funded' => 'success',
    'nonfunded' => 'inverse', 'canceled' => 'inverse'}

  # Accessing Helpers
  #   You can access any helper via a proxy
  #
  #   Normal Usage: helpers.number_to_currency(2)
  #   Abbreviated : h.number_to_currency(2)
  #
  #   Or, optionally enable "lazy helpers" by including this module:
  include Draper::LazyHelpers
  #   Then use the helpers with no proxy:
  #     number_to_currency(2)

  def colored_state_description
    content_tag :span, state_description, class: "label label-#{color_class}"
  end

  def edit_button
    button_to "Edit Project", edit_project_path(@project), :method => 'get', :class => 'btn btn-info btn-large'
  end

  def delete_button
    button_to "Delete Project", @project, :method => :delete, :confirm => "Are you sure you want to delete this project?", :class => 'btn btn-danger btn-large'
  end

  def activate_button
    button_to "Activate Project", activate_project_path(@project), :method => :put, :confirm => "Are you sure you want to activate this project? You will not be able to edit the project once it is active.", :class => 'btn btn-success btn-large'
  end

  def cancel_button
    button_to "Cancel Project", @project, :method => :delete, :confirm => "Are you sure you want to cancel this project? All contributions to it will also be canceled.", :class => 'btn-danger btn-large'
  end

private

  def state_name
    result = model.state.titlecase
    if model.state == 'funded'
      result = 'Funded!'
    elsif model.state == 'nonfunded'
      result = 'Non-funded'
    end
    result
  end

  def state_description
    "Project State: #{state_name}"
  end

  def color_class
    @@color_classes[model.state] || 'important'
  end


  # Defining an Interface
  #   Control access to the wrapped subject's methods using one of the following:
  #
  #   To allow only the listed methods (whitelist):
  #     allows :method1, :method2
  #
  #   To allow everything except the listed methods (blacklist):
  #     denies :method1, :method2

  # Presentation Methods
  #   Define your own instance methods, even overriding accessors
  #   generated by ActiveRecord:
  #
  #   def created_at
  #     h.content_tag :span, time.strftime("%a %m/%d/%y"),
  #                   :class => 'timestamp'
  #   end
end
