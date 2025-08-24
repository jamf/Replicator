//
//  PreferencesTabVC.swift
//  Replicator
//
//  Created by leslie on 8/21/25.
//  Copyright © 2025 Jamf. All rights reserved.
//

import AppKit

class PreferencesTabVC: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        print("viewWillAppear")
        
        if SitePreferences.show {
            selectTab(at: 2)
            SitePreferences.show = false
        }
    }

    func selectTab(at index: Int) {
        guard index >= 0, index < tabViewItems.count else { return }
        print("show preference tab \(index)")
        selectedTabViewItemIndex = index
    }
}
