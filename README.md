# PHP Monitor

PHP Monitor (or phpmon) is a macOS utility that runs on your Mac and displays the active PHP version in your status bar. 

<img src="./docs/screenshot.png" width="278px" alt="phpmon screenshot"/>

For me, it comes in handy when running multiple versions of PHP with Homebrew and you wish to be able to see at a glance which version is currently linked & active with Laravel Valet, and switch between versions.

## System requirements

Minimal system requirements are:

* macOS 10.14 or higher
* PHP 7.3 installed via Homebrew, other versions optional
* Laravel Valet 2.3 or higher installed

## Recommended setup

This means that this configuration is recommended and supported:

* macOS 10.15 Catalina
* PHP 7.3.x installed with Homebrew 2; other versions of PHP are optional (with support for PHP 5.6 and PHP 7.0 [as well](https://github.com/eXolnet/homebrew-deprecated))
* Laravel Valet 2.5.x

## Why I built this

I wanted to be able to see at a glance which version of PHP was linked, and handle dealing with Laravel Valet in a simple app without having to deal with the terminal every time. 

Initially, I had an Alfred workflow for this. But this does the job as well, while also showing me at all times which version of PHP is linked (which is the main benefit over e.g. an Alfred workflow).

## How it works

### Version detection

This utility runs `php -r 'print phpversion();'` in the background periodically (every 60 seconds) and extracts the version number.

### Switching PHP versions

This utility will detect which PHP versions you have installed via Homebrew, and then allows you to switch between them.

This means:

- You have at least the latest version of PHP installed (`php@7.3`)
- You have installed Laravel Valet (`which valet` returns `/usr/local/bin/valet`)
- You ran `valet trust`, which means Valet commands can be run without using sudo

The utility runs the following commands:

- Unlink all detected PHP versions
- Switch to PHP 7.3 (this is done in order to ensure that Valet works, even when attempting to use PHP 5.6)
- Tell Valet to switch to a specific PHP version
- Link the desired version of PHP

### Want to know more?

If you want to know more about how this works, I recommend you check out the source code. 

This app isn't very complicated after all. In the end, this just (conveniently) executes some shell commands.
