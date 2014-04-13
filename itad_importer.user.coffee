### IsThereAnyDeal.com Collection Importer

Any patches to this script should be made against the original
CoffeeScript source file available (and documented) at:

  https://github.com/ssokolow/itad_importer

Copyright ©2014 Stephan Sokolow
License: MIT (http://opensource.org/licenses/MIT)

TODO:
- Add support for wishlist importing too
- Add a `@downloadURL` for the script

Note: While we do not use GM_info, we must request it to force the userscript
to be isolated from the page so its jQuery doesn't collide with the site's
jQuery.

// ==UserScript==
// @name IsThereAnyDeal.com Collection Importer
// @version 0.1b1
// @namespace http://isthereanydeal.com/
// @description Adds buttons to various sites to export your game lists to ITAD
// @icon http://s3-eu-west-1.amazonaws.com/itad/images/banners/50x50.gif
// @grant GM_info
// @require https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js
//
// @match *://www.dotemu.com/*
// @match *://secure.gog.com/account*
// @match *://www.humblebundle.com/home*
// @match *://indiegamestand.com/wallet.php
// @match *://www.shinyloot.com/m/games*
// @match *://www.shinyloot.com/m/wishlist*
// ==/UserScript==
###

# This string will be interpreted as raw HTML
BUTTON_LABEL = "Export to ITAD"

# Less overhead than instantiating a new jQuery object
attr = (node, name) -> node.getAttribute(name)

# Common code to extract metadata from the GOG.com shelf and wishlist views
gog_nonlist_parse = -> {
  # The shelf view mode only sees game IDs and slugs easily
  id: attr(x, 'data-gameid')
  url: ('http://www.gog.com/en/game/' +
      attr(x, 'data-gameindex'))
  sources: ['gog']
} for x in $('[data-gameindex]')

shinyloot_insert_button = ->
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

# Scrapers are looked up first by domain (lightweight) and then by
# a regex check on the URL (accurate).
# This should allow for extremely robust scaling as well as enabling the
# possibility of a build script which automatically generates the
# Greasemonkey `@include` lines.
scrapers =
  'www.dotemu.com' :
    'https://www\\.dotemu\\.com/(en|fr|es)/user/?' :
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
    '^https://secure\\.gog\\.com/account(/games(/(shelf|list))?)?/?(\\?|$)' :
      'source_id': 'gog'
      'game_list' : ->
        if $('.shelf_container').length > 0
          gog_nonlist_parse()
        else if $('.games_list').length > 0
          {
          id: $(x).closest('.game-item').attr('id').substring(8)
          # The list view mode only sees game titles easily
          title: x.textContent.trim()
          sources: ['gog']
          } for x in $('.game-title-link')

      'insert_button': ->
        if $('.shelf_container').length > 0
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
        else if $('.games_list').length > 0
          # Use GOG's style class but force it to be its own tweaked
          # button group because their style won't round both ends
          # of the same button
          $("<span class='list_btn'></span>")
          .css({ float: 'right', borderRadius: '9px' })
          .html(BUTTON_LABEL)
          # Prevent it from throwing off the other group
          .wrap('<span></span>')
          .appendTo('.list_header')
    '^https://secure\\.gog\\.com/account/wishlist' :
      'source_id': 'gog'
      'game_list' : gog_nonlist_parse
      'insert_button': ->
        # Borrow the styling from the games list since I couldn't find
        # anything better in GOG's own styling.
        $("<span class='list_btn'></span>")
        .css({ float: 'right', borderRadius: '9px' })
        .html(BUTTON_LABEL)
        # Prevent it from throwing off the other group
        .wrap('<span></span>')
        .appendTo('.wlist_header')
      'is_wishlist': true

  'www.humblebundle.com' :
    'https://www\\.humblebundle\\.com/home/?' :
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
    'https://indiegamestand\\.com/wallet\\.php' :
      'source_id': 'indiegamestand'
      'game_list' : -> {
        # **Note:** IGS game URLs change during promos and some IGS wallet
        # entries may not have them (eg. entries just present to provide
        # a second steam key for some DLC from another entry)
        url: $('.game-thumb', x)?.closest('a')?[0]?.href
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
    'https?://www\\.shinyloot\\.com/m/games/?' :
      'source_id': 'shinyloot'
      'game_list' : -> {
        url: $('.right-float a img', x).closest('a')[0].href
        title: $(x).prev('h3').text().trim()
        sources: ['shinyloot']
        } for x in $('#accordion .ui-widget-content')
      'insert_button': shinyloot_insert_button
    'https?://www\\.shinyloot\\.com/m/wishlist/?' :
      'source_id': 'shinyloot'
      'game_list' : -> {
        url: $('.gameInfo + a', x)[0].href
        title: $('.gameName', x).text().trim()
        } for x in $('.gameItem')
      'insert_button': shinyloot_insert_button
      'is_wishlist': true

# Callback for the button
scrapeGames = (profile) ->
  params = {
    json: JSON.stringify(profile.game_list()),
    source: profile.source_id
  }

  url = if profile.is_wishlist?
    'http://isthereanydeal.com/outside/user/wait/3rdparty'
  else
    'http://isthereanydeal.com/outside/user/collection/3rdparty'

  # **TODO:** Figure out why attempting to use an iframe for non-HTTPS sites
  # navigates the top-level window.
  form = $("<form id='itad_submitter' method='POST' />").attr('action', url)
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
$(->
  # Resolve and call the correct profile
  #
  # It seems we don't need an explicit `if location.host of scrapers`
  # before the `for` loop
  console.log("Loading ITAD importer...")
  if scrapers[location.host]
    console.log("Matched domain: " + location.host)
    for regex, profile of scrapers[location.host]
      try
        profile_matched = location.href.match(regex)
      catch e
        console.error("Bad regex: " + regex)

      if profile_matched
        console.log("Matched profile: " + regex)
        # Allow reloading the script without reloading the page for RAD
        $('#itad_btn, #itad_dlg, .itad_close').remove()
        # Use the `?` existential operator to die quietly if the profile
        # doesn't have an `insert_button` member.
        profile.insert_button?().attr('id', 'itad_btn').click(
          -> scrapeGames(profile)
        )
        # We only ever want to match one profile so break here
        break
)
