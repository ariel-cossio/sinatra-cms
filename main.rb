require 'sinatra'
require 'mongoid'
require 'slim'
require 'sass'
require 'redcarpet'

configure do
  Mongoid.load!("./mongoid.yml")
  enable :sessions
  set :session_secret, '*&(^B234*&(^'
end

helpers do
	def admin?
    	session[:admin]
  	end

  	def protected!
  		halt 401,"You are not authorized to see this page!" unless admin?
  	end

  	def url_for page
  		if admin?
    		"/pages/" + page.id
  		else
    		"/" + page.permalink
  		end
	end
end


class Page
	include Mongoid::Document

	field :title,   type: String
	field :content, type: String
	field :permalink, type: String, default: -> { make_permalink }

  	def make_permalink
	  title.downcase.gsub(/\W/,'-').squeeze('-').chomp('-') if title
	end

end

get('/login'){session[:admin]=true; redirect back}
get('/logout'){session[:admin]=nil; redirect back}

get '/pages' do
  @pages = Page.all
  @title = "Simple CMS: Page List"
  slim :index
end

get '/pages/new' do
  protected!
  @page = Page.new
  slim :new
end


get '/pages/:id/edit' do
  protected!
  @page = Page.find(params[:id])
  slim :edit
end


get '/pages/:id' do
  @page = Page.find(params[:id])
  @title = @page.title
  slim :show
end

post '/pages' do
  protected!
  page = Page.create(params[:page])
  redirect to("/pages/#{page.id}")
end


put '/pages/:id' do
  protected!
  page = Page.find(params[:id])
  page.update_attributes(params[:page])
  redirect to("/pages/#{page.id}")
end


get '/pages/delete/:id' do
  protected!
  @page = Page.find(params[:id])
  slim :delete
end


delete '/pages/:id' do
  protected!
  Page.find(params[:id]).destroy
  redirect to('/pages')
end


get '/:permalink' do
  begin
    @page = Page.find_by(permalink: params[:permalink])
  rescue
    pass
  end
  slim :show
end

get('/styles/main.css'){ scss :styles }
