# frozen_string_literal: true

require 'selenium-webdriver'

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
    target = find(xpath)
    target&.send_keys(text)
  end

  def read(xpath, default = '')
    target = find(xpath)
    target&.text || default
  end

  def click(xpath)
    target = find(xpath)
    target&.click
  end

  def find(xpath)
    @wait.until do
      element = @driver.find_element(:xpath, xpath)
      return element if element.displayed?
    end
  rescue Selenium::WebDriver::Error::TimeoutError
    puts "element not found at xpath: #{xpath}"
    nil
  end
end

# custom web task
class Task
  def initialize(driver, actions)
    @driver = driver
    @actions = actions
  end

  def execute
    @actions.each do |type, method, *args|
      raise ArgumentError("unknown action type: #{type}") unless respond_to?(type)

      send(type, method, *args)
    end
  end

  def driver(method, *args)
    raise ArgumentError("unknown driver method: #{method}") unless @driver.respond_to?(method)

    @driver.send(method, *args)
  end
end

# web automation workflow
class Workflow
  def initialize
    @driver = Driver.new
    @tasks = []
  end

  def add(actions)
    @tasks << Task.new(@driver, actions)
  end

  def execute
    @tasks.each(&:execute)
  end
end

def gmail_login(user, pass)
  wf = Workflow.new
  wf.add([
           [:driver, :navigate, 'https://www.google.com/gmail/about/'],
           [:driver, :click, '/html/body/header/div/div/div/a[2]'],

           [:driver, :write, '//*[@id="identifierId"]', user],
           [:driver, :click, '//*[@id="identifierNext"]/div/button'],

           [:driver, :write, '//*[@id="password"]/div[1]/div/div[1]/input', pass],
           [:driver, :click, '//*[@id="passwordNext"]/div/button'],

           [:driver, :click, '//*[@id="yDmH0d"]/div[1]/div[1]/div[2]/div/div/div[3]/div/div[2]/div/div/button']
         ])
  wf.execute
end

