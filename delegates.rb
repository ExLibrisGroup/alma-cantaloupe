require 'aws-sdk'
require 'fileutils'
require 'net/http'
require 'json'
require 'base64'
require 'cgi'
require 'jwt'
require 'openssl'
require 'logger'
require 'java'
java_import java.lang.System

class CustomDelegate



  attr_accessor :context

  def authorized?(options = {})
	true
  end	

 def redirect(options = {})			
 
end

 

 def extra_iiif2_information_response_keys(options = {})
    { }
  end  

 
# def s3source_object_info(options = {})
#     JSON.parse(Base64.decode64(context['identifier']))
# end


 def filesystemsource_pathname(options = {})
			# Decode the identifier
			identifier = JSON.parse(Base64.decode64(context['identifier']))

			# Build path
			path = get_property('FilesystemCache.pathname')
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
	
def get_property(property)
	Java::EduIllinoisLibraryCantaloupeConfig::ConfigurationFactory.getInstance().getString(property)	
	rescue
	nil
end


end
