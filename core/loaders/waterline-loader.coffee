walk = require('fs-walk')
path = require("path")
Waterline = require('waterline')
WaterlineMysqlAdapter = require('sails-mysql')

class ModelsLoader

	# Instantiate a new instance of the ORM
	@orm: new Waterline

	@initialize: (app, dbConfig) ->
		dbConfig = ModelsLoader.updateAdapters dbConfig
		ModelsLoader.loadModels path.join(__dirname, '..', '..', dbConfig.modelsPath)
		ModelsLoader.orm.initialize dbConfig, (err, models) ->
			throw err if err
			app.models = models.collections
			app.connections = models.connections
		# At the time of creation, Waterline v0.10.18 internally converts models to lowercase
		app.getModel = (name) ->
			return app.models[name.toLowerCase()]

	# Update config
	@updateAdapters: (dbConfig) ->
		console.log('Updating DB adapters')
		for own key, adapter of dbConfig.adapters
			if adapter is 'mysqlAdapter'
				dbConfig.adapters[key] = WaterlineMysqlAdapter
		dbConfig

	# Initialize ORM and map schema
	@loadModels: (modelsDir) ->
		# Load model definitions
		console.log('Loading models')
		walk.walkSync modelsDir, (basedir, filename, stat) ->
			re = /(?:\.([^.]+))?$/
			# Skip directories and files beginning with _
			if (filename.indexOf(".") isnt 0) and (filename.indexOf("_") isnt 0) and (re.exec(filename)[1] is "json")
				console.log(' - ' + filename)
				schemaJson = require(path.join(basedir, filename))
				ModelsLoader.orm.loadCollection(Waterline.Collection.extend(schemaJson))
		ModelsLoader

module.exports = ModelsLoader