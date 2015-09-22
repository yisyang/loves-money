eh = require('../../core/handlers/error-handler.js')

# Domain redirect service
redirector = (req, res, next) ->
	if req.headers.host and req.headers.host not in ['loves.money', 'www.loves.money', 'api.loves.money']
		requestAlias = req.headers.host.replace(/\.loves\.money$/, '')

		aliases = req.app.getModel('DomainAlias')
		aliases.findOne { srcName: requestAlias }, (err, alias) ->
			# Error
			if err
				err = eh.createError('Unable to get alias', { status: 500 })
				next(err)
			# Alias found, simply redirect user
			if alias
				if alias.destDomain.match(/^(ht|f)tps?:\/\//)
					res.redirect alias.destDomain
				else
					res.redirect 'http://' + alias.destDomain
			# Not found
			else
				err = eh.createError('Alias not found', { status: 404 })
				next(err)
			return
	else
		next()
	return

module.exports = redirector