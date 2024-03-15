# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# demo http client
class Client
  def initialize(url)
    @url = URI.parse(url)
    @http = Net::HTTP.new(@url.host, @url.port)
  end

  def execute(payload)
    request = Net::HTTP::Post.new(@url.request_uri)
    request.content_type = 'application/json'
    request.body = payload.to_json

    response = @http.request(request)
    handle_response(response)
  end

  private

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      response.error!
    end
  end
end

client = Client.new('http://localhost:9999')

payload = { 'actions' =>
              [
                [:driver, :navigate, 'https://www.biziday.ro/'],
                [:collect, :news, :css, 'span'],
                [:fallback, :collect, :news, '/html']
              ] }

response = client.execute(payload)
IO.write("#{__dir__}/response.json", response.to_json)
