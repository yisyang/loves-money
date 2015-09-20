hmacSha1 = require('crypto-js/hmac-sha1')
jwt = require('jsonwebtoken')

class AuthController

	@postLogin: (req, res) ->
		# Verify that everythng needed have been provided
		if !req.body.email || !req.body.pwHash
			res._cc.fail 'Missing credentials', 401
			return

		# Search for customer by email and attempt to authenticate
		req.app.getModel('Customer').findOne().where({ email: req.body.email })
		.then (customer) ->
			# Customer found, try to match pw
			if customer and req.body.pwHash
				providedPwHash = hmacSha1(req.body.pwHash, customer.id + req.app.get('config').secret_keys.db_hash).toString()
				if providedPwHash is customer.pwHash
					return customer
			false
		.then (customer) ->
			if !customer
				throw new Error('Customer not found or bad password')

			# User logged in, issue JWT
			appConfig = req.app.get('config')
			token = jwt.sign(formatCustomer(customer), appConfig.jwt.secret, {
				expiresInMinutes: appConfig.jwt.expire_minutes
			})
			res._cc.success token
			return
		.catch (err) ->
			if err
				res._cc.fail 'Invalid credentials', 401, null, err
				return
			return

		return

	@getRefresh: (req, res) ->
		currentUser = req.app.get 'user'

		# At this point credentials are verified by middleware, simply re-issue JWT using existing claims from req.user
		appConfig = req.app.get('config')
		token = jwt.sign(currentUser, appConfig.jwt.secret, {
			expiresInMinutes: 1
		})
		res._cc.success token
		return

# Format customer to only include public data
formatCustomer = (customer) ->
	{
		id: customer.id
		name: customer.name
		email: customer.email
	}

module.exports = AuthController