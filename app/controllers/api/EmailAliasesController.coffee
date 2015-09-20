hmacSha1 = require('crypto-js/hmac-sha1')
Promise = require('bluebird')

class EmailAliasesController

	@reservedAliases: ['', 'abuse', 'admin', 'administrator', 'billing', 'help', 'hostmaster', 'info', 'postmaster', 'ssl-admin', 'support', 'webmaster']

	@getIndex: (req, res) ->
		res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
		return

	@formatAlias: (alias) ->
		{
			customerId: alias.customerId
			alias: alias.srcName
			email: alias.destEmail
		}

	@getAlias: (req, res) ->
		req.app.getModel('EmailAlias').findOne { srcName: req.params.alias }
		.then (emailAlias) ->
			if emailAlias
				res._cc.success EmailAliasesController.formatAlias emailAlias
			else
				res._cc.fail 'Alias not found'
			return
		.catch (err) ->
			res._cc.fail 'Unable to get alias', 500, null, err
			return
		return

	@postAlias: (req, res) ->
		currentUser = req.app.get 'user'

		# Prepare alias model data
		newAlias =
			customerId: currentUser.id
			srcName: req.body.alias
			destEmail: req.body.email

		if !newAlias.srcName or newAlias.srcName in EmailAliasesController.reservedAliases
			res._cc.fail 'Requested alias is reserved'
			return

		# Attempt to create the alias
		EmailAlias = req.app.getModel('EmailAlias')
		EmailAlias.create newAlias
		# Attempt to create mailserver alias
		.then (alias) ->
			req.app.getModel('VirtualAlias').create(
				domainId: req.app.get('config').mailserver_domain_id
				source: newAlias.srcName + '@loves.money'
				destination: newAlias.destEmail
			)
			# Alias and mailserver alias successfully created
			.then () ->
				res._cc.success EmailAliasesController.formatAlias alias
			# Failed to create mailserver alias, rollback and destroy alias entry
			.catch (err) ->
				EmailAlias.destroy { id: alias.id }, ->
					return
				res._cc.fail 'Error creating mail alias', 500, null, err
				return
			return
		# Alias creation failed, attempt to find and report reason for failure
		.catch (err) ->
			EmailAlias.findOne().where({ srcName: newAlias.srcName })
			.then (alias) ->
				if alias
					res._cc.fail 'The alias is already registered'
					throw false
				EmailAlias.findOne().where({ destEmail: newAlias.destEmail }).then (alias) ->
					alias
			.then (alias) ->
				if alias
					res._cc.fail 'The email is already registered'
					throw false
				else
					# Failed to debug issue, simply throw earlier err
					throw err
				return
			.catch (err) ->
				if err
					res._cc.fail 'Error creating alias', 500, null, err
				return
			return
		return

	@deleteAlias: (req, res) ->
		# Although such aliases would never exist due to the create sanitization, we're repeating the sanitization here
		# for peace of mind
		if !req.params.alias or req.params.alias in EmailAliasesController.reservedAliases
			res._cc.fail 'Requested alias is reserved'
			return

		EmailAlias = req.app.getModel('EmailAlias')
		EmailAlias.findOne().where({ srcName: req.params.alias })
		.then (alias) ->
			# Make sure that the alias exists
			if !alias
				res._cc.fail 'Alias not found'
				throw false

			# Customer must have ownership over the alias, or must be an admin
			currentUser = req.app.get 'user'
			if currentUser.id isnt alias.customerId and !currentUser.isAdmin
				res._cc.fail 'You are not the owner of this alias!', 401
				return

			# Alias exists and ownership confirmed
			# Attempt to delete mailserver alias
			req.app.getModel('VirtualAlias').destroy(
				domainId: req.app.get('config').mailserver_domain_id
				destination: alias.destEmail
				custom: true
			)
			# Mailserver alias successfully deleted
			.then () ->
				# Attempt to delete customer alias
				EmailAlias.destroy { id: alias.id }
			# Customer alias successfully deleted
			.then () ->
				res._cc.success()
				return
			# Failed to delete mailserver alias or customer alias
			.catch (err) ->
				res._cc.fail 'Unable to delete alias', 500, null, err
				return
			return
		.catch (err) ->
			if err
				res._cc.fail 'Unable to get alias', 500, null, err
			return
		return

	@deleteAll: (req, res) ->
		if req.app.get('config').env is not 'development'
			res._cc.fail 'Forbidden', 403
			return

		currentUser = req.app.get 'user'
		if !currentUser.isAdmin
			res._cc.fail 'Not authorized', 401
			return

		req.app.getModel('EmailAlias').query('TRUNCATE TABLE email_aliases')
		# Customer alias truncated
		.then () ->
			req.app.getModel('VirtualAlias').destroy { custom: true }
		# Corresponding mailserver alias truncated
		.then () ->
			res._cc.success()
			return
		.catch (err) ->
			if err
				res._cc.fail 'Unable to truncate aliases', 500, null, err
			return
		return

module.exports = EmailAliasesController