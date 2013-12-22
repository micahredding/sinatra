require 'sinatra'
require 'sinatra/form_helpers'
require 'json'
require 'digest/sha1'
require 'camlistore'
require 'rest_client'

# http://stackoverflow.com/a/9361331/3015918
module JSON
  def self.is_json?(foo)
    begin
      return false unless foo.is_a?(String)
      JSON.parse(foo).all?
    rescue JSON::ParserError
      false
    end
  end
end

class Blobserver
	@@camli = Camlistore.new

	def Blobserver.blobref blobcontent
		'sha1-' + Digest::SHA1.hexdigest(blobcontent)
	end

	def Blobserver.enumerate
		@@camli.enumerate_blobs.blobs
	end

	def Blobserver.put blobcontent
		blobref = Blobserver.blobref(blobcontent)
		boundary = 'randomboundaryXYZ'
		content_type = "multipart/form-data; boundary=randomboundaryXYZ"
		host = "localhost:3179"
		upload_url = 'http://localhost:3179/bs/camli/upload'

		post_body = ''
		post_body << "--" + boundary + "\n"
		post_body << 'Content-Disposition: form-data; name="' + blobref + '"; filename="' + blobref + '"' + "\n"
		post_body << 'Content-Type: application/octet-stream' + "\n\n"
		post_body << blobcontent
		post_body << "\n" + '--' + boundary + '--'

		RestClient.post upload_url, post_body, :content_type => content_type, :host => host
	end

	def Blobserver.get blobref
	  @@camli.get(blobref)
	end

end

# class Blob
# 	attr_accessor :blobref, :blobcontent
# 	def initialize blobref, blobcontent
# 		@blobref = blobref
# 		@blobcontent = blobcontent
# 	end
# 	def self.valid? blobcontent
# 		true
# 	end
# 	def self.get blobref
# 		blobcontent = Blobserver.get(blobref)
# 		if blobcontent
# 			self.new(blobref, blobcontent)
# 		else
# 			nil
# 		end
# 	end
# 	def self.put blobcontent
# 		self.new(Blobserver.put(blobcontent), blobcontent)
# 	end
# 	def self.enumerate
# 		blobs = []
# 		Blobserver.enumerate.each do |blobref, blobcontent|
# 			blobs << self.new(blobref, blobcontent)
# 		end
# 		blobs
# 	end
# end

# class SchemaBlob < Blob
# 	def blobhash
# 		JSON.parse(@blobcontent)
# 	end
# 	def self.valid? blobcontent
# 		JSON.is_json?(blobcontent)
# 	end
# 	def self.find_by field, value
# 		blobs = self.enumerate
# 		blobs.select do |blob|
# 			blob.blobhash[field] == value
# 		end
# 		blobs
# 	end
# end

# class Permanode < SchemaBlob
# 	def Permanode.create
# 		blobcontent = {
# 			'type' => 'permanode',
# 			'random' => rand(0..1000)
# 		}.to_json
# 		super blobcontent
# 	end
# 	def claims
# 		Claim.find_by_permanode(@blobref)
# 	end
# 	def current_claim
# 		claims.last || nil
# 	end
# 	def current_content
# 		return nil if current_claim.nil?
# 		current_claim.content
# 	end
# end

# class Claim < SchemaBlob
# 	def Claim.create permanode, content
# 		blobcontent = {
# 			'type' => 'claim',
# 			'permanode' => permanode.blobref || permanode,
# 			'content' => content.blobref || content,
# 		}.to_json
# 		super blobcontent
# 	end
# 	def Claim.find_by_permanode permanode_ref
# 		self.find_by('permanode', permanode_ref)
# 	end
# 	def content
# 		Content.get(@blobhash['content'])
# 	end
# end

get '/b/create' do
	erb :blobform
end

post '/b/create' do
	blobcontent = params[:blob]["blobcontent"]
	puts blobcontent
	@blob = Blobserver.put(blobcontent)
	redirect "/b/#{@blob['blobRef']}"
	redirect '/b/create'
end

get '/b/:blobref' do
	@blob = Blobserver.get(params[:blobref])
	if @blob.nil?
		redirect '/error'
	end
	@title = @blob['blobRef']
	erb :blob
end

get '/b' do
	@title = 'All Blobs'
	@blobs = Blobserver.enumerate
	erb :index
end

get '/error' do
	@title = 'Error'
	erb :error
end

get '/' do
	redirect '/b'
end