# frozen_string_literal: true

require 'selenium-webdriver'

# web driver error
class DriverError < StandardError
  attr_reader :xpath

  def initialize(msg, xpath = nil)
    @xpath = xpath
    super(msg)
  end
end

# simple web driver wrapper
class Driver
  def initialize(opts = {})
    @driver = Selenium::WebDriver.for(opts.fetch(:type, :chrome))
    @wait = Selenium::WebDriver::Wait.new(timeout: opts.fetch(:timeout, 3))
  end

  def navigate(url)
    @driver.navigate.to(url)
  end

  def write(xpath, text)
    find(xpath)&.send_keys(text)
  end

  def read(xpath)
    find(xpath, silent: true)&.text
  end

  def click(xpath)
    find(xpath)&.click
  end

  def find(xpath, silent: false)
    @wait.until do
      element = @driver.find_element(:xpath, xpath)
      return element if element.displayed?
    end
  rescue Selenium::WebDriver::Error::TimeoutError
    raise DriverError.new("element not found at xpath: #{xpath}", xpath) unless silent

    nil
  end
end

# task is a container responsible with "understanding" how to execute custom web driver actions
# !!! actions API is still a WIP
class Task
  def initialize(driver, state, actions)
    @driver = driver
    @state = state
    @actions = actions
  end

  def execute
    @execution = {}
    @actions.each_with_index { |action, index| execute_action(action, index) }
  end

  def execute_action(action, index)
    type, *args = action
    raise ArgumentError("unknown action type: #{type}") unless respond_to?(type)

    send(type, *args) if send?(type, index)
    @execution[index] = true
  rescue DriverError => e
    puts "action #{index} failed: #{e.message}"
    @execution[index] = false
  end

  def send?(type, index)
    type != :fallback || @execution[index - 1] == false
  end

  def driver(*args)
    method, *driver_args = args
    raise ArgumentError("unknown driver method: #{method}") unless @driver.respond_to?(method)

    @driver.send(method, *driver_args)
  end

  def fallback(*args)
    type, *fallback_args = args
    send(type, *fallback_args)
  end

  def collect(*args)
    key, *read_args = args
    @state[key] = @driver.read(*read_args)
  end
end

# web automation workflow
class Workflow
  attr_reader :state

  def initialize(driver = nil)
    @driver = driver || Driver.new
    @state = {}
    @tasks = []
  end

  def add(actions)
    @tasks << Task.new(@driver, @state, actions)
  end

  def execute
    @tasks.each(&:execute)
  end

  def fork
    new(@driver)
  end
end

def demo_actions
  [
    [:driver, :navigate, 'https://www.biziday.ro/'],

    [:driver, :click, '//*[@id="main"]/ul/li[1]/aaa'],
    [:fallback, :driver, :click, '//*[@id="main"]/ul/li[1]/aa'],
    [:fallback, :driver, :click, '//*[@id="main"]/ul/li[1]/a'],

    [:collect, :html, '/html']
  ]
end

wf = Workflow.new
wf.add(demo_actions)
wf.execute
puts wf.state

sleep
