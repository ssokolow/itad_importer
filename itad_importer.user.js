// Generated by CoffeeScript 1.7.1

/* IsThereAnyDeal.com Collection Importer

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
// @match *://www.greenmangaming.com/user/account*
// ==/UserScript==
 */
var BUTTON_LABEL, attr, gmg_insert_button, gog_nonlist_parse, scrapeGames, scrapers, shinyloot_insert_button;

BUTTON_LABEL = "Export to ITAD";

attr = function(node, name) {
  return node.getAttribute(name);
};

gog_nonlist_parse = function() {
  var x, _i, _len, _ref, _results;
  _ref = $('[data-gameindex]');
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    x = _ref[_i];
    _results.push({
      id: attr(x, 'data-gameid'),
      url: 'http://www.gog.com/en/game/' + attr(x, 'data-gameindex'),
      sources: ['gog']
    });
  }
  return _results;
};

shinyloot_insert_button = function() {
  return $('<button></button>').html(BUTTON_LABEL).css({
    background: 'url("/images/filters/sort-background-inactive.png") ' + 'repeat-x scroll 0% 0% transparent',
    border: '1px solid #666',
    borderRadius: '2px',
    boxShadow: '0px 1px 6px #777',
    color: '#222',
    fontSize: '12px',
    fontWeight: 'bold',
    fontFamily: 'Arial,Helvetica,Sans-serif',
    float: 'right',
    padding: '2px 8px',
    marginRight: '-6px',
    verticalAlign: 'middle'
  }).appendTo('#content .header');
};

gmg_insert_button = function() {
  if (location.hash === "#games") {
    return $('#content h1').append('<a class="button right" id="itad_button">' + BUTTON_LABEL + '</a>');
  } else {
    return $('#itad_button').detach();
  }
};

