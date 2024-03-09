# frozen_string_literal: true

require 'selenium-webdriver'

# simple web driver wrapper
class Driver
  def initialize
    @driver = Selenium::WebDriver.for :chrome
  end

  def navigate(url)
    @driver.navigate.to url
  end

  def write_to(xpath, text)
    element = @driver.find_element :xpath, xpath
    element.send_keys text
  end

  def click(xpath)
    element = @driver.find_element :xpath, xpath
    element.click
  end
end

# base task
class Task
  def initialize(driver)
    @driver = driver
  end

  def execute(*)
    raise 'undefined task execution'
  end
end

# web automation workflow
class Workflow
  def initialize
    @driver = Driver.new
    @tasks = []
  end

  def add(task, args)
    @tasks << [(task.new @driver), args]
  end

  def execute
    @tasks.each { |task, args| task.execute(*args) }
  end
end

# runtime user defined task
class CustomTask < Task
  def execute(*actions)
    actions.each do |method, *args|
      raise ArgumentError "unknown action type: #{method}" unless @driver.respond_to?(method)

      @driver.send(method, *args)
    end
  end
end

# login to linkedin
class LinkedinLogin < Task
  def execute(type, *args)
    @driver.navigate 'https://www.linkedin.com'
    case type
    when :credentials
      credentials(*args)
    else
      raise ArgumentError, "unknown login type: #{type}"
    end
  end

  def credentials(user, pass)
    @driver.write_to '//*[@id="session_key"]', user
    @driver.write_to '//*[@id="session_password"]', pass
    @driver.click '//*[@id="main-content"]/section[1]/div/div/form/div[2]/button'
  end
end

def static_workflow_example
  job_search_wf = Workflow.new
  job_search_wf.add(LinkedinLogin, [:credentials, 'test@email.com', 'pass'])
  job_search_wf.execute
end

def runtime_workflow_example
  # custom task actions
  login_actions = []
  login_actions << [:navigate, 'https://www.linkedin.com']
  login_actions << [:write_to, '//*[@id="session_key"]', 'test@email.com']
  login_actions << [:write_to, '//*[@id="session_password"]', 'pass']
  login_actions << [:click, '//*[@id="main-content"]/section[1]/div/div/form/div[2]/button']

  job_search_wf = Workflow.new
  job_search_wf.add(CustomTask, login_actions)
  job_search_wf.execute
end
