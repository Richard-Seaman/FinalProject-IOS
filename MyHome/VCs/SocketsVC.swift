//
//  SocketsVC.swift
//  MyHome
//
//  Created by Richard Seaman on 24/06/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Foundation

class SocketsVC: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    // Table Variables
    var tableViewController = UITableViewController()
    
    // Sections
    let sectionHeadings:[String] = ["RPI", "Sockets"]
    let sIndexRpi:Int = 0
    let sIndexSockets:Int = 1
    
    // Rpi
    let rIndexRpiStatus:Int = 0
    
    // Identifiers
    let rpiStatusIdentifier:String = "RpiStatusCell"
    let socketIdentifier:String = "SocketCell"
    
    // RPI Status
    var rpiLastCheckTime: Double? = nil
    
    // Socket objects
    var sockets:[RFSocket] = [RFSocket]()
    
    // Firebase
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up nav bar
        self.navigationItem.titleView = getNavImageView(UIApplication.shared.statusBarOrientation)
        
        // Set up the loading view
        self.loadingView.backgroundColor = colourDefault
        self.loadingLabel.text = "Syncing..."
        self.loadingIndicator.hidesWhenStopped = true
        self.loadingView.alpha = 0
        
        // Apply tableview to Table View Controller (needed to get rid of blank space)
        tableViewController.tableView = tableView
        
        // Apply the row height
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0;
        
        ref = Database.database().reference()
        
        // Observe changes to the Realtime Database
        ref.child("sockets").observe(.value, with: { (snapshot) in
            print(snapshot.childrenCount)
            
            // Get socket dictionary
            //let sockets = snapshot.value as? NSDictionary
            if let sockets = snapshot.value as? NSDictionary{
                
                if let stringKeys = sockets.allKeys as? [String] {
                    
                    // Empty all existing sockets
                    // They're about to be repopulated
                    self.sockets.removeAll()
                    
                    // Extract each of the individual socket dictionaries and extract their statuses
                    // Check all keys (non sockets can be handled)
                    for key in stringKeys {
                        // Try to cast the value as another dictionary
                        if let socketDict = sockets[key] as? NSDictionary {
                            // if successful, try to get the value of the status key
                            if let status:Int = socketDict["status"] as? Int {
                                // If found a status key, this indicates it's a socket dictionary
                                // Get the info and create socket object
                                
                                let number:Int? = socketDict["number"] as? Int
                                let display:String? = socketDict["display"] as? String
                                
                                self.sockets.append(RFSocket(key: key, isOn: status == 1 ? true : false, number: number, display: display))
                            }
                        }
                    }
                    
                    // Sort the sockets by number
                    self.sockets.sort(by: self.sorterSockets)
                    
                }
                
                // Extract the rpi status dictionary and get the time
                if let rpiDict = sockets["rpiLastCheck"] as? NSDictionary {
                    self.rpiLastCheckTime = rpiDict["time"] as? Double
                }
                
            }
            
            // Reload the table
            self.refresh()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    // Sort RF Socket objects by their number (and if they don't have numbers, use their keys)
    func sorterSockets(this:RFSocket, that:RFSocket) -> Bool {
        if (this.number != nil && that.number != nil) {
            return this.number! < that.number!
        }
        return this.key > that.key
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func refresh() {
        self.tableView.reloadData()
    }
    
    // UI Updates
    
    func startLoading() {
        self.loadingIndicator.startAnimating()
        self.loadingView.alpha = 1
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopLoading), userInfo: nil, repeats: false)
    }
    
    @objc func stopLoading() {
        self.loadingIndicator.stopAnimating()
        self.loadingView.alpha = 0
    }
    
    @objc func switchChanged(currentSwitch:UISwitch) {
        
        self.sockets[currentSwitch.tag].isOn = currentSwitch.isOn
        self.pushSocketStatus(socket: self.sockets[currentSwitch.tag])
        
    }
    /*
    func updateSocket(socket:RFSocket) {
        
        print("Updating Socket:")
        print(socket.toString)
        
        // Update Firebase value
        let socketDict = ["display": socket.display != nil ? socket.display! : "",
                          "number": socket.number != nil ? socket.display! : "",
                          "time_between_image_captures": self.timeImageCapture,
                          "time_delay_before_picture": self.timeImageDelay,
                          "time_between_display_updates": self.timeDisplayUpdate,
                          "time_between_checks_background": self.timeBackgroundChecks]
        
        let childUpdates = ["config": configDict]
        
        ref.updateChildValues(childUpdates)
        
    }*/
    
    func pushSocketStatus(socket:RFSocket) {
        
        print("Pushing Socket Status:")
        print(socket.toString)
        
        let childUpdates = ["sockets/" + socket.key + "/status": socket.getStatusForFb()]
        ref.updateChildValues(childUpdates)
        
    }
    
    // MARK: - Tableview methods
    
    // Assign the rows per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == sIndexRpi) {
            return 1
        } else {
            return self.sockets.count
        }
    }
    
    // Determine Number of sections
    func numberOfSections(in tableView: UITableView) -> Int{
        return sectionHeadings.count
    }
    
    // Set properties of section header
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        returnHeader(view)
    }
    
    // Assign Section Header Text
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        return sectionHeadings[section]
    }
    
    
    // Explicitly decide the sections and rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = UITableViewCell()
        
        switch indexPath.section {
            
        case sIndexRpi:
            
            // Sensor section
            switch indexPath.row {
                
            case rIndexRpiStatus:
                // Rpi Status Row
                cell = tableView.dequeueReusableCell(withIdentifier: self.rpiStatusIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let descLabel = cell.viewWithTag(2) as? UILabel
                let timeLabel = cell.viewWithTag(3) as? UILabel
                
                // Figure out the time
                var timeStr = "Unknown"
                if let lastSyncTime = self.rpiLastCheckTime {
                    
                    let currentTime:Double = Date().timeIntervalSince1970
                    print("Last Sync time: \(lastSyncTime)")
                    print("Current time: \(currentTime)")
                    
                    // Convert epoch time to string timestamp
                    let date = Date(timeIntervalSince1970: lastSyncTime)
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
                    dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
                    timeStr = dateFormatter.string(from: date)
                    
                }
                
                // Set the elements
                if let actDescLabel = descLabel {
                    actDescLabel.text = "Last RPI Sync: "
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = timeStr
                }
                
            default:
                cell = UITableViewCell()
            }
            
        case sIndexSockets:
            
            // Socket Row
            cell = tableView.dequeueReusableCell(withIdentifier: self.socketIdentifier) as UITableViewCell!
            
            // Grab the elements using the tag
            let socketNumberLabel = cell.viewWithTag(2) as? UILabel
            let socketDisplayTextField = cell.viewWithTag(3) as? UITextField
            let socketStatusSwitch = cell.viewWithTag(4) as? UISwitch
            
            // Set the elements
            if let socketNumberLabel = socketNumberLabel {
                if let socketNumber = self.sockets[indexPath.row].number {
                    socketNumberLabel.text = String(format: "Socket %d:", socketNumber)
                } else {
                    socketNumberLabel.text = "Socket ??"
                }
            }
            
            if let socketDisplayTextField = socketDisplayTextField {
                if let socketDisplay = self.sockets[indexPath.row].display {
                    socketDisplayTextField.text = socketDisplay
                } else {
                    socketDisplayTextField.text = ""
                }
            }
            
            if let socketStatusSwitch = socketStatusSwitch {
                socketStatusSwitch.isOn = self.sockets[indexPath.row].isOn  // set to whatever the FB value is
                socketStatusSwitch.addTarget(self, action: #selector(SocketsVC.switchChanged), for: UIControlEvents.valueChanged)  // add the action
                socketStatusSwitch.tag = indexPath.row  // so we know which socket to update
            }
            
           
            
        default:
            cell = UITableViewCell()
        }
        
        cell.isUserInteractionEnabled = true
        cell.accessoryType = UITableViewCellAccessoryType.none
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Animate de-selection regardless of cell...
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    

}
