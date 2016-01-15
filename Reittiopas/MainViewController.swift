//
//  ViewController.swift
//  Reittiopas
//
//  Created by Jesse Sipola on 29.12.2015.
//  Copyright © 2015 Jesse Sipola. All rights reserved.
//

import UIKit
import MapKit
import AddressBookUI
import CoreData

class MainViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, ReittiopasClientDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    
    // MARK: Segue Unwinding
    
    @IBAction func returnFromRouteDetails(segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Layout Constraints
    
    @IBOutlet weak var searchButtonTopConstraint: NSLayoutConstraint!
    
    // MARK: - Time
    
    private var selectedTimeIsForDeparture = true
    private var selectedTime = NSDate() {
        didSet {
            setTitleForTimeButton()
        }
    }
    
    @IBOutlet weak var selectTimeView: UIView!
    @IBOutlet weak var chooseTimeButton: UIButton! {
        didSet {
            chooseTimeButton.setRoundedCorners()
        }
    }
    @IBOutlet weak var whenButton: UIButton! {
        didSet {
            setTitleForTimeButton()
            whenButton.setRoundedCorners()
        }
    }
    @IBOutlet weak var datePicker: UIDatePicker! {
        didSet {
            datePicker.setValue(UIColor.whiteColor(), forKeyPath: "textColor")
            datePicker.datePickerMode = .CountDownTimer
            datePicker.datePickerMode = .DateAndTime
        }
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            selectedTimeIsForDeparture = true
        } else {
            selectedTimeIsForDeparture = false
        }
    }
    
    @IBAction func whenButtonTouched(sender: UIButton) {
        selectTimeView.alpha = 0
        view.endEditing(true)
        self.view.bringSubviewToFront(selectTimeView)
        selectTimeView.hidden = false
        UIView.animateWithDuration(0.3) {
            self.selectTimeView.alpha = 1
        }
    }
    
    @IBAction func chooseTimeButtonTouched(sender: UIButton) {
        selectedTime = datePicker.date
        UIView.animateWithDuration(0.3, animations: {
            self.selectTimeView.alpha = 0
        }) { _ in
            self.selectTimeView.hidden = true
        }
    }
    
    private func setTitleForTimeButton() {
        var title: String?
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
                
        title = "klo \(formatter.stringFromDate(selectedTime))"
        
        let calendar = NSCalendar.currentCalendar()
        
        if calendar.isDateInToday(selectedTime) {
            title = "tänään \(title!)"
        } else if calendar.isDateInTomorrow(selectedTime) {
            title = "huomenna \(title!)"
        } else {
            formatter.timeStyle = .NoStyle
            formatter.dateStyle = .ShortStyle
            title = "\(formatter.stringFromDate(selectedTime)) \(title!)"
        }
        
        if selectedTimeIsForDeparture {
            title = "Lähtö \(title!)"
        } else {
            title = "Perillä \(title!)"
        }
        
        whenButton.setTitle(title, forState: .Normal)
    }

    // MARK: - Searching
    
    let reittiopas = ReittiopasClient()
    private var showingSearchResults = false {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var destination: Location? {
        didSet {
            print("latitude \(destination!.coordinate.latitude) longitude: \(destination!.coordinate.longitude)")
        }
    }
    private var startingPoint: Location? {
        didSet {
            fromTextField.text = startingPoint?.description
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchButton: UIButton! {
        didSet {
            searchButton.setRoundedCorners()
        }
    }
    
    @IBAction func searchButtonTouched(sender: UIButton) {
        view.endEditing(true)
        
        if destination != nil && startingPoint != nil {
            if selectedTimeIsForDeparture {
                reittiopas.getRoutes(startingPoint!.coordinate, to: destination!.coordinate, when: selectedTime)
            } else {
                reittiopas.getRoutes(startingPoint!.coordinate, to: destination!.coordinate, when: selectedTime, timetype: "arrival")
            }
            searching = true
        } else {
            if destination == nil {
                toTextField.layer.borderWidth = 2
            }
            if startingPoint == nil {
                fromTextField.layer.borderWidth = 2
            }
        }
        
    }
    
    var locationAutofillResults: [Location] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private enum LocationSearchType {
        case Destination, StartingPoint
    }
    
    lazy var managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    private func findLocations(destination: String) {
        
        let getResults: () -> [Location]! = {
            let searchComponents = destination.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let fetchRequest = NSFetchRequest(entityName: "Location")
            fetchRequest.fetchLimit = 20
            fetchRequest.fetchBatchSize = 20
            fetchRequest.returnsDistinctResults = true
            
            let katuSortDescriptor = NSSortDescriptor(key: "katu", ascending: true)
            let numberSortDescriptor = NSSortDescriptor(key: "number", ascending: true)
            fetchRequest.sortDescriptors = [katuSortDescriptor, numberSortDescriptor]
            
            if let number = Int64(searchComponents.last!) {
                var destinationString = searchComponents.first!
                for var i = 1; i < searchComponents.count - 1; i++ {
                    destinationString = "\(destinationString) \(searchComponents[i])"
                }
                let predicate = NSPredicate(format: "(katu contains[cd] %@) AND (number == \(number))", destinationString)
                
                fetchRequest.predicate = predicate
            } else {
                let destination = destination.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                let predicate = NSPredicate(format: "katu contains[cd] %@", destination)
                fetchRequest.predicate = predicate
            }
            
            let results = try? self.managedContext.executeFetchRequest(fetchRequest) as! [Location]
            return results
        }
        
        let processResults = { (results: [Location]!) in
            if let results = results {
                self.locationAutofillResults = results
            }
        }
        
        getResults ~> processResults
        
    }
    
    // MARK: - Map
    
    private var activeTextField: UITextField?
    private var userIsUsingMap = false {
        didSet {
            if userIsUsingMap {
                if toTextField.isFirstResponder() {
                    activeTextField = toTextField
                } else if fromTextField.isFirstResponder() {
                    activeTextField = fromTextField
                }
                self.view.endEditing(true)
                selectFromMapButton.setTitle("Piilota kartta", forState: .Normal)
            } else {
                setMapMode(false)
                activeTextField?.becomeFirstResponder()
                selectFromMapButton.setTitle("Valitse kartalta", forState: .Normal)
            }
        }
    }
    private var selectedMapCoordinate: CLLocationCoordinate2D? {
        didSet {
            if selectedMapCoordinate != nil {
                let selectedCLLocation = CLLocation(latitude: selectedMapCoordinate!.latitude, longitude: selectedMapCoordinate!.longitude)
                CLGeocoder().reverseGeocodeLocation(selectedCLLocation) {
                    placemarks, error in
                    if let placemark = placemarks?.first {
                        if let street = placemark.addressDictionary?[kABPersonAddressStreetKey] as? String {
                            if let city = placemark.addressDictionary?[kABPersonAddressCityKey] as? String {
                                self.activeTextField?.text = "\(street), \(city)"
                            } else {
                                self.activeTextField?.text = "\(street)"
                            }
                        } else {
                            self.activeTextField?.text = "Valittu sijainti"
                        }
                    }
                }
                
                self.updateLocationFromMapButton.enabled = true
                self.updateLocationFromMapButton.backgroundColor = UIColor.orangeColor()
                
                if selectedLocation == nil {
                    selectedLocation = MKPointAnnotation()
                    selectedLocation!.coordinate = selectedMapCoordinate!
                    mapView.addAnnotation(selectedLocation!)
                } else {
                    mapView.removeAnnotation(selectedLocation!)
                    selectedLocation?.coordinate = selectedMapCoordinate!
                    mapView.addAnnotation(selectedLocation!)
                }
            }
        }
    }
    private var selectedLocation: MKPointAnnotation?
    
    @IBOutlet weak var selectFromMapButton: UIButton! {
        didSet {
            selectFromMapButton.setRoundedCorners()
        }
    }
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.setRoundedCorners()
            mapView.delegate = self
            mapView.showsUserLocation = true
            let gesture = UILongPressGestureRecognizer(target: self, action: "selectLocationGestureRecognizer:")
            gesture.minimumPressDuration = 0.2
            mapView.addGestureRecognizer(gesture)
            
            let helsinkiCoordinate = CLLocationCoordinate2DMake(60.192059, 24.945831)
            let span = MKCoordinateSpanMake(0.5, 0.5)
            let helsinkiRegion = MKCoordinateRegionMake(helsinkiCoordinate, span)
            mapView.setRegion(helsinkiRegion, animated: false)
        }
    }
    
    @IBAction func selectFromMapButtonTouched(sender: UIButton) {
        userIsUsingMap = !userIsUsingMap
    }
    
    func selectLocationGestureRecognizer(sender: UILongPressGestureRecognizer) {
        let point = sender.locationInView(self.mapView)
        switch sender.state {
        case .Began:
            selectedMapCoordinate = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        default: break
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MKUserLocation {
            return nil
        }
        
        let identifier = "pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = false
        }
        return view
    }

    @IBOutlet weak var updateLocationFromMapButton: UIButton! {
        didSet {
            updateLocationFromMapButton.setRoundedCorners()
        }
    }
    @IBAction func updateLocationFromMapButtonTouched(sender: UIButton) {
        if activeTextField != nil {
            let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedContext)
            let location = Location(entity: entity!, insertIntoManagedObjectContext: nil)
            location.katu = activeTextField?.text
            location.latitude = selectedMapCoordinate!.latitude
            location.longitude = selectedMapCoordinate!.longitude
            
            if activeTextField! == toTextField {
                destination = location
            } else if activeTextField == fromTextField {
                startingPoint = location
            }
        }
        setSearchMode(false)
        //setMapMode(false)
    }
    
    // MARK: - Text Fields
    
    @IBOutlet weak var fromTextField: UITextField! {
        didSet {
            fromTextField.layer.borderColor = UIColor.redColor().CGColor
            fromTextField.delegate = self
            fromTextField.setRoundedCorners()
            fromTextField.addTarget(self, action: "textFieldEditingChanged:", forControlEvents: .EditingChanged)
        }
    }
    @IBOutlet weak var toTextField: UITextField! {
        didSet {
            toTextField.layer.borderColor = UIColor.redColor().CGColor
            toTextField.setRoundedCorners()
            toTextField.delegate = self
            toTextField.addTarget(self, action: "textFieldEditingChanged:", forControlEvents: .EditingChanged)
            toTextField.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    private var userIsTypingLocation = false {
        didSet {
            if !userIsTypingLocation {
                tableView.reloadData()
            }
        }
    }
    
    func textFieldEditingChanged(textField: UITextField) {
        if textField.text != nil && !textField.text!.isEmpty {
            userIsTypingLocation = true
            if textField.text!.characters.count > 0 {
                findLocations(textField.text!)
            }
        } else {
            userIsTypingLocation = false
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == fromTextField {
            if textField.text == currentLocation?.description {
                locationManager.stopUpdatingLocation()
                textField.text = nil
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == fromTextField {
            if textField.text == nil || textField.text!.isEmpty {
                locationManager.startUpdatingLocation()
                textField.text = currentLocation?.description
            }
        }
        userIsTypingLocation = false
    }
    
    // MARK: - Location Manager
    private var currentLocation: Location? {
        didSet {
            startingPoint = currentLocation
        }
    }
    private var currentCLLocation: CLLocation? {
        didSet {
            CLGeocoder().reverseGeocodeLocation(currentCLLocation!) {
                placemarks, error in
                if let placemark = placemarks?.first {
                    let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedContext)
                    let location = Location(entity: entity!, insertIntoManagedObjectContext: nil)
                    if let name = placemark.name, let city = placemark.addressDictionary?[kABPersonAddressCityKey] as? String {
                        location.katu = name
                        location.city = city
                    } else {
                        location.katu = "Nykyinen sijainti"
                    }
                    if let latitude = placemark.location?.coordinate.latitude {
                        location.latitude = latitude
                    }
                    if let longitude = placemark.location?.coordinate.longitude {
                        location.longitude = longitude
                    }
                    self.currentLocation = location
                }
            }
        }
    }

    private var locationManager = CLLocationManager()
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentCLLocation = location
        }
    }
    
    // MARK: - Showing Results
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.setRoundedCorners()
        }
    }
    
    var oldSearchLocations: [Location] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var tableViewMode: TableViewMode {
        if showingSearchResults {
            return .SearchResults
        } else {
            if userIsTypingLocation {
                return .AutoFill
            } else {
                return .OldSearchLocation
            }
        }
    }
    
    private enum TableViewMode {
        case OldSearchLocation, SearchResults, AutoFill
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedLocation: Location?
        switch tableViewMode {
        case .SearchResults:
            performSegueWithIdentifier("Show route", sender: indexPath.row)
        case .AutoFill:
            selectedLocation = locationAutofillResults[indexPath.row]
            fallthrough
        case .OldSearchLocation:
            if tableViewMode == .OldSearchLocation {
                selectedLocation = oldSearchLocations[indexPath.row]
            }
            insertPreviousLocation(selectedLocation!)
            if toTextField.isFirstResponder() {
                toTextField.text = selectedLocation?.description
                destination = selectedLocation
            } else if fromTextField.isFirstResponder() {
                fromTextField.text = selectedLocation?.description
                startingPoint = selectedLocation
            }
            setSearchMode(false)
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableViewMode {
        case .SearchResults: return reittiopas.latestSearchResults.count
        case .OldSearchLocation: return oldSearchLocations.count
        case .AutoFill: return locationAutofillResults.count
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch tableViewMode {
        case .SearchResults: return "Reittisuositukset:"
        case .AutoFill: return "Paikkaehdotukset:"
        case .OldSearchLocation: return "Edelliset haut:"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableViewMode {
        case .SearchResults: return routeCellForIndexPath(indexPath)
        case .OldSearchLocation, .AutoFill: return locationCellForIndexPath(indexPath)
        }
    }
    
    private func locationCellForIndexPath(indexPath: NSIndexPath) -> LocationCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Location") as! LocationCell
        configureLocationCellForIndexPath(cell, indexPath: indexPath)
        return cell
    }
    
    private func configureLocationCellForIndexPath(cell: LocationCell, indexPath: NSIndexPath) {
        switch tableViewMode {
        case .OldSearchLocation:
            cell.titleLabel.text = oldSearchLocations[indexPath.row].description
        case .AutoFill:
            cell.titleLabel.text = locationAutofillResults[indexPath.row].description
        default: break
        }
    }

    private func routeCellForIndexPath(indexPath: NSIndexPath) -> RouteCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Route") as! RouteCell
        configureRouteCellForRoute(cell, route: reittiopas.latestSearchResults[indexPath.row])
        return cell
    }
    
    private func configureRouteCellForRoute(cell: RouteCell, route: Route) {
        let formatter = NSDateFormatter()

        formatter.dateFormat = "HH:mm"
        
        func setDeparture(leg: Route.RouteLeg) {
            if let date = route.legs?.first?.locations?.first?.departureTime {
                cell.departureTimeLabel.text = formatter.stringFromDate(date)
            }
        }
        
        func setArrival(leg: Route.RouteLeg) {
            if let date = route.legs?.last?.locations?.last?.arrivalTime {
                cell.arrivalTimeLabel.text = formatter.stringFromDate(date)
            }
        }
        
        func setTransportations(lineCodes: [String]?) {
            for subview in cell.vehicleView.subviews {
                subview.removeFromSuperview()
            }
            if let lineCodes = lineCodes {
                var vehicles: [(type: Int, code: String)] = []
                for code in lineCodes {
                    if let line = reittiopas.lineInformation[code] {
                        if let type = line.transportTypeId, let shortCode = line.shortCode {
                            vehicles.append((type, shortCode))
                        }
                    }
                }
                var latestXPosition: CGFloat = 0
                for vehicle in vehicles {
                    let label = UILabel()
                    label.setRoundedCorners()
                    label.text = vehicle.code
                    label.font = label.font?.fontWithSize(12)
                    label.adjustsFontSizeToFitWidth = true
                    label.textAlignment = .Center
                    
                    //label.sizeToFit()
                    label.frame.origin.y = 2
                    label.frame.size.height = cell.vehicleView.frame.height - 8
                    label.frame.size.width = label.frame.size.height
                    label.textColor = UIColor.whiteColor()
                    
                    switch vehicle.type {
                    case 1, 3, 4, 5, 8, 22, 25, 36, 39: label.backgroundColor = UIColor.blueColor()
                    case 6: label.backgroundColor = UIColor.orangeColor()
                    case 2: label.backgroundColor = UIColor(red: 51/255, green: 153/255, blue: 102/255, alpha: 1) // Tram
                    case 7: label.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.6)
                    case 12: label.backgroundColor = UIColor.redColor()
                    default: break
                    }
                    
                    label.frame.origin.x = latestXPosition + 2
                    latestXPosition = label.frame.maxX
                    
                    cell.vehicleView.addSubview(label)
                }
            } else {
                let label = UILabel()
                label.text = "kävely"
                label.font = label.font?.fontWithSize(17)
                label.sizeToFit()
                label.frame.size.height = cell.vehicleView.frame.height
                cell.vehicleView.addSubview(label)
            }
        }
        
        if let legs = route.legs {
            if legs.count >= 1 {
                setDeparture(legs.first!)
                setArrival(legs.last!)
                setTransportations(route.getLineCodes())
            }
        }
        
    }
    
    // MARK: - Reittiopas Client Delegate
    
    func updatedSearchResults() {
        setResultsMode(true)
        searching = false
        if reittiopas.latestSearchResults.count > 0 {
            tableView.hidden = false
        } else {
            //No results
        }
    }
    
    // MARK: - Old Locations
    
    private func loadPreviousLocations() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let coordinator = (UIApplication.sharedApplication().delegate as! AppDelegate).persistentStoreCoordinator
        if let data = defaults.valueForKey("iReittiOldSearchLocations") as? NSData {
            if let urls = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [NSURL] {
                for url in urls {
                    if let objectId = coordinator.managedObjectIDForURIRepresentation(url) {
                        if let location = managedContext.objectWithID(objectId) as? Location {
                            oldSearchLocations.append(location)
                        }
                    }
                }
            }
        }
        
    }
    
    private func insertPreviousLocation(location: Location) {
        if !oldSearchLocations.contains(location) {
            print("New location entered.")
            oldSearchLocations.insert(location, atIndex: 0)
        } else {
            print("Searching for matching location.")
            for var i = 0; i < oldSearchLocations.count; i++ {
                if oldSearchLocations[i].objectID.URIRepresentation() == location.objectID.URIRepresentation() {
                    print("Found a matching location")
                    let original = oldSearchLocations[0]
                    oldSearchLocations[0] = oldSearchLocations[i]
                    oldSearchLocations[i] = original
                    break
                }
            }
            
        }
        savePreviousLocations()
    }
    
    private func savePreviousLocations() {
        var locations: [NSURL] = []
        for var i = 0; i < min(10, oldSearchLocations.count); i++ {
            locations.append(oldSearchLocations[i].objectID.URIRepresentation())
        }
        
        let locationData = NSKeyedArchiver.archivedDataWithRootObject(locations)
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setValue(locationData, forKey: "iReittiOldSearchLocations")
    }
    
    // MARK: - View
    
    private struct defaultConstraintSize {
        static let textViewTop: CGFloat = 8
        static let searchButtonTop: CGFloat = 16
        static let tableViewBottom: CGFloat = 8
        static let tableViewTop: CGFloat = 8
        static let mapViewBottom: CGFloat = 4
        static let showMapButtonBottom: CGFloat = -30
    }
    
    @IBOutlet weak var toTextFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var fromTextFieldTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var showMapButtonBottomConstraint: NSLayoutConstraint!
    
    var searching = false {
        didSet {
            if searching {
                activityIndicator.startAnimating()
                activityIndicator.hidden = false
                searchButton.enabled = false
                toTextField.enabled = false
                fromTextField.enabled = false
                whenButton.enabled = false
            } else {
                activityIndicator.stopAnimating()
                activityIndicator.hidden = true
                searchButton.enabled = true
                toTextField.enabled = true
                fromTextField.enabled = true
                whenButton.enabled = true
            }
        }
    }
    
    private func setSearchMode(active: Bool) {
        if active {
            showingSearchResults = false
            if fromTextField.isFirstResponder() {
                self.view.bringSubviewToFront(fromTextField)
            } else if toTextField.isFirstResponder() {
                self.view.bringSubviewToFront(toTextField)
            }
            
            tableViewBottomConstraint.constant = keyboardHeight + 4
            mapViewBottomConstraint.constant = keyboardHeight + 4
            tableViewHeightConstraint.constant = self.view.frame.height - whenButton.frame.maxY - keyboardHeight - defaultConstraintSize.tableViewTop
            toTextFieldTopConstraint.constant = -whenButton.frame.height
            fromTextFieldTopConstraint.constant = -whenButton.frame.height
            searchButtonTopConstraint.constant = -whenButton.frame.height
            showMapButtonBottomConstraint.constant = 4
            
            UIView.animateWithDuration(0.4, animations: {
                self.view.layoutIfNeeded()
                self.mapView.alpha = 0
                self.updateLocationFromMapButton.alpha = 0
            }) { _ in
                self.mapView.alpha = 1
                self.updateLocationFromMapButton.alpha = 1
                self.mapView.hidden = true
                self.updateLocationFromMapButton.hidden = true
            }
        } else {
            toTextFieldTopConstraint.constant = defaultConstraintSize.textViewTop
            fromTextFieldTopConstraint.constant = defaultConstraintSize.textViewTop
            searchButtonTopConstraint.constant = defaultConstraintSize.searchButtonTop
            tableViewBottomConstraint.constant = defaultConstraintSize.tableViewBottom
            showMapButtonBottomConstraint.constant = defaultConstraintSize.showMapButtonBottom
            tableViewHeightConstraint.constant = 0
            
            UIView.animateWithDuration(0.3, animations: {
                self.view.layoutIfNeeded()
                self.mapView.alpha = 0
                self.updateLocationFromMapButton.alpha = 0
            }) { _ in
                self.mapView.alpha = 1
                self.updateLocationFromMapButton.alpha = 1
                self.mapView.hidden = true
                self.updateLocationFromMapButton.hidden = true
            }
            
            self.view.endEditing(true)
        }
    }
    
    @IBOutlet weak var mapViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    
    private func setMapMode(active: Bool) {
        if active {
            mapView.hidden = false
            updateLocationFromMapButton.hidden = false
            tableViewBottomConstraint.constant = defaultConstraintSize.tableViewBottom
            mapViewBottomConstraint.constant = defaultConstraintSize.mapViewBottom
            tableViewHeightConstraint.constant = 0
            
            UIView.animateWithDuration(0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            updateLocationFromMapButton.enabled = false
            updateLocationFromMapButton.backgroundColor = UIColor.lightGrayColor()
            
            if let selectedLocation = selectedLocation {
                mapView.removeAnnotation(selectedLocation)
                self.selectedLocation = nil
                selectedMapCoordinate = nil
                activeTextField?.text = nil
            }
        }
    }
    
    private func setResultsMode(active: Bool) {
        if active {
            showingSearchResults = true
            tableViewHeightConstraint.constant = self.view.frame.height - searchButton.frame.maxY - defaultConstraintSize.tableViewTop - defaultConstraintSize.tableViewBottom
            
            UIView.animateWithDuration(0.4, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    
    var keyboardHeight: CGFloat = 0
    
    func keyboardWillShow(notification: NSNotification) {
        if userIsUsingMap {
            userIsUsingMap = false
        }
        if keyboardHeight == 0 {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
               keyboardHeight = keyboardSize.height
            }
        }
        setSearchMode(true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if userIsUsingMap {
            setMapMode(true)
        } else {
            setSearchMode(false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reittiopas.delegate = self
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurView = UIVisualEffectView(frame: self.view.frame)
        blurView.effect = blurEffect
        selectTimeView.insertSubview(blurView, atIndex: 0)
        
        loadPreviousLocations()
        
        //let startTime = NSDate()
        //Database().removeDB()
        //Database().populateDatabase()
        
        //let timeSpent = NSDate().timeIntervalSinceDate(startTime)
        //print("Time spent working with DB: \(timeSpent)")
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        if selectedTimeIsForDeparture {
            selectedTime = NSDate()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        locationManager.startUpdatingLocation()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == "Show route" {
                if let dvc = segue.destinationViewController as? RouteViewController, let index = sender as? Int {
                    dvc.reittiopas = self.reittiopas
                    if var legs = reittiopas.latestSearchResults[index].legs {
                        legs[0].locations?[0].name = self.startingPoint?.description
                        if let locations = legs[legs.count-1].locations {
                            legs[legs.count-1].locations![locations.count-1].name = self.destination?.description
                        }
                        dvc.legs = legs
                    }
                }
            }
        }
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
        if let identifier = identifier {
            switch identifier {
            case "Return to search":
                return RightToLeftSegueUnwind(identifier: identifier, source: fromViewController, destination: toViewController, performHandler: {})
            default: break
            }
        }
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
}

