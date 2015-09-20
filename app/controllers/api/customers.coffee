hmacSha1 = require('crypto-js/hmac-sha1')
uuid = require('uuid')

controller = {}

controller.index = (req, res) ->
	res._cc.fail 'Invalid route, please use the UI at loves.money or view github source for valid requests.'
	return

controller.getCustomer = (req, res) ->
	currentUser = req.app.get 'user'
	if currentUser.id isnt req.params.id and !currentUser.isAdmin
		res._cc.fail 'Not authorized', 401
		return

	req.app.getModel('Customer').findOne { id: req.params.id }, (err, customer) ->
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
	if !req.body.name || !req.body.email || !req.body.pwHash
		res._cc.fail 'Missing required parameters'
		return

	# Verify that the email address is not taken
	req.app.getModel('Customer').findOne().where({ email: req.body.email })
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
	# Attempt to delete customer by marking status as inactive
	req.app.getModel('Customer').findOne { id: req.params.id, active: true }
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
		id: customer.id
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
	newCustomer.id = uuid.v4()
	# Apply server-side hasing on top of client-side PW hash for DB storage
	newCustomer.pwHash = hmacSha1(req.body.pwHash, newCustomer.id + req.app.get('config').secret_keys.db_hash).toString()

	# Attempt to add customer
	req.app.getModel('Customer').create newCustomer
	.then (customer) ->
		customer
	.catch (err) ->
		if retriesLeft <= 0
			throw err
		createCustomer req, retriesLeft - 1

module.exports = controller