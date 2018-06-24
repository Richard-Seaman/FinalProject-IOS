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

class SocketsVC: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    
    // Table Variables
    var tableViewController = UITableViewController()
    
    // Sections
    let sectionHeadings:[String] = ["RPI", "Sockets"]
    let sectionRows:[Int] = [1, 5]
    let sIndexRpi:Int = 0
    let sIndexSockets:Int = 1
    
    // Rpi
    let rIndexRpiStatus:Int = 0
    
    
    // Identifiers
    let rpiStatusIdentifier:String = "RpiStatusCell"
    let socketIdentifier:String = "SocketCell"
    
    
    // Variables/Objects mapped to sockets
    var socketTextFields:[Int: UITextField] = [Int: UITextField]()
    var socketStatus:[Int: Bool] = [Int: Bool]()
    
    // Firebase
    var ref: DatabaseReference!
    
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
        
        ref.child("config").observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.childrenCount)
            // Get config values
            let config = snapshot.value as? NSDictionary
            self.timeSensorRead = config?["time_between_sensor_reads"] as? Int ?? 60
            self.timeSensorUpload = config?["time_between_sensor_uploads"] as? Int ?? 900
            self.timeImageCapture = config?["time_between_image_captures"] as? Int ?? 60
            self.timeImageDelay = config?["time_delay_before_picture"] as? Int ?? 0
            self.timeDisplayUpdate = config?["time_between_display_updates"] as? Int ?? 10
            self.timeBackgroundChecks = config?["time_between_checks_background"] as? Int ?? 60
            
            // Reload the table
            self.refresh()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
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
    
    func displayStringForTime(totalSeconds:Int) -> String {
        // Convert from seconds to "Xm Ys"
        let minutes = Int((Double(totalSeconds) / 60.0).rounded(.down))
        let seconds = totalSeconds % 60
        
        var displayString = ""
        if (minutes > 0) {
            displayString = "\(minutes)m"
            if (seconds > 0) {
                displayString = displayString + " \(seconds)s"
            }
        } else {
            displayString = "\(seconds)s"
        }
        
        return displayString
    }
    
    @objc func sliderFinished(slider:UISlider) {
        
        // Figure out the increment
        let increment:Float = Float(self.timeIncrements[slider.tag]!)
        // Round the seconds to the nearest increment
        let rounded = Int(round(slider.value / increment) * increment)
        
        // Figure out which variable to update
        switch slider.tag {
        case self.sliderTagTimeSensorRead:
            self.timeSensorRead = rounded
            print("timeSensorRead = \(self.timeSensorRead)")
        case self.sliderTagTimeSensorUpload:
            self.timeSensorUpload = rounded
            print("timeSensorUpload = \(self.timeSensorUpload)")
        case self.sliderTagTimeImageCapture:
            self.timeImageCapture = rounded
            print("timeImageCapture = \(self.timeImageCapture)")
        case self.sliderTagTimeImageDelay:
            self.timeImageDelay = rounded
            print("timeImageDelay = \(self.timeImageDelay)")
        case self.sliderTagTimeBackgroundChecks:
            self.timeBackgroundChecks = rounded
            print("timeBackgroundChecks = \(self.timeBackgroundChecks)")
        case self.sliderTagTimeDisplayUpdate:
            self.timeDisplayUpdate = rounded
            print("timeDisplayUpdate = \(self.timeDisplayUpdate)")
        default:
            print("Unknown slider did end edit")
        }
    }
    
    @objc func sliderValueChanged(slider:UISlider) {
        
        // Figure out the increment
        let increment:Float = Float(self.timeIncrements[slider.tag]!)
        // Round the seconds to the nearest increment
        let rounded = Int(round(slider.value / increment) * increment)
        // Update the text beside the slider
        self.timeLabels[slider.tag]?.text = displayStringForTime(totalSeconds: Int(rounded))
        
    }
    
    @objc func applyButtonTapped() {
        print("Sync button tapped")
        self.startLoading()
        
        let configDict = ["time_between_sensor_reads": self.timeSensorRead,
                          "time_between_sensor_uploads": self.timeSensorUpload,
                          "time_between_image_captures": self.timeImageCapture,
                          "time_delay_before_picture": self.timeImageDelay,
                          "time_between_display_updates": self.timeDisplayUpdate,
                          "time_between_checks_background": self.timeBackgroundChecks]
        
        let childUpdates = ["config": configDict]
        
        ref.updateChildValues(childUpdates)
        
    }
    
    // MARK: - Tableview methods
    
    // Assign the rows per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionRows[section]
    }
    
    // Determine Number of sections
    func numberOfSections(in tableView: UITableView) -> Int{
        return sectionRows.count
    }
    
    // Set properties of section header
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        returnHeader(view)
    }
    
    // Assign Section Header Text
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        return sectionHeadings[section]
    }
    
    func setUpSlider(slider:UISlider, min:Float, max:Float, tag:Int, currentValue:Float) {
        slider.tintColor = colourDefault
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = currentValue
        slider.tag = tag
        slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: [UIControlEvents.valueChanged])
        slider.addTarget(self, action: #selector(sliderFinished(slider:)), for: [UIControlEvents.touchUpInside, UIControlEvents.touchUpOutside])
    }
    
    // Explicitly decide the sections and rows
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell:UITableViewCell = UITableViewCell()
        
        switch indexPath.section {
            
        case sIndexSensor:
            
            // Sensor section
            switch indexPath.row {
                
            case rIndexSensorRead:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Time between sensor readings. Multiple sensor readings are averaged before uploading."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeSensorRead)
                    self.timeLabels[self.sliderTagTimeSensorRead] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeSensorRead), max: Float(self.maxTimeSensorRead), tag: self.sliderTagTimeSensorRead, currentValue: Float(self.timeSensorRead))
                    self.timeIncrements[self.sliderTagTimeSensorRead] = 30
                }
                
            case rIndexSensorUpload:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Time between sensor uploads. This will be the increment between timestamps."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeSensorUpload)
                    self.timeLabels[self.sliderTagTimeSensorUpload] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeSensorUpload), max: Float(self.maxTimeSensorUpload), tag: self.sliderTagTimeSensorUpload, currentValue: Float(self.timeSensorUpload))
                    self.timeIncrements[self.sliderTagTimeSensorUpload] = 60 * 5
                }
                
            default:
                cell = UITableViewCell()
            }
            
        case sIndexImage:
            
            // Image section
            switch indexPath.row {
                
            case rIndexImageCapture:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Minimum time between image captures."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeImageCapture)
                    self.timeLabels[self.sliderTagTimeImageCapture] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeImageCapture), max: Float(self.maxTimeImageCapture), tag: self.sliderTagTimeImageCapture, currentValue: Float(self.timeImageCapture))
                    self.timeIncrements[self.sliderTagTimeImageCapture] = 15
                }
                
            case rIndexImageDelay:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Delay between detecting the door is open and taking the picture."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeImageDelay)
                    self.timeLabels[self.sliderTagTimeImageDelay] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeImageDelay), max: Float(self.maxTimeImageDelay), tag: self.sliderTagTimeImageDelay, currentValue: Float(self.timeImageDelay))
                    self.timeIncrements[self.sliderTagTimeImageDelay] = 1
                }
                
            default:
                cell = UITableViewCell()
            }
            
        case sIndexMisc:
            
            // Image section
            switch indexPath.row {
                
            case rIndexDisplayTime:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Minimum time that each display message is shown for."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeDisplayUpdate)
                    self.timeLabels[self.sliderTagTimeDisplayUpdate] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeDisplayUpdate), max: Float(self.maxTimeDisplayUpdate), tag: self.sliderTagTimeDisplayUpdate, currentValue: Float(self.timeDisplayUpdate))
                    self.timeIncrements[self.sliderTagTimeDisplayUpdate] = 5
                }
                
            case rIndexBackgroundCheck:
                // Slider Row
                cell = tableView.dequeueReusableCell(withIdentifier: sliderIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let textLabel = cell.viewWithTag(2) as? UILabel
                let slider = cell.viewWithTag(3) as? UISlider
                let timeLabel = cell.viewWithTag(4) as? UILabel
                
                // Set the elements
                if let actTextLabel = textLabel {
                    actTextLabel.text = "Time between checking for images to process."
                }
                if let actTimeLabel = timeLabel {
                    actTimeLabel.text = displayStringForTime(totalSeconds: self.timeBackgroundChecks)
                    self.timeLabels[self.sliderTagTimeBackgroundChecks] = actTimeLabel
                }
                if let actSlider = slider {
                    setUpSlider(slider: actSlider, min: Float(self.minTimeBackgroundChecks), max: Float(self.maxTimeBackgroundChecks), tag: self.sliderTagTimeBackgroundChecks, currentValue: Float(self.timeBackgroundChecks))
                    self.timeIncrements[self.sliderTagTimeBackgroundChecks] = 60
                }
                
            default:
                cell = UITableViewCell()
                cell.isUserInteractionEnabled = false
            }
            
        case self.sIndexApply:
            
            // Apply section
            switch indexPath.row {
                
            case rIndexApplyButton:
                // Button Row
                cell = tableView.dequeueReusableCell(withIdentifier: buttonIdentifier) as UITableViewCell!
                
                // Grab the elements using the tag
                let button = cell.viewWithTag(90) as? UIButton
                
                // Set the elements
                if let button = button {
                    button.addTarget(self, action: #selector(applyButtonTapped), for: UIControlEvents.touchUpInside)
                    button.setTitle("Sync to RPI", for: UIControlState())
                    
                    button.layer.backgroundColor = colourDefault.cgColor
                    button.layer.cornerRadius = 2.5
                }
                
            default:
                cell = UITableViewCell()
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
