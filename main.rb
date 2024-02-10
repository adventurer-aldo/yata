require 'webrick'
require 'webrick/httpproxy'
require 'json'

# Replace these values with your server's IP and port
HOST = 'localhost'
PORT = 8302

server = WEBrick::HTTPProxyServer.new(:Port => PORT)

puts "Listening on #{HOST}:#{PORT}"

server.mount_proc '/' do |req, res|
  puts '==========REQUEST================='
  puts req.to_s
  puts '=========RESPONSE================='
  puts res.to_s
  puts '=========================='
end

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

server.start
