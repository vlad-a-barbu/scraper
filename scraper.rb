# frozen_string_literal: true

require 'selenium-webdriver'
require 'open-uri'
require 'selenium_tor'

# web driver error
class DriverError < StandardError; end

# simple web driver wrapper
class Driver
  DEFAULT_RETRY_COUNT = 3
  DEFAULT_TIMEOUT = 10 # seconds

  def initialize(opts = {})
    @proxies = opts.fetch(:proxies, nil)
    @retry_count = opts.fetch(:retry_count, DEFAULT_RETRY_COUNT)
    @wait = Selenium::WebDriver::Wait.new(timeout: opts.fetch(:timeout, DEFAULT_TIMEOUT))
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
    raise DriverError, "element not found at xpath #{xpath}"
  end

  private

  def init_driver
    random_proxy || tor_proxy
  end

  # WIP https://gitlab.com/matzfan/selenium-tor
  def tor_proxy
    options = Selenium::WebDriver::Tor::Options.new
    Selenium::WebDriver.for :tor, options:
  end

  def random_proxy
    return if @proxies.nil?

    @retry_count.times do
      proxy = @proxies.sample
      response = healthcheck(proxy)
      next if response.nil?

      options = Selenium::WebDriver::Firefox::Options.new
      options.proxy = Selenium::WebDriver::Proxy.new(http: proxy)
      Selenium::WebDriver.for :firefox, options:
    end
    nil
  end

  def healthcheck(proxy)
    puts "proxy healthcheck: #{proxy}"
    URI.open('https://api.ipify.org?format=json', proxy: "http://#{proxy}") do |response|
      response.each_line { |line| puts line }
      return response
    end
  rescue StandardError => e
    puts "healthcheck failed: #{e.message}"
    nil
  end
end

# task is a container responsible with "understanding" how to execute custom web driver actions
# !!! actions API is still a WIP
class Task
  PATH_SEPARATOR = '/'

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
    path, *read_args = args
    value = @driver.read(*read_args)
    store(path, value)
  end

  def fallback(*args)
    type, *fallback_args = args
    send(type, *fallback_args)
  end

  private

  def store(path, value)
    keys = path.split(PATH_SEPARATOR)
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
  attr_reader :state

  def initialize(opts = {})
    @driver = Driver.new(opts)
    @state = {}
    @tasks = []
  end

  def add(actions)
    @tasks << Task.new(@tasks.length + 1, @driver, @state, actions)
  end

  def execute
    @tasks.each(&:execute)
  end

  def save(path)
    IO.write(path, @state.to_json)
  end
end

# example workflow config
def collect_actions(page)
  (1..50).map do |id|
    [
      :collect,
      "page#{page}/movie#{id}",
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

wf.save('./movies.json')