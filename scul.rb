require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'openssl'
require 'affine'

unless defined? Pubkey
  Pubkey = OpenSSL::PKey::RSA.new(File.read('scul.pub'))
end

class Link
  include DataMapper::Resource
  property :id, Serial
  property :url, String, :index=>true

  @@affine = Affine::Cipher.new(60466169, 12034710206, 81268112)

  def self.find_by_code(code)
    return nil unless code.is_a? String
    link_id = @@affine.decipher(code.to_i(36))
    link = get link_id
    return nil unless link && link.code == code

    link
  rescue Affine::RangeError
    nil
  end

  def code
    @@affine.encipher(self.id).to_s(36)
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/scul.sqlite3")
#DataMapper.auto_upgrade!

get '/' do
  response['Cache-Control'] = 'public, max-age=86400'
  '<img src="mus_musculus.jpg" alt="mus musculus" />'
end

get '/u/:code' do |code|
  response['Cache-Control'] = 'public, max-age=86400'
  content_type 'text/plain'
  l = Link.find_by_code code
  return unfound unless l

  "http://scul.us/#{l.code} => #{l.url}"
end

get '/:code' do |code|
  response['Cache-Control'] = 'public, max-age=86400'
  content_type 'text/plain'
  l = Link.find_by_code code
  return unfound unless l

  response['Location'] = l.url
  halt 301, "thanks for using scul.us"
end

post '/' do
  content_type 'text/plain'

  valid_url = decrypt params
  return forbid unless valid_url

  l = Link.first_or_create :url=>valid_url
  l.save

  "http://scul.us/#{l.code}"
end

def unfound
  halt 404, 'not found'
end

def forbid
  halt 403, 'forbidden'
end

def decrypt(params)
  plaintext = Pubkey.public_decrypt params[:url]
  false unless plaintext =~ /^https?:\/\//
  plaintext
rescue Exception => e
  false
end
