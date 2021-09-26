//
//  MenuViewController.swift
//  PhotoBrowserDemo
//
//  Created by Eduardo Callado on 11/27/16.
//
//

import UIKit

class MenuViewController: UITableViewController, IDMPhotoBrowserDelegate { }

// MARK: View Lifecycle

extension MenuViewController {
	override func viewDidLoad() {
		self.setupTableViewFooterView()
	}
}

// MARK: Layout

extension MenuViewController {
	override var prefersStatusBarHidden: Bool {
		return true
	}
}

// MARK: General

extension MenuViewController {
	func setupTableViewFooterView() {
		let tableViewFooter: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 426 * 0.9 + 40))
		
		let buttonWithImageOnScreen1 = UIButton(type: .custom)
		buttonWithImageOnScreen1.frame = CGRect(x: 15, y: 0, width: 640/3 * 0.9, height: 426/2 * 0.9)
		buttonWithImageOnScreen1.tag = 101
		buttonWithImageOnScreen1.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen1.setImage(UIImage(named: "photo1m.jpg"), for: .normal)
		buttonWithImageOnScreen1.imageView?.contentMode = .scaleAspectFill
		buttonWithImageOnScreen1.backgroundColor = UIColor.black
		buttonWithImageOnScreen1.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(sender:)), for: .touchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen1)
		
		let buttonWithImageOnScreen2 = UIButton(type: .custom)
		buttonWithImageOnScreen2.frame = CGRect(x: 15, y: 426/2 * 0.9 + 20, width: 640/3 * 0.9, height: 426/2 * 0.9)
		buttonWithImageOnScreen2.tag = 102
		buttonWithImageOnScreen2.adjustsImageWhenHighlighted = false
		buttonWithImageOnScreen2.setImage(UIImage(named: "photo3m.jpg"), for: .normal)
		buttonWithImageOnScreen2.imageView?.contentMode = .scaleAspectFill
		buttonWithImageOnScreen2.backgroundColor = UIColor.black
		buttonWithImageOnScreen2.addTarget(self, action: #selector(buttonWithImageOnScreenPressed(sender:)), for: .touchUpInside)
		tableViewFooter.addSubview(buttonWithImageOnScreen2)
		
		self.tableView.tableFooterView = tableViewFooter;
	}
}

// MARK: Actions

extension MenuViewController {
    @objc func buttonWithImageOnScreenPressed(sender: AnyObject) {
		let buttonSender = sender as? UIButton
		
		// Create an array to store IDMPhoto objects
		var photos: [IDMPhoto] = []
		
		var photo: IDMPhoto
		
		if buttonSender?.tag == 101 {
			let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")!]
			photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
			photo.caption = "Grotto of the Madonna"
			photos.append(photo)
		}
		
		let path_photo3l = [Bundle.main.path(forResource: "photo3l", ofType: "jpg")!]
		photo = IDMPhoto.photos(withFilePaths:path_photo3l).first as! IDMPhoto
		photo.caption = "York Floods"
		photos.append(photo)
		
		let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")!]
		photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
		photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
		photos.append(photo)
		
		let path_photo4l = [Bundle.main.path(forResource: "photo4l", ofType: "jpg")!]
		photo = IDMPhoto.photos(withFilePaths:path_photo4l).first as! IDMPhoto
		photo.caption = "Campervan";
		photos.append(photo)
		
		if buttonSender?.tag == 102 {
			let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")!]
			photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
			photo.caption = "Grotto of the Madonna";
			photos.append(photo)
		}
		
		// Create and setup browser
		let browser: IDMPhotoBrowser = IDMPhotoBrowser(photos: photos, animatedFrom: buttonSender) // using initWithPhotos:animatedFromView:
		browser.delegate = self
		browser.displayActionButton = false
		browser.displayArrowButton = true
		browser.displayCounterLabel = true
		browser.usePopAnimation = true
		browser.scaleImage = buttonSender?.currentImage
		browser.dismissOnTouch = true
		
		// Show
		self.present(browser, animated: true, completion: nil)
	}
}

// MARK: TableView Data Source

extension MenuViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return 4
		case 2:
			return 0
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Single photo"
		case 1:
			return "Multiple photos"
		case 2:
			return "Photos on screen"
		default:
			return ""
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		// Create
		let cellIdentifier = "Cell";
		var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
		}
		
		// Configure
		if indexPath.section == 0 {
			cell?.textLabel?.text = "Local photo"
		} else if indexPath.section == 1 {
			switch indexPath.row {
			case 0:
				cell?.textLabel?.text = "Local photos"
			case 1:
				cell?.textLabel?.text = "Photos from Flickr"
            case 2:
                cell?.textLabel?.text = "Photos from Flickr - Custom"
            case 3:
                cell?.textLabel?.text = "Video"
			default:
				break
			}
		}
		
		return cell!
	}
}

// MARK: TableView Delegate

extension MenuViewController {
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		// Create an array to store IDMPhoto objects
		var photos: [IDMPhoto] = []
		
		var photo: IDMPhoto
		
