# VisionKit plugin for Cordova

A wrapper around the iOS 13 VisionKit API's to provide document scanning on iOS.

**VisionKit requires iOS 13+**

## Installation
```
   $ cordova plugin add cordova-plugin-visionkit
```

## Usage
```
  const success = (images) => {
    images.forEach((path) => {
      console.log(path);
    });
  };

  const failure = (error) => {
    console.error(failure);
  };

  window.VisionKit.scan(success, failure);
```

_Note: If the user cancels the scanner you'll recieve a success callback with an empty array_
