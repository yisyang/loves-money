class IndexController

	@getIndex: (req, res) ->
		res._cc.fail "Invalid route, please use the UI at loves.money or view github source for valid requests."
		return

module.exports = IndexController