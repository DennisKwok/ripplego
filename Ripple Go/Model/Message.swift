//
//  Message.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import Firebase

struct Message {
    
    let key: String
//    let savedBy: String
    let addedBy: String
    var ref:DatabaseReference?
    var message:String
    var lat: String
    var long: String
    var coordinates : String
    var building: String
    
    init(addedBy:String, building:String, message:String ,lat:String, long:String, coordinates:String, key: String = "") {
        self.key = key
        self.message = message
        self.lat = lat
        self.long = long
        self.coordinates = coordinates
        self.addedBy = addedBy
        self.building = building
        self.ref = nil
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let message = value["message"] as? String,
            let addedBy = value["addedBy"] as? String,
            let lat = value["lat"] as? String,
            let long = value["long"] as? String,
            let building = value["building"] as? String,
            let coordinates = value["coordinates"] as? String else{
                return nil
        }
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        self.message = message
        self.addedBy = addedBy
        self.lat = lat
        self.long = long
        self.building = building
        self.coordinates = coordinates
      
    }
    
    func toAnyObject() -> Any {
        return [
            "message": message,
            "addedBy": addedBy,
            "lat": lat,
            "long": long,
            "coordinates": coordinates,
        ]
    }
    
}
