//
//  AppDelegate.swift
//  SensorTagTechcrunch
//
//  Created by Joseph Heenan on 5/2/15.
//  Copyright (c) 2015 Joseph Heenan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!

        let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let icon = NSImage(named: "statusicon")
        icon?.setTemplate(true)
        statusItem.image = icon;
        statusItem.menu = statusMenu;
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

