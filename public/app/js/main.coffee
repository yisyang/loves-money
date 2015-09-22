$(document).ready () ->

	### Initialize ###

	$('.ui.dropdown').dropdown()


	### Helpers ###

	# Needs clean up... but will do for now
	window.LM.showError = (msg) ->
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
				    <div class="ui basic cancel inverted button">
				        OK
				    </div>
				</div>
			')
			.appendTo('body')
		errorModal.modal('show')

	return