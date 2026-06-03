# Ares LFRP Plugin

An unofficial Looking for RP plugin for AresMUSH.

This plugin lets approved characters mark themselves as looking for roleplay and displays active LFRP entries in the web portal sidebar.

The original idea for adding a Looking for RP sidebar tool to an AresMUSH web portal was inspired by [Red Planet](https://redplanetmu.com/).

## Support Status

This is an unofficial community plugin. It is not part of AresMUSH core.

This plugin was built for Age of Heroes MUSH and is shared for other AresMUSH games that want a lightweight Looking for RP sidebar tool.

Tested on AresMUSH / ares-webportal v2.11.x.

Other versions may work, but have not been tested.

## Features

* Lets approved characters mark themselves as looking for RP.
* Lets players clear their LFRP status.
* Shows active LFRP entries in the web portal sidebar.
* Supports scene-type labels: Any Scene, TXT Only, Live Only, and Async Only.
* Expires LFRP entries automatically.
* Provides in-game commands and help.
* Provides web request handlers for portal integration.
* Supports websocket-driven sidebar updates with a periodic refresh fallback.
* Includes optional neutral sidebar styling.

## Commands

The plugin provides the following in-game commands:

    lfrp
    lfrp/list
    lfrp/stop

The exact help text is included in:

    plugin/help/en/lfrp.md

## Configuration

Configuration lives in:

    game/config/lfrp.yml

Default configuration:

    ---
    lfrp:
      default_hours: 6
      max_hours: 12
      announce_channel: RP Requests
      refresh_seconds: 60

`default_hours` controls how long an LFRP entry lasts when no duration is provided.

`max_hours` caps the longest LFRP duration.

`announce_channel` controls which channel receives LFRP start, stop, and preference-change announcements.

`refresh_seconds` controls the web portal sidebar's periodic fallback refresh. The default is 60 seconds when the value is missing, blank, or not a number. Set this to 0 to disable automatic polling. Values from 1 through 4 are treated as 5 seconds. Values above 60 are treated as 60 seconds.

The sidebar also listens for the custom `lfrp_update` websocket event. When someone starts, stops, or changes their LFRP status, the server pushes an update to connected web clients so the sidebar can update without waiting for the next fallback refresh.

## Repository Layout

    plugin/
      Server-side AresMUSH plugin files. Ares installs these into `aresmush/plugins/lfrp/`.

    game/config/
      Default configuration file.

    custom_files/
      Manual merge files for web portal and website customizations. The Ares installer ignores this folder.

## Install

1. Run `plugin/install https://github.com/whimsiquelle/ares-lfrp-plugin`.
2. Review `game/config/lfrp.yml`.
3. Manually review and merge the files in `custom_files/`.
4. Run `website/deploy` after modifying anything in `ares-webportal`.

## Web Portal Files

The web portal files are provided as custom files because many AresMUSH games already customize their sidebar and custom website data.

Do not blindly overwrite your existing web portal or website custom files if your game already has local edits.

Common files to compare and merge:

    aresmush/plugins/website/custom_web_data.rb
    ares-webportal/app/components/sidebar-custom.hbs
    ares-webportal/app/components/sidebar-custom.js

`custom_web_data.rb` supplies the sidebar with the LFRP list and whether the current viewer can use LFRP.

The included sidebar component uses these web request handlers:

    lfrpList
    lfrpStart
    lfrpStop

The sidebar loads the LFRP list when it starts, listens for `lfrp_update` websocket events, and keeps a periodic fallback refresh so missed websocket events and natural expirations self-correct.

## Styling

This repository includes optional neutral sidebar styling in:

    custom_files/lfrp.scss

Copy that file into your game's `custom_style.scss`, or adapt it to match your site's theme.

The stylesheet intentionally avoids Age of Heroes-specific colors, fonts, borders, shadows, and comic-page styling. It only provides basic layout rules for the LFRP sidebar list, buttons, dropdown, empty state, and scene-type badge.

The main classes are:

    .looking-for-rp
    .lfrp-list
    .lfrp-entry
    .lfrp-empty
    .lfrp-buttons
    .lfrp-button
    .lfrp-scene-type-badge

## What This Plugin Does Not Do

This plugin does not overwrite `who.hbs`.

Games that want a Who-page LFRP indicator should add that separately as a local customization.

This plugin does not include a full site theme.

This plugin does not guarantee compatibility with every customized sidebar. If your game already has significant sidebar changes, merge the custom files manually.

## Uninstall

You will need to remove the LFRP database objects, remove the plugin files, remove the config file, and remove any web portal customizations you merged manually.

See the AresMUSH guide to removing plugins for general help:

https://aresmush.com/tutorials/code/contribs.html#uninstalling-plugins




## License

This is an unofficial community plugin for AresMUSH. Community-developed AresMUSH plugins fall under the same license requirements as the original AresMUSH code.
