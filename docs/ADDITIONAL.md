### Q&A

#### Q: Does this support Apple Silicon?

Yes. This is a universal app.

#### Q: Is PHP 8.x supported?

Yes.

#### Q: This app is doing network requests? Why?

It's Homebrew. I can't prevent `brew` from doing things via the network when I invoke it.

PHP Monitor itself doesn't do any network requests. Feel free to check the source code or intercept the traffic, if you don't believe me.

#### Q: How can I set this up on a fresh Mac?

If you want to set up your computer for the very first time, here's how I do it:

Install [Homebrew](https://brew.sh) first.

Install PHP, composer, add to path:

    brew install php
    brew install composer
    nano .zshrc

Make sure the following line is not in the comments:

    export PATH=$HOME/bin:/usr/local/bin:$PATH

and add the following to your .zshrc:

    export PATH=$HOME/bin:~/.composer/vendor/bin:$PATH

Make sure PHP is linked correctly:

    which php

should return: `/usr/local/bin/php`

    composer global require laravel/valet
    valet install

This should install `dnsmasq` and set up Valet. Great, almost there!

    valet trust

Finally, run PHP Monitor. Since the app is notarized and signed with a developer ID, it should work.

#### Q: I want PHP Monitor to start up when I boot my Mac!

You can do this by dragging *PHP Monitor.app* into the **Login Items** section in **System Preferences > Users & Groups** for your account.

Super convenient!

#### Q: PHP Monitor says that the latest version of PHP is not installed, but it is!

Try installing again using `brew install php`. 

This should resolve the issue.

#### Q: PHP Monitor says the correct version is loaded, but my Valet sites don't work!

You may need to run `valet install`. (Preferably after updating `valet` by running `composer global update`).

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
