//
//  Route.swift
//  iReitti
//
//  Created by Jesse Sipola on 2.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//

import Foundation
import MapKit

final class Route: ResponseObjectSerializable, ResponseCollectionSerializable, CustomStringConvertible {
    
    struct RouteLeg {
        var length: Double?
        var duration: Double?
        var type: String?
        var code: String?
        var locations: [RouteLocation]?
        var shape: [CLLocationCoordinate2D]?
        
        init(data: [String:AnyObject]) {
            length = data["length"] as? Double
            duration = data["duration"] as? Double
            type = data["type"] as? String
            code = data["code"] as? String
            if let shape = data["shape"] as? [[String:Double]] {
                self.shape = []
                for coordinate in shape {
                    if let latitude = coordinate["y"], let longitude = coordinate["x"] {
                        self.shape?.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
            }
            
            if let locs = data["locs"] as? [[String:AnyObject]] {
                locations = []
                for item in locs {
                    locations?.append(RouteLocation(data: item))
                }
            }
        }
    }
    
    struct RouteLocation {
        var coordinate: CLLocationCoordinate2D?
        var arrivalTime: NSDate?
        var departureTime: NSDate?
        var name: String?
        var code: String?
        var shortCode: String?
        var stopAddress: String?
        var platformNumber: String?
        var shortName: String?
        var terminalCode: String?
        var terminalName: String?
        
        init(data: [String:AnyObject]) {
            if let coord = data["coord"] as? [String:Double], let longitude = coord["x"], let latitude = coord["y"] {
                self.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            }
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmm"
            
            if let arrival = data["arrTime"] as? String {
                self.arrivalTime = dateFormatter.dateFromString(arrival)
            }
            if let departure = data["depTime"] as? String {
                self.departureTime = dateFormatter.dateFromString(departure)
            }
            
            self.name = data["name"] as? String
            self.code = data["code"] as? String
            self.shortCode = data["shortCode"] as? String
            self.stopAddress = data["stopAddress"] as? String
            self.platformNumber = data["platformNumber"] as? String
            self.shortName = data["shortName"] as? String
            self.terminalCode = data["terminal_code"] as? String
            self.terminalName = data["terminal_name"] as? String
        }
    }
    
    var length: Double?
    var duration: Double?
    var legs: [RouteLeg]?
    
    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        if let repArray = representation as? [AnyObject], let representation = repArray.first {
            self.length = representation.valueForKeyPath("length") as? Double
            self.duration = representation.valueForKeyPath("duration") as? Double
            if let legs = representation.valueForKeyPath("legs") as? [[String:AnyObject]] {
                self.legs = []
                for item in legs {
                    self.legs?.append(RouteLeg(data: item))
                }
            }
        }
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Route] {
        let routes = representation as! [AnyObject]
        return routes.map { Route(response: response, representation: $0)! }
    }
    
    func getLineCodes() -> [String]? {
        var lineCodes: [String]?
        if let legs = self.legs {
            for var i = 0; i < legs.count; i++ {
                if let code = legs[i].code {
                    if lineCodes == nil {
                        lineCodes = [code]
                    } else {
                        lineCodes?.append(code)
                    }
                }
            }
        }
        return lineCodes
    }
    
    var description: String {
        return "iReitti.Route(length: \(self.length) duration: \(self.duration)) legs: \(self.legs?.count)"
    }
}