### IsThereAnyDeal.com Collection Importer
// ==UserScript==
// @name IsThereAnyDeal.com Collection Importer
// @version 0.1b18
// @namespace http://isthereanydeal.com/
// @description Adds buttons to various sites to export your game lists to ITAD
// @icon http://s3-eu-west-1.amazonaws.com/itad/images/banners/50x50.gif
// @license MIT
// @supportURL https://github.com/ssokolow/itad_importer/issues
// @require https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js
//
// @match *://fireflowergames.com/my-account*
// @match *://fireflowergames.com/my-lists/*
// @match *://flyingbundle.com/users/account*
// @match *://www.flyingbundle.com/users/account*
// @match *://www.gog.com/account*
// @match *://www.gog.com/order/status/*
// @match *://itch.io/my-purchases*
// @match *://*.itch.io/*
// @match *://groupees.com/purchases*
// @match *://groupees.com/users/*
// @match *://www.humblebundle.com/home*
// @match *://www.humblebundle.com/downloads?key=*
// @match *://www.humblebundle.com/s?key=*
// ==/UserScript==

Any patches to this script should be made against the original
CoffeeScript source file available (and documented) at:

  https://github.com/ssokolow/itad_importer

Copyright ©2014-2018 Stephan Sokolow
License: MIT (http://opensource.org/licenses/MIT)

TODO:
- Add a `@downloadURL` for the script

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

# Prevent conflict between our jQuery and site jQuery without using @grant
this.$ = this.jQuery = jQuery.noConflict(true)

# Less overhead than instantiating a new jQuery object
attr = (node, name) -> node.getAttribute(name)

gog_prepare_title = (elem) ->
  dom = $('.product-title', elem).clone()
  $('._product-flag', dom).remove()
  dom.text()

itch_plain = (elem) ->
  elem.toLowerCase();

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

humble_parse = -> {
  version: "02",
  data: {
    title: x.textContent.trim(),
    copies: [{ type: 'humblestore' }]
  } for x in $('div.row').has(
    # Humble Library has no easy way to list only games
    ' .downloads.windows .download,
      .downloads.linux .download,
      .downloads.mac .download,
      .downloads.android .download'
  ).find('div.title')}

# Scrapers are looked up first by domain (lightweight) and then by
# a regex check on the URL (accurate).
# This should allow for extremely robust scaling as well as enabling the
# possibility of a build script which automatically generates the
# Greasemonkey `@include` lines.
scrapers =
  'fireflowergames.com':
    '^https://fireflowergames\\.com/my-account/?':
      'source_id': 'fireflower'
      'game_list': ->
        results = $('ul.digital-downloads li a')
        titles = [$(x).text().split(" – ")[0].trim() for x in results][0]
        uniques = titles.filter((title, pos) ->  titles.indexOf(title) == pos)

        # TODO: Take screenshot

        {
          version: "02",
          data: {
            title: title,
            copies: [{
              type: 'fireflower',
              status: 'redeemed',
              owned: 1,
            }]
          } for title in uniques
        }
      'insert_button': ->
        # XXX: If you can debug the broken behaviour with <button>, please do.
        # I don't have time.
        $('<a class="button"></a>')
          .html(BUTTON_LABEL)
          .css({
            verticalAlign: '20%',
            marginLeft: '1em',
          }).appendTo($('ul.digital-downloads').prev())

    '^http://fireflowergames\\.com/my-lists/(edit-my|view-a)-list/\\?.+':
      'source_id': 'fireflower'
      'game_list': ->
        results = $('table.wl-table tbody td.check-column input:checked')
          .parents('tr').find('td.product-name a')

        if (!results.length)
          results = $('table.wl-table td.product-name a')

        {
          version: "02",
          data: { title: $(x).text().trim() } for x in results
        }
      'insert_button': ->
        # XXX: If you can debug the broken behaviour with <button>, please do.
        # I don't have time.
        $('<a class="button"></a>')
          .html(BUTTON_LABEL)
          .wrap('<td></td>')
          .appendTo($('table.wl-actions-table tbody:first').find('tr:last'))
      'is_wishlist': true

  'flyingbundle.com':
    'https?://(www\\.)?flyingbundle\\.com/users/account#?':
      'source_id': 'flying_bundle'
      'game_list': -> {
        version: "02",
        data: {
          title: $(x).text(),
          copies: [{
            type: 'Flying Bundle',
            status: 'redeemed',
            owned: 1,
            source: {
              type: "s",
              id: "other"
            }
          }]
        } for x in $(".div_btn_download[href^='/users/sources']"
        ).parents('li').find(':first')
      }
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
          "version": "02",
          "data": {
            title: gog_prepare_title(x)
            copies: [{
              type: 'gog',
              status: 'redeemed',
              owned: 1,
            }]
          } for x in $('.order + .container .product-row')
        }

      'insert_button': ->
        console.debug("insert_button called for GOG order status page")
        $(".order-article__btn-pointer-wrapper .order-article__btn-pointer")
          .css({
            marginTop: -4,
            zIndex: 20,
          })
        $('.order-article__dropdown-items').css('z-index', 10)
        $("<a class='_dropdown__item ng-scope'></a>")
          .html("On ITAD")
          .prependTo($('.order-message__actions ._dropdown__items')
            .filter(':first'))

    '^https?://www\\.gog\\.com/account(/games(/(shelf|list))?)?/?(\\?|$)':
      'source_id': 'gog'
      'game_list': ->
        console.debug("game_list called for GOG collection page")
        {
          "version": "02",
          "data": {
            # id: attr(x, 'gog-account-product')
            title: gog_prepare_title(x)
            copies: [{
              type: 'gog',
              status: 'redeemed',
              owned: 1,
            }]
          } for x in $('.product-row')
        }

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

  'itch.io':
    '^https?://itch\\.io/my-purchases':
      'source_id': 'itchio'
      'game_list': ->
        old_date=0
        new_date=null
        console.debug("game_list called for itch.io collection page")
        {
#           new_date=0
          "version": "02",
          "data": {
            # id: attr(x, 'gog-account-product')
            #.attr('title').trim()
            title: $('.title.game_link',x).first().text().trim()
            copies: [{
              new_date: new Date($('span',$('.date_header',x)).first().attr('title')).getTime()/1000
#if (new_date == null)
#                 new_date=o
              added: new Date($('span',$('.date_header',x)).first().attr('title')).getTime()/1000
              type: 'itchio',
              status: 'redeemed',
              owned: 1,
            }]
          } for x in $('.game_cell')
        }

      'insert_button': ->
        console.debug("insert_button called for itch.io collection page")
        $("<span></span>")
        .css
          float: 'right'
          cursor: 'pointer'
          # TODO: Replace the following hacks with whatever GOG uses
          position: 'relative'
          marginBottom: '-2em'
          zIndex: 1
        .html(BUTTON_LABEL + " (This Page)")
        .appendTo($('.header_tabs').filter(':first'))
 
    '^https?://.+\\.itch\\.io/.+/download/.+':
