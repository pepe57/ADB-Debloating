# Debloat MIUI/HyperOS, One UI, and Pixel Launcher via ADB

[telegram-news-badge]: https://img.shields.io/badge/Sophia%20News-Telegram-blue?style=flat&logo=Telegram
[telegram-news]: https://t.me/sophianews
[telegram-group]: https://t.me/sophia_chat
[telegram-group-badge]: https://img.shields.io/badge/Sophia%20Chat-Telegram-blue?style=flat&logo=Telegram

[![Telegram][telegram-news-badge]][telegram-news] [![Telegram][telegram-group-badge]][telegram-group]

## How-to

* Enable USB debugging in developer settings page
* Connect your phone to PC via USB cable
* Download [latest](https://github.com/farag2/ADB-Debloating/releases/latest) release
* Open PowerShell as admin and run `Set-ExecutionPolicy -ExecutionPolicy Bypass -Force`
* Change location to folder
* Right-click on `Download_ADB.ps1` to download the latest ADB
* Run `Function.ps1` to choose which application to remove

## Links

* [Google USB Driver](https://developer.android.com/studio/run/win-usb)
  * [Official all OEMs drivers](https://developer.android.com/studio/run/oem-usb#Drivers)
* [Download ADB](https://developer.android.com/studio/releases/platform-tools)
* [App Inspector](https://play.google.com/store/apps/details?id=com.jgba.appinspector)
* [ADB AppControl](https://4pda.to/forum/index.php?showtopic=993643)

# Addendum

## Get apps packages list

```cmd
adb.exe shell pm list packages -f > D:\packages.txt
```

## Copy folder to local drive

```cmd
# /storage/emulated/0
# /sdcard

# Check the whole filesystem
adb shell ls /data

adb pull /storage/3039-3538/dcim/camera D:\folder
adb pull sdcard/DCIM/Camera D:\folder
```
