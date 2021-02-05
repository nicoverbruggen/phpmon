# PHP Monitor

<img src="./phpmon/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" alt="phpmon icon" width="128px" />

PHP Monitor (or phpmon) is a lightweight macOS utility app that runs on your Mac and displays the active PHP version in your status bar.

<img src="./docs/screenshot.png" width="389px" alt="phpmon screenshot (menu bar app)"/>

<small><i>Screenshot: A menu showing all of the functionality of PHP Monitor.</i></small>

It's also super convenient to switch between different versions of PHP. You'll even get notifications (only if you choose to opt-in, of course)!

<img src="./docs/notification.png" width="370px" alt="phpmon screenshot (notification)"/>

It also gives you quick access to various useful functionality (like accessing configuration files, restarting services, and more).

## 🖥 System requirements

PHP Monitor is a universal application that runs on Apple Silicon **and** Intel-based Macs.

* macOS 10.15 Catalina or higher (works on macOS 11 Big Sur)
* Homebrew is installed in `/usr/local/homebrew` or `/opt/homebrew` (the default)
* The brew formula `php` has to be installed (which version is detected)
* Laravel Valet 2.13 or higher

_Please note that future versions of PHP will not work automatically, minor changes are usually required to add support for newer versions of PHP. You may need to update your Valet installation to keep everything working if a major version update of PHP has been released._

## 🚀 How to install

You can install via Homebrew, or may download the latest [release](https://github.com/nicoverbruggen/phpmon/releases).

To install via Homebrew, run:

	brew tap nicoverbruggen/homebrew-cask
	brew install --cask phpmon

To upgrade your existing installation, run:

	brew upgrade phpmon

_The app is signed and notarized, meaning all you have to do is approve its first launch._

## ⭐️ Star me!

If this software has been useful to you, all I ask is that you **please star the repository**, so I know that the software is being used. You can also send me  [feedback](https://twitter.com/nicoverbruggen) if the app came in handy. 😃

## 👨‍💻 Why build this?

I wanted to be able to **see at a glance** which version of PHP was linked, and handle dealing with Laravel Valet in a simple app without having to deal with the terminal every time. 

Initially, I had an Alfred workflow for this — but it has now been replaced with this utility, which also does a good job at displaying additional information at a glance, like the current PHP version, memory limits, and more.

## 🤬 The app won't start?!

PHP Monitor performs some integrity checks to ensure a good experience when using the app. You'll get a message telling you that PHP Monitor won't work correctly in a variety of scenarios. 

**Follow instructions as specified in the alert in order to resolve any issues.**

## 🏎 Quick Troubleshooting

If you are having issues, the first thing you should be doing is installing the latest version of PHP Monitor _and_ Laravel Valet. This can resolve a variety of issues. To upgrade Valet, run `composer global update`. Don't forget to run `valet install` after upgrading.

If you're still having issues, here's a few common issues and solutions:

<details>
<summary><strong>PHP Monitor tells me `php` is not installed</strong></summary>

Try installing again using `brew install php`. 

This should resolve the issue! If that does not fix the issue, run `brew link php --force`. (Afterwards, you may need to restart your terminal to make sure the new linked version is detected.)

	brew install php
	brew link php --force
	
</details>

<details>
<summary><strong>Valet sites won't load (502 Bad Gateway)</strong></summary>

If you're visiting your `.test` domain, and you're getting a 502 (Bad Gateway) after switching to a different PHP version, you're dealing with a common issue.

This problem is usually resolved by upgrading Valet and running `valet install` again.

	composer global update
	valet install

</details>
	
<details>
<summary><strong>One of the limits (memory limit, max POST size, max upload size) shows an exclamation mark</strong></summary>

The value you provided in your INI file is invalid. If that is the case, PHP will attempt to parse your value as bytes, which is usually unintended. (`1GB` will resolve to merely a few bytes, and all of your applications will run out of memory!)

You must a provide a value like so: `1024K`, `256M`, `1G`. Alternatively, `-1` is also allowed, or just an integer (which will result in N amount of bytes being the limit).

**Example**: Trying to use `1GB` as the memory limit, for example, will result in this exclamation mark. The correct way to set a 1GB limit is by using `1G` as the value. (Note: The displayed value will append `B` for clarity, so if you set `1G`, the value reported by PHP Monitor will be 1 GB.)

</details>

<details>
<summary><strong>One of my commented out extensions is not being detected</strong></summary>

The app searches in the relevant `php.ini` file for a specific pattern. For regular extensions:

* `extension="*.so"`
* `; extension="*.so"`

For Zend extensions:

* `zend_extension="*.so"`
* `; zend_extension="*.so"`

The `*` is a wildcard and the name of the extension. If you've commented out the extension, make sure you've commented it out with a semicolon (;) and a single space after the semicolon for PHP Monitor to detect it.
</details>

## 📝 Additional information

Please consult the [extra file](docs/ADDITIONAL.md) that contains more information. It may have answers to additional questions and more information to troubleshoot your problem.

I did not include any tracking or analytics software, so if you encounter issues, let me know [via an issue](https://github.com/nicoverbruggen/phpmon/issues/new).

## 💵 Support me?

I usually develop this application in my spare time, after work. If you find the application useful and you have a bit of money to spare, feel free to send me [a tip via PayPal](https://paypal.me/nicoverbruggen).

## 🚜 How it works

### Loading info about PHP in the background

This utility runs `php -r 'print phpversion()'` in the background periodically. It also checks your `.ini` files for extensions and loads more information about your limits (memory limit, POST limit, upload limit). 

In order to save power, this only happens once every 60 seconds.

### Switching PHP versions

This utility will detect which PHP versions you have installed via Homebrew, and then allows you to switch between them.

This means:

- You have at least the latest version of PHP installed (`php`)
- You have installed Laravel Valet (`which valet` returns `/usr/local/bin/valet`)
- You ran `valet trust`, which means Valet commands can be run without using sudo

The utility runs the following commands:

- Unlink all detected PHP versions
- Switch to whatever version of PHP `php` is at (this is done to ensure that Valet works, even when attempting to use PHP 5.6)
- Stop all php-fpm service instances
- Link the desired version of PHP
- Start the correct php-fpm service for the desired PHP version

### Want to know more?

If you want to know more about how this works, I recommend you check out the source code. 

This app isn't very complicated after all. In the end, this just (conveniently) executes some shell commands.

## 🔧 Build instructions

<img src="./docs/build.png" width="320px" alt="build button in Xcode"/>

If you'd like to build PHP Monitor yourself, you need:

* Xcode (usually the latest version)
* The contents of this repository

Once you have downloaded this repository, open `PHP Monitor.xcodeproj`, and you should be able to immediately build the app for your system by pressing Cmd-R. This will create a debug build. (If Xcode complains about code signing, you can turn it off.)

If you'd like to create a production build, choose "Any Mac" as the target and select Product > Archive.
