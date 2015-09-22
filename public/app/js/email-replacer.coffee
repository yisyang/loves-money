$(document).ready () ->
	emRegex = /\ \(at loves\.money\)/g

	# Resolve emails only
	$('.em-js').each () ->
		currentText = $(this).text()
		if currentText.indexOf(' (at loves.money)') isnt -1
			replacedText = currentText.replace(emRegex, '@loves.money')
			$(this).html(replacedText)
		return

	# Resolve emails and add links
	$('.em-js-link').each () ->
		currentText = $(this).text()
		if currentText.indexOf(' (at loves.money)') isnt -1
			replacedText = currentText.replace(emRegex, '@loves.money')
			$(this).html(
				$('<a>').attr('href', 'm' + 'ail' + 'to:' + replacedText).text(replacedText)
			)
		return