# frozen_string_literal: true

require 'selenium-webdriver'

# simple driver
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

# base task with execution args
class LazyTask
  def initialize(driver, task, args)
    @task = task.new driver
    @args = args
  end

  def invoke
    @task.execute(*@args)
  end
end

# web tasks automation workflow
class Workflow
  def initialize(lazy_tasks)
    driver = Driver.new
    @lazy_tasks = lazy_tasks.map { |lazy_task| LazyTask.new driver, *lazy_task }
  end

  def execute
    @lazy_tasks.each(&:invoke)
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

job_search_wf = Workflow.new [
  [LinkedinLogin, [:credentials, 'email@gmail.com', 'password']]
]
job_search_wf.execute

