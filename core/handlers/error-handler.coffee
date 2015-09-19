_ = require('lodash')

ErrorHandler = {}


ErrorHandler.createError = (msg, params) ->
	err = new Error(msg)
	_.assign(err, params) if params
	err.status = err.status or 500

	return err

ErrorHandler.displayError = (res, err, env) ->
	# Depending on app environment, send simple error or full stack trace
	if env is "development" then errDisplay = err
	else errDisplay = { status: err.status, message: err.message }

	# Send error
	res.status err.status or 500
	res.render "error",
		title: 'Error'
		error: errDisplay
	return


ErrorHandler.createAppError = (msg, params) ->
	(req, res, next) ->
		err = ErrorHandler.createError(msg, params)
		next err
		return

ErrorHandler.displayAppError = (errOverwrite) ->
	(err, req, res, next) ->
		if errOverwrite then err = errOverwrite

		ErrorHandler.displayError(res, err, req.app.get('config').env)
		return


ErrorHandler.renderRouterError = (msg, params) ->
	(req, res) ->
		err = ErrorHandler.createError(msg, params)
		ErrorHandler.displayError(res, err, req.app.get('config').env)
		return


ErrorHandler.displayResErrorFactory = (res, env) ->
	(err) ->
		ErrorHandler.displayError(res, err, env)
		return

ErrorHandler.renderResErrorFactory = (res, env) ->
	(msg, params) ->
		err = ErrorHandler.createError(msg, params)
		ErrorHandler.displayError(res, err, env)
		return

ErrorHandler.resRenderer = (req, res, next) ->
	res._cc = {} unless res._cc
	res._cc.displayError = ErrorHandler.displayResErrorFactory(res, req.app.get('config').env)
	res._cc.renderError = ErrorHandler.renderResErrorFactory(res, req.app.get('config').env)
	res._cc.success = (jsonBody) ->
		if jsonBody?
			res.json { success: true, data: jsonBody }
		else
			res.json { success: true }
		res.end()
		return
	res._cc.fail = (message, httpStatus = 400, jsonBody, err) ->
		res.status(httpStatus)

		output = { success: false, message: message }
		if req.app.get('config').env is 'development' and err?
			output.error = err
		if jsonBody?
			output.data = jsonBody

		res.json output
		res.end()
		return
	next()
	return


module.exports = ErrorHandler