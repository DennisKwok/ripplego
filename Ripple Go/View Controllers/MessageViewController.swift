//
//  MessageViewController.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMaps

class MessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageCellDelegate{
    
    @IBOutlet weak var addressLine1: UILabel!
    @IBOutlet weak var addressLine2: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var leaveMsgBtn: UIButton!
    @IBOutlet weak var messagesTable: UITableView!
    @IBOutlet weak var hint: UILabel!
    
    
    var address:[String:Any]!
    var currentLocation: CLLocation!
    var ref: DatabaseReference!
    var user:User!
    var lat:Double = -1
    var long:Double = -1
    
    var msgs:[Message] = []
    let spinner:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesTable.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier:  "MessageCell")
        messagesTable.backgroundColor = UIColor.white
        
        //Load more indicator
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: messagesTable.bounds.width, height: CGFloat(44))
        messagesTable.tableFooterView = spinner
        
        if let building = address["BUILDING"] as? String {
            self.addressLine1.text = building.capitalized
        }
        if let add = address["ADDRESS"] as? String {
            self.addressLine2.text = add.capitalized
        }
        
        if let latitude = address["LATITUDE"] as? String {
            lat = Double(latitude)!
        }
        
        if let longitude = address["LONGITUDE"] as? String {
            long =  Double(longitude)!
        }
        
//        showHint()
        calculateDistance()
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMessages(){
        let ref = Database.database().reference(fromURL:GlobalVar.sharedInstance.FirebaseURL).child("messages")
        let query = ref.queryOrdered(byChild: "coordinates").queryEqual(toValue: "\(lat),\(long)")
        print("\(lat),\(long)")
        
        query.observe(.value, with: { (snapshot) in
            var newItems: [Message] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let msg = Message(snapshot: snapshot) {
                    newItems.append(msg)
                }
            }
            
            self.msgs = newItems
            self.messagesTable.reloadData()
            self.messagesTable.tableFooterView = nil
        })
    }
    
    func showHint(){
        hint.isHidden = false
        messagesTable.isHidden = true
    }
    
    func showMessages(){
        hint.isHidden = true
        messagesTable.isHidden = false
    }
    
    func calculateDistance(){
        let coordinate = CLLocation(latitude: lat, longitude: long)
        let distanceInMeters = coordinate.distance(from: currentLocation)
        
        if (distanceInMeters > 1000){
            distance.text = "\(String(format: "%.0f", distanceInMeters/1000)) km away"
            showHint()
            self.messagesTable.tableFooterView = nil
        }
        else{
            distance.text = "\(String(format: "%.0f", distanceInMeters)) m away"
            if distanceInMeters <= 10 {
                showMessages()
                getMessages()
            }
            else{
                showHint()
                self.messagesTable.tableFooterView = nil
            }
        }
        
    }
    
    @IBAction func leaveMsgTapped(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "Enter your message below", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            self.ref = Database.database().reference()
            let data = [ "message" : textField!.text!,
                         "building" : self.address["BUILDING"] as? String ?? "",
                         "lat" : "\(self.lat)",
                         "long" : "\(self.long)",
                         "coordinates" : "\(self.lat),\(self.long)",
                         "addedBy" : "\(Auth.auth().currentUser!.email!)"]
            
            self.ref.child("messages").childByAutoId().setValue(data)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: Table View Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.msgs.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        
        
        if(indexPath.row < self.msgs.count){
            let message = self.msgs[indexPath.row]
            cell.email.text = message.addedBy
            cell.messages.text = message.message
            checkLiked(indexPath: indexPath)
        }
        cell.messageCellDelegate = self
        cell.index = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func didPressButton(_ tag: Int, saved: Bool) {
        print("I have pressed a button with a tag: \(tag)")
        self.ref = Database.database().reference()
        if(tag < self.msgs.count){
            let message = self.msgs[tag]
            
            if(saved){
                let email = Auth.auth().currentUser!.email!
                let ref = Database.database().reference()
            
                ref.child("messages").child(message.key).child("saved_by").queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
                    
                    if let saved = snapshot.value as? [String : AnyObject] {
                        for (key, value) in saved {
                            if value as! String == email {
                               self.ref.child("messages").child(message.key).child("saved_by").child("\(key)").removeValue()
                                let uid = Auth.auth().currentUser!.uid
                                self.ref.child("saved_messages").child("\(uid)").child(message.key).removeValue()
                                let ip = IndexPath(row: tag, section: 0)
                                (self.messagesTable.cellForRow(at: ip) as! MessageCell).saveBtn.setTitle("Save", for: .normal)
                                (self.messagesTable.cellForRow(at: ip) as! MessageCell).saved = false
                            }
                        }
                    }
                })
                
                ref.removeAllObservers()
                
                
            }
            else{
                self.ref.child("messages").child(message.key).child("saved_by").childByAutoId().setValue("\(Auth.auth().currentUser!.email!)")
                let uid = Auth.auth().currentUser!.uid
                 self.ref.child("saved_messages").child("\(uid)").child(message.key).setValue("true")
            }
        }
    }
    
    func checkLiked(indexPath:IndexPath){
            let email = Auth.auth().currentUser!.email!
            let ref = Database.database().reference()
            
            let message = self.msgs[indexPath.row]
            
            ref.child("messages").child(message.key).child("saved_by").queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
                
                if let saved = snapshot.value as? [String : AnyObject] {
                    for (_, value) in saved {
                        if value as! String == email {
                            (self.messagesTable.cellForRow(at: indexPath)! as! MessageCell).saveBtn.setTitle("Unsave", for: .normal)
                            (self.messagesTable.cellForRow(at: indexPath)! as! MessageCell).saved = true
                        }
                    }
                }
            })
            ref.removeAllObservers()
}
    
}



