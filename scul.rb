require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'openssl'
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')

pubkey = OpenSSL::PKey::RSA.new(File.read('scul.pub'))

class Link
  include DataMapper::Resource
  property :id, Integer, :serial=>true, :key=>true
  property :link, String
end

get '/' do
  '<img src="mus_musculus.jpg" alt="mus musculus" />'
end

post '/' do
  valid_url = decrypt params
  forbid unless valid_url


end

def forbid
  halt 403, 'forbidden'
end

def decrypt(params)
  plaintext = pubkey.public_decrypt params[:url]
  false unless plaintext =~ /^https?:\/\//
rescue
  false
end
