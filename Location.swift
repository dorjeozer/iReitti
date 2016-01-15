//
//  Location.swift
//  iReitti
//
//  Created by Jesse Sipola on 7.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//

import Foundation
import CoreData
import MapKit

/*

Location types:

0: Street
1: Public transportation stop
2: Other

*/

class Location: NSManagedObject {
    
    @NSManaged var type: Int16
    @NSManaged var katu: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var number: Int64
    @NSManaged var city: String?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.latitude, self.longitude)
    }
    
    override var description: String {
        if let katu = self.katu {
            if let city = self.city {
                if number == 0 {
                    return "\(katu), \(city)"
                }
                return "\(katu) \(number), \(city)"
            } else {
                return katu
            }
        }
        return "\(self.katu) \(number), \(city)"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

}
