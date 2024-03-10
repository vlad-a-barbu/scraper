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
  DEFAULT_BROWSER = :chrome
  DEFAULT_TIMEOUT_SECONDS = 10

  def initialize(opts = {})
    browser = opts.fetch(:type, DEFAULT_BROWSER)
    timeout = opts.fetch(:timeout, DEFAULT_TIMEOUT_SECONDS)
    @driver = Selenium::WebDriver.for(browser)
    @wait = Selenium::WebDriver::Wait.new(timeout:)
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
  def initialize(id, driver, state, actions)
    @id = id
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

    return unless send?(type, index)

    puts "executing task #{@id} action #{index + 1}"
    send(type, *args)
    @execution[index] = true
  rescue DriverError => e
    puts "task #{@id} action #{index + 1} failed: #{e.message}"
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

  def collect(*args)
    key, *read_args = args
    @state[key] = @driver.read(*read_args)
  end

  def fallback(*args)
    type, *fallback_args = args
    send(type, *fallback_args)
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
    @tasks << Task.new(@tasks.length + 1, @driver, @state, actions)
  end

  def execute
    @tasks.each(&:execute)
  end
end

# example workflow config
def collect_actions(page)
  (1..50).map do |id|
    [
      :collect,
      "movie#{(page - 1) * 50 + id}",
      "//*[@id=\"pmc-gallery-vertical\"]/div[#{page < 2 ? 1 : 2}]/div/div[#{id}]/article/div[1]/div/h2"
    ]
  end
end

wf = Workflow.new
wf.add([
         [:driver, :navigate, 'https://www.rollingstone.com/tv-movies/tv-movie-lists/best-sci-fi-movies-1234893930/tank-girl-1995-2-1234928496/'],
         [:driver, :click, '//*[@id="onetrust-accept-btn-handler"]']
       ])
wf.add(collect_actions(1))
wf.add([[:driver, :click, '//*[@id="pmc-gallery-vertical"]/div[2]/a']])
wf.add(collect_actions(2))
wf.add([[:driver, :click, '//*[@id="pmc-gallery-vertical"]/div[3]/a']])
wf.add(collect_actions(3))
wf.execute
puts wf.state

sleep
