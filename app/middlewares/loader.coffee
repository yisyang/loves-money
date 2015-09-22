eh = require('../../core/handlers/error-handler.js')
AuthJwt = require('./auth-jwt.js')
lovesMoneyRedirector = require('./redirector.js')

class MiddlewaresLoader

	@middlewares: {
		'jwt-verify': AuthJwt.verify
		'jwt-verify-admin': AuthJwt.verifyAdmin
		'redirector': lovesMoneyRedirector
	}

	@registerMiddlewares: (app) ->
		app.set 'middlewares', MiddlewaresLoader.middlewares

module.exports = MiddlewaresLoader