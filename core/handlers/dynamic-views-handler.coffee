_ = require('lodash')
path = require('path')

ViewsHandler = {}

ViewsHandler.setupViews = (app, views) ->
	console.log "Setting up multi-views"

	app.set 'views', views
	app.set 'multiViewsBase', views

	console.log "Using jade templating language"
	# Prettify jade
	if app.get('config').env is 'development'
		console.log " - using pretty mode"
		app.locals.pretty = true
	app.set 'view engine', 'jade'

	# Allow res to add more views dynamically
	app.use (req, res, next) ->
		res._cc = {} unless res._cc
		res._cc.resetViewPath = ->
			viewsCore = app.get 'multiViewsBase'
			views = _.cloneDeep(viewsCore)
			app.set 'views', views
		res._cc.addViewPath = (viewPath) ->
			views = app.get 'views'
			config = app.get 'config'
			views.unshift(path.join(__dirname, '..', '..', config.appDir, viewPath))
		next()
		return

	return

ViewsHandler.attachControllerViews = (viewPath, routerFn) ->
	# Make sure view path is defined correctly
	addLocalPath = true
	if typeof viewPath is "undefined" or viewPath is false
		addLocalPath = false
	else if typeof viewPath isnt "string"
		throw new Error("The first parameter must be a string representing the view path")

	# Make sure routerFn is defined correctly
	if not routerFn or typeof routerFn isnt "function" or routerFn.length < 3
		throw new Error("The second parameter must be a function that handles fn(req, res, next) params.")

	(req, res, next) ->
		# Always reset to core view paths
		res._cc.resetViewPath()

		# Add local view path
		if(addLocalPath)
			res._cc.addViewPath(viewPath)

		# Proceed with rest of function
		routerFn(req, res, next)

module.exports = ViewsHandler