//
//  NetworkManager.swift
//  MirzaZuhaib
//
//  Created by MirzaZuhaib on 2/18/19.
//  Copyright © 2019 Mirza Zuhaib Beg. All rights reserved.
//

import Foundation

/// NetworkManager class to make network request
class NetworkManager: NSObject {
    
    /// Get Data From Server Completion block
    internal typealias GetDataFromServerCompletionClosure = (_ data:Data?, _ response: URLResponse?, _ error: Error?) -> Void
    
    /// Method to make Web API Call
    ///
    /// - Parameters:
    ///   - request: request
    ///   - completion: completion
    func makeWebAPICall(request: NSMutableURLRequest, withCompletionBlock completion: @escaping GetDataFromServerCompletionClosure) {
        DispatchQueue.global(qos: .userInitiated).async {
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                completion(data,response,error)
            })
            task.resume()
        }
    }
}
