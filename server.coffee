browserify = require('browserify-middleware')
express = require('express')
path = require('path')
favicon = require('serve-favicon')
_ = require('lodash')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
MultiViews = require('multi-views')
config = require('./config/config.js')
ErrorHandler = require('./core/handlers/error-handler.js')
CorsHandler = require('./core/handlers/cors-handler.js')
DynamicViewsHandler = require('./core/handlers/dynamic-views-handler.js')
ModelsLoader = require('./core/loaders/waterline-loader.js')
RoutesLoader = require('./core/loaders/routes-loader.js')
MiddlewaresLoader = require('./app/middlewares/loader.js')

app = express()

# Replace default express message with a more interesting one
app.disable('x-powered-by')
app.use (req, res, next) ->
	res.setHeader('X-Powered-By', 'Endless river of sweat and tears')
	next()
	return

# Block coffee files from direct access
app.use '*.coffee', (req, res, next) ->
	console.log("[Blocked] Access to coffeescript %s %s", req.method, req.url)
	err = ErrorHandler.createError('Forbidden', { status: 403 })
	next err
	return

# Add static routes
app.use "/public", express.static path.join(__dirname, 'public')
app.use "/core", express.static path.join(__dirname, 'public', 'core')
app.use "/vendor", express.static path.join(__dirname, 'public', 'vendor')
app.use "/js", express.static path.join(__dirname, 'public', config.appDir, 'js')
app.use "/css", express.static path.join(__dirname, 'public', config.appDir, 'css')
app.use "/img", express.static path.join(__dirname, 'public', config.appDir, 'img')
app.use "/partials", express.static path.join(__dirname, 'public', config.appDir, 'partials')
app.use "/templates", express.static path.join(__dirname, 'public', config.appDir, 'templates')

# Load and save configs
app.set 'config', config

# Register middlewares used in routes (or elsewhere)
MiddlewaresLoader.registerMiddlewares(app)

# Take care of customer defined redirects (example.loves.money to www.example.com)
app.use app.get('middlewares')['redirector']

# Send favicon
app.use favicon path.join(__dirname, 'public', config.appDir, 'img', 'favicon.ico')

# Read cookie
app.use cookieParser()

# Read post request and non-multi-part form data
app.use bodyParser.json({ extended: false })
app.use bodyParser.urlencoded({ extended: false })

# Allow CORS for non-static resources
app.use CorsHandler.allowDomain('*')

# Allow res to use the Error Handler through res._cc.renderError, cc standards for CarCrash, the name of the framework
app.use ErrorHandler.resRenderer

# Load Waterline ORM
ModelsLoader.initialize(app, config.db)

# View engine setup
MultiViews.setupMultiViews(app)
DynamicViewsHandler.setupViews(app, [
	path.join(__dirname, config.appDir, 'views', 'default')
	path.join(__dirname, 'core', 'views', 'default')
])

# TODO: clean up
# Now that the views are ready, send all unresolved static routes directly to 404
app.use "/public", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/core", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/vendor", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/js", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/css", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/img", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/partials", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }
app.use "/templates", ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }

# Start logging
app.use logger(if config.env is 'development' then 'dev' else 'tiny')

# Add UI and API routes
RoutesLoader.loadRoutes path.join(__dirname, config.appDir, 'routes')
RoutesLoader.registerRoutes app

views = app.get 'views'

# Catch 404 and forward to error handler
app.use ErrorHandler.createAppError 'Not Foundx', { status: 404 }

# Do error reporting
app.use ErrorHandler.displayAppError()

module.exports = app