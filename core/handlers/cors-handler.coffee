class CorsHandler

	@allowDomain: (domain) ->
		# Make sure domain is defined correctly
		if typeof domain is "undefined" or domain is ''
			throw new Error "The first parameter must be a string representing the domain"

		(req, res, next) ->
			res.header 'Access-Control-Allow-Origin', domain
			res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
			res.header 'Access-Control-Allow-Headers', 'Content-Type'

			next()

			return

module.exports = CorsHandler