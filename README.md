# DontKillMyMusic

A tweak that prevents you from killing the app that is currently playing.

## How does it work?
  First, I hooked into `SBMediaController` to check if there is any app that is playing. In that class there is a method called `_mediaRemoteNowPlayingApplicationIsPlayingDidChange` which is perfect because it gets called evertime an app starts/ends playing. In that method I store `isPlaying` into `playing` &  `bundleIdentifier` into `playingAppId`.
  
  Then, I hooked into `SBAppLayout`, which is the class used for all the appswithcer cards. Unlike `SBMediaController` there isn't `bundleIdentifier` variable lying around, but there is an NSDictionary called `rolesToLayoutItemsMap` which contains the bundleId of the switcher cards. so I made created a method  called `getAppId` to set the switcher card's bundleId to `swipeAppId`.
  
  Finally, I hooked into `SBFluidSwitcherItemContainer`, which basically controls the entire appswitcher. In `layoutSubviews` I called `getAppId` then compared `playingAppId` and `swipeAppId` and if it is true, set the width of the UIScrollView of the app to 0, so you wouldn't be able to swipe it.
  
  NOTE: I didn't cover extra things, like other tweak support or app lock for other apps.
  
## Changlog

* V1.0.3-2 (Current)
  - Fixed bug where you cant enter an app when it is tapped if lockapp isnt enabled.

* V1.0.3-1
  - Fixed typo in the settings section.

* V1.0.3
  - Added the ability to lock other apps if you wish so.

* V1.0.2-1
  - Added toggle for EasySwitcherX fix

* V1.0.2
  - Support for EasySwitcherX
  - Code Cleanup

* V1.0.1
  - Enable Bug fix
  - Support for SBCard by julioverne
  - Added Icon by [@hasteDesigns](https://twitter.com/hasteDesigns)

* V1.0.0  
  - Inital Relase

## Download

* Add my [repo](https://github.com/Karimo299/repo)
* You can also download the deb from [here](./packages)

## Credits

* [Karimo299](https://twitter.com/karimo299)
* [hasteDesigns](https://twitter.com/hasteDesigns)
