hmacSha1 = require('crypto-js/hmac-sha1')
Promise = require('bluebird')

class DomainAliasesController

	@reservedAliases: ['', 'api', 'admin', 'administrator', 'billing', 'help', 'info', 'ssl-admin', 'support', 'www']

	@getIndex: (req, res) ->
		res.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
		return

	@formatAlias: (alias) ->
		{
			customerId: alias.customerId
			alias: alias.srcName
			domain: alias.destDomain
		}

	@getAlias: (req, res) ->
		req.app.getModel('DomainAlias').findOne { srcName: req.params.alias }
		.then (domainAlias) ->
			if domainAlias
				res.success DomainAliasesController.formatAlias domainAlias
			else
				res.fail 'Alias not found'
			return
		.catch (err) ->
			res.fail 'Unable to get alias', 500, null, err
			return
		return

	@postAlias: (req, res) ->
		currentUser = req.app.get 'user'

		# Prepare alias model data
		newAlias =
			customerId: currentUser.id
			srcName: req.body.alias
			destDomain: req.body.domain

		if !newAlias.srcName or newAlias.srcName in DomainAliasesController.reservedAliases
			res.fail 'Requested alias is reserved'
			return

		# Attempt to create the alias
		DomainAlias = req.app.getModel('DomainAlias')
		DomainAlias.create newAlias
		# Alias successfully created
		.then (alias) ->
			res.success DomainAliasesController.formatAlias alias
			return
		# Alias creation failed, attempt to find and report reason for failure
		.catch (err) ->
			DomainAlias.findOne().where({ srcName: newAlias.srcName })
			.then (alias) ->
				if alias
					res.fail 'The alias is already registered'
					throw false
				DomainAlias.findOne().where({ destDomain: newAlias.destDomain }).then (alias) ->
					alias
			.then (alias) ->
				if alias
					res.fail 'The domain is already registered'
					throw false
				else
					# Failed to debug issue, simply throw earlier err
					throw err
				return
			.catch (err) ->
				if err
					res.fail 'Error creating alias', 500, null, err
				return
			return
		return

	@deleteAlias: (req, res) ->
		# Although such aliases would never exist due to the create sanitization, we're repeating the sanitization here
		# for peace of mind
		if !req.params.alias or req.params.alias in DomainAliasesController.reservedAliases
			res.fail 'Requested alias is reserved'
			return

		DomainAlias = req.app.getModel('DomainAlias')
		DomainAlias.findOne().where({ srcName: req.params.alias })
		.then (alias) ->
			# Make sure that the alias exists
			if !alias
				res.fail 'Alias not found'
				throw false

			# Customer must have ownership over the alias, or must be an admin
			currentUser = req.app.get 'user'
			if currentUser.id isnt alias.customerId and !currentUser.isAdmin
				res.fail 'You are not the owner of this alias!', 401
				return

			# Alias exists and ownership confirmed
			# Attempt to delete customer alias
			DomainAlias.destroy { id: alias.id }
			# Customer alias successfully deleted
			.then () ->
				res.success()
				return
			# Failed to delete customer alias
			.catch (err) ->
				res.fail 'Unable to delete alias', 500, null, err
				return
			return
		.catch (err) ->
			if err
				res.fail 'Unable to get alias', 500, null, err
			return
		return

	@deleteAll: (req, res) ->
		if req.app.get('config').env is not 'development'
			res.fail 'Forbidden', 403
			return

		currentUser = req.app.get 'user'
		if !currentUser.isAdmin
			res.fail 'Not authorized', 401
			return

		req.app.getModel('DomainAlias').query('TRUNCATE TABLE domain_aliases')
		# Customer alias truncated
		.then () ->
			res.success()
			return
		.catch (err) ->
			if err
				res.fail 'Unable to truncate aliases', 500, null, err
			return
		return

module.exports = DomainAliasesController