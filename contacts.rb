# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions

  set :erb, :escape_html => true
  set :session_secret, SecureRandom.hex(32)
end

configure(:development) do 
  require_relative "database_persistence"
  require_relative "session_persistence.rb" 
  also_reload "database_persistence.rb" 
  also_reload "session_persistence.rb" 
end

before do
  @storage = DatabasePersistence.new(logger) 
  @session = SessionPersistence.new(session)
end

not_found do
  redirect "/notfound"
end

helpers do
# checks which if any category is checked when editing a contact
  def checked_if_edit(value)
    category = params[:category] || @storage.single_contact(@id)[:category]
    value == category ? "checked" : ""
  end

# checks on the home page to see if a filter category is selected
  def checked_if_home(value)
    category = @session.checked_category
    if category == "clear"
      @session.remove_checked_category
    else
      category
    end
    value == category ? "checked" : ""
  end
end

#loads contact info
def load_contact(id)
  contact = @storage.single_contact(id) if id && @storage.single_contact(id)
  return contact if contact

  session[:error] = "The specified contact was not found."
  redirect "/contacts"
end

# retrieves info for a contact into an array
def gather_contact_info
  [first_name = params[:first_name].strip,
  last_name = params[:last_name].strip,
  email = params[:email],
  phone = params[:phone].gsub(/[ -]/, " "),
  category = params[:category]]
end

# Checks name is Alphabetic characters
def validate_name(name)
  name.strip!
 (1..50).cover?(name.size) && name.scan(/[a-z ]+/i) == [name]
end

# Checks if aplhanumeric characters, @, alpahetic, ., then alphabetic for 
def validate_email(email)
  (1..70).cover?(email.size)&& email.scan(/[a-z0-9]+[@][a-z]+[.][a-z]+/i) == [email]
end

# Validates Phone number structure
def validate_phone(phone)
  phone.gsub(/[ -]/, "").scan(/[0-9]{10,11}/i) == [phone.gsub(/[ -]/, "")]
end

# Sequentially checks if all inputs are valid
def valid?
  list = [
    validate_name(params[:first_name]),
    validate_name(params[:last_name]),
    validate_email(params[:email]),
    validate_phone(params[:phone])
  ]
  list.all? {|item| item == true }
end

# Adds appropriate error messages to an array for later use
def error_messages
  errors = []
  !validate_name(params[:first_name]) ? errors << "First Name Input Wrong, 1-50 Alphabetic Characters Please" : ""
  !validate_name(params[:last_name]) ? errors << "Last Name Input Wrong, 1-50 Alphabetic characters Please" : ""
  !validate_email(params[:email]) ? errors << "Email Input Wrong, example@info.com format" : ""
  !validate_phone(params[:phone]) ? errors << "Phone Input Wrong 10/11 digit phone number" : ""
  errors
end

#redirects to the home page
get "/" do
 redirect "/contacts"
end

# ah ah ah
get "/notfound" do

  erb :notfound, layout: :blank
end

# lists all the contacts on the home page, checks if filter is selected
get "/contacts" do
  # @id ||= 0
  if @session.checked_category && @session.checked_category != "clear"
    @contacts_list = @storage.all_contacts.select do |contact|
      contact[:category] == @session.checked_category
    end
  else
    @contacts_list = @storage.all_contacts
  end
  
  erb :home, layout: :layout
end

# Path for contact filters to be submitted to
post "/contacts" do
  @session.update_checked_category(params[:category])

  if @session.checked_category && @session.checked_category != "clear"
    @contacts_list = @storage.all_contacts.select do |contact|
      contact[:category] == @session.checked_category
    end
  else
    @contacts_list = @storage.all_contacts
  end

  erb :home, layout: :layout
end

# Displays page for making new contact
get "/contacts/new" do
  
  erb :new, layout: :layout
end

# Creates new contact
post "/contacts/new" do
  if valid?
    first_name, last_name, email, phone, category = gather_contact_info

    @storage.add_contact({first_name: first_name, last_name: last_name, email: email, phone: phone, category: category})
    redirect "/contacts"
  else
    session[:error] = error_messages()
    erb :new, layout: :layout
  end
end

# displays page for one contact
get "/contacts/:id" do
  @id = params[:id].to_i
  contact_hash = load_contact(@id)
  name = "#{contact_hash[:first_name]} #{contact_hash[:last_name]}"
  email = contact_hash[:email]
  phone = contact_hash[:phone].gsub(/[ -]/, " ")
  category = contact_hash[:category]

  @contact = {"Name" => name, "Email" => email, "Phone" => phone, "Category" => category.capitalize }
  erb :contact, layout: :layout
end

# displays page to edit one contacts
get "/contacts/:id/edit" do
  @id = params[:id].to_i
  @contact = @storage.single_contact(@id)

  erb :edit, layout: :layout
end

# edits the single contact
post "/contacts/:id/edit" do
  @id = params[:id].to_i
  @contact = @storage.single_contact(@id)
  if valid?
    first_name, last_name, email, phone, category = gather_contact_info
    temp_hash_contact = {first_name: first_name, last_name:  last_name, email: email, phone: phone, category: category }
    @storage.update_single_contact(@id, temp_hash_contact)

    redirect "/contacts/#{@id}"
  else
    session[:error] = error_messages()

    erb :edit, layout: :layout
  end

end

# Deletes a contact
post "/contacts/:id/delete" do
  @storage.delete_contact(params[:id].to_i)
  redirect "/contacts"
end