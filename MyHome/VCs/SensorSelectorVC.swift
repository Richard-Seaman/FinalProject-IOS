//
//  SensorSelectorVC.swift
//  MyHome
//
//  Created by Richard Seaman on 07/07/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class SensorSelectorVC: UIViewController, UITableViewDataSource, UITableViewDelegate   {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // Table Variables
    var tableViewController = UITableViewController()
    
    // Sections
    let sectionHeadings:[String] = ["Sensors"]
    let sIndexSensor:Int = 0
    
    // Identifiers
    let sensorSelectorIdentifier:String = "SensorSelectorCell"
    
    // Firebase
    var ref: DatabaseReference!
    
    // Sensors
    var sensors:[Sensor] = [Sensor]()
    var selectedSensor:Sensor? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up nav bar
        //self.navigationItem.titleView = getNavImageView(UIApplication.shared.statusBarOrientation)
        
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
        ref.child("sensorMeta").observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get socket dictionary
            //let sockets = snapshot.value as? NSDictionary
            if let sensorMeta = snapshot.value as? NSDictionary{
                
                if let stringKeys = sensorMeta.allKeys as? [String] {
                    
                    // Empty all existing sensors
                    // They're about to be repopulated
                    self.sensors.removeAll()
                    
                    // Extract each of the individual dictionaries
                    // Check all keys (non sesnor meta data can be handled)
                    for key in stringKeys {
                        // Try to cast the value as another dictionary
                        if let metaDict = sensorMeta[key] as? NSDictionary {
                            // if successful, try to get the value of the display key
                            if let display:String = metaDict["display"] as? String {
                                // If found, this indicates it's a meta dictionary
                                // Get the info and create sensor object
                                let location:String? = metaDict["location"] as? String
                                let dataKeys:String? = metaDict["dataKeys"] as? String
                                let dataUnits:String? = metaDict["dataUnits"] as? String
                                self.sensors.append(Sensor(key: key, display: display, location: location, dataKeys:dataKeys, dataUnits:dataUnits))
                            }
                        }
                    }
                    
                    // Sort the sockets by display
                    self.sensors.sort(by: self.sorterSensors)
                    
                }
                
            }
            
            // Reload the table
            self.refresh()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        self.startLoading()
    }

    // Sort Sensor objects by their display names (and if they don't have display names, use their keys)
    func sorterSensors(this:Sensor, that:Sensor) -> Bool {
        if (this.display != nil && that.display != nil) {
            return this.display! < that.display!
        }
        return this.key > that.key
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func refresh() {
        self.tableView.reloadData()
        self.stopLoading()
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
    
    
    // MARK: - Tableview methods
    
    // Assign the rows per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == sIndexSensor) {
            return self.sensors.count
        } else {
            return 0
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
    
    
    // Decide the sections and rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = UITableViewCell()
        
        switch indexPath.section {
            
        case sIndexSensor:
            
            // Sensor Selector Row
            cell = tableView.dequeueReusableCell(withIdentifier: self.sensorSelectorIdentifier) as UITableViewCell!
            
            // Grab the elements using the tag
            let displayLabel = cell.viewWithTag(2) as? UILabel
            let locationTextField = cell.viewWithTag(3) as? UITextField
            
            // Set the elements
            if let displayLabel = displayLabel {
                if let display = self.sensors[indexPath.row].display {
                    displayLabel.text = display
                }
            }
            if let locationTextField = locationTextField {
                if let location = self.sensors[indexPath.row].location {
                    locationTextField.text = location
                }
            }
            
        
        default:
            cell = UITableViewCell()
        }
        
        cell.isUserInteractionEnabled = true
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Animate de-selection regardless of cell...
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Remember the selection
        self.selectedSensor = self.sensors[indexPath.row]
        
        // Open the detailed sensor view
        self.performSegue(withIdentifier: "toSensor", sender: self)
        
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass the selected sensor to the new VC
        if (segue.identifier == "toSensor") {
            let newVC = segue.destination as! SensorVC
            newVC.sensor = self.selectedSensor
        }
    }
    

}
