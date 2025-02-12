# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "rails", "~> 7.2.0"
  gem "puma"
  gem "sqlite3"
  gem "omniauth"
  gem "omniauth-rails_csrf_protection", "~> 1.0"
  gem "omniauth-tesla", path: "../.."
end

require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

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
  config.load_defaults 7.1
  config.eager_load = true
  config.hosts << ENV["PUBLIC_TUNNEL_HOST"] if ENV["PUBLIC_TUNNEL_HOST"].present?

  routes.append do
    root to: "welcome#index"

    get "/auth/:provider/callback" => "sessions#create"
    post "/signout" => "sessions#destroy", :as => :signout
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # Scopes https://developer.tesla.com/docs/fleet-api#authorization-scopes
  provider :tesla, ENV.fetch("TESLA_CLIENT_ID"), ENV.fetch("TESLA_CLIENT_SECRET"),
    scope: "openid user_data vehicle_device_data vehicle_cmds vehicle_charging_cmds",
    full_host: ENV["PUBLIC_TUNNEL_HOST"] || "http://localhost:9292"
end

class User < ActiveRecord::Base
end

class WelcomeController < ActionController::Base
  def index
    @users_count = User.count
    render inline: <<-HTML
      <p>Hi! There are #{@users_count} users.</p>
      <% if session[:user_id] %>
        <p>Signed in as <%= User.find(session[:user_id]).email %></p>
        <%= button_to "Logout", "/signout" %>
      <% else %>
        <%= button_to "Login with Tesla", "/auth/tesla" %>
      <% end %>
    HTML
  end
end

class SessionsController < ActionController::Base
  def create
    auth = request.env["omniauth.auth"]
    pp auth
    user = User.find_or_create_by(email: auth["uid"]) do |user|
      user.email = auth["uid"]
      user.full_name = auth["info"]["full_name"]
    end
    user.refresh_token = auth["credentials"]["token"]
    user.save!
    session[:user_id] = user.id
    redirect_to "/", notice: "Signed in!"
  end

  def destroy
    session[:user_id] = nil
    redirect_to "/", notice: "Signed out!"
  end
end

App.initialize!

Rails.application.routes.routes.map do |route|
  {verb: route.verb, path: route.path.spec.to_s, controller: route.defaults[:controller], action: route.defaults[:action]}
end.each { |route| p route }
puts
pp OmniAuth.strategies

run App
