#ZGParallaxView
******

ZGParallaxView is a parallax top header view with real time blur which can be attach to any subclass of UIScrollView, UITableView, even UIWebView.

Created by Swift 2.0 on XCode 7.1

#Requirements
******
ZGParallaxView requires Xcode 7 or even later, Swift 2.0 or later, target iOS 8.0 and above.
#How to
******
###Manual
Drag ZGParallaxView.swift into your project

```swift
parallaxView = ZGParallaxView.parallaxView(view, size: CGSizeMake(self.tableView.frame.size.width, 164))
parallaxView!.maxHeight = 300
parallaxView!.maxBlurRadius = 2
parallaxView!.minHeight = 164
parallaxView!.stickToHeader = true
tableView.tableHeaderView = parallaxView
```
#How it looks
******
![](./screencast.gif)
#Todo
******
* Add category for UITableView, UIWebView, UICollectionView, UIScrollView to make ZGParallaxView easy to use.
* Improve blur effect


#License
******
ZGParallaxView is available under the MIT license. See the LICENSE file for more info.


