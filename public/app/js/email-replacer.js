// Generated by CoffeeScript 1.8.0
(function() {
  $(document).ready(function() {
    var emRegex;
    emRegex = /\ \(at loves\.money\)/g;
    $('.em-js').each(function() {
      var currentText, replacedText;
      currentText = $(this).text();
      if (currentText.indexOf(' (at loves.money)') !== -1) {
        replacedText = currentText.replace(emRegex, '@loves.money');
        $(this).html(replacedText);
      }
    });
    return $('.em-js-link').each(function() {
      var currentText, replacedText;
      currentText = $(this).text();
      if (currentText.indexOf(' (at loves.money)') !== -1) {
        replacedText = currentText.replace(emRegex, '@loves.money');
        $(this).html($('<a>').attr('href', 'm' + 'ail' + 'to:' + replacedText).text(replacedText));
      }
    });
  });

}).call(this);

//# sourceMappingURL=email-replacer.js.map
