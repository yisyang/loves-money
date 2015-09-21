class IndexController
	@index = (req, res) ->
		res.render "index",
			title: "loves.money - BETA - domain and email forwarding service"
		return

module.exports = IndexController