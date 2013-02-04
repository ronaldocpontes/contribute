# === Attributes
#
# * *project_id* (+integer+)
# * *list_id* (+integer+)
# * *position* (+integer+)
# * *created_at* (+datetime+)
# * *updated_at* (+datetime+)
class Listing < ActiveRecord::Base
  acts_as_list scope: :list

  paginates_per 8
end
