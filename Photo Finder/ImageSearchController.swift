//
//  ImageSearchController.swift
//  Photo Finder
//
//  Created by Scott Krulcik on 10/4/15.
//  Copyright © 2015 Scott Krulcik. All rights reserved.
//

import Foundation

class ImageSearchController: NSObject {
    private var urlSession: NSURLSession
    private var responseDataKey = "responseData"
    private var imageResultListKey = "results"

    override init() {
        let urlConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        urlSession = NSURLSession(configuration: urlConfig)
        super.init()
    }

    func queryForImages(query dirtyQueryString:String, _ completion: ([ImageResult]? -> Void)) {
        if let queryString = dirtyQueryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()),
            let queryURL = NSURL(string: "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=\(queryString)") {
                let queryTask = urlSession.dataTaskWithURL(queryURL, completionHandler:{
                    (data: NSData?, response: NSURLResponse?, error: NSError?) in
                    guard data != nil && response != nil else {
                        NSLog("search/query/error \(error!)")
                        completion(nil)
                        return
                    }
                    NSLog("search/response/recieved")
                    do {
                        if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) as? [String: AnyObject],
                            let responseData = json[self.responseDataKey] as? [String : AnyObject],
                            let jsonResults = responseData[self.imageResultListKey] as? [[String : AnyObject]] {
                                completion(ImageResult.fromList(jsonResults))
                        }
                    } catch {
                        NSLog("search/response/invalid-data \(error)")
                    }
                })
                queryTask.resume()
        } else {
            NSLog("search/query/url/error URL creation failed")
        }
    }
    
}

