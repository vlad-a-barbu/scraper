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

  def write(selector, text)
    find(selector).send_keys(text)
  end

  def read(selector, multiple)
    find(selector, multiple:).map(&:text)
  end

  def click(selector)
    find(selector).click
  end

  def find(selector, multiple: false)
    how, what = *selector
    find_internal(how, what, multiple)
  rescue Selenium::WebDriver::Error::TimeoutError
    raise DriverError, "element not found by #{how}: #{what}"
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

  def find_internal(how, what, multiple)
    if multiple
      @wait.until do
        elements = @driver.find_elements(how, what)
        return elements unless elements.empty?
      end
    else
      @wait.until { [@driver.find_element(how, what)] }
    end
  end
end
