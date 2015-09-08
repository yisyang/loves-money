###
CC JS Helpers

Copyright (c) 2015 Scott Yang

Dependencies:
CC Core (cc.core.js)
jQuery (Ver 1.11+)
###
((global) ->
	"use strict"

	###
	Verify that CSS file is loaded and alternatively load from local source

	@param {String} filename File name of remotely loaded CSS
    @param {String} localpath Local path of css file

	Example:
	CC = new CarCrashSingletonClass({foo: 'bar'})
	CC.verifyCssRequire('some.css.file.css', '/vendor/somewhere/some.css.file.css')
	###
	global.CarCrashSingletonClass::verifyCssRequire = (filename, localpath) ->
		$.each document.styleSheets, (i, sheet) ->
			if sheet.href.substring(0 - filename.length) is filename
				rules = (if sheet.rules then sheet.rules else sheet.cssRules)
				if rules.length is 0
					$("<link />")
					.attr(
						rel: "stylesheet"
						type: "text/css"
						href: localpath
					)
					.appendTo("head")
			return
		return

	return

) window