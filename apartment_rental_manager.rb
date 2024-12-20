require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require_relative "database_persistence"

SECRET = "d79106c32dc3e0bf583d1fb5b7572c37477a6361c203efd9ba37ec2abf716040"


configure do
  enable :sessions
  set :session_secret, SECRET
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:error] = "You must be signed in to do that."
    session[:current_path] = request.fullpath
    redirect "/users/signin"
  end
end

def contains_alphabetic_chars?(input)
  input = input.delete(',').delete('$')
  input != input.to_i.to_s
end

def building_does_not_exist?(building_id)
  contains_alphabetic_chars?(building_id) ||
    @storage.building(building_id.to_i, params).nil?
end

def apartment_does_not_exist?(building_id, apartment_id)
  contains_alphabetic_chars?(apartment_id) ||
    @storage.apartment(building_id, apartment_id.to_i).nil?
end

def load_building(building_id)
  if building_does_not_exist?(building_id)
    session[:error] = "That building does not exist."
    redirect "/buildings"
  else
    @storage.building(building_id, params)
  end
end

def load_apartment(apartment_id)
  if apartment_does_not_exist?(@building_id, apartment_id)
    session[:error] = "That apartment does not exist."
    redirect "/buildings/#{@building_id}"
  else
    @storage.apartment(@building_id, @apartment_id)
  end
end

def next_building_id(buildings)
  max = buildings.map { |building| building[:id] }.max || 0
  max + 1
end

def next_apartment_id(building)
  max = building[:apartments].map { |apartment| apartment[:id] }.max || 0
  max + 1
end

def apartment_features
  [params[:name].strip,
   params[:bed].strip,
   params[:bath].strip,
   params[:sq_ft].strip,
   params[:price].strip]
end

# Return error msg if name is invalid, return nil if name is valid.
def error_for_building_name(new_name)
  if !(1..100).cover?(new_name.size)
    'ERROR: Building name must be between 1 and 100 characters.'
  elsif @storage.all_buildings(params).any? { |building| building[:name] == new_name }
    'ERROR: Duplicate building name.'
  end
end

# Return error msg if name is invalid, return nil if name is valid.
def error_for_new_apartment(features_array)
  error = error_for_apartment_features(features_array)
  return error if error
  
  features_array.each do |feature|
    if !(1..100).cover?(feature.size)
      return 'ERROR: Apartment name must be between 1 and 100 characters.'
    elsif @storage.apartments(@building_id, params).any? { |apartment| apartment[:name] == features_array[0] }
      return 'ERROR: Duplicate apartment name.'
    end
  end
  nil
end

# Returns an error message if apartment features are invalid
def error_for_apartment_features(features_array)
  features_array.each_with_index do |feature, index|
    if !(1..100).cover?(feature.size)
      return 'ERROR: Features must be valid characters between 1-100 in length.'
    elsif index > 0 && contains_alphabetic_chars?(feature)
      return 'ERROR: Feature must be a whole number.'
    end
  end
  nil
end

def load_page_number(params)
  page = params.fetch(:page, "0")

  if page.to_i < 0 || (page != page.to_i.to_s)
    session[:error] = "That page does not exist."
    redirect "/buildings/#{params[:id]}?page=0" unless params[:id].nil?
    redirect "/buildings?page=0"
  else
    page.to_i
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  redirect "/users/signin"
end

# View all buildings
get "/buildings" do
  require_signed_in_user
  @page = load_page_number(params)
  @buildings = @storage.all_buildings(params)

  erb :buildings, layout: :layout
end

# View add new building form
get "/buildings/new" do
  require_signed_in_user
  erb :new_building, layout: :layout
end

# Add a new building
post "/buildings" do
  require_signed_in_user

  new_building_name = params[:building_name].strip
  error = error_for_building_name(new_building_name)

  if error
    session[:error] = error
    erb :new_building, layout: :layout
  else
    @storage.add_new_building(new_building_name)
    session[:success] = "The new building was added."
    redirect "/buildings"
  end
end

