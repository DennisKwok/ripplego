//
//  ViewController.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 11/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    //MARK: IBOutlet
    @IBOutlet weak var topBarView: UIView!
    
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var searchBar: UITextField!

    @IBOutlet weak var addressLine1: UILabel!
    @IBOutlet weak var addressLine2: UILabel!
    
    @IBOutlet weak var viewMsgbtn: UIButton!
    
    //MARK: IBOutlet Constraints
    @IBOutlet weak var searchBarXConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarHeight: NSLayoutConstraint!
    @IBOutlet weak var line1BottomSpace: NSLayoutConstraint!
    
    @IBOutlet weak var trailingMsgBtn: NSLayoutConstraint!
    
    //MARK:Location Manager
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var googleMapView:GMSMapView!
    var searchResultTableViewController:SearchResultTableViewController!
    
    var currentPage:Int = 1
    let spinner:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    var addressSelected:[String:Any]! = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupSearchTable()
        
        self.searchBar.addTarget(self, action:#selector(searchTextChanged(_:)), for: UIControlEvents.editingChanged)
        
        self.hideKeyboardWhenTappedAround()
        
        setupGoogleMap()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        line1BottomSpace.constant = -80
        trailingMsgBtn.constant = -150
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: Setup Google Map
    func setupGoogleMap(){
        let camera = GMSCameraPosition.camera(withLatitude: 1.292747 , longitude: 103.839484, zoom: 18.0)
        googleMapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)

        self.view.addSubview(googleMapView)
        self.view.sendSubview(toBack: googleMapView)
    }
    
    //MARK: Setup Search Table
    func setupSearchTable(){
        searchResultTableView.register(UINib(nibName: "SearchResultCell", bundle: nil), forCellReuseIdentifier:  "SearchResultCell")
        searchResultTableViewController = SearchResultTableViewController()
        searchResultTableView.delegate = searchResultTableViewController
        searchResultTableView.dataSource = searchResultTableViewController
        searchResultTableViewController.parent = self
        searchResultTableView.rowHeight = UITableViewAutomaticDimension
        searchResultTableView.estimatedRowHeight = 70.0
        searchResultTableView.keyboardDismissMode = .onDrag
        
        //Load more indicator
        spinner.startAnimating()
        spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: searchResultTableView.bounds.width, height: CGFloat(44))
        searchResultTableViewController.spinner = spinner
        searchResultTableView.tableFooterView = spinner
    }
    
    //MARK: Search Bar Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.searchBtnWidthConstraint.constant = 40
            self.searchBarXConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func searchTextChanged(_ textField: UITextField){
        searchResultTableViewController.searchResult = []
        currentPage = 1
        self.searchResultTableView.tableFooterView = spinner
        let s:String = self.searchBar.text?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        if s.count != 0 {
            searchAddress(query: s, page: 1)
            self.topBarHeight.constant = self.view.frame.height + 40
        }
        else{
            self.topBarHeight.constant = 120
        }
    }
    
    func searchNextPage(){
        let s:String = self.searchBar.text?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        currentPage += 1
        searchAddress(query: s, page: currentPage)
    }
    
    func searchAddress(query:String, page:Int){
        let url = URL(string: "https://developers.onemap.sg/commonapi/search?searchVal=\(query)&returnGeom=y&getAddrDetails=y&pageNum=\(page)")
        if let usableUrl = url {
            let request = URLRequest(url: usableUrl)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let d = data {
                    if let value = String(data: d, encoding: String.Encoding.ascii) {
                        
                        if let jsonData = value.data(using: String.Encoding.utf8) {
                            do {
                                let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]

                                if let arr = json["results"] as? [[String: Any]] {
                                    self.searchResultTableViewController.searchResult.append(contentsOf: arr)
                                    
                                    // Call UI update on main thread
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        self.searchResultTableView.tableFooterView = nil
                                        self.searchResultTableView.reloadData()
                                    }
                                }
                            } catch {
                                NSLog("ERROR \(error.localizedDescription)")
                            }
                        }
                    }
                    
                }
        })
            task.resume()
        }
    }
    
    //Displaying address selected
    func addressSelected(address:[String:Any]){
        self.addressSelected = address
        self.topBarHeight.constant = 120
        if let building = address["BUILDING"] as? String {
            self.addressLine1.text = building.capitalized
        }
        if let add = address["ADDRESS"] as? String {
            self.addressLine2.text = add.capitalized
        }
        
        var lat:Double = -1
        var long:Double = -1
        
        if let latitude = address["LATITUDE"] as? String {
            lat = Double(latitude)!
        }
        
        if let longitude = address["LONGITUDE"] as? String {
            long =  Double(longitude)!
        }
        
        self.googleMapView.clear()
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        marker.map = self.googleMapView
        
        UIView.animate(withDuration: 1, delay: 0.3, options: .curveEaseIn, animations: {
            let fancy = GMSCameraPosition.camera(withLatitude: lat,
                                                 longitude: long,
                                                 zoom: 15)
            self.googleMapView.camera = fancy
        }, completion: { (finished:Bool) in
            self.line1BottomSpace.constant = 60 + self.addressLine1.frame.height
            UIView.animate(withDuration: 0.5, delay: 0.8, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (finished:Bool) in
                self.trailingMsgBtn.constant = 15
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            })
        })
        
        UIView.animate(withDuration: 0.2) {
            self.searchBtnWidthConstraint.constant = 40
            self.searchBarXConstraint.constant = 50
        }
    }
    
    
    //MARK: Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: 15)
        self.googleMapView.animate(to: camera)
        locationManager.stopUpdatingLocation()
        self.googleMapView.clear()
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        marker.title = "Your Location"
        marker.snippet = "Singapore"
        marker.map = googleMapView
        
        self.currentLocation = location
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted, .denied:
            locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedAlways:
            locationManager.requestWhenInUseAuthorization()
            break
        }
    }

    //MARK : SEGUE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewMessages" {
            if let messageVC = segue.destination as? MessageViewController {
                messageVC.address = self.addressSelected
                messageVC.currentLocation = self.currentLocation
            }
        }
        else if segue.identifier == "toSavedMessages" {
            if let messageVC = segue.destination as? MyMessageViewController {
                messageVC.viewSavedMsgs = true
            }
        }
        else if segue.identifier == "toMyMessages" {
            if let messageVC = segue.destination as? MyMessageViewController {
                messageVC.viewSavedMsgs = false
            }
        }
    }
    
    //MARK: Button Handler
    
    @IBAction func backTapped(_ sender: Any) {
        self.searchBar.text = ""
        
        self.searchResultTableViewController.searchResult = []
        self.searchResultTableView.reloadData()
        
        self.line1BottomSpace.constant = -80
        self.trailingMsgBtn.constant = -150
        self.searchBtnWidthConstraint.constant = 0
        self.searchBarXConstraint.constant = 5
        self.topBarHeight.constant = 120
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
        
        locationManager.startUpdatingLocation()
    }
}

//MARK: Extension
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


