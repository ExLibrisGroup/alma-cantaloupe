require 'jwt'
require 'aws-sdk'
require 'openssl'
require 'fileutils'

module Cantaloupe

  def self.authorized?(identifier, full_size, operations, resulting_size,
                       output_format, request_uri, request_headers, client_ip,
                       cookies)
  	# Validate token
		@key_file = File.join(Cantaloupe::Utils::WORKDIR, 'keyfile-pub.pem')
		@public_key ||= OpenSSL::PKey::RSA.new(File.read(@key_file))
		token = JWT.decode(identifier, @public_key, true, { :algorithm => 'RS256' })[0]
		true
	rescue Exception => ex
		puts "delegates.rb: authorized? error. #{ex.class}: #{ex.message}"
		false
  end	

  def self.extra_iiif2_information_response_keys(identifier)
    { }
  end  

	module FilesystemResolver

		###
		# Gets a JWT as an identifier, validates the token,
		# and extracts the endpoint, bucket, and file path.
		# Calculates the path. Checks if the file exists.
		# If not, file is downloaded. Returns the path.
		###
    def self.get_pathname(identifier)
			# Decode the token (validation done in authorized?)
			token = JWT.decode(identifier, nil, false)[0]

			# Build path
			path = Utils::get_property('FilesystemCache.pathname')
			path = File.join(path, 'source', token['bucket'], token['key'])

			# If doesn't exist, download
			if !File.exist? path
				FileUtils.makedirs File.dirname(path)
				s3 = Aws::S3::Client.new(region: token['region'])
				s3.get_object(
  				response_target: path,
  				bucket: token['bucket'],
  				key: token['key']
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
