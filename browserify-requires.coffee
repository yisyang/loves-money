crypto = require('crypto')
sha1 = require('crypto-js/sha1')
hmacSha1 = require('crypto-js/hmac-sha1')

config = {}
config.client_encryption_key = sha1('thisKeyIsMeantToBePublicAnd!AllThatSecure').toString().substring(0, 32)


window.LM = {}
window.LM.sha1 = (raw) ->
	sha1(raw).toString()
window.LM.hmacSha1 = (raw, secret) ->
	hmacSha1(raw, secret).toString()
window.LM.encrypt = (raw, key, iv) ->
	# Create a aes256 cipher
	cipher = crypto.createCipheriv('aes-256-cbc', key, iv)
	# Pass data into cipher
	cipher.update(raw, 'utf8')
	# Return the encrypted data
	cipher.final('base64')
window.LM.decrypt = (encrypted, key, iv) ->
	# Create decipher
	decipher = crypto.createDecipheriv('aes-256-cbc', key, iv)
	# Pass data into decipher
	decipher.update(encrypted, 'base64')
	# Return the decrypted data
	decipher.final('utf8')

#"api_secret": "We_have3released$an5update7with11s3v3ral13important8" # Allows additional access from UI
#"client_secret": "thisKeyIsMeantToBePublicAnd!AllThatSecure" # Key for encrypting and decrypting of UI stuff
