hmacSha1 = require('crypto-js/hmac-sha1')
sha1 = require('crypto-js/sha1')

controller = {}

controller.index = (req, res) ->
	res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
	return

controller.get = (req, res) ->
	customers = req.app.models.customer
	customers.findOne { id: req.params.customer }, (err, customer) ->
		if err
			res._cc.fail 'Unable to get customer', {}, err
		if customer
			res._cc.success formatAlias req, customer
		else
			res._cc.fail 'Alias not found'
		return
	return

controller.create = (req, res) ->
	customers = req.app.models.customer

	# Prepare customer model data
	new_customer =
		src_name: req.body.customer
		dest_domain: req.body.domain
		dest_email: req.body.email
		customer_secret_hash: hmacSha1(req.body.secret, req.app.get('config').secret_keys.db_hash).toString()
		customer_secret: sha1(Math.random().toString()).toString()

	if !new_customer.src_name or new_customer.src_name in ['abuse', 'admin', 'administrator', 'billing', 'hostmaster', 'info', 'postmaster', 'ssl-admin', 'support', 'webmaster']
		res._cc.fail 'Requested customer is reserved'
		return

	# Attempt to create the customer
	customers.create new_customer
	# Attempt to create mailserver customer
	.then (customer) ->
		req.app.models.virtual_customer.create(
			domain_id: req.app.get('config').mailserver_domain_id
			source: new_customer.src_name + '@loves.money'
			destination: new_customer.dest_email
		)
		# Alias and mailserver customer successfully created
		.then () ->
			res._cc.success formatAlias req, customer
		# Failed to create mailserver customer, rollback and destroy customer entry
		.catch (err) ->
			customers.destroy { id: customer.id }, ->
				return
			res._cc.fail 'Error creating mail customer', {}, err
			return
		return
	# Alias creation failed, attempt to find and report reason for failure
	.catch () ->
		customers.findOne().where({ src_name: new_customer.src_name })
		.then (customer) ->
			if customer
				res._cc.fail 'The customer is already registered'
				throw false
			customers.findOne().where({ dest_domain: new_customer.dest_domain }).then (customer) ->
				customer
		.then (customer) ->
			if customer
				res._cc.fail 'The domain is already registered'
				throw false
			customers.findOne().where({ dest_email: new_customer.dest_email }).then (customer) ->
				customer
		.then (customer) ->
			if customer
				res._cc.fail 'The email is already registered'
				throw false
			return
		.catch (err) ->
			if err
				res._cc.fail 'Error creating customer', {}, err
			return
		return
	return

controller.delete = (req, res) ->
	# Make sure that customer_secret is provided
	if !req.body.customer_secret
		return res._cc.fail 'Please provide the customer_secret'

	# Although such customers would never exist due to the create sanitization, we're repeating the sanitization here
	# for peace of mind
	if !req.params.customer or req.params.customer in ['abuse', 'admin', 'administrator', 'billing', 'hostmaster', 'info', 'postmaster', 'ssl-admin', 'support', 'webmaster']
		res._cc.fail 'Requested customer is reserved'
		return

	customers = req.app.models.customer
	customers.findOne().where({ src_name: req.params.customer })
	.then (customer) ->
		# Make sure that the customer exists
		if !customer
			res._cc.fail 'Alias not found'
			throw false

		# Confirm ownership by matching customer_secret_hash
		if customer.customer_secret isnt req.body.customer_secret
			res._cc.fail 'Incorrect secret'
			throw false

		# Alias exists and ownership confirmed
		# Attempt to delete mailserver customer
		req.app.models.virtual_customer.destroy(
			domain_id: req.app.get('config').mailserver_domain_id
			destination: customer.dest_email
		)
		# Mailserver customer successfully deleted
		.then () ->
			# Finally delete customer
			customers.destroy { id: customer.id }, (err) ->
				if err
					res._cc.fail 'Unable to delete customer', {}, err
					throw false
				res._cc.success()
				return
		# Failed to delete mailserver customer
		.catch (err) ->
			res._cc.fail 'Error deleting mail customer', {}, err
			return
		return

		return
	.catch (err) ->
		if err
			res._cc.fail 'Unable to get customer', {}, err
		return

controller.truncate = (req, res) ->
	if req.app.get('config').env is not 'development'
		res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
		return
	else
		customers = req.app.models.customer
		customers.query 'TRUNCATE TABLE customers', (err) ->
			if err
				return res._cc.fail 'Unable to truncate customers', {}, err
			res._cc.success()
			return
	return

# Format customer to only include public data
formatAlias = (req, customer) ->
	result =
		customer: customer.src_name
		domain: customer.dest_domain
		email: customer.dest_email
	# If authorized, also return additional data
	if req.headers['api-secret'] is req.app.get('config').secret_keys.api_secret
		result.customer_secret = customer.customer_secret
	result

module.exports = controller