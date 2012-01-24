# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120124220754) do

  create_table "categories", :force => true do |t|
    t.string   "shortDescription"
    t.text     "longDescription"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "shortDescription"
    t.text     "longDescription"
    t.decimal  "fundingGoal",      :precision => 10, :scale => 0
    t.date     "startDate"
    t.date     "endDate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "categoryId"
  end

end
