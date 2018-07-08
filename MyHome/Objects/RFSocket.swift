//
//  RFSocket.swift
//  MyHome
//
//  Created by Richard Seaman on 24/06/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit

class RFSocket: NSObject {
    
    var key:String = String()
    var isOn:Bool = true
    var number:Int? = nil
    var display:String? = nil
    
    init(key:String, isOn:Bool, number:Int?, display:String?) {
        self.key = key
        self.isOn = isOn
        self.number = number
        self.display = display
    }
    
    func getStatusForFb() -> Int {
        return self.isOn ? 1 : 0
    }
    
    func toString() -> String {
        return "{key:\(key), isOn:\(isOn), number:\(String(describing: number)), display:\(String(describing: display))}"
    }

}