		if indexPath.section == 0 { // Local photo
			let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")!]
			photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
			photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
			photos.append(photo)
		}
		else if indexPath.section == 1 { // Multiple photos
			if indexPath.row == 0 { // Local Photos
				let path_photo1l = [Bundle.main.path(forResource: "photo1l", ofType: "jpg")!]
				photo = IDMPhoto.photos(withFilePaths:path_photo1l).first as! IDMPhoto
				photo.caption = "Grotto of the Madonna"
				photos.append(photo)
				
				let path_photo2l = [Bundle.main.path(forResource: "photo2l", ofType: "jpg")!]
				photo = IDMPhoto.photos(withFilePaths:path_photo2l).first as! IDMPhoto
				photo.caption = "The London Eye is a giant Ferris wheel situated on the banks of the River Thames, in London, England."
				photos.append(photo)
				
				let path_photo3l = [Bundle.main.path(forResource: "photo3l", ofType: "jpg")!]
				photo = IDMPhoto.photos(withFilePaths:path_photo3l).first as! IDMPhoto
				photo.caption = "York Floods"
				photos.append(photo)
				
				let path_photo4l = [Bundle.main.path(forResource: "photo4l", ofType: "jpg")!]
				photo = IDMPhoto.photos(withFilePaths:path_photo4l).first as! IDMPhoto
				photo.caption = "Campervan";
				photos.append(photo)
            } else if indexPath.row == 1 || indexPath.row == 2 { // Photos from Flickr or Flickr - Custom
                let photosWithURLArray = [NSURL.init(string: "http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg")!,
                                          NSURL.init(string: "http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg")!,
                                          NSURL.init(string: "http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg")!,
                                          NSURL.init(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!]
                let photosWithURL: [IDMPhoto] = IDMPhoto.photos(withURLs: photosWithURLArray) as! [IDMPhoto]

                photos = photosWithURL
            } else if indexPath.row == 3 { // Videos
                let video1 = IDMPhoto(videoURL: URL(string: "http://vjs.zencdn.net/v/oceans.mp4")!)!
                video1.caption = "Big Buck Bunny — by THE PEACH OPEN MOVIE PROJECT"
                video1.videoThumbnailURL = URL(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!;
                video1.failureImage = UIImage(named: "photo1m.jpg")

                let photo1 = IDMPhoto(url: URL(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!)!
                photo1.caption = "A standard picture separating two videos"

                let video2 = IDMPhoto(videoURL: URL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!)!
                video2.caption = "A cover coming straight from coverr.co for an example"
                video2.videoThumbnailURL = URL(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!;
                video2.failureImage = UIImage(named: "photo3m.jpg")

                let video3 = IDMPhoto(videoURL: URL(string: "https://dev.spond.com/storage/video/122863E2382B693E0B2702A27579E8D9/stream.m3u8")!)!
                video3.caption = "A cover coming straight from coverr.co for an example"
                video3.videoThumbnailURL = URL(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!;
                video3.failureImage = UIImage(named: "photo4m.jpg")

                let video4 = IDMPhoto(videoURL: URL(string: "https://dev.spond.com/storage/video/1ECA36B273D5B69C5C0E2D5B4CA9DB86/stream.m3u8")!)!
                video4.caption = "A cover coming straight from coverr.co for an example"
                video4.videoThumbnailURL = URL(string: "http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg")!;
                video4.failureImage = UIImage(named: "photo2m.jpg")

                let videos: [IDMPhoto] = [
                    video1,
                    photo1,
                    video2,
                    video3,
                    video4
                ]

                photos = videos
            }
		}

		// Create and setup browser
		let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayActionButton = true
        browser?.displayArrowButton = false
        browser?.usePopAnimation = true
        browser?.useWhiteBackgroundColor = false
        browser?.displayDoneButton = true

		browser?.delegate = self

		if indexPath.section == 1 { // Multiple photos
			if indexPath.row == 1 || indexPath.row == 3 { // Photos from Flickr
				browser?.displayCounterLabel = true
			} else if indexPath.row == 2 { // Photos from Flickr - Custom
				browser?.actionButtonTitles      = ["Option 1", "Option 2", "Option 3", "Option 4"]
				browser?.displayCounterLabel     = true
				browser?.useWhiteBackgroundColor = true
				browser?.leftArrowImage          = UIImage(named: "IDMPhotoBrowser_customArrowLeft.png")
				browser?.rightArrowImage         = UIImage(named: "IDMPhotoBrowser_customArrowRight.png")
				browser?.leftArrowSelectedImage  = UIImage(named: "IDMPhotoBrowser_customArrowLeftSelected.png")
				browser?.rightArrowSelectedImage = UIImage(named: "IDMPhotoBrowser_customArrowRightSelected.png")
				browser?.doneButtonImage         = UIImage(named: "IDMPhotoBrowser_customDoneButton.png")
				browser?.view.tintColor          = UIColor.orange
				browser?.progressTintColor       = UIColor.orange
                browser?.trackTintColor          = UIColor(white: 0.8, alpha: 1)
			}
		}
		
		// Show
		present(browser!, animated: true, completion: nil)
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

// MARK: IDMPhotoBrowser Delegate

extension MenuViewController {
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
		let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
		print("Did show photoBrowser with photo index: \(index), photo caption: \(photo.caption!)")
	}
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, willDismissAtPageIndex index: UInt) {
		let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
		print("Will dismiss photoBrowser with photo index: \(index), photo caption: \(photo.caption!)")
	}
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didDismissAtPageIndex index: UInt) {
		let photo: IDMPhoto = photoBrowser.photo(at: index) as! IDMPhoto
		print("Did dismiss photoBrowser with photo index: \(index), photo caption: \(photo.caption!)")
	}
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didDismissActionSheetWithButtonIndex buttonIndex: UInt, photoIndex: UInt) {
		let photo: IDMPhoto = photoBrowser.photo(at: buttonIndex) as! IDMPhoto
		print("Did dismiss photoBrowser with photo index: \(buttonIndex), photo caption: \(photo.caption!)")
		
		UIAlertView(title: "Option \(buttonIndex+1)", message: nil, delegate: nil, cancelButtonTitle: "OK").show()
	}
}
