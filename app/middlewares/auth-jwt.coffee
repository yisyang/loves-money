eh = require('../../core/handlers/error-handler.js')
jwt = require('jsonwebtoken')

class AuthJwt
	# Static method for verifying JWT tokens using req.header
	@verify: (req, res, next) ->
		# Get token from request header
		if req.headers.authorization?.substring(0, 7) isnt 'Bearer '
			res._cc.fail 'Invalid credentials', 401
			return
		token = req.headers.authorization?.substring(7)

		# Parse token, store result
		try
			parsed = jwt.verify(token, req.app.get('config').jwt.secret)
			req.app.set 'user', parsed

			next()
		catch err
			if err.name is 'TokenExpiredError'
				res._cc.fail 'Token expired', 401, null, err
			else
				res._cc.fail 'Invalid credentials', 401, null, err
		return

	# Convenience middleware for guarding a route to admins only, must be used after @verify
	@verifyAdmin: (req, res, next) ->
		currentUser = req.app.get 'user'
		if !currentUser?.isAdmin
			res._cc.fail 'Not authorized', 401
			return

		next()
		return

module.exports = AuthJwt