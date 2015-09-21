$(document).ready () ->
	### Initialize ###

	$('.ui.dropdown').dropdown()


	### Demo functions ###

	# Change in lookup/add/remove
	$('.demo-menu').on 'click', '.item', () ->
		requestType = $(this).attr('data-value')

		# Mark selected item as active
		$('.demo-menu').children('.item').removeClass('active')
		$(this).addClass('active')

		# Replace button text
		$('.demo-submit-button').text($(this).text())

		if requestType is 'add'
			# Dig deeper
			$('input[name="alias-type"]').trigger('change')
		else
			# Hide whatever should be hidden
			$('input[name="domain"]').closest('.field').not('.hidden').transition('slide down')
			$('input[name="email"]').closest('.field').not('.hidden').transition('slide down')


	# Change in alias type
	$('input[name="alias-type"]').on 'change', () ->
		requestType = $('.demo-menu .item.active').attr('data-value')

		# Additional fields not needed
		if requestType isnt 'add'
			return

		# Show fields depending on alias type
		aliasType = $(this).val()
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


	### Helpers ###

	# Needs clean up... but will do for now
	showError = (msg) ->
		$('div.lm-error-modal').remove()
		errorModal = $('<div>')
			.addClass('ui small basic modal lm-error-modal')
			.html('
				<h1 class="ui header">
				    <i class="red warning circle icon"></i>
				    Error
				</h1>
				<div class="content">
				    <p>' + msg + '</p>
				</div>
				<div class="actions">
				    <div class="ui basic inverted button">
				        OK
				    </div>
				</div>
			')
			.appendTo('body')
		errorModal.modal('show')