browserify = require('browserify-middleware');
express = require('express')
path = require('path')
favicon = require('serve-favicon')
multiViews = require('multi-views')
_ = require('lodash')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
#multer = require('multer')
config = require('./config/config.js')
eh = require('./core/handlers/error-handler.js')
DynamicViewsHandler = require('./core/handlers/dynamic-views-handler.js')
AuthJwt = require('./app/middlewares/auth-jwt.js')
app = express()

# Load and save config
app.set 'config', config

# Register middlewares used in routes (or elsewhere)
middlewares = {
	'jwt-verify': AuthJwt.verify
}
app.set 'middlewares', middlewares

# Replace default express message with a more interesting one
app.disable('x-powered-by')
app.use (req, res, next) ->
	res.setHeader('X-Powered-By', 'Endless river of sweat and tears')
	next()
	return

# Block coffee files from direct access
app.use '*.coffee', (req, res, next) ->
	console.log("[Blocked] Access to coffeescript %s %s", req.method, req.url)
	err = eh.createError('Not Found', { status: 404 })
	next(err)

# Add static routes
app.use "/public", express.static path.join(__dirname, 'public')
app.use "/core", express.static path.join(__dirname, 'public', 'core')
app.use "/vendor", express.static path.join(__dirname, 'public', 'vendor')
app.use "/js", express.static path.join(__dirname, 'public', config.appDir, 'js')
app.use "/css", express.static path.join(__dirname, 'public', config.appDir, 'css')
app.use "/img", express.static path.join(__dirname, 'public', config.appDir, 'img')
app.use "/partials", express.static path.join(__dirname, 'public', config.appDir, 'partials')
app.use "/templates", express.static path.join(__dirname, 'public', config.appDir, 'templates')

# Take care of customer defined redirects (example.loves.money to www.example.com)
lovesMoneyRedirector = require('./app/middlewares/redirector.js')
app.use lovesMoneyRedirector

# Send favicon
app.use favicon path.join(__dirname, 'public', config.appDir, 'img', 'favicon.ico')

# Read cookie
app.use cookieParser()

# Read post request and non-multi-part form data
app.use bodyParser.json({ extended: false })
app.use bodyParser.urlencoded({ extended: false })

# Parse request body and files - should only be used on pages that need it, and with manual clean up
#app.use multer({ dest: path.join(__dirname, 'uploads', config.appDir, config.env) })

# Allow CORS for non-static resources
allowDomain = require('./core/handlers/cors-handler.js')
app.use allowDomain('*')

# Allow res to use the Error Handler through res._cc.renderError, cc standards for CarCrash, the name of the framework
app.use eh.resRenderer

# Load Waterline ORM
modelsLoader = require('./core/loaders/waterline-loader.js')
if typeof(modelsLoader.updateAdapters) is 'function'
	config.db = modelsLoader.updateAdapters config.db

modelsLoader.loadModels path.join(__dirname, config.appDir, 'schema', 'waterline')
modelsLoader.orm.initialize config.db, (err, models) ->
	throw err if err
	app.models = models.collections
	app.connections = models.connections

# View engine setup
multiViews.setupMultiViews(app)
DynamicViewsHandler.setupViews(app, [
	path.join(__dirname, config.appDir, 'views', 'default')
	path.join(__dirname, 'core', 'views', 'default')
])

# TODO: clean up
# Send all static routes to 404 page
app.use "/public", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/core", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/vendor", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/js", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/css", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/img", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/partials", eh.displayAppError eh.createError 'Not Found', { status: 404 }
app.use "/templates", eh.displayAppError eh.createError 'Not Found', { status: 404 }

# Start logging
app.use logger(if config.env is 'development' then 'dev' else 'tiny')

# Add UI and API routes
routesLoader = require('./core/loaders/routes-loader.js')
routesLoader.loadRoutes path.join(__dirname, config.appDir, 'routes')
routesLoader.registerRoutes app

views = app.get 'views'

# Catch 404 and forward to error handler
app.use eh.createAppError 'Not Found', { status: 404 }

# Do error reporting
app.use eh.displayAppError()

module.exports = app