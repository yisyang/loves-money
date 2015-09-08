###
CC API JS Helper

Copyright (c) 2015 Scott Yang

Dependencies:
CC Core (cc.core.js)
CC Prompt (cc.prompt.js)
jQuery (Ver 1.11+)
Q (Ver 1.x)
###
((global) ->
	"use strict"

	###
	Posts to CC API

	@param params JSON object of key => value
	@return Promise

	Example:
	CC = new CarCrashSingletonClass({foo: 'bar'})
	CC.api({'method': 'POST', 'action': '/user/login', 'data': {'user': 'guest', 'password': 'pass'}})
	###
	global.CarCrashSingletonClass::api = (params) ->
		me = this
		deferred = Q.defer()
		$.ajax
			type: params.method
			url: params.action
			data: params.data
			dataType: "json"
			cache: false
			success: (resp) ->
				if typeof (resp.success) isnt "undefined" and resp.success
					deferred.resolve(resp)
				else
					apiError = me.composeApiError(resp)
					deferred.reject(apiError)
				return
			error: (xhr, textStatus, errorThrown) ->
				error = new Error("Network request failed.")
				error.textStatus = textStatus
				error.errorThrown = errorThrown
				deferred.reject(error)
				return
		return

	###
	Compose AJAX error message using resp.errors

	@param resp Ajax response
	###
	global.CarCrashSingletonClass::composeApiError = (resp) ->
		if typeof (resp.errors) isnt "undefined" and resp.errors
			displayedError = "API errors occurred: <br>"
			for error in resp.errors
				displayedError += error.code + ": " + error.message + "<br>"
		else
			# Show generic error
			displayedError = "General API error occurred."
		displayedError

	return

) window