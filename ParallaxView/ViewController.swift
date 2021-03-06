//
//  ViewController.swift
//  ParallaxView
//
//  Created by Phil Chia on 15/11/4.
//  Copyright © 2015年 TouchDream. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet var tableView: UITableView!
	var parallaxView: ZGParallaxView?
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
		let view = UIImageView(image: UIImage(named: "1.png"))
		view.contentMode = .ScaleAspectFill
		var frame = view.frame
		frame.size =  CGSizeMake(self.tableView.frame.size.width, 64)
		view.frame = frame
		parallaxView = ZGParallaxView.parallaxView(withSubView: view, andSize: CGSizeMake(self.tableView.frame.size.width, 64))
		parallaxView!.maxHeight = 150
		parallaxView!.minHeight = 64
		parallaxView!.maxBlurAlpha = 0.4
		parallaxView!.blurEffect = .Light
		tableView.tableHeaderView = parallaxView
		tableView.showsVerticalScrollIndicator = false
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 100
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
		cell.textLabel!.text = "Override Me!!"
		return cell
	}
	
	func limitScrollViewOffset(offset: CGFloat) {
		self.tableView.contentOffset.y = offset
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		parallaxView?.scrollViewDidScroll(scrollView)
	}
}

