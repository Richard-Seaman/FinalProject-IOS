//
//  Sensor.swift
//  MyHome
//
//  Created by Richard Seaman on 07/07/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit

class Sensor: NSObject {

    var key:String = String()
    var display:String? = nil
    var location:String? = nil
    var dataKeys: [String]? = nil
    var dataUnits: [String]? = nil
    var data:NSDictionary? = nil
    
    init(key:String, display:String?, location:String?, dataKeys:String?, dataUnits:String?) {
        
        self.key = key
        self.display = display
        self.location = location
        
        if let dataKeysStr:String = dataKeys {
            var list:[String] = dataKeysStr.components(separatedBy: ",")
            for i in 0 ..< list.count {
                list[i] = list[i].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            self.dataKeys = list
        }
        
        if let dataUnitsStr:String = dataUnits {
            var list:[String] = dataUnitsStr.components(separatedBy: ",")
            for i in 0 ..< list.count {
                list[i] = list[i].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            self.dataUnits = list
        }
        
    }
    
    func toString() -> String {
        return "{key:\(key), display:\(String(describing: display)), location:\(String(describing: location))}"
    }
    
    
}
