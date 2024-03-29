# frozen_string_literal: true

# task is a container responsible with "understanding" how to execute custom web driver actions
class Task
  def initialize(id, driver, state, actions)
    @id = id
    @driver = driver
    @state = state
    @actions = actions
  end

  def execute
    @history = {}
    @actions.each_with_index { |action, index| execute_action(action, index) }
  end

  private

  def execute_action(action, index)
    type, *args = action
    raise ArgumentError("unknown action type: #{type}") unless respond_to?(type, true)

    return if type.to_sym == :fallback && @history[index - 1] == true

    puts "executing task #{@id} action #{index + 1}"
    send(type, *args)
    @history[index] = true
  rescue DriverError => e
    puts "task #{@id} action #{index + 1} failed: #{e.message}"
    @history[index] = false
  end

  def driver(*args)
    method, *driver_args = args
    raise ArgumentError("unknown driver method: #{method}") unless @driver.respond_to?(method)

    @driver.send(method, *driver_args)
  end

  def collect(*args)
    store_path, *read_args = args
    all, selector = *read_args
    value = if all.to_sym.eql?(:all)
              @driver.read(selector, multiple: true)
            else
              selector = *read_args
              @driver.read(selector, multiple: false)
            end
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
