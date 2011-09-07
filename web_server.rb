require 'sinatra'

get '/' do
  
  erb :index
end

get '/touch' do
  erb :touch
end

get '/paint_screen' do
  erb  :paint_screen
end

get '/maps_screen' do
  erb :maps_screen
end