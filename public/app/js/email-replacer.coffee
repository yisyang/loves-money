$(document).ready () ->
	$('.em-js').each () ->
		currentText = $(this).text()
		if currentText.indexOf(' (at loves.money)') isnt -1
			replacedText = currentText.replace(' (at loves.money)', '@loves.money')
			$(this).html(
				$('<a>').attr('href', 'm' + 'ail' + 'to:' + replacedText).text(replacedText)
			)