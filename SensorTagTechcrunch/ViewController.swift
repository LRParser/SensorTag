//
//  ViewController.swift
//  SensorTagTechcrunch
//
//  Created by Joseph Heenan on 5/2/15.
//  Copyright (c) 2015 Joseph Heenan. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate, LeapListener {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var currentDiff: NSTextField!
    
    @IBOutlet weak var postureImage: NSImageCell!
    
    var allowedDiff : Double = 0.0
    var breakScore : Double = 10.0;
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    @IBAction func didCalibrate(sender: NSTextField) {
        print("Calibrate text added");
        allowedDiff = sender.doubleValue;
        print("Allowed diff \(allowedDiff)")
    }


    @IBAction func didSetBreakScore(sender: NSTextField) {
        print("Break score set");
        breakScore = sender.doubleValue;
        print("Break score \(breakScore)")
    }

    
    @IBOutlet weak var slouchLabel: NSTextField!
    var calibratedDouble : Double!
    
    var calibratedX : Double! = 0
    var calibratedY : Double! = 0
    var calibratedZ : Double! = 0
    // Sensor Values
    var allSensorLabels : [String] = []
    var allSensorValues : [Double] = []
    var ambientTemperature : Double!
    var objectTemperature : Double!
    var accelerometerX : Double!
    var accelerometerY : Double!
    var accelerometerZ : Double!
    var relativeHumidity : Double!
    var magnetometerX : Double!
    var magnetometerY : Double!
    var magnetometerZ : Double!
    var gyroscopeX : Double!
    var gyroscopeY : Double!
    var gyroscopeZ : Double!
    var hasMagValues : Bool = false;
    var alertSent : Bool = false;
    
    var hasBeenCalibrated : Bool = false
    var launchPath = "/usr/bin/curl"

    let straightImage = NSImage(named: "appImagesStraight")
    
    let slouchImage = NSImage(named: "appImagesSlouch")
    
    @IBOutlet weak var magXLabel: NSTextField!
    
    @IBOutlet weak var magYLabel: NSTextField!
    
    @IBOutlet weak var magZLabel: NSTextField!
    
    @IBOutlet weak var magXDiff: NSTextField!
    
    @IBOutlet weak var magYDiff: NSTextField!
    
    @IBOutlet weak var magZDiff: NSTextField!
    
    var sumSquaredErrors : Double!
    
    @IBOutlet weak var triggerField: NSTextField!
    
    @IBAction func calibrateButton(sender: AnyObject) {
        
        if(self.hasMagValues) {
        self.calibratedX = self.magnetometerX;
        self.calibratedY = self.magnetometerY;
        self.calibratedZ = self.magnetometerZ;
        
        self.hasBeenCalibrated = true;
        
            //self.triggerField.doubleValue = 50.00;
            //self.allowedDiff = 50.00;
            
        println("Calibrated \(self.calibratedX), \(self.calibratedY), \(self.calibratedZ)");
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "posture.io"
    }
    
    // BLE
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!
    
    func onConnect(notification: NSNotification!) {
        println("Leap connected");
    }
    
    func onFrame(notification: NSNotification!) {
        // println("Leap data received");
        
        var controller : LeapController = notification.object as! LeapController;
        var leapFrame : LeapFrame = controller.frame(0) as LeapFrame!;
        
        var leapGestures : [AnyObject]! = leapFrame.gestures(nil) as! [LeapGesture!]

        for gesture in leapGestures {
            if(gesture.type == LeapGestureType.LEAP_GESTURE_TYPE_CIRCLE && gesture.state == LeapGestureState.LEAP_GESTURE_STATE_START) {
                println("Circle gesture");
            }
            if(gesture.type == LeapGestureType.LEAP_GESTURE_TYPE_SWIPE && gesture.state == LeapGestureState.LEAP_GESTURE_STATE_START) {
                println("Swipe gesture");
                titleLabel.doubleValue = titleLabel.doubleValue + 0.1;
            
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        

        
        
        var leapController : LeapController = LeapController(listener: self)
        let leapGestureType = LeapGestureType.LEAP_GESTURE_TYPE_CIRCLE;
        leapController.enableGesture(leapGestureType, enable: true)
        leapController.enableGesture(LeapGestureType.LEAP_GESTURE_TYPE_SWIPE, enable: true)

        titleLabel.integerValue = 100;
        
        

        let icon = NSImage(named: "statusicon")
        icon?.setTemplate(true)
        statusItem.image = icon;
        statusItem.menu = statusMenu;
        
        

        postureImage.image = straightImage;
        
        println("View loaded");

        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Initialize all sensor values and labels
        allSensorLabels = SensorTag.getSensorLabels()
        for (var i=0; i<allSensorLabels.count; i++) {
            allSensorValues.append(0)
        }
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    /******* CBCentralManagerDelegate *******/
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Scan for peripherals if BLE is turned on
            central.scanForPeripheralsWithServices(nil, options: nil)
            
            self.statusLabel.stringValue = "Searching for BLE Devices"
            println(self.statusLabel.stringValue);
        }
        else {
            // Can have different conditions for all states if needed - show generic alert for now
            self.statusLabel.stringValue = "Not connected";
            println(self.statusLabel.stringValue);

        }
    }
    
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        if SensorTag.sensorTagFound(advertisementData) == true {
            
            // Update Status Label
            self.statusLabel.stringValue = "Sensor Tag Found"
            println(self.statusLabel.stringValue);

            // Stop scanning, set as the peripheral to use and establish connection
            self.centralManager.stopScan()
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
        else {
            self.statusLabel.stringValue = "Sensor Tag NOT Found"
            println(self.statusLabel.stringValue);

            //showAlertWithText(header: "Warning", message: "SensorTag Not Found")
        }
    }
    
    // Discover services of the peripheral
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        self.statusLabel.stringValue = "Discovering peripheral services"
        println(self.statusLabel.stringValue);

        peripheral.discoverServices(nil)
    }
    
    
    // If disconnected, start searching again
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        self.statusLabel.stringValue = "Disconnected"
        println(self.statusLabel.stringValue);

        central.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    /******* CBCentralPeripheralDelegate *******/
    
    // Check if the service discovered is valid i.e. one of the following:
    // IR Temperature Service
    // Accelerometer Service
    // Humidity Service
    // Magnetometer Service
    // Barometer Service
    // Gyroscope Service
    // (Others are not implemented)
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        self.statusLabel.stringValue = "Looking at peripheral services"
        println(self.statusLabel.stringValue);

        for service in peripheral.services {
            let thisService = service as! CBService
            if SensorTag.validService(thisService) {
                // Discover characteristics of all valid services
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
        }
    }
    
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        
        
        var enableValue = 1
        let enablyBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))
        
        for charateristic in service.characteristics {
            let thisCharacteristic = charateristic as! CBCharacteristic
            if SensorTag.validDataCharacteristic(thisCharacteristic) {
                // Enable Sensor Notification
                self.sensorTagPeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
            }
            if SensorTag.validConfigCharacteristic(thisCharacteristic) {
                // Enable Sensor
                self.sensorTagPeripheral.writeValue(enablyBytes, forCharacteristic: thisCharacteristic, type: CBCharacteristicWriteType.WithResponse)
            }
        }
        
    }
    
    
    
    // Get data values when they are updated
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        
        self.statusLabel.stringValue = "Connected"

        if characteristic.UUID == IRTemperatureDataUUID {
            self.ambientTemperature = SensorTag.getAmbientTemperature(characteristic.value())
            self.objectTemperature = SensorTag.getObjectTemperature(characteristic.value(), ambientTemperature: self.ambientTemperature)
            self.allSensorValues[0] = self.ambientTemperature
            self.allSensorValues[1] = self.objectTemperature
        }
        else if characteristic.UUID == AccelerometerDataUUID {
            let allValues = SensorTag.getAccelerometerData(characteristic.value())
            self.accelerometerX = allValues[0]
            self.accelerometerY = allValues[1]
            self.accelerometerZ = allValues[2]
            self.allSensorValues[2] = self.accelerometerX
            self.allSensorValues[3] = self.accelerometerY
            self.allSensorValues[4] = self.accelerometerZ
        }
        else if characteristic.UUID == HumidityDataUUID {
            self.relativeHumidity = SensorTag.getRelativeHumidity(characteristic.value())
            self.allSensorValues[5] = self.relativeHumidity
        }
        else if characteristic.UUID == MagnetometerDataUUID {
            let allValues = SensorTag.getMagnetometerData(characteristic.value())
            self.magnetometerX = allValues[0]
            self.magnetometerY = allValues[1]
            self.magnetometerZ = allValues[2]
            self.allSensorValues[6] = self.magnetometerX
            self.allSensorValues[7] = self.magnetometerY
            self.allSensorValues[8] = self.magnetometerZ
            
            print("MagX \(self.magnetometerX), MagY \(self.magnetometerY), MagZ \(self.magnetometerZ))");
            
            self.hasMagValues = true;
            
            print("hasMagValues");
            
            self.magXLabel.doubleValue = self.magnetometerX
            
            self.magYLabel.doubleValue = self.magnetometerY
            
            self.magZLabel.doubleValue = self.magnetometerZ
            
            if(self.hasBeenCalibrated) {
            var xDiff : Double = pow(self.magnetometerX - self.calibratedX,2)
                
                println("xDiff \(xDiff)")
            
            self.magXDiff.doubleValue = xDiff;
            
            var yDiff : Double = pow(self.magnetometerY - self.calibratedY,2)
                
                println("yDiff \(xDiff)")

            
            self.magYDiff.doubleValue = yDiff;
            
            var zDiff : Double = pow(self.magnetometerZ - self.calibratedZ, 2);
                
                zDiff = self.magnetometerZ - self.calibratedZ;
                
                println("zDiff \(xDiff)")

            
            self.magZDiff.doubleValue = zDiff;
            
                var sumSquaredErrors : Double = xDiff + yDiff + zDiff;
            
            currentDiff.doubleValue = sumSquaredErrors;
            
            if(sumSquaredErrors > self.allowedDiff) {
                self.slouchLabel.stringValue = "TRUE"
                
                postureImage.image = slouchImage;

                
                let icon = NSImage(named: "slouchicon")
                icon?.setTemplate(true)
                statusItem.image = icon;
                statusItem.menu = statusMenu;
                
                if(titleLabel.doubleValue > 0) {
                    titleLabel.doubleValue = titleLabel.doubleValue - 0.1;
                }
                
                // Schedule a break on outlook.com
                // for first posture failure
                if(!alertSent) {
                
                    var now = NSDate()
                    var formatter = NSDateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss-04:00'"
                    formatter.timeZone = NSTimeZone(abbreviation: "EDT")
                    var nowPlus15 = now.dateByAddingTimeInterval(60 * 15)
                    var currentDateString = formatter.stringFromDate(nowPlus15);
                    println(currentDateString)
                    
                    var futureDate = nowPlus15.dateByAddingTimeInterval(60 * 15)
                    var futureDateString = formatter.stringFromDate(futureDate);
                    println(futureDateString)
                    
                    
                    // var emailAcct = "postureio@outlook.com";
                    var emailAcct = "joeheenan@postureio.onmicrosoft.com";
                    
                    
                    var jsonString = "{\"Subject\": \"Posture.io: Micro-strech\",\"Body\": {\"ContentType\": \"HTML\",\"Content\": \"Review exercises at ergodesktop.com\"},\"Start\": \"\(currentDateString)\",\"StartTimeZone\": \"Eastern Standard Time\",\"End\": \"\(futureDateString)\",\"EndTimeZone\": \"Eastern Standard Time\",\"Attendees\": [{\"EmailAddress\": {\"Address\": \"\(emailAcct)\",\"Name\": \"Joe Heenan\"},\"Type\": \"Required\"}]}";
                    
                    NSTask.launchedTaskWithLaunchPath(launchPath, arguments: ["-u","joeheenan@postureio.onmicrosoft.com:@377rector", "-X", "POST", "https://outlook.office365.com/api/v1.0/me/events", "-H", "Content-Type: application/json", "-H","Accept: application/json","-d",jsonString]);
                    
                    alertSent = true;
                
                    
                }
                
                
                
                
            }
            else {
                self.slouchLabel.stringValue = "FALSE"
                
                postureImage.image = straightImage;
                
                let icon = NSImage(named: "statusicon")
                icon?.setTemplate(true)
                statusItem.image = icon;
                statusItem.menu = statusMenu;
                
                //if(titleLabel.doubleValue < 100) {
                //    titleLabel.doubleValue = titleLabel.doubleValue+0.1;
                //}
                
            }
                
            }
            

        }
        else if characteristic.UUID == GyroscopeDataUUID {
            let allValues = SensorTag.getGyroscopeData(characteristic.value())
            self.gyroscopeX = allValues[0]
            self.gyroscopeY = allValues[1]
            self.gyroscopeZ = allValues[2]
            self.allSensorValues[9] = self.gyroscopeX
            self.allSensorValues[10] = self.gyroscopeY
            self.allSensorValues[11] = self.gyroscopeZ
        }
        else if characteristic.UUID == BarometerDataUUID {
            //println("BarometerDataUUID")
        }
        
    }



}

