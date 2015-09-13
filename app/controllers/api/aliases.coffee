hmacSha1 = require('crypto-js/hmac-sha1')
sha1 = require('crypto-js/sha1')

controller = {}

controller.getIndex = (req, res) ->
	res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
	return

controller.getAlias = (req, res) ->
	aliases = req.app.models.alias
	aliases.findOne { src_name: req.params.alias }, (err, alias) ->
		if err
			res._cc.fail 'Unable to get alias', {}, err
		if alias
			res._cc.success formatAlias req, alias
		else
			res._cc.fail 'Alias not found'
		return
	return

controller.postAlias = (req, res) ->
	aliases = req.app.models.alias

	# Prepare alias model data
	new_alias =
		src_name: req.body.alias
		dest_domain: req.body.domain
		dest_email: req.body.email
		customer_secret_hash: hmacSha1(req.body.secret, req.app.get('config').secret_keys.db_hash).toString()
		alias_secret: sha1(Math.random().toString()).toString()

	if !new_alias.src_name or new_alias.src_name in ['abuse', 'admin', 'administrator', 'billing', 'hostmaster', 'info', 'postmaster', 'ssl-admin', 'support', 'webmaster']
		res._cc.fail 'Requested alias is reserved'
		return

	# Attempt to create the alias
	aliases.create new_alias
	# Attempt to create mailserver alias
	.then (alias) ->
		req.app.models.virtual_alias.create(
			domain_id: req.app.get('config').mailserver_domain_id
			source: new_alias.src_name + '@loves.money'
			destination: new_alias.dest_email
		)
		# Alias and mailserver alias successfully created
		.then () ->
			res._cc.success formatAlias req, alias
		# Failed to create mailserver alias, rollback and destroy alias entry
		.catch (err) ->
			aliases.destroy { id: alias.id }, ->
				return
			res._cc.fail 'Error creating mail alias', {}, err
			return
		return
	# Alias creation failed, attempt to find and report reason for failure
	.catch () ->
		aliases.findOne().where({ src_name: new_alias.src_name })
		.then (alias) ->
			if alias
				res._cc.fail 'The alias is already registered'
				throw false
			aliases.findOne().where({ dest_domain: new_alias.dest_domain }).then (alias) ->
				alias
		.then (alias) ->
			if alias
				res._cc.fail 'The domain is already registered'
				throw false
			aliases.findOne().where({ dest_email: new_alias.dest_email }).then (alias) ->
				alias
		.then (alias) ->
			if alias
				res._cc.fail 'The email is already registered'
				throw false
			return
		.catch (err) ->
			if err
				res._cc.fail 'Error creating alias', {}, err
			return
		return
	return

controller.deleteAlias = (req, res) ->
	# Make sure that alias_secret is provided
	if !req.body.alias_secret
		return res._cc.fail 'Please provide the alias_secret'

	# Although such aliases would never exist due to the create sanitization, we're repeating the sanitization here
	# for peace of mind
	if !req.params.alias or req.params.alias in ['abuse', 'admin', 'administrator', 'billing', 'hostmaster', 'info', 'postmaster', 'ssl-admin', 'support', 'webmaster']
		res._cc.fail 'Requested alias is reserved'
		return

	aliases = req.app.models.alias
	aliases.findOne().where({ src_name: req.params.alias })
	.then (alias) ->
		# Make sure that the alias exists
		if !alias
			res._cc.fail 'Alias not found'
			throw false

		# Confirm ownership by matching customer_secret_hash
		if alias.alias_secret isnt req.body.alias_secret
			res._cc.fail 'Incorrect secret'
			throw false

		# Alias exists and ownership confirmed
		# Attempt to delete mailserver alias
		req.app.models.virtual_alias.destroy(
			domain_id: req.app.get('config').mailserver_domain_id
			destination: alias.dest_email
			custom: true
		)
		# Mailserver alias successfully deleted
		.then () ->
			# Attempt to delete customer alias
			aliases.destroy { id: alias.id }
		# Customer alias successfully deleted
		.then () ->
			res._cc.success()
			return
		# Failed to delete mailserver alias or customer alias
		.catch (err) ->
			res._cc.fail 'Unable to delete alias', {}, err
			return
		return
	.catch (err) ->
		if err
			res._cc.fail 'Unable to get alias', {}, err
		return
	return

controller.deleteAll = (req, res) ->
	if req.app.get('config').env is not 'development'
		res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
		return

	aliases = req.app.models.alias
	aliases.query('TRUNCATE TABLE aliases')
	# Customer alias truncated
	.then () ->
		req.app.models.virtual_alias.destroy { custom: true }
	# Corresponding mailserver alias truncated
	.then () ->
		res._cc.success()
		return
	.catch (err) ->
		if err
			res._cc.fail 'Unable to truncate aliases', {}, err
		return
	return

# Format alias to only include public data
formatAlias = (req, alias) ->
	result =
		alias: alias.src_name
		domain: alias.dest_domain
		email: alias.dest_email
	# If authorized, also return additional data
	if req.headers['api-secret'] is req.app.get('config').secret_keys.api_secret
		result.alias_secret = alias.alias_secret
	result

module.exports = controller