//
//  MyMessageViewController.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class MyMessageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var msgs:[Message] = []
    var viewSavedMsgs:Bool!
    
    
    @IBOutlet weak var messageTitle: UILabel!
    @IBOutlet weak var messagesTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesTable.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier:  "MessageCell")
        messagesTable.backgroundColor = UIColor.white
        
        
        
        if (viewSavedMsgs){
            messageTitle.text = "Saved Messages"
            let uid = Auth.auth().currentUser!.uid
            let ref = Database.database().reference()
            
            ref.queryOrdered(byChild: "addedBy")
            
            ref.child("saved_messages").child("\(uid)").queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
                if let saved = snapshot.value as? [String : AnyObject] {
                    var newItems: [Message] = []
                    print(saved)
                    for (key, _) in saved {
                        ref.child("messages").child("\(key)").queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
//                            print(snapshot.value!)
                            if let msg = Message(snapshot: snapshot) {
                                    newItems.append(msg)
                            }
                            print("NEW : \(newItems)")
                            self.msgs = newItems
                            self.messagesTable.reloadData()
                        })
                    }
                    
                }
            })
            
            ref.removeAllObservers()
        }
        else{
            let ref = Database.database().reference(fromURL:GlobalVar.sharedInstance.FirebaseURL).child("messages")
            let query = ref.queryOrdered(byChild: "addedBy").queryEqual(toValue: Auth.auth().currentUser!.email!)
            
            
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
            })
        }
        
        
    }
    
    
    //MARK: Table View Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.msgs.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        if(indexPath.row < self.msgs.count){
            let message = self.msgs[indexPath.row]
            cell.email.text = message.building
            cell.messages.text = message.message
            cell.saveBtn.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
            let deleteBtn = UITableViewRowAction(style: .default, title: "Delete") { action, indexPath in
                
                if(indexPath.row < self.msgs.count){
                    if(self.viewSavedMsgs){
                        self.unsaveMessage(indexPath: indexPath)
                    }
                    else{
                        self.deleteMessage(indexPath: indexPath)
                    }
                }
                
               
            }
            return [deleteBtn]
        
    }
    
    func deleteMessage(indexPath: IndexPath){
        let message = self.msgs[indexPath.row]
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser!.uid
        
        ref.child("messages").child(message.key).removeValue()
        ref.child("saved_messages").child("\(uid)").child(message.key).removeValue()
        
        self.msgs.remove(at: indexPath.row)
        self.messagesTable.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
    }
    
    func unsaveMessage(indexPath: IndexPath){
        let message = self.msgs[indexPath.row]
        let email = Auth.auth().currentUser!.email!
        let ref = Database.database().reference()
        
        ref.child("messages").child(message.key).child("saved_by").queryOrderedByKey().observeSingleEvent(of: .value, with: { snapshot in
            
            if let saved = snapshot.value as? [String : AnyObject] {
                for (key, value) in saved {
                    if value as! String == email {
                        ref.child("messages").child(message.key).child("saved_by").child("\(key)").removeValue()
                        let uid = Auth.auth().currentUser!.uid
                        ref.child("saved_messages").child("\(uid)").child(message.key).removeValue()
                        
                    }
                }
            }
        })
        
        ref.removeAllObservers()
        
        
        self.msgs.remove(at: indexPath.row)
        self.messagesTable.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
    }
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
