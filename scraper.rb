# frozen_string_literal: true

require 'selenium-webdriver'
require 'selenium_tor'

# web driver error
class DriverError < StandardError; end

# simple web driver wrapper
class Driver
  def initialize
    @wait = Selenium::WebDriver::Wait.new
    @driver = init_driver
  end

  def navigate(url)
    @driver.navigate.to(url)
  end

  def write(xpath, text)
    find(xpath).send_keys(text)
  end

  def read(xpath)
    find(xpath).text
  end

  def click(xpath)
    find(xpath).click
  end

  def find(xpath)
    @wait.until { @driver.find_element(:xpath, xpath) }
  rescue Selenium::WebDriver::Error::TimeoutError
    raise DriverError, "element not found at xpath: #{xpath}"
  end

  def quit
    @driver.quit
  end

  private

  def init_driver
    options = Selenium::WebDriver::Tor::Options.new
    options.add_argument('--headless')
    Selenium::WebDriver.for :tor, options:
  rescue StandardError => e
    raise DriverError, "driver initialization failed: #{e.message}"
  end
end

# task is a container responsible with "understanding" how to execute custom web driver actions
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

  private

  def execute_action(action, index)
    type, *args = action
    raise ArgumentError("unknown action type: #{type}") unless respond_to?(type, true)

    return if type == :fallback && @execution[index - 1] == true

    puts "executing task #{@id} action #{index + 1}"
    send(type, *args)
    @execution[index] = true
  rescue DriverError => e
    puts "task #{@id} action #{index + 1} failed: #{e.message}"
    @execution[index] = false
  end

  def driver(*args)
    method, *driver_args = args
    raise ArgumentError("unknown driver method: #{method}") unless @driver.respond_to?(method)

    @driver.send(method, *driver_args)
  end

  def collect(*args)
    store_path, *read_args = args
    value = @driver.read(*read_args)
    store(store_path, value)
  end

  def fallback(*args)
    type, *fallback_args = args
    send(type, *fallback_args)
  end

  def store(path, value)
    keys = path.to_s.split('/')
    ptr = @state

    keys.each_with_index do |key, index|
      ptr[key] ||= {}
      if index == keys.length - 1
        ptr[key] = value
      else
        ptr = ptr[key]
      end
    end
  end
end

# web automation workflow
class Workflow
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

wf = Workflow.new

wf.add([
         [:driver, :navigate, 'https://api.ipify.org?format=json'],
         [:collect, :ip, '/html/body/div/div/div/div[1]/div/div/div[2]/table/tbody/tr/td[2]'],
         [:fallback, :collect, :ip, '/html']
       ])

wf.execute

wf.save('ip.json')
