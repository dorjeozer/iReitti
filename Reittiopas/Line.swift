//
//  Line.swift
//  iReitti
//
//  Created by Jesse Sipola on 10.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//
import MapKit
import Foundation

final class Line: ResponseObjectSerializable, ResponseCollectionSerializable, CustomStringConvertible {
    
    var code: String?
    var shortCode: String?
    var transportTypeId: Int?
    var lineStart: String?
    var lineEnd: String?
    var name: String?
    var timetableUrl: String?
    var lineShape: String? //[CLLocationCoordinate2D]?
    var lineStops: [LineStop]?
    var sortId: String?
    var dateFrom: NSDate?
    var dateTo: NSDate?
    
    struct LineStop {
        var code: String?
        var codeShort: String?
        var address: String?
        var name: String?
        var coordinate: String?
        var cityName: String?
        var terminalCode: String?
        var terminalName: String?
        var shortName: String?
        var platformNumber: String?
        
        init(data: [String:AnyObject]) {
            
        }
    }
    
    required init?(response: NSHTTPURLResponse, representation: AnyObject) {

        if let representation = representation as? [String : AnyObject] {
            self.code = representation["code"] as? String
            self.shortCode = representation["code_short"] as? String
            self.transportTypeId = representation["transport_type_id"] as? Int
            self.lineStart = representation["line_start"] as? String
            self.lineEnd = representation["line_end"] as? String
            self.name = representation["name"] as? String
            self.timetableUrl = representation["timetable_url"] as? String
            self.lineShape = representation["line_shape"] as? String
            self.sortId = representation["sort_id"] as? String
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            if let date = representation["date_from"] as? String {
                self.dateFrom = dateFormatter.dateFromString(date)
            }
            if let date = representation["date_to"] as? String {
                self.dateTo = dateFormatter.dateFromString(date)
            }
            
            if let stops = representation["line_stops"] as? [[String:AnyObject]] {
                self.lineStops = []
                for item in stops {
                    self.lineStops?.append(LineStop(data: item))
                }
            }
        }
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Line] {
        let lines = representation as! [AnyObject]
        return lines.map { Line(response: response, representation: $0)! }
    }
    
    var description: String {
        return "Line(code: \(self.code) shortCode: \(self.shortCode))"
    }
}
