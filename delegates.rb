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

		

	identifier = JSON.parse(Base64.decode64(context['identifier']))
	cookies = context['cookies']
	if context['cookies'].select{ |c| c['JWT_CLAIMS'] }.any?
			@key_file = File.join(get_work_dir, 'keyfile-pub.pem')	
 			@public_key ||= OpenSSL::PKey::RSA.new(File.read(@key_file))		
			token = JWT.decode(cookies['JWT_CLAIMS'], @public_key, true, { :algorithm => 'RS256' ,:aud=> 'Audience',:iss=> 'Issuer' })[0]

			if token['rep_id'] != identifier['rep_id']
				 raise 'An error has occured.'
			end
			true
		else	
			if identifier['instance'].end_with?('.corp')
	        			uri = "http://#{identifier['instance']}.exlibrisgroup.com:1801"
        			else
	       				uri = "https://#{identifier['instance']}.alma.exlibrisgroup.com"
			end
			uri = URI("#{uri}/view/delivery/#{identifier['institution']}/#{identifier['rep_id']}")
				
				Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme.eql?('https')) do |http|
  				resp = http.head(uri)
  				resp.is_a?(Net::HTTPSuccess)
			end
	
	end

	rescue Exception => ex 
			puts "delegates.rb: authorized? error. #{ex.class}: #{ex.message}"
			false
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

 def get_work_dir
	
			workdir= File.expand_path(File.dirname(System.getProperties['cantaloupe.config']))
			puts workdir
			return workdir
		rescue LoadError # For development with regular Ruby
			require 'inifile'
			workdir= File.expand_path(File.dirname(__FILE__))
			@inifile = IniFile.load(File.join(workdir, 'cantaloupe.properties'))['global']
			puts workdir
			return workdir
		end	
def get_property(property)
	@inifile ? @inifile[property] :
	Java::EduIllinoisLibraryCantaloupeConfig::ConfigurationFactory.getInstance().getString(property)	
	rescue
	nil
end


end

identifier = 'eyJyZWdpb24iOiJ1cy1lYXN0LTEiLCJidWNrZXQiOiJhbG1hZC10ZXN0Iiwia2V5IjoieWlmYXQvZmxvd2VyLmpwZyIsInJlcF9pZCI6MTI5MDE5OTk4MDAwMDU2MSwiaW5zdGFuY2UiOiJuYTAxIiwiaW5zdGl0dXRpb24iOiJUUl9JTlRFR1JBVElPTl9JTlNUIn0='
#Cantaloupe::FilesystemResolver::get_pathname(identifier)
#puts Cantaloupe::authorized?(identifier, 
#	nil, nil, nil, #full_size, operations, resulting_size,
#  nil, nil, nil, nil, #                     output_format, request_uri, request_headers, client_ip,
#  nil) #                     cookies)