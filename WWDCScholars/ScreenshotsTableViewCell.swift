//
//  ScreenshotsTableViewCell.swift
//  WWDCScholars
//
//  Created by Andrew Walker on 17/04/2016.
//  Copyright © 2016 WWDCScholars. All rights reserved.
//

import UIKit

enum ScreenshotType: Int {
    case Scholarship
    case AppStore
}

class ScreenshotsTableViewCell: UITableViewCell, UICollectionViewDelegate, ImageTappedDelegate {
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var noScreenshotsLabel: UILabel!
    
    private var screenshotType: ScreenshotType = .Scholarship
    private var appStoreScreenshots: [URL] = []
    private var appStoreURL = ""
    
    var scholarshipScreenshots: [URL] = []
    var delegate: ImageTappedDelegate?
    var is2016: Bool = false {
        didSet {
            self.collectionViewTopConstraint.constant = self.is2016 == true ? 60.0 : 16.0
            self.layoutIfNeeded()
            
            if self.is2016 == true {
                segmentedControl.hidden = false
            }
        }
    }
    
    override func awakeFromNib() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.segmentedControl.applyScholarsSegmentedStyle()
        
        self.setNoScreenshotsLabelHidden(true)
        self.retrieveAppStoreScreenshots()
    }
    
    func setAppStoreURL(url: URL) {
        self.appStoreURL = url
        self.is2016 = (url == "") ? false : self.is2016
        guard self.appStoreURL != "" else {
            return
        }
        
        self.retrieveAppStoreScreenshots() {
            self.collectionView.reloadData()
        }
    }
    
    internal func showFullScreenImage(imageView: UIImageView) {
        self.delegate?.showFullScreenImage(imageView)
    }
    
    private func retrieveAppStoreScreenshots(completionHandler: (() -> Void)? = nil) {
        guard self.appStoreURL != "" else {
            return
        }
        
        let appID = String().matchesForRegexInText("([\\d]{10,})", text: self.appStoreURL).first
        if appID == nil {
            print("App Store URL is shortened version, impossible to retrieve APP ID", self.appStoreURL)
            
            return
        }
        
        let lookupURL = "http://itunes.apple.com/lookup?id=\(appID!)"
        
        request(.GET, lookupURL).responseString() { response in
            if let data = response.result.value {
                let json = JSON.parse(data)
                
                if let results = json["results"].array {
                    for appJson in results {
                        if let appStoreScreenshots = appJson["screenshotUrls"].array {
                            for screenshot in appStoreScreenshots {
                                if let screenshotString = screenshot.string {
                                    self.appStoreScreenshots.append(URL(screenshotString))
                                    completionHandler?()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private functions

    func setNoScreenshotsLabelHidden(hiddenStatus: Bool) {
        self.noScreenshotsLabel.hidden = hiddenStatus
    }
    
    // MARK: - IBActions
    
    @IBAction func segmentedControlChanged(sender: AnyObject) {
        self.screenshotType = ScreenshotType(rawValue: self.segmentedControl.selectedSegmentIndex) ?? .Scholarship
        
        switch self.screenshotType {
        case .Scholarship where self.scholarshipScreenshots.count == 0:
            self.setNoScreenshotsLabelHidden(false)
        case .AppStore where self.appStoreScreenshots.count == 0:
            self.setNoScreenshotsLabelHidden(false)
        default:
            self.setNoScreenshotsLabelHidden(true)
        }
        
        self.collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension ScreenshotsTableViewCell: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.screenshotType == .Scholarship ? self.scholarshipScreenshots.count : self.appStoreScreenshots.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("screenshotsCollectionViewCell", forIndexPath: indexPath) as! ScreenshotsCollectionViewCell

        let screenshot = NSURL(string: self.screenshotType == .Scholarship ? self.scholarshipScreenshots[indexPath.item] : self.appStoreScreenshots[indexPath.item])

        if screenshot != nil {
            cell.activityIndicator.startAnimating()
            cell.imageView.af_setImageWithURL(screenshot!, placeholderImage: nil, imageTransition: .CrossDissolve(0.2), runImageTransitionIfCached: false, completion: { response in
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.removeFromSuperview()
                
                // Don't cache screenshots
                let imageDownloader = UIImageView.af_sharedImageDownloader
                let urlRequest = NSURLRequest(URL: screenshot!)
                //Clear from in-memory cache
                imageDownloader.imageCache?.removeImageForRequest(urlRequest, withAdditionalIdentifier: nil)
                //Clear from on-disk cache
                imageDownloader.sessionManager.session.configuration.URLCache?.removeCachedResponseForRequest(urlRequest)
                
            })
        }
        
        cell.delegate = self
        
        return cell
    }
}


























