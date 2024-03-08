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
    element = @driver.find_element(:xpath, xpath)
    element.send_keys text
  end

  def click(xpath)
    element = @driver.find_element(:xpath, xpath)
    element.click
  end
end

# driver base task
class Task
  def initialize(driver)
    @driver = driver
  end

  def execute(*args)
    @args = args
    raise 'undefined task execution'
  end
end

# login to linkedin
class LinkedinLogin < Task
  def execute(type, *args)
    @driver.navigate 'https://www.linkedin.com/'
    case type
    when :credentials
      user, pass = args
      @driver.write_to '//*[@id="session_key"]', user
      @driver.write_to '//*[@id="session_password"]', pass
      @driver.click '//*[@id="main-content"]/section[1]/div/div/form/div[2]/button'
    else
      raise ArgumentError, "unknown login type: #{type}"
    end
  end
end

driver = Driver.new

login = LinkedinLogin.new(driver)
login.execute(:credentials, 'test@email.com', 'password')
