# frozen_string_literal: true

require_relative 'driver'
require_relative 'task'

# web automation workflow
class Workflow
  attr_reader :state

  def initialize
    @driver = Driver.new
    @state = {}
    @tasks = []
  end

  def add(actions)
    @tasks << Task.new(@tasks.length + 1, @driver, @state, actions)
  end

  def execute
    @tasks.each(&:execute)
    @driver.quit
  rescue StandardError => e
    puts "workflow execution failed: #{e.message}"
    @driver.quit
  end

  def save(path)
    IO.write(path, @state.to_json)
  end
end
