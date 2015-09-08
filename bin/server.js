#!/usr/bin/env node
var app = require('../server.js');
var path = require("path");
var https = require('https');
var http = require('http');
var fs = require('fs');
var server;

var config = app.get('config');
if (!config.https || !config.https.enabled) {
	server = http.createServer(app);
} else {
	var options = {
		key: fs.readFileSync(path.join(__dirname, '..', 'config', config.https.key)),
		cert: fs.readFileSync(path.join(__dirname, '..', 'config', config.https.cert))
	};
	server = https.createServer(options, app);
}
server.listen(app.get('config').port, function () {
	console.log('Express server listening on port ' + server.address().port);
});