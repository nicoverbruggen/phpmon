# PHP Monitor

PHP Monitor (or phpmon) is a lightweight macOS utility app that runs on your Mac and displays the active PHP version in your status bar.

It also gives you quick access to various useful functionality (like switching PHP versions, restarting services, accessing configuration files, and more).

<img src="./docs/screenshot.png" width="278px" alt="phpmon screenshot"/>

For me, it comes in handy when running multiple versions of PHP with Homebrew. If you wish to be able to see at a glance which version is currently linked & active with Laravel Valet, PHP Monitor is your new best friend. 

It's also super convenient to and switch between versions.

## System requirements

* macOS 10.15 Catalina
* PHP 7.4 installed with Homebrew 2.x
* Laravel Valet 2.x

_Please note that future versions of PHP will not work automatically, minor changes are required to add support for newer versions of PHP._

## Why I built this

I wanted to be able to see at a glance which version of PHP was linked, and handle dealing with Laravel Valet in a simple app without having to deal with the terminal every time. 

Initially, I had an Alfred workflow for this. But this does the job as well, while also showing me at all times which version of PHP is linked (which is the main benefit over e.g. an Alfred workflow).

## How it works

### Version detection

This utility runs `php -r 'print phpversion()'` in the background periodically (every 60 seconds).

### Switching PHP versions

This utility will detect which PHP versions you have installed via Homebrew, and then allows you to switch between them.

This means:

- You have at least the latest version of PHP installed (`php@7.4`)
- You have installed Laravel Valet (`which valet` returns `/usr/local/bin/valet`)
- You ran `valet trust`, which means Valet commands can be run without using sudo

The utility runs the following commands:

- Unlink all detected PHP versions
- Switch to PHP 7.4 (this is done in order to ensure that Valet works, even when attempting to use PHP 5.6)
- Stop all php-fpm service instances
- Link the desired version of PHP
- Start the correct php-fpm service for the desired PHP version

### Want to know more?

If you want to know more about how this works, I recommend you check out the source code. 

This app isn't very complicated after all. In the end, this just (conveniently) executes some shell commands.

## Troubleshooting

**If you are having issues, the first thing you should be doing is installing the latest version of PHP Monitor. This can resolve a variety of issues.**

### Reasons for alerts at startup

PHP Monitor performs some integrity checks to ensure a good experience when using the app. You'll get a message telling you that PHP Monitor won't work correctly in the following scenarios:

- The PHP binary is not located in `/usr/local/bin/php`
- PHP 7.4 is missing in `/usr/local/opt`
- Laravel Valet is missing in `/usr/local/bin/valet`
- Brew has not been added to sudoers in `/private/etc/sudoers.d/brew`
- Valet has not been added to sudoers in `/private/etc/sudoers.d/valet`
- Multiple PHP services are active (see more info below)

Follow instructions as specified in the alert in order to resolve any issues.

### Additional troubleshooting

#### Q: I want PHP Monitor to start up when I boot my Mac!

You can do this by dragging *PHP Monitor.app* into the **Login Items** section in **System Preferences > Users & Groups** for your account.

Super convenient!

#### Q: PHP Monitor says that the latest version of PHP is not installed, but it is!

Try installing again using `brew install php@7.4`. 

This should resolve the issue.

#### Q: PHP Monitor reports another version compared to phpinfo on my local website, what is going on?

_Beginning with version 2.0 you'll get alerts about this at startup._

If you're still seeing another version of PHP in your scripts running on your local webserver (nginx) — e.g. when running `phpinfo()` — I recommend you shut down all PHP services that are currently active. You can find out what services are active by running:

    sudo brew services list | grep php

This will present to you a list of services, like so (depending on the installed versions of PHP):

```
php           started root /Library/LaunchDaemons/homebrew.mxcl.php.plist
php@5.6       stopped
php@7.0       stopped
php@7.1       stopped
php@7.2       stopped
php@7.3       stopped
```

You'll want to make sure that **only one service is running** and that it is running **as `root`**. You can terminate a service by running:

    sudo brew services stop {service_name}

So in order to disable PHP 7.3, you'd need to run:

    sudo brew services stop php@7.3

If you notice that PHP FPM is running as your own user account, you can turn off the service by running:

    brew services stop php@7.3

The easiest way to make sure that PHP Monitor works again is to run the following commands:

    sudo brew services stop php
    sudo brew services stop php@7.3
    sudo brew services stop php@7.2
    sudo brew services stop php@7.1
    sudo brew services stop php@7.0
    sudo brew services stop php@5.6
    sudo brew services stop nginx

Then, in PHP Monitor, select "Restart php-fpm service", which should start the service. 

Alternatively, you can run `sudo brew services start php@7.4` where `7.4` is your preferred version of PHP (for the latest version of PHP, you may omit `@7.4` like in the example above).

---

If this software has been useful to you, star the repository so I know that the software is being used. I did not include any tracking or analytics software, so if you encounter issues, let me know via an issue.
