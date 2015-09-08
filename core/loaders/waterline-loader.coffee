walk = require('fs-walk')
path = require("path")
Waterline = require('waterline')
WaterlineMysqlAdapter = require('sails-mysql')

# Prepare object
RoutesLoader = {}

# Instantiate a new instance of the ORM
RoutesLoader.orm = new Waterline

# Update config
RoutesLoader.updateAdapters = (dbConfig) ->
	console.log('Updating DB adapters')
	for own key, adapter of dbConfig.adapters
		if adapter is 'mysqlAdapter'
			dbConfig.adapters[key] = WaterlineMysqlAdapter
	dbConfig

# Initialize ORM and map schema
RoutesLoader.loadModels = (modelsDir) ->
	# Load model definitions
	console.log('Loading models')
	walk.walkSync modelsDir, (basedir, filename, stat) ->
		re = /(?:\.([^.]+))?$/
		# Skip directories and files beginning with _
		if (filename.indexOf(".") isnt 0) and (filename.indexOf("_") isnt 0) and (re.exec(filename)[1] is "json")
			console.log(' - ' + filename)
			schemaJson = require(path.join(basedir, filename))
			RoutesLoader.orm.loadCollection(Waterline.Collection.extend(schemaJson))
	RoutesLoader

module.exports = RoutesLoader