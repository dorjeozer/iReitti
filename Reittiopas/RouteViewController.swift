//
//  RouteViewController.swift
//  iReitti
//
//  Created by Jesse Sipola on 11.1.2016.
//  Copyright © 2016 Jesse Sipola. All rights reserved.
//

import UIKit
import MapKit

class RouteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {

    var formatter = NSDateFormatter()
    var reittiopas: ReittiopasClient?
    var legs: [Route.RouteLeg]?
    var startingPoint: String?
    var destination: String?
    
    @IBAction func backButtonTouched(sender: UIButton) {
        performSegueWithIdentifier("Return to search", sender: nil)
    }
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            drawRouteOnMap()
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.tableView.alpha = 0
            self.tableView.hidden = false
            UIView.animateWithDuration(0.3, animations: {
                self.mapView.alpha = 0
                self.tableView.alpha = 1
            }) { _ in
                self.mapView.hidden = true
                self.mapView.alpha = 1
            }
        } else if sender.selectedSegmentIndex == 1 {
            self.mapView.alpha = 0
            self.mapView.hidden = false
            UIView.animateWithDuration(0.3, animations: {
                self.mapView.alpha = 1
                self.tableView.alpha = 0
            }) { _ in
                self.tableView.hidden = true
                self.tableView.alpha = 1
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let legs = legs {
            return legs.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return " "
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRectZero)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return detailCellForIndexPath(indexPath)
    }
    
    private func detailCellForIndexPath(indexPath: NSIndexPath) -> RouteDetailCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Route details") as! RouteDetailCell
        configureDetailCell(legs![indexPath.row], cell: cell)
        return cell
    }
    
    private func configureDetailCell(leg: Route.RouteLeg, cell: RouteDetailCell) {
        if let length = leg.length, let type = leg.type {
            var typeName = "Kävelyä"
            if let typeCode = Int(type) {
                switch typeCode {
                case 1, 3, 4, 5, 8, 21, 22, 23, 25, 36, 39: typeName = "Bussi"
                case 2: typeName = "Raitiovaunu"
                case 6: typeName = "Metro"
                case 7: typeName = "Lautta"
                case 12: typeName = "Juna"
                default: break
                }
                
                if let code = leg.code, let line = reittiopas?.lineInformation[code] {
                    if let name = line.shortCode {
                        typeName = "\(typeName) \(name)"
                    }
                }
            }
            let roundedLength = round(length / 10) / 100
            cell.travelLabel.text = "\(typeName) \(roundedLength) km"
        }
        if let locations = leg.locations {
            if let location = locations.first {
                if let name = location.name, let time = location.departureTime {
                    var stopCode = ""
                    if let code = location.shortCode {
                        stopCode = "(\(code))"
                    }
                    cell.departureLabel.text = "\(formatter.stringFromDate(time)) \(name) \(stopCode)"
                }
            }
            if let location = locations.last {
                if let name = location.name, let time = location.arrivalTime {
                    var stopCode = ""
                    if let code = location.shortCode {
                        stopCode = "(\(code))"
                    }
                    cell.arrivalLabel.text = "\(formatter.stringFromDate(time)) \(name) \(stopCode)"
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        var strokeColor = UIColor.grayColor()
        if let type = overlay.title, let typeName = type {
            switch typeName {
            case "1", "3", "4", "5", "8", "21", "22", "23", "25", "36", "39": strokeColor = UIColor.blueColor()
            case "2": strokeColor = UIColor.greenColor()
            case "6": strokeColor = UIColor.orangeColor()
            case "7": strokeColor = UIColor.cyanColor()
            case "12": strokeColor = UIColor.redColor()
            case "walk":  strokeColor = UIColor.grayColor()
            default: break
            }
        }
        if overlay.isKindOfClass(MKPolyline) {
            let polyLine = overlay
            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = strokeColor
            polyLineRenderer.lineWidth = 4.0
            
            return polyLineRenderer
        } else if overlay.isKindOfClass(MKCircle) {
            let circle = overlay
            let circleRenderer = MKCircleRenderer(overlay: circle)
            circleRenderer.fillColor = strokeColor
            circleRenderer.strokeColor = UIColor.whiteColor()
            circleRenderer.lineWidth = 3
            print("returning circle renderer")
            return circleRenderer
        }
        
        return nil
    }
    
    private func drawStopsOnMap(inputData: [(type: String, coordinates: [CLLocationCoordinate2D])]) {
        for location in extractStopCoordinatesFromShapeCoordinates(inputData) {
            let circle = MKCircle(centerCoordinate: location.coordinate, radius: 5)
            circle.title = location.type
            mapView.addOverlay(circle, level: .AboveRoads)
        }
    }
    
    private func extractStopCoordinatesFromShapeCoordinates(inputData: [(type: String, coordinates: [CLLocationCoordinate2D])]) -> [(coordinate: CLLocationCoordinate2D, type: String)] {
        var returnArray = [(coordinate: CLLocationCoordinate2D, type: String)]()
        for item in inputData {
            if item.type != "walk" {
                if let coordinate = item.coordinates.first {
                    returnArray.append((coordinate, item.type))
                }
                if let coordinate = item.coordinates.last {
                    returnArray.append((coordinate, item.type))
                }
            }
        }
        return returnArray
    }
    
    private func drawRouteOnMap() {
        if let coords = extractShapeCoordinates() {
            for (index, item) in coords.enumerate() {
                var coordinates = item.coordinates
                if item.type == "walk" {
                    if index < coords.count - 1 {
                        if let coordinate = coords[index + 1].coordinates.first {
                            coordinates.append(coordinate)
                        }
                        if index != 0 {
                            if let coordinate = coords[index - 1].coordinates.last {
                                coordinates.insert(coordinate, atIndex: 0)
                            }
                        }
                    } else if index == coords.count - 1 {
                        if let coordinate = coords[index - 1].coordinates.last {
                            coordinates.insert(coordinate, atIndex: 0)
                        }
                    }
                }
                drawRouteLine(item.type, coordinates: coordinates)
            }
            
            drawStopsOnMap(coords)
            let centerCoordinate = coords[0].coordinates.first!
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(centerCoordinate, span)
            mapView.setRegion(region, animated: false)
        }
    }
    
    private func drawRouteLine(type: String, var coordinates: [CLLocationCoordinate2D]) {
        let routeLine = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        routeLine.title = type
        self.mapView.addOverlay(routeLine, level: .AboveRoads)
    }
    
    private func extractShapeCoordinates() -> [(type: String, coordinates: [CLLocationCoordinate2D])]? {
        if let legs = self.legs {
            var coordinates = [(type: String, coordinates: [CLLocationCoordinate2D])]()
            for leg in legs {
                if let shape = leg.shape, type = leg.type {
                    coordinates.append((type, shape))
                }
            }
            return coordinates
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .NoStyle
    }
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .Default
    }

}
