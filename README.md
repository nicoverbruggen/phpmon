# PHP Monitor

PHP Monitor (or phpmon) is a macOS utility that runs on your Mac and displays the active PHP version in your status bar. 

<img src="./docs/screenshot.png" width="278px" alt="phpmon screenshot"/>

For me, it comes in handy when running multiple versions of PHP with Homebrew and you wish to be able to see at a glance which version is currently linked & active with Laravel Valet, and switch between versions.

## System requirements

**Minimal system requirements**

* macOS 10.14 or higher
* PHP 7.4 installed via Homebrew
* Laravel Valet 2.3 or higher installed

**Recommended system**

* macOS 10.15 Catalina
* PHP 7.4 installed with Homebrew 2.2
    - other versions of PHP are optional
    - includes support for PHP 5.6 and PHP 7.0 [as well](https://github.com/eXolnet/homebrew-deprecated)
* Laravel Valet 2.5.x installed

## Why I built this

I wanted to be able to see at a glance which version of PHP was linked, and handle dealing with Laravel Valet in a simple app without having to deal with the terminal every time. 

Initially, I had an Alfred workflow for this. But this does the job as well, while also showing me at all times which version of PHP is linked (which is the main benefit over e.g. an Alfred workflow).

## How it works

### Version detection

This utility runs `php -r 'print phpversion();'` in the background periodically (every 60 seconds) and extracts the version number.

### Switching PHP versions

This utility will detect which PHP versions you have installed via Homebrew, and then allows you to switch between them.

This means:

- You have at least the latest version of PHP installed (`php@7.4`)
- You have installed Laravel Valet (`which valet` returns `/usr/local/bin/valet`)
- You ran `valet trust`, which means Valet commands can be run without using sudo

The utility runs the following commands:

- Unlink all detected PHP versions
- Switch to PHP 7.4 (this is done in order to ensure that Valet works, even when attempting to use PHP 5.6)
- Tell Valet to switch to a specific PHP version
- Link the desired version of PHP

### Want to know more?

If you want to know more about how this works, I recommend you check out the source code. 

This app isn't very complicated after all. In the end, this just (conveniently) executes some shell commands.

## Troubleshooting

### Reasons for alerts at startup

PHP Monitor performs some integrity checks to ensure a good experience when using the app. You'll get a message telling you that PHP Monitor won't work correctly in the following scenarios:

- The PHP binary is not located in `/usr/local/bin/php`
- PHP 7.4 is missing in `/usr/local/opt`
- Laravel Valet is missing in `/usr/local/bin/valet`
- Brew has not been added to sudoers in `/private/etc/sudoers.d/brew`
- Valet has not been added to sudoers in `/private/etc/sudoers.d/valet`

Follow instructions as specified in the alert in order to resolve any issues.

### Still seeing another PHP version (from before switching versions)?

If you're still seeing an old version of PHP in your scripts — e.g. when running `phpinfo()` — I recommend you shut down the PHP service by running: 

    sudo brew services stop php

Please note that PHP Monitor will not be able to stop this service (it doesn't run as an administrator), so you'll need to handle this yourself.

You should only have to do this **once**, and then PHP Monitor should work as usual. 
