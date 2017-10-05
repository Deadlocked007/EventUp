//
//  Event.swift
//  EventUp!
//
//  Created by Siraj Zaneer on 9/28/17.
//  Copyright © 2017 Siraj Zaneer. All rights reserved.
//

import UIKit

class Event: NSObject {

    var name: String!
    var date: Double!
    var longitude: String!
    var latitude: String!
    var tags: String!
    var peopleCount: Int!
    var rating: Double!
    var ratingCount: Int!
    
    init(eventData: [String: Any]) {
        name = eventData["name"] as! String
        date = eventData["date"] as! Double
        longitude = eventData["longitude"] as! String
        latitude = eventData["latitude"] as! String
        tags = eventData["tags"] as! String
        peopleCount = eventData["peopleCount"] as! Int
        rating = eventData["rating"] as! Double
        ratingCount = eventData["ratingCount"] as! Int
    }
}
