//
//  SensorVC.swift
//  MyHome
//
//  Created by Richard Seaman on 07/07/2018.
//  Copyright © 2018 RichApps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SwiftChart

class SensorVC: UIViewController, ChartDelegate {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var dateSelectorView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var prevDateButton: UIButton!
    @IBOutlet weak var nextDateButton: UIButton!
    
    @IBOutlet weak var sensorSelectorView: UIView!
    @IBOutlet weak var sensorSelector: UISegmentedControl!
    
    @IBOutlet weak var labelLeadingMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    fileprivate var labelLeadingMarginInitialConstant: CGFloat!
    
    @IBOutlet weak var chart: Chart!
    
    var sensor:Sensor!
    var selectedDate:Date = Date()
    var selectedSeries:String = ""

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

        ref = Database.database().reference()
        
        // Observe changes to the Realtime Database
        ref.child("sensors/" + self.sensor.key).observe(.value, with: { (snapshot) in
            
            // Get data dictionary
            if let sensorData = snapshot.value as? NSDictionary {
                self.sensor.data = sensorData
            }
            
            // Reload the table
            self.refresh()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        // Add the prev/next day button targets
        self.prevDateButton.addTarget(self, action: #selector(SensorVC.prevDay), for: .touchUpInside)
        self.nextDateButton.addTarget(self, action: #selector(SensorVC.nextDay), for: .touchUpInside)
        
        // Configure the sensor selector segmented control
        self.sensorSelector.tintColor = colourDefault
        self.sensorSelector.removeAllSegments()
        if let sensorKeys = self.sensor.dataKeys {
            for index in 0 ..< sensorKeys.count {
                self.sensorSelector.insertSegment(withTitle: sensorKeys[index], at: index, animated: false)
            }
            // Initially set the data series to display
            self.sensorSelector.selectedSegmentIndex = 0
            self.selectedSeries = sensorKeys[0]
        }
        self.sensorSelector.addTarget(self, action: #selector(SensorVC.sensorSelectorDidChange(selector:)), for: .valueChanged)
        
        labelLeadingMarginInitialConstant = labelLeadingMarginConstraint.constant
        self.chart.delegate = self
        
        self.startLoading()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Redraw chart on rotation
        chart.setNeedsDisplay()
    }
    
    
    
    // UI Updates
    
    func refresh() {
        
        self.startLoading()
        
        // Reset the data label
        self.label.text = ""
        
        // Configure the date selector view
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        self.dateLabel.text = dateFormatter.string(from: self.selectedDate)
        
        // Check if today is selected and disable next button if it is
        self.nextDateButton.isEnabled = true
        if (Calendar.current.component(.year,  from: self.selectedDate) == Calendar.current.component(.year,  from: Date())) {
            if (Calendar.current.component(.month,  from: self.selectedDate) == Calendar.current.component(.month,  from: Date())) {
                if (Calendar.current.component(.day,  from: self.selectedDate) == Calendar.current.component(.day,  from: Date())) {
                    // If it is, disable the next button
                    self.nextDateButton.isEnabled = false
                }
            }
        }
        
        // Remove all series from the chart (about to recreate)
        self.chart.removeAllSeries()
        
        //let now:Double = Date().timeIntervalSince1970
        
        // Check if the sensor has any data
        if let data = self.sensor.data {
            // Check for data keys for this sensor
            if let dataKeys = self.sensor.dataKeys {
                // Make sure it has the selected series as a key
                if (dataKeys.contains(self.selectedSeries)) {
                    // Create an array of tuples for the x and y series data
                    var seriesData:[(x:Double, y:Double)] = []
                    // Loop through each of the time series data entries and check for this data key
                    // (i.e. epock times e.g. "1530725213")
                    if let timeStrKeys = data.allKeys as? [String] {
                        for timeStrKey in timeStrKeys {
                            // Only include those that can be cast to an Double
                            if let timeKey = Double(timeStrKey) {
                                // Create a date from the time
                                let dataDate = Date(timeIntervalSince1970: timeKey)
                                // Check if the data's date is relevant to the selected date
                                if (includeDataFromDate(dataData: dataDate)) {
                                    // Get the data for this particular time
                                    if let timeDict = data[timeStrKey] as? [String:AnyObject] {
                                        // Check if it has data for the key we're interested in (e.g. temperature)
                                        if let val:Double = timeDict[self.selectedSeries] as? Double {
                                            // if all goes well, add to the series
                                            seriesData.append((x: timeKey, y: val))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    // If the series isn't empty, add it to the chart
                    if (seriesData.count > 0) {
                        // sort data by time
                        seriesData.sort { (a, b) -> Bool in
                            a.x < b.x
                        }
                        self.chart.add(ChartSeries(data: seriesData))
                        
                        // Set the min/max y axis values for two specific cases; temperature / humidity
                        // Otherwise will have no min/max applied and will adjust as required
                        if (self.selectedSeries.lowercased() == "temperature") {
                            self.chart.minY = 14
                            self.chart.maxY = 28
                        } else if (self.selectedSeries.lowercased() == "humidity") {
                            self.chart.minY = 40
                            self.chart.maxY = 70
                        }
                    }
                    
                }
                
            }
        }
        
        // Configure the chart
        
        // Figure out and add labels
        self.chart.xLabels = self.getLabelPositionsForDate(date: self.selectedDate)
        self.chart.xLabelsFormatter = { String(Calendar.current.component(.hour,  from: Date(timeIntervalSince1970: $1))) + "h" }
        
        //self.chart.minY = 0
        self.chart.yLabelsFormatter = { String(Int($1)) +  self.sensor.getUnitForKey(key: self.selectedSeries) }
        
        self.stopLoading()
        
    }
    
    // Regardless of the date, we want to display a label at the same hour intervals accross the day
    // But the hour interval epoch time will be different for each date
    // Must calculate on the fly
    func getLabelPositionsForDate(date:Date) -> [Double] {
        
        // Create an array of doubles which will store the corresponding epoch time for each of the required hour positions
        var labelPositions:[Double] = [Double]()
        
        // Break up the date into components
        let calendar = Calendar(identifier: .gregorian)
        let year = Calendar.current.component(.year,  from: date)
        let month = Calendar.current.component(.month,  from: date)
        let day = Calendar.current.component(.day,  from: date)
        
        // The constant hour positions we want labels at, regardless of the date
        let hours:[Int] = [0, 3, 6, 9, 12, 15, 18, 21]
        
        // For each of hour required
        for hour in hours {
            // Create a date from the components and the hour
            let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: 0, second: 0)
            let dateForLabel = calendar.date(from: components)!
            // Add the corresponding epoch time to the array
            labelPositions.append(dateForLabel.timeIntervalSince1970)
        }
        
        return labelPositions
    }
    
    // Check if data's date matches the selected date
    func includeDataFromDate(dataData:Date) -> Bool {
        if (Calendar.current.component(.year,  from: self.selectedDate) == Calendar.current.component(.year,  from: dataData)) {
            if (Calendar.current.component(.month,  from: self.selectedDate) == Calendar.current.component(.month,  from: dataData)) {
                if (Calendar.current.component(.day,  from: self.selectedDate) == Calendar.current.component(.day,  from: dataData)) {
                    return true
                }
            }
        }
        return false
    }
    
    // Functions for changing the selected date (by +/- 1 day)
    @objc func prevDay() {
        self.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: self.selectedDate)!
        self.refresh()
    }
    @objc func nextDay() {
        self.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: self.selectedDate)!
        self.refresh()
    }
    
    // Function for changing selected sensor key
    @objc func sensorSelectorDidChange(selector:UISegmentedControl) {
        if let dataKeys = self.sensor.dataKeys {
            self.selectedSeries = dataKeys[selector.selectedSegmentIndex]
            self.refresh()
        }
    }
    
    func startLoading() {
        self.loadingIndicator.startAnimating()
        self.loadingView.alpha = 1
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopLoading), userInfo: nil, repeats: false)
    }
    
    @objc func stopLoading() {
        self.loadingIndicator.stopAnimating()
        self.loadingView.alpha = 0
    }
    
    ///////////////////////////////////////////////////////////////////////////////
    // Chart delegate methods
    // NB: Not Original Code!
    // Chart delegate methods were copied from the example provided within the SwiftChart github repository
    // available at: https://github.com/gpbl/SwiftChart/tree/master/Example/SwiftChart
    // They were only slightly adjusted to suit this application
    
    func didTouchChart(_ chart: Chart, indexes: Array<Int?>, x: Double, left: CGFloat) {
        
        if let value = chart.valueForSeries(0, atIndex: indexes[0]) {
            
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 0
            label.text = numberFormatter.string(from: NSNumber(value: value))
            
            // Align the label to the touch left position, centered
            var constant = labelLeadingMarginInitialConstant + left - (label.frame.width / 2)
            
            // Avoid placing the label on the left of the chart
            if constant < labelLeadingMarginInitialConstant {
                constant = labelLeadingMarginInitialConstant
            }
            
            // Avoid placing the label on the right of the chart
            let rightMargin = chart.frame.width - label.frame.width
            if constant > rightMargin {
                constant = rightMargin
            }
            
            labelLeadingMarginConstraint.constant = constant
            
        }
        
    }
    
    func didFinishTouchingChart(_ chart: Chart) {
        label.text = ""
        labelLeadingMarginConstraint.constant = labelLeadingMarginInitialConstant
    }
    
    func didEndTouchingChart(_ chart: Chart) {
        
    }
    
    // End of Chart Delegate methods (which were mostly copied from online example)
    ///////////////////////////////////////////////////////////////////////////////
    
    

}
