$(document).ready(function () {
  $.get("https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/index.yaml", function (data) {
    window.atomic_index = jsyaml.safeLoad(data);
  });

  $('.randoms > *').hide()
});

roll_the_dice = function () {
  var tactic_name = Object.keys(window.atomic_index)[Math.floor(Math.random() * Object.keys(window.atomic_index).length)];
  var tactic = window.atomic_index[tactic_name]
  console.log("Random tactic:")
  console.log(tactic_name)
  console.log(tactic)

  var technique_name = Object.keys(tactic)[Math.floor(Math.random() * Object.keys(tactic).length)];
  var technique = tactic[technique_name]
  console.log("Random technique:")
  console.log(technique_name)
  console.log(technique)

  var test = technique.atomic_tests[Math.floor(Math.random() * technique.atomic_tests.length)];
  console.log("Random test:")
  console.log(test)

  $('.random-tactic-name').text(tactic_name).fadeIn(function () {
    setTimeout(function () {
      $('.random-technique-name').text(technique_name).fadeIn(function () {
        setTimeout(function () {
          $('.random-test-name').text(test.name).fadeIn();
          $('.random-test-description').text(test.description).fadeIn();
          $('.random-test-platforms em').text(test.supported_platforms).fadeIn();
          if (test.input_arguments) {
            $('.random-test-input-arguments pre').text(jsyaml.safeDump(test.input_arguments)).fadeIn();
          } else {
            $('.random-test-input-arguments').hide()
          }
          $('.random-test-executor-name').text("Run with " + test.executor.name).fadeIn();
          $('.random-test-executor-steps').text(test.executor.command).fadeIn();

          var link = "https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/" +
            technique.technique.identifier + "/" + technique.technique.identifier + ".md"
          $('.random-test-link').attr('href', link)
          $('.random-test-link').text(link).fadeIn();
          $('.randoms > *').show()
        }, 500);
      });
    }, 500);
  });
}
