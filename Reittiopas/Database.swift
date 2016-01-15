//
//  Database.swift
//  iReitti
//
//  Created by Jesse Sipola on 4.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Database {
    ///*
    func populateDatabase() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext:managedContext)
        let places = parseCSV()
        
        print("Started creating Core Data objects from Location data.")
        for place in places {
            let location = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            location.setValue(place["katu"], forKey: "katu")
            location.setValue(place["kaupunki"], forKey: "city")
            location.setValue(place["osoitenumero"], forKey: "number")
            location.setValue(place["latitude"], forKey: "latitude")
            location.setValue(place["longitude"], forKey: "longitude")
            location.setValue(place["type"], forKey: "type")
        }
        
        do {
            print("Started saving files...")
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        print("Places saved.")
    }
    //*/
    
    func removeDB() {
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        //2
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        //3
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            print("Deleting \(results.count) Locations.")
            for item in results {
                managedContext.deleteObject(item as! NSManagedObject)
            }
            try managedContext.save()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    private func parseCSV() -> [[String:AnyObject]] {
        print("Started parsing CSV data.")
        var places = [[String:AnyObject]]()
        
        if let path = NSBundle.mainBundle().pathForResource("uudetpaikat_etrs_utf8", ofType: "csv") {
            if let data = NSData(contentsOfFile: path) {
                if let dataString = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    let array = dataString.componentsSeparatedByCharactersInSet(.newlineCharacterSet())
                    for item in array {
                        let itemArray = item.componentsSeparatedByString(";")
                        if itemArray.count == 6 {
                            var place = [String:AnyObject]()
                            place["katu"] = itemArray[0]
                            if let osoitenumero = Int(itemArray[1]) {
                                place["osoitenumero"] = osoitenumero
                            }
                            place["kaupunki"] = itemArray[2]
                            if let latitude = Double(itemArray[3]) {
                                place["latitude"] = latitude
                            }
                            if let longitude = Double(itemArray[4]) {
                                place["longitude"] = longitude
                            }
                            if let type = Int(itemArray[5]) {
                                place["type"] = type
                            }
                            
                            places.append(place)
                        }
                    }
                } else { print("String conversion didn't work.") }
            } else {
                print("No data.")
            }
        }
        print("Finished parsing CSV data.")
        return places
    }
}
