require 'aws-sdk'
require 'fileutils'
require 'net/http'
require 'json'
require 'base64'

module Cantaloupe
	@@reps ||= {}

  def self.authorized?(identifier, full_size, operations, resulting_size,
                       output_format, request_uri, request_headers, client_ip,
                       cookies)

  	identifier = JSON.parse(Base64.decode64(identifier))
  	if @@reps.key?(identifier['rep_id'])
  		return @@reps[identifier['rep_id']]
  	else
  		uri = URI("https://#{identifier['instance']}.alma.exlibrisgroup.com/view/delivery/#{identifier['institution']}/#{identifier['rep_id']}")
  		Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  			resp = http.head(uri)
  			@@reps[identifier['rep_id']] = resp.is_a?(Net::HTTPSuccess)
  		end
  	end

	rescue Exception => ex
		puts "delegates.rb: authorized? error. #{ex.class}: #{ex.message}"
		false
  end	

  def self.extra_iiif2_information_response_keys(identifier)
    { }
  end  

	module FilesystemResolver

		###
		# Gets a JWT as an identifier 
		# and extracts the endpoint, bucket, and file path.
		# Calculates the path. Checks if the file exists.
		# If not, file is downloaded. Returns the path.
		###
    def self.get_pathname(identifier)
			# Decode the identifier
			identifier = JSON.parse(Base64.decode64(identifier))

			# Build path
			path = Utils::get_property('FilesystemCache.pathname')
			path = File.join(path, 'source', identifier['bucket'], identifier['key'])

			# If doesn't exist, download
			if !File.exist? path
				FileUtils.makedirs File.dirname(path)
				s3 = Aws::S3::Client.new(region: identifier['region'])
				s3.get_object(
  				response_target: path,
  				bucket: identifier['bucket'],
  				key: identifier['key']
  			)
			end

			path
		rescue Exception => ex
			puts "delegates.rb: get_pathname error. #{ex.class}: #{ex.message}"
			nil
    end

  end
  private

  module Utils

  	begin
			require 'java'
			include_package java.lang
			WORKDIR = File.expand_path(File.dirname(System.getProperties['cantaloupe.config']))
		rescue LoadError # For development with regular Ruby
			require 'inifile'
			WORKDIR = File.expand_path(File.dirname(__FILE__))
			@inifile = IniFile.load(File.join(WORKDIR, 'cantaloupe.properties'))['global']
		end	

  	def self.get_property(property)
			@inifile ? @inifile[property] : 
				Java::EduIllinoisLibraryCantaloupeConfig::ConfigurationFactory.getInstance().getString(property) 
		rescue
			nil
  	end
  end  

end

identifier = 'eyJyZWdpb24iOiJ1cy1lYXN0LTEiLCJidWNrZXQiOiJhbG1hZC10ZXN0Iiwia2V5IjoieWlmYXQvZmxvd2VyLmpwZyIsInJlcF9pZCI6MTI5MDE5OTk4MDAwMDU2MSwiaW5zdGFuY2UiOiJuYTAxIiwiaW5zdGl0dXRpb24iOiJUUl9JTlRFR1JBVElPTl9JTlNUIn0='
#Cantaloupe::FilesystemResolver::get_pathname(identifier)
#puts Cantaloupe::authorized?(identifier, 
#	nil, nil, nil, #full_size, operations, resulting_size,
#  nil, nil, nil, nil, #                     output_format, request_uri, request_headers, client_ip,
#  nil) #                     cookies)
