# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "log/cron_log.log"

every 1.day, :at => '12 am' do
  rake "contribution:completed_projects"
end

every :hour do
  rake "contribution:update_contributors"
end

every :reboot do
  rake "all_contribution:completed_projects"
end

=begin
every 1.hour do
  rake "contribute:cleanup_unconfirmed"
end
=end

# How often should we check to see if things are still pending or failing?
every 3.hours do
  rake "contribution:retry_contributions"
end
