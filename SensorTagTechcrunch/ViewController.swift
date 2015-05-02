//
//  ViewController.swift
//  SensorTagTechcrunch
//
//  Created by Joseph Heenan on 5/2/15.
//  Copyright (c) 2015 Joseph Heenan. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    
    var calibratedX : Double!
    var calibratedY : Double!
    var calibratedZ : Double!
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
    var hasBeenCalibrated : Bool!
    
    var sumSquaredErrors : Double!
    
    @IBAction func calibrateButton(sender: AnyObject) {
        
        hasBeenCalibrated = true;
        self.calibratedX = self.magnetometerX;
        self.calibratedY = self.magnetometerY;
        self.calibratedZ = self.magnetometerZ;
        
        println("Calibrated \(self.calibratedX), \(self.calibratedY), \(self.calibratedZ)");
        
    }
    // BLE
    var centralManager : CBCentralManager!
    var sensorTagPeripheral : CBPeripheral!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        }
        else {
            // Can have different conditions for all states if needed - show generic alert for now
            self.statusLabel.stringValue = "Not connected";
        }
    }
    
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        if SensorTag.sensorTagFound(advertisementData) == true {
            
            // Update Status Label
            self.statusLabel.stringValue = "Sensor Tag Found"
            
            // Stop scanning, set as the peripheral to use and establish connection
            self.centralManager.stopScan()
            self.sensorTagPeripheral = peripheral
            self.sensorTagPeripheral.delegate = self
            self.centralManager.connectPeripheral(peripheral, options: nil)
        }
        else {
            self.statusLabel.stringValue = "Sensor Tag NOT Found"
            //showAlertWithText(header: "Warning", message: "SensorTag Not Found")
        }
    }
    
    // Discover services of the peripheral
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        self.statusLabel.stringValue = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    
    // If disconnected, start searching again
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        self.statusLabel.stringValue = "Disconnected"
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
        println("Magnometer");

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
            println("Magnometer");

        }
        else if characteristic.UUID == GyroscopeDataUUID {
            let allValues = SensorTag.getGyroscopeData(characteristic.value())
            self.gyroscopeX = allValues[0]
            self.gyroscopeY = allValues[1]
            self.gyroscopeZ = allValues[2]
            self.allSensorValues[9] = self.gyroscopeX
            self.allSensorValues[10] = self.gyroscopeY
            self.allSensorValues[11] = self.gyroscopeZ
            println("Gyroscope");
        }
        else if characteristic.UUID == BarometerDataUUID {
            //println("BarometerDataUUID")
        }
        
    }



}
