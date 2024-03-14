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

  def read(xpath, multiple: false)
    find(xpath, multiple:).map(&:text)
  end

  def click(xpath)
    find(xpath).click
  end

  def find(xpath, multiple: false)
    if multiple
      @wait.until { @driver.find_elements(:xpath, xpath) }
    else
      @wait.until { [@driver.find_element(:xpath, xpath)] }
    end
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
