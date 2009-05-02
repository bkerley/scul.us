require 'openssl'
require 'rubygems'
require 'httparty'
pri = OpenSSL::PKey::RSA.new(File.read('scul.key'))
v = HTTParty.post 'http://scul.us', :query=>{:url=>pri.private_encrypt(readline.strip)}
puts v
