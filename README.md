## Collection Import Script for IsThereAnyDeal.com

[![Issues Ready to be Worked on](https://badge.waffle.io/ssokolow/itad_importer.png?label=confirmed&title=Ready)](https://waffle.io/ssokolow/itad_importer)

This userscript adds "Export to ITAD" buttons to online game vendors who do
not provide a way for sites like IsThereAnyDeal.com to query user game lists
and wishlists remotely.

It is currently in **beta** and any bugs should be reported in the
[issue tracker](https://github.com/ssokolow/itad_importer/issues).

Currently supported vendors are:

* [FireFlower Games](http://fireflowergames.com/)
* [Flying Bundle](http://www.flyingbundle.com/) (direct downloads only)
* [GOG.com](http://www.gog.com) (collection only. Wishlists supported by ITAD
  directly.)
* [Groupees](http://groupees.com/) (direct downloads in bundles tab only)
* [Humble Store](http://www.humblebundle.com) ([Bug:](https://github.com/ssokolow/itad_importer/issues/14) Import via whole-collection
  view includes Steam-only purchases)

See the [screenshot sheet](https://raw.githubusercontent.com/ssokolow/itad_importer/master/screenshots/1.png) for a reference as to where the added buttons should appear.

### Installation

1. Install [Greasemonkey](https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/)
   in [Firefox](http://getfirefox.com/)
   ([Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo)
   in Chrome should also work but hasn't yet been tested)
2. Restart Firefox
3. Install the [userscript](https://greasyfork.org/en/scripts/13887-isthereanydeal-com-collection-importer)

(Installation [via GreasyFork](https://greasyfork.org/en/scripts/13887-isthereanydeal-com-collection-importer) is recommended to ensure automatic updates
function as reliably as possible.)

### Development

The authoritative copy of this script is the
[CoffeeScript](http://coffeescript.org/) source file. Patches against the
generated JavaScript may or may not be accepted at the developers' discretion.
(We have to rewrite them in CoffeeScript, so they'll have to be worthwhile.)

At the moment, the official method for developing this script has yet to be
updated for Quantum-era Firefox and is as follows:

1. On a Unixy machine (eg. Linux), install Firefox 52 ESR and a version of
   Greasemonkey old enough to store its scripts as bare files on disk.
2. Install the [release version](https://greasyfork.org/en/scripts/13887-isthereanydeal-com-collection-importer)
   of the script in Firefox
3. Install [Node.js](http://nodejs.org/)
4. Run `npm install`
5. Run `npm run-script develop`
6. Saving changes to the CoffeeScript source will now regenerate the copy of
   the script installed in Firefox.
7. When you're finished, hit <kbd>Enter</kbd>
8. The development script will regenerate the in-repository JavaScript and code
   documentation before exiting.
9. Commit the updated built files.

However, if you do not have a Unixy machine handy, this quick and dirty method
can also be used:

 1. Open http://coffeescript.org/
 2. Open the "Try CoffeeScript" tab.
 3. Use the browser's Developer Tools to add a `contentEditable`
  attribute to the `<pre>` tag for the right pane so you can use
  <kbd>Ctrl</kbd>+<kbd>A</kbd> followed by <kbd>Ctrl</kbd>+<kbd>C</kbd> to
  quickly copy everything.
 4. Install the
  [release version](https://greasyfork.org/en/scripts/13887-isthereanydeal-com-collection-importer)
  of the script and use Greasemonkey's edit button to open up the version it's
  using so you can test changes simply by copying JS from "Try CoffeeScript" to
  the editor, saving, and reloading the page in the browser.
 5. Use the "Try CoffeeScript" button to switch back and forth between
  code and reference materials.

