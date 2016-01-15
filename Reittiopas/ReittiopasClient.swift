//
//  ReittiopasClient.swift
//  iReitti
//
//  Created by Jesse Sipola on 30.12.2015.
//  Copyright © 2015 Jesse Sipola. All rights reserved.
//

import Foundation
import MapKit
import Alamofire

protocol ReittiopasClientDelegate {
    func updatedSearchResults()
}

class ReittiopasClient {
    
    var delegate: ReittiopasClientDelegate?
    let defaultParameters = [
        "userhash" : Userhash.key,
        "epsg_in" : "4326",
        "epsg_out" : "4326"
    ]
    
    var latestSearchResults: [Route] = [] {
        didSet {
            if latestSearchResults.count > 0 {
                getLines()
            } else {
                delegate?.updatedSearchResults()
            }
        }
    }
    var lineInformation = [String : Line]()
    
    private func getLines() {
        if latestSearchResults.count > 0 {
            var linesQuery: String?
            
            for route in latestSearchResults {
                if let codes = route.getLineCodes() {
                    for code in codes {
                        if lineInformation[code] == nil {
                            if linesQuery == nil {
                                linesQuery = "\(code)"
                            } else {
                                linesQuery = "\(linesQuery!)|\(code)"
                            }
                        }
                    }
                }
            }
            
            if linesQuery != nil {
                print("Searching for lines...")
                var parameters = [
                    "request" : "lines",
                    "query" : linesQuery!
                ]
                parameters.update(defaultParameters)
                
                Alamofire.request(.GET, "http://api.reittiopas.fi/hsl/beta/", parameters: parameters, encoding: ParameterEncoding.URL).responseCollection { (response: Response<[Line], NSError>) in
                    
                    if let results = response.result.value {
                        for line in results {
                            if let code = line.code {
                                self.lineInformation[code] = line
                            } else {
                                print("failed getting code for \(line)")
                            }
                        }
                    } else {
                        print(response.request)
                        print(response.result.error)
                    }
                    self.delegate?.updatedSearchResults()
                }
            } else {
                self.delegate?.updatedSearchResults()
                print("Fail")
            }
        }
    }
    
    func getRoutes(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, when: NSDate, timetype: String = "departure") {
        print("Searching for routes at \(when.description)...")
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = NSTimeZone(abbreviation: "EET")
        formatter.locale = NSLocale.currentLocale()
        
        let date = formatter.stringFromDate(when)
        
        formatter.dateFormat = "HHmm"

        let time = formatter.stringFromDate(when)
        
        var parameters = [
            "request" : "route",
            "from" : "\(from.longitude),\(from.latitude)",
            "to" : "\(to.longitude),\(to.latitude)",
            "time": time,
            "date": date,
            "show": "5",
            "timetype": timetype,
            "detail": "full"
        ]
        parameters.update(defaultParameters)
        
        Alamofire.request(.GET, "http://api.reittiopas.fi/hsl/beta/", parameters: parameters, encoding: ParameterEncoding.URL).responseCollection { (response: Response<[Route], NSError>) in
            
            if let results = response.result.value {
                self.latestSearchResults = results
            } else {
                self.latestSearchResults = []
                print(response.request)
                print(response.result.error)
            }
            
        }
        
    }
    
}