# View a building
get "/buildings/:id" do
  require_signed_in_user

  @page = load_page_number(params)
  @building_id = params[:id].to_i
  @building = load_building(params[:id])
  @apartments = @storage.apartments(@building_id, params)
  erb :building, layout: :layout
end

# Edit an existing building
get "/buildings/:id/edit" do
  require_signed_in_user

  @building = load_building(params[:id])
  erb :edit_building, layout: :layout
end

# Rename an existing building
post "/buildings/:id" do
  require_signed_in_user

  id = params[:id].to_i
  @building = load_building(params[:id])
  new_building_name = params[:building_name].strip

  error = error_for_building_name(new_building_name)

  if error
    session[:error] = error
    erb :edit_building, layout: :layout
  else
    @storage.update_building_name(id, new_building_name)
    session[:success] = "The building name was updated."
    redirect "/buildings/#{id}"
  end
end

# Delete a building
post "/buildings/:id/destroy" do
  require_signed_in_user

  id = params[:id].to_i
  @storage.delete_building(id)

  session[:success] = "The building was deleted."
  redirect "/buildings"
end

# Add a new apartment to the building
post "/buildings/:building_id/apartments" do
  require_signed_in_user

  @page = load_page_number(params)
  @building_id = params[:building_id].to_i
  @building = load_building(params[:building_id])

  features = apartment_features
  error = error_for_new_apartment(features)
  if error
    session[:error] = error
    erb :building, layout: :layout
  else
    @storage.add_new_apartment(@building_id, features)
    session[:success] = "The apartment was added."
    redirect "/buildings/#{@building_id}"
  end
end

# View apartment details of a building
get "/buildings/:building_id/apartment/:apartment_id" do
  require_signed_in_user

  @apartment_id = params[:apartment_id].to_i
  @building_id = params[:building_id].to_i
  @apartment = load_apartment(params[:apartment_id])
  @building = load_building(params[:building_id])

  erb :apartment, layout: :layout
end

# Display edit apartment page
get "/buildings/:building_id/apartment/:apartment_id/edit" do
  require_signed_in_user

  @apartment_id = params[:apartment_id].to_i
  @building_id = params[:building_id].to_i
  @apartment = load_apartment(params[:apartment_id])
  @building = load_building(params[:building_id])

  erb :edit_apartment, layout: :layout
end

# Delete an existing apartment
post "/buildings/:building_id/apartment/:apartment_id/destroy" do
  require_signed_in_user

  @building_id = params[:building_id].to_i
  @building = load_building(params[:building_id])
  apartment_id = params[:apartment_id].to_i

  @storage.delete_apartment(@building_id, apartment_id)
  session[:success] = "The apartment has been deleted."
  redirect "/buildings/#{@building_id}"
end

# Edit an existing apartments features
post "/buildings/:building_id/apartment/:apartment_id" do
  require_signed_in_user

  @apartment_id = params[:apartment_id].to_i
  @building_id = params[:building_id].to_i
  @apartment = load_apartment(params[:apartment_id])
  @building = load_building(params[:building_id])

  features = apartment_features
  error = error_for_apartment_features(features)
  if error
    session[:error] = error
    erb :edit_apartment, layout: :layout
  else
    @storage.update_apartment_features(@building_id, @apartment_id, features)
    session[:success] = "The apartment was updated."
    redirect "/buildings/#{@building_id}/apartment/#{@apartment_id}"
  end
end

# Display sign in screen
get "/users/signin" do
  session[:success] = "Welcome to Apartment Rental Manager!"
  erb :signin, layout: :layout
end

# Sign in user
post "/users/signin" do
  if params[:username] == "username" && params[:password] == "password"
    session[:username] = params[:username]
    session[:success] = "Welcome!"
    redirect "#{session[:current_path]}" # redirect "/buildings" works
  else
    session[:error] = "Invalid credentials"
    status 422
    erb :signin, layout: :layout
  end
end

# Sign out user
post "/users/signout" do
  session.delete(:username)
  session.delete(:current_path)
  session[:success] = "You have been signed out."
  redirect "/"
end
