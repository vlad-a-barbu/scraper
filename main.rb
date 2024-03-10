# frozen_string_literal: true

require 'selenium-webdriver'

# driver failed to find element
class ElementNotFoundError < StandardError
  attr_reader :xpath

  def initialize(msg = 'element not found', xpath = nil)
    @xpath = xpath
    super(msg)
  end
end

# simple web driver wrapper
class Driver
  def initialize(opts = {})
    @driver = Selenium::WebDriver.for(opts.fetch(:type, :chrome))
    @wait = Selenium::WebDriver::Wait.new(timeout: opts.fetch(:timeout, 10))
  end

  def navigate(url)
    @driver.navigate.to(url)
  end

  def write(xpath, text)
    find(xpath)&.send_keys(text)
  end

  def read(xpath)
    find(xpath, silent: true)&.attribute('innerHTML')
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
    puts "element not found at xpath: #{xpath}"
    raise ElementNotFoundError(xpath:) unless silent

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
    @actions.each do |type, *args|
      raise ArgumentError("unknown action type: #{type}") unless respond_to?(type)

      send(type, *args)
    end
  end

  def driver(*args)
    method, *driver_args = args
    raise ArgumentError("unknown driver method: #{method}") unless @driver.respond_to?(method)

    @driver.send(method, *driver_args)
  end

  # todo
  def fallback(*args); end

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

def gmail_login_actions(user, pass)
  [
    [:driver, :navigate, 'https://www.google.com/gmail/about/'],
    [:driver, :click, '/html/body/header/div/div/div/a[2]'],

    [:driver, :write, '//*[@id="identifierId"]', user],
    [:driver, :click, '//*[@id="identifierNext"]/div/button'],

    [:driver, :write, '//*[@id="password"]/div[1]/div/div[1]/input', pass],
    [:driver, :click, '//*[@id="passwordNext"]/div/button'],

    [:driver, :click, '//*[@id="yDmH0d"]/div[1]/div[1]/div[2]/div/div/div[3]/div/div[2]/div/div/button'],

    [:collect, :html, '/html']
  ]
end

def demo_actions
  [
    [:driver, :navigate, 'https://www.biziday.ro/'],
    [:collect, :html, '/html']
  ]
end

wf = Workflow.new
wf.add(demo_actions)
wf.execute
puts wf.state

sleep
