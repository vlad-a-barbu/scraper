# frozen_string_literal: true

require 'net/http'

def fetch_proxies(type)
  session = Net::HTTP.new('raw.githubusercontent.com', 443)
  session.use_ssl = true

  request = Net::HTTP::Get.new("/TheSpeedX/SOCKS-List/master/#{type}.txt")
  response = session.request(request)

  File.open("#{__dir__}/proxies/#{type}.txt", 'w') do |file|
    file.write(response.body.strip)
  end
end

fetch_proxies('socks5')
fetch_proxies('socks4')
fetch_proxies('http')
