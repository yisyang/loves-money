express = require('express')
SubdomainsHandler = require('../handlers/subdomain-handler.js')
DynamicViewsHandler = require('../handlers/dynamic-views-handler.js')

# Define factory
RoutesGroupFactory = {}
RoutesGroupFactory.createRouter = (file) ->
	# Read file
	routesConfig = require(file)

	# Object to add routes to app
	router = {}
	router.registerRoutes = (app) ->
		# Object to hold included routes
		routes = {}
		config = app.get 'config'

		# Build routes
		for own key, routesGroup of routesConfig.routesGroups
			controllerFileName = routesGroup.controller

			# Auto-include necessary files
			if not routes[controllerFileName]?
				controllerRouter = express.Router()
				controllerMethods = require('../../' + config.appDir + '/' + routesConfig.controllerPath + '/' + controllerFileName)
				controllerRouter.controllerMethods = controllerMethods
				routes[controllerFileName] = controllerRouter

				# Apply dynamic view to controller if applicable
				if routesConfig.viewPath
					routesController = DynamicViewsHandler.attachControllerViews(routesConfig.viewPath, routes[controllerFileName])
				else
					routesController = DynamicViewsHandler.attachControllerViews(false, routes[controllerFileName])

			# Build routes
			for own key, route of routesGroup.routes
				try
					routes[controllerFileName][route.method](route.url, routes[controllerFileName]['controllerMethods'][route.handler])
				catch error
					console.log('Error registering route ' + route.handler + '.' + route.method)
					throw error

			# Register routes to app and subdomain
			routesConfig.subdomain = '' if !routesConfig.subdomain?
			app.use routesGroup.prefix, SubdomainsHandler(routesConfig.subdomain, routesController)

		true

	# Return the routes group object
	router

# Export factory
module.exports = RoutesGroupFactory