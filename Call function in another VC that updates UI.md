# ViewController2 (ViewController)
- add to viewDidLoad
NotificationCenter.default.addObserver(self, selector: #selector(toggleExportOnly(_:)), name: .saveOnlyButtonToggle, object: nil)

@objc func toggleExportOnly(_ notification: Notification) {
    disableSource() // updates UI element (button state)
}
func disableSource() {
    
}

extension Notification.Name {
    public static let saveOnlyButtonToggle = Notification.Name("toggleExportOnly")
}


# ViewController1 (PreferencesViewController)
- needs to update the UI in ViewController2
NotificationCenter.default.post(name: .saveOnlyButtonToggle, object: self)


# App/Window closes
- remove observer, add to closeDidClose/addDidQuit

NotificationCenter.default.removeObserver(self, name: .saveOnlyButtonToggle, object: nil)
or
DistributedNotificationCenter.default.removeObserver(self, name: .saveOnlyButtonToggle, object: nil)
