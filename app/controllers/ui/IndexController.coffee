class IndexController
	@index: (req, res) ->
		res.render "index"
		return

	@about: (req, res) ->
		res.render "about"
		return

	@contact: (req, res) ->
		res.render "contact"
		return

	@demo: (req, res) ->
		res.render "demo"
		return

	@pricing: (req, res) ->
		res.render "pricing"
		return


module.exports = IndexController