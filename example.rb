# frozen_string_literal: true

require_relative 'lib/workflow'

# system('pkill -f tor-browser')

wf = Workflow.new

wf.add([
         [:driver, :navigate, 'https://www.biziday.ro/'],
         [:collect, :news, :all, [:css, '.news-content :nth-child(1)']],
         [:fallback, :collect, :html, [:xpath, '/html']]
       ])

wf.execute

wf.save("#{__dir__}/output.json")
