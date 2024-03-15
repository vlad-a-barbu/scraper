# frozen_string_literal: true

require 'sinatra'
require_relative '../lib/workflow'

post '/' do
  content_type :json

  data = JSON.parse(request.body.read)

  wf = Workflow.new
  wf.add(data['actions'])
  wf.execute

  wf.state.to_json
end


get '/example' do
  content_type :json

  wf = Workflow.new

  wf.add([
           [:driver, :navigate, 'https://api.ipify.org?format=json'],
           [:collect, :ip, :xpath, '/html/body/div/div/div/div[1]/div/div/div[2]/table/tbody/tr/td[2]'],
           [:fallback, :collect, :ip, '/html']
         ])

  wf.execute

  wf.state.to_json
end

