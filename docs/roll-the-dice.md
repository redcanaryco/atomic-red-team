---
layout: default
---

# Roll the Dice

Not sure where to start? Roll the dice to select a random Atomic Test from the catalog. Kudos to 
[Tim Malcomvetter](https://medium.com/@malcomvetter/red-team-use-of-mitre-att-ck-f9ceac6b3be2) and
[Tim McG](https://www.twitter.com/NotMedic) for the idea.

<div style="text-align: center; margin-bottom: 30px;">
  <a class="btn btn-roll-the-dice" href="#" onclick="roll_the_dice()">Roll the dice!</a>
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
