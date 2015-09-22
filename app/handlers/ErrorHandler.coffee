ErrorHandler = require('../../core/handlers/error-handler.js')

class LmErrorHandler extends ErrorHandler
	@resRenderer = (req, res, next) ->
		# Call parent method with dummy closure to avoid having it call next()
		super req, res, () ->
			return

		# Design app success and fail shortcuts... for this app it's just the core methods
		res.success = res._cc.success
		res.fail = res._cc.fail

		next()
		return

module.exports = LmErrorHandler