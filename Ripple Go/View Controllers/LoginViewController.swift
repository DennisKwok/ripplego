//
//  LoginViewController.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit

class LoginViewController: UIViewController{
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()

        spinner.startAnimating()
        spinner.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signUpTapped(_ sender: Any) {
        loading()
        
        Auth.auth().createUser(withEmail: emailInput.text!, password: passwordInput.text!) { (user, error) in
            if error == nil {
                if let user = user {
                    print(user)
                    self.notLoading()
                    let alert = UIAlertController(title: "", message: "Account successfully created" , preferredStyle: UIAlertControllerStyle.alert)
                    self.present(alert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        alert.dismiss(animated: true, completion: nil)
                        self.performSegue(withIdentifier: "toMap", sender: nil)
                    }
                }
            } else {
                self.notLoading()
                let alert = UIAlertController(title: "", message: error?.localizedDescription , preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        loading()
        
        Auth.auth().signIn(withEmail: emailInput.text!, password: passwordInput.text!) { (user, error) in
            if error == nil {
                if let user = user {
                    print(user)
                    self.notLoading()
                        self.performSegue(withIdentifier: "toMap", sender: nil)
                }
            } else {
                self.notLoading()
                let alert = UIAlertController(title: "", message: error?.localizedDescription , preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func loading(){
        spinner.isHidden = false
        loginBtn.isHidden = true
        signUpBtn.isHidden = true
        emailInput.isEnabled = false
        passwordInput.isEnabled = false
    }
    
    func notLoading(){
        spinner.isHidden = true
        loginBtn.isHidden = false
        signUpBtn.isHidden = false
        emailInput.isEnabled = true
        passwordInput.isEnabled = true
    }
}
