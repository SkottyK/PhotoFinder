//
//  ImageSearchController.swift
//  Photo Finder
//
//  Created by Scott Krulcik on 10/4/15.
//  Copyright © 2015 Scott Krulcik. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ImageSearchController: NSObject {
    private var urlSession: NSURLSession
    private var imageResultListKey = "items"
    let apiKey = "API_KEY_PLACEHOLDER"
    let cxString = "CX_STRING_PLACEHOLDER"
    let apiURL = "https://www.googleapis.com/customsearch/v1"
    let chunkSize = 6
    /*
     * num [1, 10] The number of search results to return
     * searchType {"image",""} Specifies regular or image search
     * cx Name of the custom search
     * key private API key
     */
    var params: String {
        return "cx=\(cxString)&key=\(apiKey)&searchType=image&num=\(chunkSize)"
    }

    override init() {
        let urlConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        urlSession = NSURLSession(configuration: urlConfig)
        super.init()
    }

    func queryForImages(query dirtyQueryString:String, withOffset offset:Int, _ completion: ([ImageResult]? -> Void)) {
        if let queryString = dirtyQueryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()),
            let queryURL = NSURL(string: "\(apiURL)?\(params)&q=\(queryString)&start=\(offset)") {
                let queryTask = urlSession.dataTaskWithURL(queryURL, completionHandler:{
                    (data: NSData?, response: NSURLResponse?, error: NSError?) in
                    guard data != nil && response != nil else {
                        NSLog("search/query/error \(error!)")
                        completion(nil)
                        return
                    }
                    do {
                        if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) as? [String: AnyObject] {
                            if let jsonResults = json[self.imageResultListKey] as? [[String : AnyObject]] {
                                completion(ImageResult.fromList(jsonResults))
                            }
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

    func addQueryToHistory(rawQuery: String, clean cleanQuery: String) {
        let request = NSFetchRequest(entityName: RecentSearch.entityName)
        request.fetchBatchSize = 1 // Should only be one of each query
        request.predicate = NSPredicate(format: "displayString LIKE %@", rawQuery)
        do {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let objs = try appDelegate.managedObjectContext.executeFetchRequest(request)
            if let matches = objs as? [RecentSearch],
                let otherSearch = matches.first {
                    otherSearch.lastSearchDate = NSDate().timeIntervalSince1970
            } else {
                if let description = NSEntityDescription.entityForName(RecentSearch.entityName, inManagedObjectContext: appDelegate.managedObjectContext),
                    let newSearch = NSManagedObject(entity: description, insertIntoManagedObjectContext: appDelegate.managedObjectContext) as? RecentSearch {
                        newSearch.lastSearchDate = NSDate().timeIntervalSince1970
                        newSearch.displayString = rawQuery
                        newSearch.queryString = cleanQuery
                }
            }
            NSLog("search/history/update \(rawQuery)")
            appDelegate.saveContext()
        } catch {
            NSLog("search/history/add-query/error \(error)")
        }
    }
    
}

