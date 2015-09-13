hmacSha1 = require('crypto-js/hmac-sha1')
sha1 = require('crypto-js/sha1')

controller = {}

controller.index = (req, res) ->
	res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
	return

controller.getCustomer = (req, res) ->
	customers = req.app.models.customer
	customers.findOne { id: req.params.customer }, (err, customer) ->
		if err
			res._cc.fail 'Unable to get customer', {}, err
		if customer
			res._cc.success formatCustomer req, customer
		else
			res._cc.fail 'Customer not found'
		return
	return

controller.postCustomer = (req, res) ->
	# TODO: verify req.user is admin

	customers = req.app.models.customer

	# Prepare customer model data
	new_customer =
		name: req.body.name
		uuid: req.body.uuid
		# Apply server-side hasing on top of client-side transformed PW for DB storage
		pwHash: hmacSha1(req.body.pw_transformed, req.app.get('config').secret_keys.db_hash).toString()
		email: req.body.email

	# Attempt to create the customer
	customers.create new_customer
	# Customer successfully created
	.then (customer) ->
		res._cc.success formatCustomer req, customer
		return
	# Customer creation failed
	.catch (err) ->
		res._cc.fail 'Error creating customer', {}, err
		return
	return

controller.deleteCustomer = (req, res) ->
	# TODO: verify req.user is admin

	customers = req.app.models.customer
	# Attempt to delete customer
	customers.destroy { id: req.params.id }
	# Customer successfully deleted
	.then (customer) ->
		res._cc.success formatCustomer req, customer
		return
	# Customer deletion failed
	.catch (err) ->
		res._cc.fail 'Unable to delete customer', {}, err
		return
	return

# Format customer to only include public data
formatCustomer = (req, customer) ->
	result =
		name: customer.name
		uuid: customer.uuid
		email: customer.email
	# If authorized, also return additional data
	if req.headers['api-secret'] is req.app.get('config').secret_keys.api_secret
		result.customer_secret = customer.customer_secret
	result

module.exports = controller