###
CC Core JS Helper

Copyright (c) 2015 Scott Yang

Dependencies:
jQuery (Ver 1.11+)
###
((global) ->
	"use strict"
	global.CarCrashSingletonClass = (options) ->

		# Check for singleton
		me = undefined
		if CarCrashSingletonClass::_singletonInstance
			me = CarCrashSingletonClass::_singletonInstance
		else
			me = CarCrashSingletonClass::_singletonInstance = this
			me.config = {}

		# Extend custom config
		$.extend me.config, options
		me

	return
) window