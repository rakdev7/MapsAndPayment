//
//  APIClient.swift
//  MapsAndPayment
//
//  Created by Rocky on 11/1/18.
//  Copyright © 2018 Rocky. All rights reserved.
//

import Foundation
import Alamofire
import Stripe

struct Ride {
    
    let pilotName: String
    
    let pilotVehicle: String
    
    let pilotLicense: String
    
}

class APIClient: NSObject, STPEphemeralKeyProvider {
    static let shared = APIClient()
    
    var baseURLString = "https://rocketrides.io"
    
    // MARK: Rocket Rides
    
    enum RequestRideError: Error {
        case missingBaseURL
        case invalidResponse
    }
    
    func requestRide(source: String, amount: Int, currency: String, completion: @escaping (Ride?, RequestRideError?) -> Void) {
        let endpoint = "/api/rides"
        
        guard
            !baseURLString.isEmpty,
            let baseURL = URL(string: baseURLString),
            let url = URL(string: endpoint, relativeTo: baseURL) else {
                completion(nil, .missingBaseURL)
                return
        }
        

        let parameters: [String: Any] = [
            "source": source,
            "amount": amount,
            "currency": currency,
            ]
        
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON { (response) in
            guard let json = response.result.value as? [String: Any] else {
                completion(nil, .invalidResponse)
                return
            }
            
            guard let pilotName = json["pilot_name"] as? String,
                let pilotVehicle = json["pilot_vehicle"] as? String,
                let pilotLicense = json["pilot_license"] as? String else {
                    completion(nil, .invalidResponse)
                    return
            }
            
            completion(Ride(pilotName: pilotName, pilotVehicle: pilotVehicle, pilotLicense: pilotLicense), nil)
        }
    }
    
    // MARK: STPEphemeralKeyProvider
    
    enum CustomerKeyError: Error {
        case missingBaseURL
        case invalidResponse
    }
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let endpoint = "/api/passengers/me/ephemeral_keys"
        
        guard
            !baseURLString.isEmpty,
            let baseURL = URL(string: baseURLString),
            let url = URL(string: endpoint, relativeTo: baseURL) else {
                completion(nil, CustomerKeyError.missingBaseURL)
                return
        }
        
        let parameters: [String: Any] = ["api_version": apiVersion]
        
        Alamofire.request(url, method: .post, parameters: parameters).responseJSON { (response) in
            guard let json = response.result.value as? [AnyHashable: Any] else {
                completion(nil, CustomerKeyError.invalidResponse)
                return
            }
            
            completion(json, nil)
        }
    }
}

