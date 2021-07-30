---
layout: default
---

# Atomic Red Team

Atomic Red Team is an open-source library of tests that security teams can
use to simulate adversarial activity in their environments.

## Fast

Atomic tests run in five minutes or less and require minimal setup. Spend less
time configuring and more time testing!

## Focused

Security teams don't want to operate with a "hopes and prayers" attidude towards
detection. Atomic tests are mapped to the MITRE ATT&CK matrix, so you always
know which techniques you do and don't detect.

## Community-driven

Atomic Red Team is open source and community developed. By working together, we
can develop a fuller picture of the security landscape.

## Download Atomic Red Team

Ready to start testing? Download the library from GitHub [here](https://github.com/redcanaryco/atomic-red-team),
or check out the [Getting started](https://github.com/redcanaryco/atomic-red-team/wiki/Getting-Started)
page of the Atomic Red Team documentation.

---

# Roll the dice

Not sure where to start? Roll the dice to select a random Atomic Test from the catalog.

<div style="text-align: center; margin-bottom: 30px;">
  <a class="btn btn-roll-the-dice" href="javascript:void(0);" onclick="roll_the_dice()">Roll the dice!</a>
</div>

<table id="roll-the-dice" style="width: auto; margin: 0 auto; display: table; min-width: 700px; max-width: 700px;">
  <tr>
    <th style="width: 120px"><strong>Tactic</strong></th>
    <td class="randoms">
      <h2 class="random-tactic-name"></h2>
    </td>
  </tr>
  <tr>
    <th><strong>Technique</strong></th>
    <td class="randoms">
      <h2 class="random-technique-name"></h2>
    </td>
  </tr>
  <tr>
    <th><strong>Atomic Test</strong></th>
    <td class="randoms">
      <h2 class="random-test-name"></h2>
      <blockquote class="random-test-description" style="display: block;"></blockquote>
      <div class="random-test-platforms">
        <h3>
          Platforms:
          <em></em>
        </h3>
      </div>
      <div class="random-test-input-arguments">
        <h3>Input Arguments:</h3>
        <pre></pre>
      </div>
      <hr/>
      <h3 class="random-test-executor-name"></h3>
      <pre class="random-test-executor-steps" style="max-width: 700px"></pre>
      <hr/>
      <p>Learn more at <a class="random-test-link" href="#"></a></p>
    </td>
  </tr>
</table>

Thanks to [Tim Malcomvetter](https://medium.com/@malcomvetter/red-team-use-of-mitre-att-ck-f9ceac6b3be2)
and [Tim McGuffin](https://www.twitter.com/NotMedic) for their idea!

<script src="{{ '/assets/javascripts/roll-the-dice.js?v=' | append: site.github.build_revision | relative_url }}"></script>
