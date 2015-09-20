walk = require('fs-walk')
path = require("path")

# Get factory
RoutesGroupFactory = require('../factories/router-factory.js')

class RoutesLoader
	# Prepare routes holder
	@routers: []

	# Load router groups
	# Register routes by loading every json file in routesDir
	@loadRoutes = (routesDir) ->
		walk.walkSync routesDir, (basedir, filename, stat) ->
			re = /(?:\.([^.]+))?$/
			# Skip directories and files beginning with _
			if (filename.indexOf(".") isnt 0) and (filename.indexOf("_") isnt 0) and (re.exec(filename)[1] is "json")
				RoutesLoader.routers.push RoutesGroupFactory.createRouter path.join(basedir, filename)
		RoutesLoader

	# Add routes to server
	@registerRoutes = (app) ->
		for own key, router of this.routers
			router.registerRoutes app
		return

module.exports = RoutesLoader