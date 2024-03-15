# frozen_string_literal: true

require 'sinatra'
require_relative '../lib/workflow'

driver = Driver.new

post '/' do
  content_type :json

  data = JSON.parse(request.body.read)

  wf = Workflow.new(driver)
  wf.add(data['actions'])
  wf.execute

  wf.state.to_json
end
