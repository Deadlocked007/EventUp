//
//  MapViewController.swift
//  EventUp!
//
//  Created by Siraj Zaneer on 9/25/17.
//  Copyright © 2017 Siraj Zaneer. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import SVProgressHUD
import AVFoundation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, FilterDelegate {
    
    @IBOutlet weak var eventMapView: MKMapView!
    @IBOutlet weak var sideBarButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    var events: [Event] = []
    var filteredEvents: [Event] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sidebarIcon = UIImageView(image: UIImage(named: "sidebarIcon"))
        sidebarIcon.frame = CGRect(x: 0, y: 0, width: sideBarButton.frame.height, height: sideBarButton.frame.height)
        sideBarButton.frame = CGRect(x: 0, y: 0, width: sideBarButton.frame.height, height: sideBarButton.frame.height)
        sideBarButton.addSubview(sidebarIcon)
        
        let refreshIcon = UIImageView(image: UIImage(named: "refreshIcon"))
        refreshIcon.frame = CGRect(x: 0, y: 0, width: refreshButton.frame.height, height: refreshButton.frame.height)
        refreshButton.frame = CGRect(x: 0, y: 0, width: refreshButton.frame.height, height: refreshButton.frame.height)
        refreshButton.addSubview(refreshIcon)
        
        let background = UIImage(named: "background")!
        self.navigationController!.navigationBar.setBackgroundImage(background, for: .default)
        
        self.navigationController!.navigationBar.tintColor = .black
        SVProgressHUD.show()
        view.isUserInteractionEnabled = false
        setupLocation()
        loadEvents()
    }
    
    func setupLocation() {
        eventMapView.delegate = self
        eventMapView.showsUserLocation = true
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
        
        locationManager.delegate = self
        
        onLocation(self)
    }
    
    
    
    @IBAction func onLocation(_ sender: Any) {
        if let userLocation = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            eventMapView.setRegion(region, animated: true)
        }
    }
    
    func filter(filters: [String: Bool]) {
        var past = false
        var current = false
        var future = false
        if filters["past"] != nil {
            past = filters["past"]!
        }
        
        if filters["current"] != nil {
            current = filters["current"]!
        }
        
        if filters["future"] != nil {
            future = filters["future"]!
        }
        
        if ((!past && !current && !future) || (past && current && future)) {
            self.eventMapView.removeAnnotations(self.eventMapView.annotations)
            for event in self.events {
                self.addEventToMap(event: event)
            }
            return
        }
        if past && current {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.date <= Date().timeIntervalSinceReferenceDate
            })
        } else if current, future {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.date >= Date().timeIntervalSinceReferenceDate
            })
        } else if past, future {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.endDate < Date().timeIntervalSinceReferenceDate || event.date > Date().timeIntervalSinceReferenceDate
            })
        } else if past {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.endDate <= Date().timeIntervalSinceReferenceDate
            })
        } else if current {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.date <= Date().timeIntervalSinceReferenceDate && event.endDate >= Date().timeIntervalSinceReferenceDate
            })
        } else if future {
            filteredEvents = events.filter({ (event) -> Bool in
                return event.date > Date().timeIntervalSinceReferenceDate
            })
        }
        
        self.eventMapView.removeAnnotations(self.eventMapView.annotations)
        for event in self.filteredEvents {
            self.addEventToMap(event: event)
        }
    }
    
    func refresh(event: Event?) {
        SVProgressHUD.show()
        loadEvents()
    }
    
    
    func loadEvents() {
        SVProgressHUD.show()
        view.isUserInteractionEnabled = false
        EventUpClient.sharedInstance.getEvents(success: { (events) in
            self.events = events
            
            self.eventMapView.removeAnnotations(self.eventMapView.annotations)
            for event in self.events {
                self.addEventToMap(event: event)
            }
            self.view.isUserInteractionEnabled = true
            SVProgressHUD.dismiss()
        }) { (error) in
            print(error.localizedDescription)
            self.view.isUserInteractionEnabled = true
            SVProgressHUD.dismiss()
        }
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        loadEvents()
    }
    
    @IBAction func onMenu(_ sender: Any) {
        so_containerViewController?.isSideViewControllerPresented = !so_containerViewController!.isSideViewControllerPresented
    }
    
    func addEventToMap(event: Event) {
        let annotation = EventAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        annotation.event = event
        annotation.title = event.name
        let heatCircle = MKCircle(center: annotation.coordinate, radius: CLLocationDistance(event.rsvpCount * 100))
        eventMapView.addAnnotation(annotation)
        eventMapView.add(heatCircle)
    }
    
    @objc func goToDetail(sender: UIButton) {
        let event = (sender.superview! as! EventAnnotationCalloutView).event
        performSegue(withIdentifier: "detailSegue", sender: event)
    }
    
    @objc func onNavigate(sender: UIButton) {
        let event = (sender.superview! as! EventAnnotationCalloutView).event!
        let coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = event.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor.cyan.withAlphaComponent(0.5)
        renderer.strokeColor = UIColor.cyan.withAlphaComponent(0.8)
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation
        {
            return nil
        }
        let annotationView = EventAnnotationView()
        let currDate = Date().timeIntervalSince1970
        let eventAnnotation = annotation as! EventAnnotation
        if currDate >= eventAnnotation.event.date && currDate <= eventAnnotation.event.endDate {
            let annotationImage = UIImage(named: "EventAnnotation_green")
            annotationView.image = annotationImage
        } else if currDate < eventAnnotation.event.date {
            let annotationImage = UIImage(named: "EventAnnotation")
            annotationView.image = annotationImage
        } else {
            let annotationImage = UIImage(named: "EventAnnotation_red")
            annotationView.image = annotationImage
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.isKind(of: EventAnnotationView.self)
        {
            for subview in view.subviews
            {
                subview.removeFromSuperview()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation
        {
            // Don't proceed with custom callout
            return
        }
        
        
        // 2
        let eventAnnotation = view.annotation as! EventAnnotation
        let event = eventAnnotation.event!
        let views = Bundle.main.loadNibNamed("EventAnnotationCalloutView", owner: nil, options: nil)
        let calloutView = views?[0] as! EventAnnotationCalloutView
        calloutView.event = event
        calloutView.layer.cornerRadius = 10
        calloutView.nameLabel.text = event.name
        EventUpClient.sharedInstance.getEventImage(uid: event.uid, success: { (image) in
            calloutView.imageView.image = image
            calloutView.imageView.clipsToBounds = true
            calloutView.imageView.layer.cornerRadius = 10
        }) { (error) in
            print(error.localizedDescription)
        }
        print("asds")
        calloutView.navigateButton.addTarget(self, action: #selector(onNavigate(sender:)), for: .touchUpInside)
        calloutView.detailButton.addTarget(self, action: #selector(goToDetail(sender:)), for: .touchUpInside)
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height*0.52)
        view.addSubview(calloutView)
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let id = segue.identifier else {
            return
        }
        
        if id == "detailSegue" {
            let destination = segue.destination as! EventDetailViewController
            destination.event = sender as! Event
            destination.delegate = self
        }
    }
    
    
}

