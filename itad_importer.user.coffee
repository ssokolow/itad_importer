### IsThereAnyDeal.com Collection Importer

Any patches to this script should be made against the original
CoffeeScript source file available (and documented) at:

  https://github.com/ssokolow/itad_importer

Copyright ©2014-2015 Stephan Sokolow
License: MIT (http://opensource.org/licenses/MIT)

TODO:
- Add a `@downloadURL` for the script

Note: While we do not use GM_info, we must request it to force the userscript
to be isolated from the page so its jQuery doesn't collide with the site's
jQuery.

// ==UserScript==
// @name IsThereAnyDeal.com Collection Importer
// @version 0.1b11
// @namespace http://isthereanydeal.com/
// @description Adds buttons to various sites to export your game lists to ITAD
// @icon http://s3-eu-west-1.amazonaws.com/itad/images/banners/50x50.gif
// @license MIT
// @supportURL https://github.com/ssokolow/itad_importer/issues
// @grant GM_info
// @require https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js
//
// @match *://www.dotemu.com/*
// @match *://fireflowergames.com/my-lists/*
// @match *://www.flyingbundle.com/users/account
// @match *://www.gog.com/account*
// @match *://www.gog.com/order/status/*
// @match *://groupees.com/purchases
// @match *://groupees.com/users/*
// @match *://www.humblebundle.com/home*
// @match *://www.humblebundle.com/downloads?key=*
// @match *://www.humblebundle.com/s?key=*
// @match *://indiegamestand.com/wallet.php
// @match *://indiegamestand.com/wishlist.php
// @match *://www.shinyloot.com/m/games*
// @match *://www.shinyloot.com/m/wishlist*
// ==/UserScript==
###

# This string will be interpreted as raw HTML
BUTTON_LABEL = "Export to ITAD"

ITAD_12X12 = """data:image/png;base64,
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAZlBMVEUEbrIEbrIJcbQLcrQefboo
g70rhb4thr8vh78zicA6jcNCksVLl8hWnctZn8xdoc1ipM9ipc9kptB5stZ6staCt9mHutqJu9ud
xuGozeSrz+W72OrA2+zJ4O7U5vLX6PPn8fj3+vyC0mvkAAAAAXRSTlMAQObYZgAAAFdJREFUCB0F
wYkCgUAABcA3CpElRyRH6/9/0kwCQALtZSwNglN9Pt5LR+jqGuelEaYbeBXh04P7KMwDeF6E8l1h
W1vh8PsO/bWeiGPdl/kzdYjdBkACQP5LygQ7CM8T6wAAAABJRU5ErkJggg=="""

ITAD_14X14_GRAY = """data:image/png;base64,
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAdVBMVEUEbrKTlaCTlZ+TlZ+UlqCY
maSYmqWcnqednqieoKmfoaugoqulprCvsLivsbiwsrmztLuztby2uL7BwsjDxcrExcvIyc7V1trW
1trX2Nvn5+rp6evx8vP19fb39/j4+Pn5+fr7+/v7+/z8/Pz8/P39/f3///8J+FboAAAAJHRSTlMA
y+rw8PHx8fHx8vLy9PT09PT19vf39/n5+fz8/f3+/v7+/v695LIzAAAAcUlEQVQIHQXBhwGCQAAE
sHui2FHsBeyy/4gmSQGgJKWCeTNFVQJNN9yH2xJB+z3WZuf3kjDuD+B8I6wfIzAbpsLuCrg3QtsD
9TAXJq8tOHYEl9+W0eHbEPaf06u/PvoWsXmuTNrdegwp1QJAVZICQMkf1qQG7Yh+Z60AAAAASUVO
RK5CYII="""

# Cache reused objects
# Source: http://stackoverflow.com/a/196991
underscore_re = /_/g
word_re = /\b\w+/g
titlecase_cb = (s) -> s.charAt(0).toUpperCase() + s.substr(1).toLowerCase()

# Less overhead than instantiating a new jQuery object
attr = (node, name) -> node.getAttribute(name)

dotemu_add_button = (parent_selector) ->
  $('<button></button>')
  .html(BUTTON_LABEL).css
    #DotEmu doesn't have a general button style we can use
    float: 'right'
    marginRight: '5px'
  .appendTo(parent_selector)

gog_prepare_title = (elem) ->
  dom = $('.product-title', elem).clone()
  $('._product-flag', dom).remove()
  dom.text()

humble_make_button = ->
  # Humble Library uses very weird button markup
  label = $('<span class="label"></span>').html(BUTTON_LABEL)
  a = $('<a class="a" href="#"></span>')
     .html(BUTTON_LABEL)
     # Apparently the `noicon` class isn't versatile enough
     .css('padding-left', '9px')

  button = $('<div class="flexbtn active noicon"></div>')
  .append('<div class="right"></div>')
  .append(label)
  .append(a)

humble_parse = -> { title: x.textContent.trim(), sources: ['humblestore']
  } for x in $('div.row').has(
  # Humble Library has no easy way to list only games
  ' .downloads.windows .download,
    .downloads.linux .download,
    .downloads.mac .download,
    .downloads.android .download'
  ).find('div.title')

shinyloot_insert_button = ->
  $('<button></button>')
  .html(BUTTON_LABEL).css
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
  .appendTo('#content .header')

# Scrapers are looked up first by domain (lightweight) and then by
# a regex check on the URL (accurate).
# This should allow for extremely robust scaling as well as enabling the
# possibility of a build script which automatically generates the
# Greasemonkey `@include` lines.
scrapers =
  'www.dotemu.com':
    # Each profile can be an object or a list of objects
    'https://www\\.dotemu\\.com/(en|fr|es)/user/?': [
        # The store being imported from
        'source_id': 'dotemu'
        # Each scraper must have a `game_list` method which returns...
        'game_list': ->
          {
            # ...one or both of `title` and `url`
            title: attr(x, 'title')
            # We're guaranteed an absolute URL if we use the DOM href property
            url: x.href
            # The stores which should be added to the user's "owned on" list
            sources: ['dotemu']
          } for x in $('div.my-games div.field-title a')

        # Each scraper must have an `insert_button` member which adds
        # a button to the DOM using `BUTTON_LABEL` and then returns
        # a jQuery wrapper so the click handler can be bound.
        'insert_button': -> dotemu_add_button('div.my-games h2.pane-title')
      ,
        'source_id': 'dotemu'
        'game_list': ->
          {
            title: attr(x, 'title')
            url: x.href
            sources: ['dotemu']
          } for x in $('div.user-wishlist .views-field-title-1 a')
        'insert_button': -> dotemu_add_button('.user-wishlist h2.pane-title')
        'is_wishlist': true
      ]

  'fireflowergames.com':
    '^http://fireflowergames\\.com/my-lists/(edit-my|view-a)-list/\\?.+':
      'source_id': 'fireflower'
      'game_list': ->
        results = $('table.wl-table tbody td.check-column input:checked')
          .parents('tr').find('td.product-name a')

        if (!results.length)
          results = $('table.wl-table td.product-name a')

        {
          title: $(x).text().trim()
          url: x.href
          sources: ['fireflower']
        } for x in results
      'insert_button': ->
        # XXX: If you can debug the broken behaviour with <button>, please do.
        # I don't have time.
        $('<a class="button"></a>')
          .html(BUTTON_LABEL)
          .wrap('<td></td>')
          .appendTo($('table.wl-actions-table tbody:first').find('tr:last'))
      'is_wishlist': true

  'www.flyingbundle.com':
    'https?://www\\.flyingbundle\\.com/users/account':
      'source_id': 'flying_bundle'
      'game_list': -> {
        title: $(x).text()
        sources: 'flying_bundle'
      } for x in $(".div_btn_download[href^='/users/sources']"
      ).parents('li').find(':first')
      'insert_button': ->
        li = $("<li></li>"
        ).appendTo('.legenda_points ul')
        $('<a href="#">' + BUTTON_LABEL + ' <img src="' + ITAD_14X14_GRAY +
          '" /></a>')
          .css('text-transform', 'uppercase')
          .wrap("<li></li>")
          .appendTo(li)

  'www.gog.com':
    '^https://www\\.gog\\.com/order/status/.+':
      'source_id': 'gog'
      'game_list': ->
        console.debug("game_list called for GOG order status page")
        {
          title: $(x).text().trim()
          sources: ['gog']
        } for x in $('.order__hero-unit ul.summary-list li')

      'insert_button': ->
        console.debug("insert_button called for GOG order status page")
        $("<a class='_dropdown__item ng-scope'></a>")
          .html("On ITAD")
          .prependTo($('.order-message__actions ._dropdown__items')
            .filter(':first'))

    '^https?://www\\.gog\\.com/account(/games(/(shelf|list))?)?/?(\\?|$)':
      'source_id': 'gog'
      'game_list': ->
        console.debug("game_list called for GOG collection page")
        {
          id: attr(x, 'gog-product')
          title: gog_prepare_title(x)
          sources: ['gog']
        } for x in $('.product-row')

      'insert_button': ->
        console.debug("insert_button called for GOG collection page")
        $("<span></span>")
        .css
          float: 'right'
          cursor: 'pointer'
          # TODO: Replace the following hacks with whatever GOG uses
          position: 'relative'
          marginBottom: '-2em'
          zIndex: 1
        .html(BUTTON_LABEL + " (This Page)")
        .prependTo($('.collection-header').filter(':first'))

  'groupees.com':
    'https?://(www\\.)?groupees\\.com/(purchases|users/\\d+)':
      'source_id': 'other'
      'game_list': ->
        {
          title: x.textContent.trim(),
          sources: ['other']
        } for x in $('.product ul.dropdown-menu')
                    .parents('.details').find('h3')
      'insert_button': ->
        $("<button></button>")
          .css({ float: 'right' }).addClass('button btn btn-sm btn-primary')
          .html(BUTTON_LABEL + " (Selected Bundle)")
          .insertBefore("input[name='search']")

  'www.humblebundle.com':
    'https://www\\.humblebundle\\.com/home/library/?':
      'source_id': 'humblestore'
      'game_list': -> {
        title: x.textContent.trim(), sources: ['humblestore']
      } for x in $('.subproduct-selector h2')
      # TODO: Figure out how to filter out non-games again
      # TODO: Figure out how to tap their Backbone.js store

      'insert_button': ->
        config = { childList: true, subtree: true }
        button = $('<button class="download-button"></button>')
          .html(BUTTON_LABEL)
          .css
            # I wish they wouldn't make their CSS rules so specific
            display: 'inline',
            border: '1px solid #CCC',
            background: '#F1F3F6',
            padding: '5px 10px 5px 10px',
            marginLeft: '10px',

        found_early = $(".top-controls")
        if found_early.length > 0
          console.log("Inserting button immediately.")
          button.appendTo(found_early)
        else
          console.log("Using MutationObserver for deferred button insertion.")
          observer = new MutationObserver((mutations) ->
            mutations.forEach((mutation) ->
              tnode_cls = mutation.target.getAttribute("class")
              found = $(".top-controls", mutation.target)
              if found.length > 0
                observer.disconnect()
                button.appendTo(found)
            )
          )
          observer.observe(document.querySelector('.js-library-holder'),
                           config)
        return button

    'https://www\\.humblebundle\\.com/home/?':
      'source_id': 'humblestore'
      'game_list': humble_parse
      'insert_button': ->
        humble_make_button().css
          float: 'right',
          fontSize: '14px',
          fontWeight: 'normal'
        .prependTo('.base-main-wrapper h1')

    'https://www\\.humblebundle\\.com/(download)?s\\?key=.+':
      'source_id': 'humblestore'
      'game_list': humble_parse
      'insert_button': ->
        parent = $('.js-gamelist-holder').parents('.whitebox')
        parent.find('.staple.s4').remove()

        humble_make_button().css
          position: 'absolute'
          top: 11
          right: 17
        .appendTo(parent)


  'indiegamestand.com':
    'https://indiegamestand\\.com/wallet\\.php':
      'source_id': 'indiegamestand'
      'game_list': ->
        {
          # **Note:** IGS game URLs change during promos and some IGS wallet
          # entries may not have them (eg. entries just present to provide
          # a second steam key for some DLC from another entry)
          url: $('.game-thumb', x)?.closest('a')?[0]?.href
          title: $('.game-title', x).text().trim()
          sources: ['indiegamestand']
        } for x in $('#wallet_contents .line-item')

      'insert_button': ->
        $('<div class="request key"></div>')
        .html(BUTTON_LABEL).wrapInner("<div></div>").css
          display: 'inline-block'
          marginLeft: '1em'
          verticalAlign: 'middle'
        # This would look nicer if floated right in `.titles` but
        # their button styles are scoped to `#game_wallet`
        .appendTo('#game_wallet h2')
    'https://indiegamestand\\.com/wishlist\\.php':
      'source_id': 'indiegamestand'
      'game_list': ->
        {
          url: $('.game-thumb', x)?.closest('a')?[0]?.href
          title: $('.game_details h3', x).text().trim()
          sources: ['indiegamestand']
        } for x in $('#store_browse_game_list .game_list_item')
      'is_wishlist': true

      'insert_button': ->
        innerDiv = $("<div></div>").css
          paddingLeft: '10px'
          background: ('url("images/icon-arrow.png") no-repeat scroll ' +
                      '155px 45% transparent')

        $('<div class="request key"></div>')
        .html(BUTTON_LABEL).wrapInner(innerDiv).css # IGS CSS
          display: 'inline-block'
          verticalAlign: 'middle'
          float: 'right'
          width: '170px'
          height: '21px'
          background: ('url("images/btn-bg-blue-longer.png") ' +
                       'no-repeat scroll 0px 0px transparent')
          lineHeight: '21px'
          color: '#FFF'
          whiteSpace: 'nowrap'
          marginLeft: '1em'
          marginBottom: '4px'
          fontSize: '12px'
          cursor: 'pointer'
        .css # Our CSS
          margin: '11px 5px auto auto'
        .appendTo('#store_browse_game_list .header')

  'www.shinyloot.com':
    'https?://www\\.shinyloot\\.com/m/games/?':
      'source_id': 'shinyloot'
      'game_list': ->
        {
          url: $('.right-float a img', x).closest('a')[0].href
          title: $(x).prev('h3').text().trim()
          sources: ['shinyloot']
        } for x in $('#accordion .ui-widget-content')
      'insert_button': shinyloot_insert_button
    'https?://www\\.shinyloot\\.com/m/wishlist/?':
      'source_id': 'shinyloot'
      'game_list': ->
        {
          url: $('.gameInfo + a', x)[0].href
          title: $('.gameName', x).text().trim()
        } for x in $('.gameItem')
      'insert_button': shinyloot_insert_button
      'is_wishlist': true

# Callback for the button
scrapeGames = (scraper_obj) ->
  params = {
    json: JSON.stringify(scraper_obj.game_list()),
    source: scraper_obj.source_id
  }

  url = if scraper_obj.is_wishlist?
    'https://isthereanydeal.com/outside/user/wait/3rdparty'
  else
    'https://isthereanydeal.com/outside/user/collection/3rdparty'

  # **TODO:** Figure out why attempting to use an iframe for non-HTTPS sites
  # navigates the top-level window.
  form = $("<form id='itad_submitter' method='POST' />").attr('action', url)
  params['returnTo'] = location.href

  # Submit the form data
  form.css({ display: 'none' })
  $.each params, (key, value) ->
    $("<input type='hidden' />")
      .attr("name", key)
      .attr("value", value)
      .appendTo(form)
  $(document.body).append(form)

  form.submit()

# CoffeeScript shorthand for `$(document).ready(function() {`
$ ->
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
        $('.itad_btn, #itad_dlg, .itad_close').remove()

        # Simplify the following code
        if not Array.isArray(profile)
          profile = [profile]

        for scraper in profile
          # We'll need a closure to ensure click() calls the proper scraper
          do (scraper) ->
            # Use the `?` existential operator to die quietly if the scraper
            # doesn't have an `insert_button` member.
            console.log("Inserting ITAD button for source ID: " +
                        scraper.source_id)
            scraper.insert_button?().addClass('itad_btn').click ->
              console.log("ITAD button clicked")
              scrapeGames(scraper)

        # We only ever want to match one profile so break here
        break
