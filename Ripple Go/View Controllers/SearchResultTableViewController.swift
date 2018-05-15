//
//  SearchResultTableViewController.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 13/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import UIKit


class SearchResultTableViewController:NSObject, UITableViewDelegate, UITableViewDataSource {
    var searchResult:[[String: Any]]! = []
    var parent:ViewController!
    var spinner:UIActivityIndicatorView!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResult.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        
        if(indexPath.row < self.searchResult.count){
            let address = self.searchResult[indexPath.row]
            if let building = address["BUILDING"] as? String {
                cell.line1.text = building.capitalized
            }
            if let add = address["ADDRESS"] as? String {
                cell.line2.text = add.capitalized
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row < self.searchResult.count){
            parent.addressSelected(address: self.searchResult[indexPath.row])
        }
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let offsetY = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height
//
//        if offsetY > contentHeight - scrollView.frame.size.height {
//               parent.searchResultTableView.tableFooterView = parent.spinner
////             spinner.startAnimating()
////             spinner.isHidden = false
////             parent.searchNextPage()
////            loadMoreDataFromServer()
////            self.tableView.reloadData()
//        }
//    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 40 {
            parent.searchResultTableView.tableFooterView = parent.spinner
            parent.searchNextPage()
        }
    }
    
}

