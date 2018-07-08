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

class SensorVC: UIViewController {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var chart: Chart!
    
    var sensor:Sensor!

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
        
        self.startLoading()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UI Updates
    
    func refresh() {
        
        self.startLoading()
        
        // Remove all series from the chart (about to recreate)
        self.chart.removeAllSeries()
        
        //let now:Double = Date().timeIntervalSince1970
        
        // Check if the sensor has any data
        if let data = self.sensor.data {
            // Check for data keys for this sensor
            if let dataKeys = self.sensor.dataKeys {
                // Add a series for each type of the data keys (e.g. temperature, humidity)
                for key in dataKeys {
                    // Create an array of tuples for the x and y series data
                    var seriesData:[(x:Double, y:Double)] = []
                    // Loop through each of the time series data entries and check for this data key
                    // (i.e. epock times e.g. "1530725213")
                    if let timeStrKeys = data.allKeys as? [String] {
                        for timeStrKey in timeStrKeys {
                            // Only include those that can be cast to an Double
                            if let timeKey = Double(timeStrKey) {
                                // Get the data for this particular time
                                if let timeDict = data[timeStrKey] as? [String:AnyObject] {
                                    // Check if it has data for the key we're interested in (e.g. temperature)
                                    if let val:Double = timeDict[key] as? Double {
                                        // if all goes well, add to the series
                                        seriesData.append((x: timeKey, y: val))
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
                    }
                }
            }
        }
        
        self.stopLoading()
        
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
    
    

}
