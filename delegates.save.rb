require 'jwt'
require 'aws-sdk'
require 'openssl'
require 'fileutils'
require 'uri'

module Cantaloupe

  def self.authorized?(identifier, full_size, operations, resulting_size,
                       output_format, request_uri, request_headers, client_ip,
                       cookies)

		# Get token from cookie
		auth_token = cookies["delivery_auth_token"]

		# Validate the token
		key_file = File.join(Cantaloupe::Utils::WORKDIR, 'keyfile-pub.pem')
		@public_key ||= OpenSSL::PKey::RSA.new(File.read(key_file))
		token = JWT.decode(auth_token, @public_key, true, { :algorithm => 'RS256' })[0]

		# Check that identifier path in token
		token['paths'].select{ |p| URI.unescape(identifier).start_with?(p)}.any?
	rescue 
		false
  end	

  def self.extra_iiif2_information_response_keys(identifier)
    { }
  end

	module AmazonS3Resolver

    ##
    # @param identifier [String] Image identifier
    # @return [String,nil] S3 object key of the image corresponding to the
    #                      given identifier, or nil if not found.
    #
    def self.get_object_key(identifier)
    	identifier.split(':')
    end

  end


	module FilesystemResolver

		###
		# Extracts the bucket, and file path.
		# Calculates the path. Checks if the file exists.
		# If not, file is downloaded. Returns the path.
		###
    def self.get_pathname(identifier)
    	bucket, key = URI.unescape(identifier).split(':')
    	region = Utils::get_property('AmazonS3Resolver.bucket.region')

			# Build path
			path = Utils::get_property('FilesystemCache.pathname')
			path = File.join(path, 'source', bucket, key)

			# If doesn't exist, download
			if !File.exist? path
				FileUtils.makedirs File.dirname(path)
				s3 = Aws::S3::Client.new(region: region)
				s3.get_object(
  				response_target: path,
  				bucket: bucket,
  				key: key
  			)
			end

			path
		rescue
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

puts Cantaloupe::FilesystemResolver.get_pathname('na-st01.ext.exlibrisgroup.com:TR_INTEGRATION_INST%2Fstorage%2Falma%2FA2%2FE3%2F34%2F0C%2FAA%2F9E%2F44%2FAE%2F4C%2F91%2F58%2F9D%2F50%2F3D%2F9D%2F21%2Fgalaxy-abell.tif')
