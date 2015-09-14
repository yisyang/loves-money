hmacSha1 = require('crypto-js/hmac-sha1')
jwt = require('jsonwebtoken')

controller = {}

controller.postLogin = (req, res) ->
	# Verify that everythng needed have been provided
	if !req.body.email || !req.body.pw_hash
		res._cc.fail 'Missing credentials'
		return
	customers = req.app.models.customer
	customers.findOne().where({ email: req.body.email })
	.then (customer) ->
		# Customer found, try to match pw
		if customer and req.body.pw_hash
			providedPwHash = hmacSha1(req.body.pw_hash, customer.uuid + req.app.get('config').secret_keys.db_hash).toString()
			if providedPwHash is customer.pw_hash
				return customer
		false
	.then (customer) ->
		if !customer
			throw new Error('Customer not found or bad password')

		# User logged in, issue JWT
		token = jwt.sign(formatCustomer(customer), req.app.get('config').secret_keys.jwt_secret);
		res._cc.success token
		return
	.catch (err) ->
		if err
			res._cc.fail 'Invalid credentials', null, err
			return
		return

	return

controller.getRefresh = (req, res) ->
	# At this point credentials are verified by middleware, simply re-issue JWT using existing claims from req.user
	token = jwt.sign(req.user, req.app.get('config').secret_keys.jwt_secret);
	res._cc.success token
	return

# Format customer to only include public data
formatCustomer = (customer) ->
	result =
		uuid: customer.uuid
		name: customer.name
		email: customer.email
	result

module.exports = controller