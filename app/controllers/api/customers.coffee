hmacSha1 = require('crypto-js/hmac-sha1')
sha1 = require('crypto-js/sha1')
uuid = require('uuid')

controller = {}

controller.index = (req, res) ->
	res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
	return

controller.getCustomer = (req, res) ->
	currentUser = req.app.get 'user'
	if currentUser.uuid isnt req.params.uuid and !currentUser.isAdmin
		res._cc.fail 'Not authorized', 401
		return

	customers = req.app.models.customer
	customers.findOne { uuid: req.params.uuid }, (err, customer) ->
		if err
			res._cc.fail 'Unable to get customer', 500, null, err
			return
		if customer
			res._cc.success formatCustomer customer
		else
			res._cc.fail 'Customer not found'
		return
	return

controller.postCustomer = (req, res) ->
	# Verify that everythng needed have been provided
	if !req.body.name || !req.body.email || !req.body.pw_hash
		res._cc.fail 'Missing required parameters'
		return

	# Verify that the email address is not taken
	customers = req.app.models.customer
	customers.findOne().where({ email: req.body.email })
	.then (customer) ->
		# Existing customer found
		if customer
			res._cc.fail 'Customer email is already in use by an ' + (if customer.active then 'active' else 'inactive') + ' customer', 500
			throw false
		return
	.then () ->
		# Inject/replace uuid and attempt to insert up to 3 times and return promise
		createCustomer req
	.then (customer) ->
		# Customer successfully created
		res._cc.success formatCustomer customer
		return
	.catch (err) ->
		if err
			res._cc.fail 'Error creating customer', 500, null, err
		return

	return

controller.deleteCustomer = (req, res) ->
	customers = req.app.models.customer
	# Attempt to delete customer by marking status as inactive
	customers.findOne { uuid: req.params.uuid, active: true }
	# Customer found
	.then (customer) ->
		customer.active = false
		customer.save()
	# Soft delete successful
	.then () ->
		res._cc.success()
		return
	# Deletion failed
	.catch (err) ->
		res._cc.fail 'Unable to delete customer', 500, null, err
		return
	return

# Format customer to only include public data
formatCustomer = (customer) ->
	result =
		uuid: customer.uuid
		name: customer.name
		email: customer.email
	result

createCustomer = (req, retriesLeft) ->
	# Although astronomically unlikely, it is still possible to have collisions on the UUID
	# for that reason we retry 3 times when adding a new customer
	if !retriesLeft?
		retriesLeft = 3

	# Prepare customer model data
	newCustomer =
		name: req.body.name
		email: req.body.email

	# Assign UUID to customer
	newCustomer.uuid = uuid.v4()
	# Apply server-side hasing on top of client-side PW hash for DB storage
	newCustomer.pw_hash = hmacSha1(req.body.pw_hash, newCustomer.uuid + req.app.get('config').secret_keys.db_hash).toString()

	# Attempt to add customer
	customers = req.app.models.customer
	customers.create newCustomer
	.then (customer) ->
		customer
	.catch (err) ->
		if retriesLeft <= 0
			throw err
		createCustomer req, retriesLeft - 1

module.exports = controller