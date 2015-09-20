eh = require('../../core/handlers/error-handler.js')
AuthJwt = require('./auth-jwt.js')
lovesMoneyRedirector = require('./redirector.js')

middlewares = {
	'jwt-verify': AuthJwt.verify
	'jwt-verify-admin': AuthJwt.verifyAdmin
	'redirector': lovesMoneyRedirector
}

module.exports = middlewares