#     '^https?://itch\\.io/my-purchases':
      'source_id': 'itchio'
      'game_list': ->
        console.debug("game_list called for itch.io download page")
        {
          "version": "02",
          "data": {
            # id: attr(x, 'gog-account-product')
            #.attr('title').trim()
            title: $('.object_title',x).first().text().replace("  "," ").trim()
#            plain: itch_plain($('.object_title',x).first().text().trim())
            copies: [{
              added: new Date($('abbr',x).attr('title').replace('@','') + " UTC").getTime()/1000
#if (new_date == null)
#                 new_date=o
#               added: new Date($('span',$('.date_header',x)).first().attr('title')).getTime()/1000
              type: 'itchio',
              status: 'redeemed',
              owned: 1,
            }]
          } for x in $('.inner_column').filter(':first')
        }

      'insert_button': ->
        console.debug("insert_button called for itch.io download page")
        $("<span></span>")
        .css
          float: 'right'
          cursor: 'pointer'
          # TODO: Replace the following hacks with whatever GOG uses
          position: 'relative'
          marginBottom: '-2em'
          zIndex: 1
        .html(BUTTON_LABEL + " (This Page)")
        .appendTo($('.header_nav_tabs').filter(':first'))


  'groupees.com':
    # TODO: Support the new UI beta

    'https?://(www\\.)?groupees\\.com/(purchases|users/\\d+)':
      'source_id': 'other'
      'game_list': ->

        # FIXME: Now I need to manually filter for actual games
        {
          "version": "02",
          "data": {
            title: x.textContent.trim(),
            copies: [{
              type: 'Groupees.com',
              status: 'redeemed',
              owned: 1,
              source: {
                type: "s",
                id: "other"
              }
            }]
          } for x in $('.product ul.dropdown-menu')
                      .parents('.details').find('h3')
        }
      'insert_button': ->
        $("<button></button>")
          .css({ float: 'right' }).addClass('button btn btn-sm btn-primary')
          .html(BUTTON_LABEL + " (Selected Bundle)")
          .insertBefore("input[name='search']")

  'www.humblebundle.com':
    'https://www\\.humblebundle\\.com/home/library/?':
      'source_id': 'humblestore'
      'game_list': -> {
        "version": "02",
        "data": {
          title: x.textContent.trim(),
          copies: [{
            type: 'humblestore',
            status: 'redeemed',
            owned: 1,
          }]
        } for x in $('.subproduct-selector h2')
      }
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

scrapers['www.flyingbundle.com'] = scrapers['flyingbundle.com']
scrapers['www.groupees.com'] = scrapers['groupees.com']

# Callback for the button
scrapeGames = (scraper_obj) ->
  params = {
    file: btoa(unescape(encodeURIComponent(JSON.stringify(
      scraper_obj.game_list())))),
    upload: 'x'
  }

  url = if scraper_obj.is_wishlist?
    'https://isthereanydeal.com/waitlist/import/'
  else
    'https://isthereanydeal.com/collection/import/'

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
  if location.host.match(/\.itch\.io/)
        scrapers[location.host] = scrapers['itch.io']
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
