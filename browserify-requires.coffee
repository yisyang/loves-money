crypto = require('crypto')
sha1 = require('crypto-js/sha1')
hmacSha1 = require('crypto-js/hmac-sha1')

class window.LM
	@config:
		client_encryption_key: sha1('thisKeyIsMeantToBePublicAndInsecure').toString().substring(0, 32)

	@sha1 = (raw) ->
		sha1(raw).toString()
	@hmacSha1 = (raw, secret) ->
		hmacSha1(raw, secret).toString()
	@encrypt = (raw, key, iv) ->
		# Create a aes256 cipher
		cipher = crypto.createCipheriv('aes-256-cbc', key, iv)
		# Pass data into cipher
		cipher.update(raw, 'utf8')
		# Return the encrypted data
		cipher.final('base64')
	@decrypt = (encrypted, key, iv) ->
		# Create decipher
		decipher = crypto.createDecipheriv('aes-256-cbc', key, iv)
		# Pass data into decipher
		decipher.update(encrypted, 'base64')
		# Return the decrypted data
		decipher.final('utf8')
