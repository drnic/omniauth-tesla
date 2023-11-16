# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "rails", "~> 7.1.0"
  gem "sqlite3"
  gem "omniauth-tesla", path: "../.."
end

require "rails/all"
# load omniauth-tesla from root of project
require_relative "../../lib/omniauth-tesla"
database = "development.sqlite3"

ENV["DATABASE_URL"] = "sqlite3:#{database}"
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: database)
ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :email
    t.string :full_name
    t.string :profile_image_url
    t.string :refresh_token
    t.string :access_token
  end
end

class App < Rails::Application
  config.root = __dir__
  config.consider_all_requests_local = true
  config.secret_key_base = "i_am_a_secret"
  config.active_storage.service_configurations = {"local" => {"service" => "Disk", "root" => "./storage"}}

  routes.append do
    root to: "welcome#index"
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :tesla, "API_KEY", "API_SECRET"
end

class User < ActiveRecord::Base
end

class WelcomeController < ActionController::Base
  def index
    @users_count = User.count
    render inline: "Hi! There are #{@users_count} users."
  end
end

App.initialize!

run App
