###
CC API JS Helper

Copyright (c) 2015 Scott Yang

Dependencies:
CC Core (cc.core.js)
jQuery (Ver 1.11+)
Q (Ver 1.x)
###
((global) ->
	"use strict"

	class rjDialog

		###
		Show alert

		@param params JSON options
            header Header text
            content Body html

		Example:
		CC = new CarCrashSingletonClass({foo: 'bar'})
		CC.dialog.alert "error"
		###
		@alert: (params) ->
			params = rjDialog.parseDomParamsMessage params
			$domObj = rjDialog.parseDomParams params

			rjDialog.displayHtml $domObj

			return

		###
        Gets confirmation

        @params params JSON options
            header Header text
            content Body html
            input Input with .title and .value properties
		###
		@prompt = (params) ->
			params = rjDialog.parseDomParamsMessage params

			if !params.input
				$.extend(params, rjDialog.getDefaultPromptInput())

			$domObj = rjDialog.parseDomParams params

			rjDialog.displayHtml $domObj

			$domObj.data 'input-promise'

		###
        Gets confirmation

        @params params JSON options
            header Header text
            content Body html
            buttons Buttons with .title and .value properties
		###
		@confirm = (params) ->
			if params is undefined
				params = 'Are you sure?'
			params = rjDialog.parseDomParamsMessage params

			if !params.buttons
				$.extend(params, rjDialog.getDefaultConfirmButtons())

			$domObj = rjDialog.parseDomParams params

			rjDialog.displayHtml $domObj

			$domObj.data 'button-promise'

		# TODO: flesh out various methods - popupIframe, popupGallery, ...

		@displayHtml: ($domObj) ->
			$domObj
				.modal('show')

			return

		@getDefaultPromptInput = ->
			{
				input: {
					title: 'Enter text'
					value: ''
				}
			}

		@getDefaultConfirmButtons = ->
			{
				buttons: [
					{
						title: 'OK'
						value: 1
						class: 'green'
					}
					{
						title: 'Cancel'
						value: 0
						class: 'red'
					}
				]
			}

		@parseDomParamsMessage = (params) ->
			# Fix undefined
			if !params?
				params = 'Message'
			else if typeof params isnt "string" and !params.content?
				params.content = '<p>' + 'Message' + '</p>'
			if typeof params is "string"
				domParams = {
					content: '<p>' + params + '</p>'
				}
			else
				domParams = params
			domParams

		@parseDomParams = (domParams) ->
			# Create jquery dom obj
			$domObj = $('<div>').addClass('ui modal')

			# Add close button
			$domObj.append(
				$('<i>').addClass('icon close')
			)

			# Add header if available
			if domParams.header
				$domObj.append(
					$('<div>').addClass('header').html(domParams.header)
				)

			# Ready content
			$content = $('<div>').addClass('content').html(domParams.content)

			# Add inputs if available
			if domParams.input
				deferred = Q.defer()
				#TODO: Update input css
				domParams.input.placeholder = '' if !domParams.input.placeholder?
				domParams.input.value = '' if !domParams.input.value?
				$input = $('<div>').addClass('ui input').append(
					$('<input>').attr(
						placeholder: domParams.input.placeholder
						type: "text"
					).val(domParams.input.value)
				)
				if domParams.input.label
					$input.addClass 'labeled'
					$input = $('<div>').addClass('field').append(
						$('<label>').text(domParams.input.label)
					).append(
						$input
					)
				$content.append $input

			# Add content
			$domObj.append $content

			# Add submission button for input
			if domParams.input
				$buttons = $('<div>').addClass('actions').append(
					$('<div>').addClass('ui button green').text('Submit').on('click', ->
						deferred.resolve($(this).parents('.ui.modal').find('.ui.input > input').eq(0).val())
						return
					)
				)
				$domObj.append $buttons
				$domObj.data 'input-promise', deferred.promise

			# Add buttons if available
			if domParams.buttons
				deferred = Q.defer()
				$buttons = $('<div>').addClass('actions')
				for button in domParams.buttons
					$button = $('<div>').addClass('ui button').text(button.title).data(
						value: button.value
					).on('click', ->
						deferred.resolve $(this).data('value')
						return
					)
					if button.class
						$button.addClass button.class
					$buttons.append $button

				$domObj.append $buttons
				$domObj.data 'button-promise', deferred.promise

			# Return
			$domObj


	global.CarCrashSingletonClass::Dialog = rjDialog

	return

) window