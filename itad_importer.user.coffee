### IsThereAnyDeal.com Collection Importer

Any patches to this script should be made against the original
CoffeeScript source file available (and documented) at:

  https://gist.github.com/ssokolow/9a7a57fbabf0948abd5e

Copyright ©2014 Stephan Sokolow
License: MIT (http://opensource.org/licenses/MIT)

CoffeeScript is simple to learn but If you aren't set up to develop
in it, you may need this quick-and-dirty testing environment:

 1. Open http://coffeescript.org/
 2. Open the "Try CoffeeScript" tab.
 3. Use the browser's Developer Tools to add a contentEditable
  attribute to the `<pre>` tag for the right pane so you can use
  <kbd>Ctrl+A</kbd> <kbd>Ctrl+C</kbd> to quickly copy everything.
 4. Install the stable version of this userscript and use Greasemonkey's
  edit button to open up the version it's using so you can test changes
  simply by copying JS from "Try CoffeeScript" to the editor, clicking
  save, and reloading the page in the browser.
 5. Use the "Try CoffeeScript" button to switch back and forth between
  code and reference materials.

Also, the best way to familiarize yourself with this script is to
install and run the `docco` documentation generator. This will unweave
the code and comments into a syntax-colorized, two-column form.

TODO: Add a `@downloadURL` for the script

Note: While we do not use GM_info, we must request it to force the userscript
to be isolated from the page so its jQuery doesn't collide with the site's
jQuery.

// ==UserScript==
// @name IsThereAnyDeal.com Collection Importer
// @version 0.1a1
// @namespace http://isthereanydeal.com/
// @description Adds buttons to various sites to export your game lists to ITAD
// @icon http://s3-eu-west-1.amazonaws.com/itad/images/banners/50x50.gif
// @grant GM_info
// @require https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js
//
// @match *://www.dotemu.com/*
// @match *://secure.gog.com/account/games*
// @match *://www.humblebundle.com/home*
// @match *://indiegamestand.com/wallet.php
// @match *://www.shinyloot.com/m/games*
// ==/UserScript==
###

# This string will be interpreted as raw HTML
BUTTON_LABEL = "Export to ITAD"

# Less overhead than instantiating a new jQuery object
attr = (node, name) -> node.getAttribute(name)

# Scrapers are looked up first by domain (lightweight) and then by
# a regex check on the URL (accurate).
# This should allow for extremely robust scaling as well as enabling the
# possibility of a build script which automatically generates the
# Greasemonkey `@include` lines.
scrapers =
  'www.dotemu.com' :
    'https://www\.dotemu\.com/(en|fr|es)/user/?' :
      # The store being imported from
      'source_id': 'dotemu'
      # Each scraper must have a `game_list` method which returns...
      'game_list' : -> {
        # ...one or both of `title` and `url`
        title: attr(x, 'title')
        # We're guaranteed an absolute URL if we use the DOM href property
        url: x.href
        # The stores which should be added to the user's "owned on" list
        sources: ['dotemu']
        } for x in $('div.field-title a')

      # Each scraper must have an `insert_button` member which adds
      # a button to the DOM using `BUTTON_LABEL` and then returns
      # a jQuery wrapper so the click handler can be bound.
      'insert_button': ->
        $('<button></button>')
        .html(BUTTON_LABEL).css({
        #DotEmu doesn't have a general button style we can use
        float: 'right'
        marginRight: '5px'
        })
        .appendTo('.my-games h2.pane-title')

  'secure.gog.com' :
    # **TODO:** Figure out a way to detect which mode is in use so we can
    # integrate with the cookie-powered /games URL.
    'https://secure\.gog\.com/account/games/shelf/?' :
      'source_id': 'gog'
      'game_list' : -> {
      # The shelf view mode only sees game IDs and slugs easily
      id: attr(x, 'data-gameid')
      url: ('http://www.gog.com/en/game/' +
          attr(x, 'data-gameindex'))
      sources: ['gog']
      } for x in $('[data-gameindex]')

      'insert_button': ->
        $("<span class='shelf_btn'></button>")
        # Use GOG's style but tweak it and force *both* ends round
        .css({
        float: 'right'
        borderRadius: '9px'
        opacity: 0.7
        marginTop: '15px'
        marginRight: '-32px'
        })
        .html(BUTTON_LABEL)
        .prependTo($('.shelf_header').filter(':first'))

    'https://secure\.gog\.com/account/games/list/?' :
      'source_id': 'gog'
      'game_list' : -> {
        id: $(x).closest('.game-item').attr('id').substring(8)
        # The list view mode only sees game titles easily
        title: x.textContent.trim()
        sources: ['gog']
        } for x in $('.game-title-link')

      'insert_button': ->
        # Use GOG's style class but force it to be its own tweaked
        # button group because their style won't round both ends
        # of the same button
        $("<span class='list_btn'></span>")
        .css({ float: 'right', borderRadius: '9px' })
        .html(BUTTON_LABEL)
        # Prevent it from throwing off the other group
        .wrap('<span></span>')
        .appendTo('.list_header')

  'www.humblebundle.com' :
    'https://www\.humblebundle\.com/home/?' :
      'source_id': 'humblestore'
      'game_list' : -> { title: x.textContent.trim(), sources: ['humblestore']
        } for x in $('div.row').has(
        # Humble Library has no easy way to list only games
        ' .downloads.windows .download,
          .downloads.linux .download,
          .downloads.mac .download,
          .downloads.android .download'
        ).find('div.title')


      'insert_button': ->
        # Humble Library uses very weird button markup
        label = $('<span class="label"></span>').html(BUTTON_LABEL)
        a = $('<a class="a" href="#"></span>')
           .html(BUTTON_LABEL)
           # Apparently the `noicon` class isn't versatile enough
           .css('padding-left', '9px')

        $('<div class="flexbtn active noicon"></div>')
        .append('<div class="right"></div>')
        .append(label)
        .append(a)
        .css({ float: 'right', fontSize: '14px', fontWeight: 'normal' })
        .prependTo('.base-main-wrapper h1')

  'indiegamestand.com' :
    'https://indiegamestand\.com/wallet\.php' :
      'source_id': 'indiegamestand'
      'game_list' : -> {
        # **Note:** IGS game URLs change during promos
        url: $('.game-thumb', x).closest('a')[0].href
        title: $('.game-title', x).text().trim()
        sources: ['indiegamestand']
        } for x in $('#wallet_contents .line-item')

      'insert_button': ->
        $('<div class="request key"></div>')
        .html(BUTTON_LABEL).wrapInner("<div></div>").css({
        display: 'inline-block'
        marginLeft: '1em'
        verticalAlign: 'middle'
        })
        # This would look nicer if floated right in `.titles` but
        # their button styles are scoped to `#game_wallet`
        .appendTo('#game_wallet h2')

  'www.shinyloot.com' :
    'http://www\.shinyloot\.com/m/games/?' :
      'source_id': 'shinyloot'
      'game_list' : -> {
        url: $('.right-float a img', x).closest('a')[0].href
        title: $(x).prev('h3').text().trim()
        sources: ['shinyloot']
        } for x in $('#accordion .ui-widget-content')

      'insert_button': ->
        $('<button></button>')
        .html(BUTTON_LABEL).css({
        # ShinyLoot's buttons are a chimeric grab-bag and
        # the nicest looking ones have site-provided CSS
        # that's tied to markup using `<ul>` and `<li>`.
        background: 'url("/images/filters/sort-background-inactive.png") ' +
                    'repeat-x scroll 0% 0% transparent'
        border: '1px solid #666'
        borderRadius: '2px'
        boxShadow: '0px 1px 6px #777'
        color: '#222'
        fontSize: '12px'
        fontWeight: 'bold'
        fontFamily: 'Arial,Helvetica,Sans-serif'
        float: 'right'
        padding: '2px 8px'
        marginRight: '-6px'
        verticalAlign: 'middle'
        })
        .appendTo('#content .header')

# Callback for the button
scrapeGames = (profile) ->
  params = {
    json: JSON.stringify(profile.game_list()),
    source: profile.source_id
  }

  # **TODO:** Figure out why attempting to use an iframe for non-HTTPS sites
  # navigates the top-level window.
  form = $("<form id='itad_submitter' method='POST' />").attr('action',
      'http://isthereanydeal.com/outside/user/collection/3rdparty')
  params['returnTo'] = location.href

  # Submit the form data
  form.css({ display: 'none' })
  $.each(params, (key, value) ->
    $("<input type='hidden' />")
      .attr("name", key)
      .attr("value", value)
      .appendTo(form)
  )
  $(document.body).append(form)

  form.submit()

# CoffeeScript shorthand for `$(document).ready(function() {`
$ ->
  # Resolve and call the correct profile
  #
  # It seems we don't need an explicit `if location.host of scrapers`
  # before the `for` loop
  for regex, profile of scrapers[location.host]
    if location.href.match(regex)
      # Allow reloading the script without reloading the page for RAD
      $('#itad_btn, #itad_dlg, .itad_close').remove()
      # Use the `?` existential operator to die quietly if the profile
      # doesn't have an `insert_button` member.
      profile.insert_button?().attr('id', 'itad_btn').click(
        -> scrapeGames(profile)
      )
      # We only ever want to match one profile so break here
      break
