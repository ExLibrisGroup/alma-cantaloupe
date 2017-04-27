require 'json'
require 'base64'

# 1288059980000561
# TR_INTEGRATION_INST/storage/alma/FB/89/77/5A/45/C9/2F/B3/6F/8A/73/57/9E/53/6F/17/ring-galaxy.jpg

a = {
	region: 'us-east-1',
	bucket: 'na-st01.ext.exlibrisgroup.com',
	key: 'TR_INTEGRATION_INST/storage/alma/FB/89/77/5A/45/C9/2F/B3/6F/8A/73/57/9E/53/6F/17/ring-galaxy.jpg',
	rep_id: 1288059980000561, #1290199980000561,
	instance: 'na01',
	institution: 'TR_INTEGRATION_INST'
}.to_json

puts b = Base64.strict_encode64(a)
puts JSON.parse(Base64.decode64(b))["key"]