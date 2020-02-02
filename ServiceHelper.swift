//
//  ServiceHelper.swift
//  MirzaZuhaib
//
//  Created by Mirza Zuhaib Beg on 2/18/19.
//  Copyright © 2019 MirzaZuhaib. All rights reserved.
//

import Foundation
import UIKit

/// ServiceHelperConstant to store constant for ServiceHelper class
struct ServiceHelperConstant {

    static let KSuccessCode = 200

    /// Errors
    static let KInternetError = "Please check your internet connection."
    static let KError = "Error"

    /// APIs
    static let KSearchAPI = "search?"

    /// API Type
    static let KGET = "GET"
    
    /// Parameter Keys
    static let Kterm = "term"
    static let Kentity = "entity"
}

/// ServiceHelper class will act as helper for making network request
class ServiceHelper: NSObject {
    
    typealias CompletionBlock = (_ success: Bool, _ data: Any?, _ error: String?) -> Void
    
    typealias ErrorBlock = (_ error: String?) -> Void

    static let baseURL = "https://itunes.apple.com/"

    typealias ParseDataCompletionBlock = (_ success: Bool, _ data: Any?, _ error: Error?) -> Void
    
    static let sharedInstance = ServiceHelper()
    
    //MARK: Search API
    
    /// Method to search From Itunes
    ///
    /// - Parameters:
    ///   - searchText: search Text
    ///   - entity: entity
    ///   - completion: completion
    func searchFromItunes(withSearchText searchText: String?, entity: String?, withCompletionBlock completion: @escaping CompletionBlock){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard  appDelegate.isReachable == true else {
            completion(false, nil, ServiceHelperConstant.KInternetError)
            return
        }
        
        var parameters = [String: String]()
        if let searchText = searchText {
            parameters[ServiceHelperConstant.Kterm] = searchText.removingWhitespaces()
        }
        if let entity = entity {
            parameters[ServiceHelperConstant.Kentity] = entity.removingWhitespaces()
        }
        
        guard let request: NSMutableURLRequest = self.getGETURLRequest(parameters, api: ServiceHelperConstant.KSearchAPI)  else {
            completion(false,nil,nil)
            return
        }
        
        let networkManager = ITNetworkManager()
        networkManager.makeWebAPICall(request: request) { [weak self] (data, response, error) in
            if let data = data, let httpResponse = response as? HTTPURLResponse,  httpResponse.statusCode == ServiceHelperConstant.KSuccessCode {
                self?.parseData(withData: data, completionHandler: { (success, data, error) in
                    let searchItemList = self?.getSearchItemList(data)
                    completion(success, searchItemList, error?.localizedDescription)
                })
            } else {
                completion(false,nil,"Something went wrong!")
            }
        }
    }
    
    //MARK: Private Methods
    
    /// Method to get GET URL Request
    ///
    /// - Parameters:
    ///   - parameters: parameters
    ///   - api: api name
    /// - Returns: request
    func getGETURLRequest(_ parameters: [String: Any]?, api: String) -> NSMutableURLRequest? {
        var urlString : String = ITServiceHelper.baseURL + api
        
        // Append parametres for GET API
        if let parameters = parameters {
            var isFirstParam = true
            for (key, object) in parameters {
                if let object = object as? String {
                    if isFirstParam == false {
                        urlString = urlString + "&"
                    }
                    urlString = urlString + key + "=" + object
                    isFirstParam = false
                }
            }
        }
        
        if let url = URL(string: urlString) {
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url)
            request.httpMethod = ServiceHelperConstant.KGET
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request
        } else {
            return nil
        }
    }
    
    /// Method to parse Data
    ///
    /// - Parameters:
    ///   - data: data
    ///   - completionHandler: completion Handler
    fileprivate func parseData(withData data: Data, completionHandler: @escaping ParseDataCompletionBlock) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            if let json = json {
                completionHandler(true, json, nil)
            } else {
                completionHandler(false, nil, nil)
            }
        } catch let error {
            completionHandler(false, nil, error)
        }
    }
    
    //MARK: Parsing Methods
    
    /// Method to get Search Item List
    ///
    /// - Parameter data: data
    /// - Returns: ITSearchItem array
    fileprivate func getSearchItemList(_ data: Any?) -> [ITSearchItem] {
        
        var searchItemList = [ITSearchItem]()
        
        if let data = data as? [String: Any] {
            if let results = data["results"] as? [[String: Any]] {
                for result in results {
                    let searchItem = self.getSearchItem(result)
                    searchItemList.append(searchItem)
                }
            }
        }
        return searchItemList
    }
    
    /// Method to get Search Item
    ///
    /// - Parameter result: result data
    /// - Returns: ITSearchItem object
    fileprivate func getSearchItem(_ result: Any?) -> ITSearchItem {
        
        let searchItem = ITSearchItem()
        
        if let result = result as? [String: Any] {
            if let artistName = result["artistName"] as? String {
                searchItem.itemTitle = artistName
            }
            if let trackCensoredName = result["trackCensoredName"] as? String {
                searchItem.itemDesc = trackCensoredName
            }
            if searchItem.itemDesc == nil, let collectionCensoredName = result["collectionCensoredName"] as? String {
                searchItem.itemDesc = collectionCensoredName
            }
            if let artworkUrl100 = result["artworkUrl100"] as? String {
                searchItem.itemImage = artworkUrl100
            }
            if let previewUrl = result["previewUrl"] as? String {
                searchItem.itemPreviewUrl = previewUrl
            }
        }
        
        return searchItem
    }
}
