# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'
require_relative 'session_persistence'

configure do
  enable :sessions

  set :erb, :escape_html => true
  set :session_secret, SecureRandom.hex(32)
end

before do
  @storage = SessionPersistence.new(session)
end

not_found do
  redirect "/notfound"
end

helpers do
  def checked_if_edit(value)
    category = params[:category] || session[:contacts][@id][:category]

    value == category ? "checked" : ""
  end

  def checked_if_home(value)
    category = @storage.checked_category

    if category == "clear"
      @storage.remove_checked_category
    else
      category
    end

    value == category ? "checked" : ""
  end
end

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

def validate_phone(phone)
  phone.gsub(/[ -]/, "").scan(/[0-9]{10,11}/i) == [phone.gsub(/[ -]/, "")]
end

def valid?
  list = [
    validate_name(params[:first_name]),
    validate_name(params[:last_name]),
    validate_email(params[:email]),
    validate_phone(params[:phone])
  ]
  list.all? {|item| item == true }
end

def error_messages
  errors = []
  !validate_name(params[:first_name]) ? errors << "First Name Input Wrong, 1-50 Alphabetic Characters Please" : ""
  !validate_name(params[:last_name]) ? errors << "Last Name Input Wrong, 1-50 Alphabetic characters Please" : ""
  !validate_email(params[:email]) ? errors << "Email Input Wrong, example@info.com format" : ""
  !validate_phone(params[:phone]) ? errors << "Phone Input Wrong 10/11 digit phone number" : ""
  errors
end



get "/" do
 redirect "/contacts"
end

get "/notfound" do

  erb :notfound, layout: :blank
end

get "/contacts" do
  # @id ||= 0
  if @storage.checked_category && @storage.checked_category != "clear"
    @contacts_list = @storage.all_contacts.select do |contact|
      contact[:category] == @storage.checked_category
    end
  else
    @contacts_list = @storage.all_contacts
  end
  
  erb :home, layout: :layout
end


post "/contacts" do
  @storage.update_checked_category(params[:category])

  if @storage.checked_category && @storage.checked_category != "clear"
    @contacts_list = @storage.all_contacts.select do |contact|
      contact[:category] == @storage.checked_category
    end
  else
    @contacts_list = @storage.all_contacts
  end

  erb :home, layout: :layout
end

get "/contacts/new" do
  
  erb :new, layout: :layout
 end

post "/contacts/new" do

  if valid?
    first_name, last_name, email, phone, category = gather_contact_info

    @storage.add_contact({first_name: first_name, last_name:  last_name, email: email, phone: phone, category: category })
    redirect "/contacts"
  else
    session[:error] = error_messages()
    erb :new, layout: :layout
  end
end

def load_contact(id)
  contact = @storage.single_contact(id) if id && @storage.single_contact(id)
  return contact if contact

  session[:error] = "The specified contact was not found."
  redirect "/contacts"
end

get "/contacts/:id" do
  @id = params[:id].to_i
  contact_hash = load_contact(@id)
  name = contact_hash[:first_name] + " " + contact_hash[:last_name]
  email = contact_hash[:email]
  phone = contact_hash[:phone].gsub(/[ -]/, " ")

  @contact = {"Name" => name, "Email" => email, "Phone" => phone }
  erb :contact, layout: :layout
end

get "/contacts/:id/edit" do
  @id = params[:id].to_i
  @contact = @storage.single_contact(@id)

  erb :edit, layout: :layout
end

post "/contacts/:id/edit" do
  @id = params[:id].to_i
  @contact = @storage.single_contact(@id)
  if valid?
    first_name, last_name, email, phone, category = gather_contact_info

    @storage.update_single_contact(@id, {first_name: first_name, last_name:  last_name, email: email, phone: phone, category: category })

    redirect "/contacts/#{@id}"
  else
    session[:error] = error_messages()

    erb :edit, layout: :layout
  end

end

post "/contacts/:id/delete" do
  @storage.delete_contact(params[:id].to_i)
  redirect "/contacts"
end