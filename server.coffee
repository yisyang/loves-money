express = require('express')
path = require('path')
favicon = require('serve-favicon')
_ = require('lodash')
logger = require('morgan')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
MultiViews = require('multi-views')
config = require('./config/config.js')
CorsHandler = require('./core/handlers/cors-handler.js')
DynamicViewsHandler = require('./core/handlers/dynamic-views-handler.js')
ModelsLoader = require('./core/loaders/waterline-loader.js')
RoutesLoader = require('./core/loaders/routes-loader.js')
ErrorHandler = require('./app/handlers/ErrorHandler.js')
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
staticRoutes = [
	{ src: '/public', dest: path.join(__dirname, 'public') }
	{ src: '/core', dest: path.join(__dirname, 'public', 'core') }
	{ src: '/vendor', dest: path.join(__dirname, 'public', 'vendor') }
	{ src: '/js', dest: path.join(__dirname, 'public', config.appDir, 'js') }
	{ src: '/css', dest: path.join(__dirname, 'public', config.appDir, 'css') }
	{ src: '/img', dest: path.join(__dirname, 'public', config.appDir, 'img') }
	{ src: '/partials', dest: path.join(__dirname, 'public', config.appDir, 'partials') }
	{ src: '/templates', dest: path.join(__dirname, 'public', config.appDir, 'templates') }
]
for staticRoute in staticRoutes
	app.use staticRoute.src, express.static staticRoute.dest

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

# Now that the views are ready, send all unresolved static routes directly to 404
for staticRoute in staticRoutes
	app.use staticRoute.src, ErrorHandler.displayAppError ErrorHandler.createError 'Not Found', { status: 404 }

# Start logging
app.use logger(if config.env is 'development' then 'dev' else 'tiny')

# Add UI and API routes
RoutesLoader.loadRoutes path.join(__dirname, config.appDir, 'routes')
RoutesLoader.registerRoutes app

views = app.get 'views'

# Catch 404 and forward to error handler
app.use ErrorHandler.createAppError 'Not Found', { status: 404 }

# Do error reporting
app.use ErrorHandler.displayAppError()

module.exports = app