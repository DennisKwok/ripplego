//
//  GlobalVar.swift
//  Ripple Go
//
//  Created by Dennis Kwok on 14/5/18.
//  Copyright © 2018 Dennis Kwok. All rights reserved.
//

import Foundation
import FirebaseAuth

class GlobalVar: NSObject {
    
    // MARK: - Shared Instance
    
    static let sharedInstance: GlobalVar = {
        let globalVar = GlobalVar()
        // setup code
        return globalVar
    }()
    
    // MARK: - Initialization Method
    var FirebaseURL:String! = "https://ripple-go.firebaseio.com/"
    
    override init() {
        super.init()
    }
}

