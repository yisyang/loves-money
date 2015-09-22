$(document).ready () ->

	### Button events ###

	# Change in lookup/add/remove
	$('.demo-menu').on 'click', '.item', () ->
		newRequestType = $(this).attr('data-value')

		# Mark selected item as active
		$('.demo-menu').children('.item').removeClass('active')
		$(this).addClass('active')

		# Replace button text
		$('.demo-submit-button').text($(this).text())

		if newRequestType is 'add'
			# Dig deeper
			$('input[name="alias-type"]').trigger('change')
		else
			# Hide whatever should be hidden
			$('input[name="domain"]').closest('.field').not('.hidden').transition('slide down')
			$('input[name="email"]').closest('.field').not('.hidden').transition('slide down')


	# Change in alias type
	$('input[name="alias-type"]').on 'change', () ->
		requestType = DemoPage.getFormRequestType()

		# Additional fields not needed
		if requestType isnt 'add'
			return

		# Show fields depending on alias type
		aliasType = DemoPage.getFormAliasType()
		if aliasType is 'domain'
			# If incorrect elements are shown, hide them first, then show correct elements
			if $('input[name="email"]').closest('.field').not('.hidden').length
				$('input[name="email"]').closest('.field').not('.hidden').transition('slide down', () ->
					$('input[name="domain"]').closest('.field.hidden').transition('slide down')
				)
			else
				$('input[name="domain"]').closest('.field.hidden').transition('slide down')
		else if aliasType is 'email'
			if $('input[name="domain"]').closest('.field').not('.hidden').length
				$('input[name="domain"]').closest('.field').not('.hidden').transition('slide down', () ->
					$('input[name="email"]').closest('.field.hidden').transition('stop all').transition('slide down')
				)
			else
				$('input[name="email"]').closest('.field.hidden').transition('stop all').transition('slide down')

	# Main feature
	$('.demo-submit-button').click () ->
		requestType = DemoPage.getFormRequestType()
		aliasType = DemoPage.getFormAliasType()

		if requestType is 'lookup'
			if aliasType is 'domain'
				DemoPage.getDomainAlias()
			else if aliasType is 'email'
				DemoPage.getEmailAlias()
		else if requestType is 'add'
			if aliasType is 'domain'
				DemoPage.postDomainAlias()
			else if aliasType is 'email'
				DemoPage.postEmailAlias()
		else if requestType is 'remove'
			if aliasType is 'domain'
				DemoPage.deleteDomainAlias()
			else if aliasType is 'email'
				DemoPage.deleteEmailAlias()
		return

	### Demo page functions ###

	class DemoPage
		@jwt
		@apiDomain: (window.location.protocol || document.location.protocol) + '//api.loves.money/';

		@getFormRequestType: () ->
			$('.demo-menu .item.active').attr('data-value')

		@getFormAliasType: () ->
			$('input[name="alias-type"]').val()

		@getFormAlias: () ->
			$('input[name="alias"]').val()

		@getFormDomain: () ->
			$('input[name="domain"]').val()

		@getFormEmail: () ->
			$('input[name="email"]').val()

		@getDomainAlias: () ->
			alias = DemoPage.getFormAlias()

			DemoPage.rest 'GET', DemoPage.apiDomain + 'domain-aliases/' + alias
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		@postDomainAlias: () ->
			postData = {
				alias: DemoPage.getFormAlias()
				domain: DemoPage.getFormDomain()
			}

			DemoPage.login()
			.then () ->
				DemoPage.rest 'POST', DemoPage.apiDomain + 'domain-aliases/', postData
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		@deleteDomainAlias: () ->
			alias = DemoPage.getFormAlias()

			DemoPage.login()
			.then () ->
				DemoPage.rest 'DELETE', DemoPage.apiDomain + 'domain-aliases/' + alias
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		@getEmailAlias: () ->
			alias = DemoPage.getFormAlias()

			DemoPage.rest 'GET', DemoPage.apiDomain + 'email-aliases/' + alias
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		@postEmailAlias: () ->
			postData = {
				alias: DemoPage.getFormAlias()
				email: DemoPage.getFormEmail()
			}

			DemoPage.login()
			.then () ->
				DemoPage.rest 'POST', DemoPage.apiDomain + 'email-aliases/', postData
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		@deleteEmailAlias: () ->
			alias = DemoPage.getFormAlias()

			DemoPage.login()
			.then () ->
				DemoPage.rest 'DELETE', DemoPage.apiDomain + 'email-aliases/' + alias
			.then (resp) ->
				DemoPage.logResponse resp
				return
			.catch (err) ->
				DemoPage.logResponse err.responseJSON
				DemoPage.reportError err
				return
			return

		# Log in as demo user and return promise
		@login: () ->
			# Exit if already logged in
			if DemoPage.jwt
				return Promise.resolve()

			# Use hardcoded values for demo user
			postData = {
				email: 'demo' + '@loves.money'
				pwHash: LM.sha1('demo123')
			}

			# Log in
			DemoPage.rest 'POST', DemoPage.apiDomain + 'auth/login', postData
			.then (resp) ->
				DemoPage.jwt = resp.data
				return
			.catch (err) ->
				DemoPage.reportError err
				return

		@getAuthHeaders: () ->
			if DemoPage.jwt
				{
				Authorization: 'Bearer ' + DemoPage.jwt
				}
			else
				{}

		@rest: (method, url, body = {}) ->
			params = {
				method: method
				url: url
				data: body
				dataType: 'json'
				headers: DemoPage.getAuthHeaders()
			}

			Promise.resolve($.ajax(params))
			.then (resp) ->
				resp
			.catch (err) ->
				# If response is 401 with message "Token expired", we will login and try again
				if err.status is 401 and err.responseJSON.message in ["Invalid credentials", "Token expired"] and !body.noMoreRetries
					body.noMoreRetries = true
					DemoPage.jwt = null
					DemoPage.login()
					.then () ->
						# Retry original request
						DemoPage.rest(method, url, body)
				# Otherwise throw it around
				else
					throw err

		@logResponse: (resp) ->
			prettyJson = JSON.stringify(resp, null, '\t')
			$('.demo-response-holder').text(prettyJson)

		@reportError: if console?.log and Function.prototype.bind then Function.prototype.bind.call(console.log, console) else () ->
			return

	return