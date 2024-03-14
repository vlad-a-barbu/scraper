# frozen_string_literal: true

require_relative 'lib/workflow'

# system('pkill -f tor-browser')

wf = Workflow.new

wf.add([
         [:driver, :navigate, 'https://api.ipify.org?format=json'],
         [:collect, :ip, '/html/body/div/div/div/div[1]/div/div/div[2]/table/tbody/tr/td[2]'],
         [:fallback, :collect, :ip, '/html']
       ])

wf.execute

wf.save("#{__dir__}/ip.json")
