
//
//  EventDetailViewController.swift
//  EventUp!
//
//  Created by Siraj Zaneer on 9/27/17.
//  Copyright © 2017 Siraj Zaneer. All rights reserved.
//

import UIKit
import MapKit

class EventDetailViewController: UIViewController {
    @IBOutlet weak var eventView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var attendeesLabel: UILabel!
    @IBOutlet weak var eventMapView: MKMapView!
    
    var event: Event!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameLabel.text = event.name
        descriptionLabel.text = event.info
        descriptionLabel.sizeToFit()
        let date = Date(timeIntervalSince1970: event.date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateLabel.text = dateFormatter.string(from: date)
        locationLabel.text = event.location
        tagsLabel.text = event.tags
        
        // Display the number of people that RSVP'd to the event
        attendeesLabel.text = "Attendees: \(event.peopleCount!)"
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(event.latitude)!, longitude: Double(event.longitude)!)
        annotation.title = event.name
        let region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        eventMapView.setRegion(region, animated: true)
        eventMapView.addAnnotation(annotation)
    }
    @IBAction func deleteEvent(_ sender: Any) {
        EventUpClient.sharedInstance.deleteEvent(uid: event.uid, success: {
            let alert = UIAlertController(title: "Success!", message: "The event was successfully deleted", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) in self.onSuccessfulEventDeletion()}))
            self.present(alert, animated: true, completion: nil)
        }) { (error) in
            print(error)
        }
    }
    func onSuccessfulEventDeletion() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func rsvpUser(_ sender: Any) {
        
        EventUpClient.sharedInstance.checkInEvent(uid: event.uid, success: {
            self.attendeesLabel.text = String(self.event.peopleCount + 1)
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
