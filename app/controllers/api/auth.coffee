jwt = require('jsonwebtoken')

controller = {}

controller.postLogin = (req, res) ->
	if req.body.user is 1 and req.body.pw is 2
		user = {
			foo: 'bar'
			hello: 'world'
		}
	if !user?
		res._cc.fail "Invalid credentials."

	# User logged in, issue JWT
	token = jwt.sign(user, req.app.get('config').secret_keys.jwt_secret);
	res._cc.success token
	return

controller.getRefresh = (req, res) ->
	# At this point credentials are verified by middleware, simply re-issue JWT using existing claims from req.user
	token = jwt.sign(req.user, req.app.get('config').secret_keys.jwt_secret);
	res._cc.success token
	return

module.exports = controller