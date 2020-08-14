require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require 'yaml'


def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def valid_cost?(cost)
  r = /^\d+\.\d\d$/
  cost.match r
end


def sanitized_name(name)
  name.strip.capitalize
end


def add_item(name, cost, month)
  if session[:data].key?(month)
    session[:data][month][sanitized_name(name)] = cost.to_f
  else
    session[:data][month] = { sanitized_name(name) => cost.to_f }
  end
end

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:data] ||= {}
end

helpers do
  def yearly_total
    monthly_totals = session[:data].map do |month|
      month[1].values.inject{ |acc, elem| acc + elem}
    end
    '%.2f' % monthly_totals.sum
  end

  def category_total(category)
    sum = 0
    session[:data].each_value do |values|
      sum += values.fetch(category, 0)
    end
    '%.2f' % sum
  end
end

get "/" do

  erb :index
end

get "/new" do
  erb :new, layout: :layout
end



post "/new" do
  # If user tries to enter same name but different cost, could ask if they want to update
  # also maybe strip/sanitize the name input to prevent the SaME item!
  if params[:name].nil? || params[:cost].nil?
    session[:message] = 'You cannot leave a field empty!'
    erb :new
  elsif valid_cost?(params[:cost])
    add_item(params[:name], params[:cost], params[:month])
    session[:data].inspect
    redirect "/"
  else
    session[:message] = "Invalid format for cost!"
    erb :new
  end

  #params[:item]
end

get "/month/:month" do
  erb :month
end