scrapers = {
  'www.dotemu.com': {
    'https://www\.dotemu\.com/(en|fr|es)/user/?': {
      'source_id': 'dotemu',
      'game_list': function() {
        var x, _i, _len, _ref, _results;
        _ref = $('div.field-title a');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push({
            title: attr(x, 'title'),
            url: x.href,
            sources: ['dotemu']
          });
        }
        return _results;
      },
      'insert_button': function() {
        return $('<button></button>').html(BUTTON_LABEL).css({
          float: 'right',
          marginRight: '5px'
        }).appendTo('.my-games h2.pane-title');
      }
    }
  },
  'secure.gog.com': {
    '^https://secure\.gog\.com/account(/games(/(shelf|list))?)?/?$': {
      'source_id': 'gog',
      'game_list': function() {
        var x, _i, _len, _ref, _results;
        if ($('.shelf_container').length > 0) {
          return gog_nonlist_parse();
        } else if ($('.games_list').length > 0) {
          _ref = $('.game-title-link');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            x = _ref[_i];
            _results.push({
              id: $(x).closest('.game-item').attr('id').substring(8),
              title: x.textContent.trim(),
              sources: ['gog']
            });
          }
          return _results;
        }
      },
      'insert_button': function() {
        if ($('.shelf_container').length > 0) {
          return $("<span class='shelf_btn'></button>").css({
            float: 'right',
            borderRadius: '9px',
            opacity: 0.7,
            marginTop: '15px',
            marginRight: '-32px'
          }).html(BUTTON_LABEL).prependTo($('.shelf_header').filter(':first'));
        } else if ($('.games_list').length > 0) {
          return $("<span class='list_btn'></span>").css({
            float: 'right',
            borderRadius: '9px'
          }).html(BUTTON_LABEL).wrap('<span></span>').appendTo('.list_header');
        }
      }
    },
    'https://secure\.gog\.com/account/wishlist': {
      'source_id': 'gog',
      'game_list': gog_nonlist_parse,
      'insert_button': function() {
        return $("<span class='list_btn'></span>").css({
          float: 'right',
          borderRadius: '9px'
        }).html(BUTTON_LABEL).wrap('<span></span>').appendTo('.wlist_header');
      },
      'is_wishlist': true
    }
  },
  'www.humblebundle.com': {
    'https://www\.humblebundle\.com/home/?': {
      'source_id': 'humblestore',
      'game_list': function() {
        var x, _i, _len, _ref, _results;
        _ref = $('div.row').has(' .downloads.windows .download, .downloads.linux .download, .downloads.mac .download, .downloads.android .download').find('div.title');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push({
            title: x.textContent.trim(),
            sources: ['humblestore']
          });
        }
        return _results;
      },
      'insert_button': function() {
        var a, label;
        label = $('<span class="label"></span>').html(BUTTON_LABEL);
        a = $('<a class="a" href="#"></span>').html(BUTTON_LABEL).css('padding-left', '9px');
        return $('<div class="flexbtn active noicon"></div>').append('<div class="right"></div>').append(label).append(a).css({
          float: 'right',
          fontSize: '14px',
          fontWeight: 'normal'
        }).prependTo('.base-main-wrapper h1');
      }
    }
  },
  'indiegamestand.com': {
    'https://indiegamestand\.com/wallet\.php': {
      'source_id': 'indiegamestand',
      'game_list': function() {
        var x, _i, _len, _ref, _ref1, _ref2, _ref3, _results;
        _ref = $('#wallet_contents .line-item');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push({
            url: (_ref1 = $('.game-thumb', x)) != null ? (_ref2 = _ref1.closest('a')) != null ? (_ref3 = _ref2[0]) != null ? _ref3.href : void 0 : void 0 : void 0,
            title: $('.game-title', x).text().trim(),
            sources: ['indiegamestand']
          });
        }
        return _results;
      },
      'insert_button': function() {
        return $('<div class="request key"></div>').html(BUTTON_LABEL).wrapInner("<div></div>").css({
          display: 'inline-block',
          marginLeft: '1em',
          verticalAlign: 'middle'
        }).appendTo('#game_wallet h2');
      }
    }
  },
  'www.shinyloot.com': {
    'https?://www\.shinyloot\.com/m/games/?': {
      'source_id': 'shinyloot',
      'game_list': function() {
        var x, _i, _len, _ref, _results;
        _ref = $('#accordion .ui-widget-content');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push({
            url: $('.right-float a img', x).closest('a')[0].href,
            title: $(x).prev('h3').text().trim(),
            sources: ['shinyloot']
          });
        }
        return _results;
      },
      'insert_button': shinyloot_insert_button
    },
    'https?://www\.shinyloot\.com/m/wishlist/?': {
      'source_id': 'shinyloot',
      'game_list': function() {
        var x, _i, _len, _ref, _results;
        _ref = $('.gameItem');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push({
            url: $('.gameInfo + a', x)[0].href,
            title: $('.gameName', x).text().trim()
          });
        }
        return _results;
      },
      'insert_button': shinyloot_insert_button,
      'is_wishlist': true
    }
  },
  'www.greenmangaming.com': {
    'https?://www\.greenmangaming\.com/user/account/': {
      'source_id': 'greenmangaming',
      'game_list': function() {
        var results, section, shops, x, y, _i, _j, _len, _len1, _ref, _ref1;
        results = [];
        _ref = $('#games #page_container section');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          y = _ref[_i];
          section = $("h2", y).text();
          if (/steam/i.test(section)) {
            shops = ['steam', 'greenmangaming'];
          } else if (/origin/i.test(section)) {
            shops = ['origin', 'greenmangaming'];
          } else {
            shops = ['greenmangaming'];
          }
          _ref1 = $('tbody tr', y);
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            x = _ref1[_j];
            results.push({
              url: $('td.download a', x)[0].href,
              title: $('td.name', x).text().trim(),
              sources: shops
            });
          }
        }
        return results;
      },
      'insert_button': function() {
        $(window).bind('hashchange', gmg_insert_button);
        return gmg_insert_button();
      }
    }
  }
};

scrapeGames = function(profile) {
  var form, params, url;
  params = {
    json: JSON.stringify(profile.game_list()),
    source: profile.source_id
  };
  url = profile.is_wishlist != null ? 'http://isthereanydeal.com/outside/user/wait/3rdparty' : 'http://isthereanydeal.com/outside/user/collection/3rdparty';
  form = $("<form id='itad_submitter' method='POST' />").attr('action', url);
  params['returnTo'] = location.href;
  form.css({
    display: 'none'
  });
  $.each(params, function(key, value) {
    return $("<input type='hidden' />").attr("name", key).attr("value", value).appendTo(form);
  });
  $(document.body).append(form);
  return form.submit();
};

$(function() {
  var profile, regex, _ref, _results;
  _ref = scrapers[location.host];
  _results = [];
  for (regex in _ref) {
    profile = _ref[regex];
    if (location.href.match(regex)) {
      $('#itad_btn, #itad_dlg, .itad_close').remove();
      if (typeof profile.insert_button === "function") {
        profile.insert_button().attr('id', 'itad_btn').click(function() {
          return scrapeGames(profile);
        });
      }
      break;
    } else {
      _results.push(void 0);
    }
  }
  return _results;
});
