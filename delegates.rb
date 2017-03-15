require 'jwt'
require 'aws-sdk'
require 'openssl'
require 'fileutils'

module Cantaloupe

  def self.authorized?(identifier, full_size, operations, resulting_size,
                       output_format, request_uri, request_headers, client_ip,
                       cookies)
    true
  end	

	module HttpResolver

		###
		# Gets a JWT as an identifier, validates the token,
		# and extracts the endpoint, bucket, and file path.
		# Then it signs the URL and returns it to Cantaloupe
		# for processing.
		#
		# This can't bve used since HttpResolver performs a 
		# HEAD request first, and the signed URL for HEAD is
		# different than that for GET.
		###
		def self.get_url(identifier)
			# Validate the token
			key_file = File.join(File.expand_path(File.dirname(__FILE__)), 'keyfile-pub.pem')
			public_key = OpenSSL::PKey::RSA.new(File.read(key_file))
			token = JWT.decode(identifier, public_key, true, { :algorithm => 'RS256' })[0]

			# Sign the URL
			Aws.config[:region] = token["region"]
 			signer = Aws::S3::Presigner.new
 			signer.presigned_url(:get_object, bucket: token["bucket"], key: token["key"])
	 	rescue 
	 		nil
		end

	end

	module FilesystemResolver

		###
		# Gets a JWT as an identifier, validates the token,
		# and extracts the endpoint, bucket, and file path.
		# Calculates the path. Checks if the file exists.
		# If not, file is downloaded. Returns the path.
		###
    def self.get_pathname(identifier)
			# Validate the token
			key_file = File.join(File.expand_path(File.dirname(__FILE__)), 'keyfile-pub.pem')
			public_key = OpenSSL::PKey::RSA.new(File.read(key_file))
			token = JWT.decode(identifier, public_key, true, { :algorithm => 'RS256' })[0]

			# Build path
			begin path = IMAGESDIR rescue path = '/tmp/cantaloupe' end
			path = File.join(path, token['bucket'], token['key'])
			
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
		rescue
			nil
    end

  end

end
