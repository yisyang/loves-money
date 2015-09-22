class SubdomainHandler
	@createRoutes: (subdomain, routerFn) ->
		# Make sure subdomain is defined correctly
		if typeof subdomain is "undefined"
			subdomain = ''
		else if typeof subdomain isnt "string"
			throw new Error("The first parameter must be a string representing the subdomain")

		# Make sure routerFn is defined correctly
		if not routerFn or typeof routerFn isnt "function" or routerFn.length < 3
			throw new Error("The second parameter must be a function that handles fn(req, res, next) params.")

		(req, res, next) ->
			# Prepare cache if not available
			if typeof (req.__subdomainEvaluationResults) is "undefined"
				req.__subdomainEvaluationResults = {}

			# Try to use cache results
			if typeof (req.__subdomainEvaluationResults[subdomain]) isnt "undefined"
				pass = req.__subdomainEvaluationResults[subdomain]
				evaluated = true
			else
				pass = false
				evaluated = false

			# Auto pass when not using subdomain
			if !evaluated
				if !subdomain.length and
				(!req.subdomains.length or (req.subdomains.length is 1 and req.subdomains[0] is 'www'))
					pass = true
					evaluated = true

			# Attempt to match subdomain
			if !evaluated
				subdomainSplit = subdomain.split(".")
				len = subdomainSplit.length

				#url - v2.api.example.dom
				#subdomains == ['api', 'v2']
				#subdomainSplit = ['v2', 'api']
				i = 0
				pass = true
				evaluated = true

				while i < len
					expected = subdomainSplit[len - (i + 1)]
					actual = req.subdomains[i]
					continue	if expected is "*"
					if actual isnt expected
						pass = false
						break
					i++

			# Evaluated at this point, transfer evaluation results
			req.__subdomainEvaluationResults[subdomain] = pass

			# Return correct router function on pass, or skip to next middleware
			if pass
				return routerFn(req, res, next)
			else
				next()

			return

module.exports = SubdomainHandler