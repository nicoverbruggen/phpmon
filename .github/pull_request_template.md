Hello there! Thank you for considering a pull request for PHP Monitor. 

Please read the text below first before you submit your PR.

## Do not PR unless...

In order to make development and maintenance of PHP Monitor easier, I ask that you _avoid_ making a pull request in the following situations:

* No issue has been associated with the changes you‘d like to merge
* You have not announced you will be addressing a particular issue
* The PR is a low effort change: e.g. commits that only fix typos or phrasing may not be accepted

(If you believe the phrasing of particular text in the app is unclear or incorrect, please open an issue first.)

In short: It is usually best to *get in touch first* if you are making substantial changes.

## About destination branches

Please keep in mind that `main` is reserved for the current code state of the latest release and should *never* be the destination branch unless a new release is happening. **Pull requests that target `main` will be closed without mercy.**

Usually, the best target is the stable `dev/x.x` branch that corresponds with the latest major version that is released. 

There may be a newer branch available, which is an appropriate place for bigger changes, but please keep in mind that it is usually best to announce you‘ll be working on such a change before you spend the time, since as the lead contributor I might not even want said change in the app. Thank you.

## Your changes

(feel free to remove the disclaimer above)

* Affected parts of the app: shared code / UI code / CLI (remove what does not apply)
* Estimated impact on performance: none / low / high (remove what does not apply)
* Made a new build with Xcode and tested this: yes / no (remove what does not apply)
* Tested on macOS version + architecture: (e.g. "Monterey on M1" or "Big Sur on Intel")
* References issue(s): (please reference the issue here, using # and the number of the issue)

(please describe what you have changed here)