import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var githubService: GitHubService!
    var notificationService: NotificationService!
    var oauthService: OAuthService!
    var config: Config!
    var pollTimer: Timer?
    var lastPRIds: Set<Int> = []
    var currentPRs: [PullRequest] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to accessory (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize services
        config = Config()
        githubService = GitHubService(config: config)
        notificationService = NotificationService()
        oauthService = OAuthService()
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Set custom icon (colored)
            if let icon = NSImage(named: "MenuBarIcon") {
                icon.isTemplate = false  // Show full color icon
                button.image = icon
                button.imagePosition = .imageLeading  // Icon on the left
            }
            
            // Set title (text after icon)
            button.title = "SuperReviews"
        }
        
        // Request notification permission
        notificationService.requestPermission()
        
        // Build menu
        updateMenu()
        
        // Check if logged in and start polling
        if config.hasToken() {
            startPolling()
            fetchUserInfo()
        }
    }
    
    func updateMenu() {
        menu = NSMenu()
        
        let isLoggedIn = config.hasToken()
        
        if isLoggedIn {
            // Connected header
            let username = config.getUsername() ?? "unknown"
            let connectedItem = NSMenuItem(title: "🟢 Connected as @\(username)", action: nil, keyEquivalent: "")
            connectedItem.isEnabled = false
            menu.addItem(connectedItem)
            
            // See PRs submenu (if we have PRs)
            if !currentPRs.isEmpty {
                let seePRsSubmenu = NSMenu()
                
                // Add each PR to submenu
                for pr in currentPRs {
                    let prItem = NSMenuItem(
                        title: "#\(pr.number) \(pr.title)",
                        action: #selector(openPR(_:)),
                        keyEquivalent: ""
                    )
                    prItem.representedObject = pr.url
                    prItem.target = self
                    seePRsSubmenu.addItem(prItem)
                }
                
                let seePRsItem = NSMenuItem(title: "See PRs", action: nil, keyEquivalent: "")
                seePRsItem.submenu = seePRsSubmenu
                menu.addItem(seePRsItem)
            }
            
            menu.addItem(NSMenuItem.separator())
            
            // Settings submenu
            let settingsSubmenu = NSMenu()
            
            // Toggle Notifications item (with status)
            let notifItem = NSMenuItem(title: "Toggle Notifications (Checking...)", action: #selector(toggleNotifications), keyEquivalent: "")
            notifItem.target = self
            settingsSubmenu.addItem(notifItem)
            
            // Update notification status asynchronously
            notificationService.checkAuthorizationStatus { isEnabled in
                DispatchQueue.main.async {
                    let title = isEnabled ? "Toggle Notifications (On)" : "Toggle Notifications (Off)"
                    notifItem.title = title
                }
            }
            
            // Repository Filter
            settingsSubmenu.addItem(NSMenuItem(title: "Repository Filter", action: #selector(openRepositoryFilter), keyEquivalent: ""))
            
            let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
            settingsItem.submenu = settingsSubmenu
            menu.addItem(settingsItem)
            
            menu.addItem(NSMenuItem.separator())
            
            // Logout
            menu.addItem(NSMenuItem(title: "Logout from GitHub", action: #selector(logout), keyEquivalent: ""))
        } else {
            // Not logged in
            menu.addItem(NSMenuItem(title: "Connect with GitHub", action: #selector(connect), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        // Quit
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func startPolling() {
        // Fetch immediately
        fetchPRs()
        
        // Then poll every 60 seconds
        pollTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchPRs()
        }
    }
    
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    func fetchUserInfo() {
        githubService.fetchUserInfo { [weak self] result in
            if case .success(let username) = result {
                self?.config.saveUsername(username)
                DispatchQueue.main.async {
                    self?.updateMenu()
                }
            }
        }
    }
    
    func fetchPRs() {
        githubService.fetchPRs { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let prs):
                print("✅ Fetched \(prs.count) PRs")
                
                // Store PRs for menu
                self.currentPRs = prs
                
                // Update status bar title
                DispatchQueue.main.async {
                    if let button = self.statusItem.button {
                        switch prs.count {
                        case 0:
                            button.title = "No PRs to review"
                        case 1:
                            button.title = "1 PR to review"
                        default:
                            button.title = "\(prs.count) PRs to review"
                        }
                    }
                }
                
                // Check for new PRs
                let currentIds = Set(prs.map { $0.id })
                let newPRs = prs.filter { !self.lastPRIds.contains($0.id) }
                
                if !newPRs.isEmpty && !self.lastPRIds.isEmpty {
                    // Send notifications for new PRs
                    for pr in newPRs {
                        self.notificationService.sendNotification(
                            title: "🔔 New PR Review Request",
                            body: "\(pr.title) — \(pr.repository) by \(pr.author)",
                            url: pr.url
                        )
                    }
                }
                
                self.lastPRIds = currentIds
                
                // Update menu
                DispatchQueue.main.async {
                    self.updateMenu()
                }
                
            case .failure(let error):
                print("❌ Error fetching PRs: \(error)")
            }
        }
    }
    
    @objc func openPR(_ sender: NSMenuItem) {
        if let urlString = sender.representedObject as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func connect() {
        // Start Device Flow
        oauthService.startDeviceFlow { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let codes):
                DispatchQueue.main.async {
                    self.showDeviceCodeDialog(userCode: codes.userCode, verificationUri: codes.verificationUri)
                    
                    // Start polling for token
                    self.oauthService.pollForToken(deviceCode: codes.deviceCode) { [weak self] result in
                        switch result {
                        case .success(let token):
                            self?.validateAndSaveToken(token)
                        case .failure(let error):
                            DispatchQueue.main.async {
                                let alert = NSAlert()
                                alert.messageText = "Authorization Failed"
                                alert.informativeText = error.localizedDescription
                                alert.alertStyle = .critical
                                
                                if let icon = NSImage(named: "AppIcon") {
                                    alert.icon = icon
                                }
                                
                                alert.addButton(withTitle: "OK")
                                alert.runModal()
                            }
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Connection Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    
                    if let icon = NSImage(named: "AppIcon") {
                        alert.icon = icon
                    }
                    
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    func showDeviceCodeDialog(userCode: String, verificationUri: String) {
        let alert = NSAlert()
        alert.messageText = "🔐 Connect to GitHub"
        
        // Create a more detailed and friendly message
        let message = """
        Follow these steps to connect:
        
        1️⃣ Copy your code (click the button below)
        2️⃣ Click 'Open GitHub & Authorize' and paste the code
        3️⃣ Click 'Authorize SuperReviews'
        
        ℹ️ About permissions:
        • SuperReviews only reads your PRs (read-only access)
        • You can skip "Organization access" - it's not needed!
        • The app works with repos where you're requested as reviewer
        
        Your code:
        """
        
        alert.informativeText = message
        alert.alertStyle = .informational
        
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        
        // Create a custom view with the code in a copyable text field
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 80))
        
        // Code display field (large, centered, copyable)
        let codeField = NSTextField(frame: NSRect(x: 0, y: 40, width: 400, height: 32))
        codeField.stringValue = userCode
        codeField.isEditable = false
        codeField.isSelectable = true
        codeField.isBezeled = true
        codeField.bezelStyle = .roundedBezel
        codeField.alignment = .center
        codeField.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        containerView.addSubview(codeField)
        
        // Copy button
        let copyButton = NSButton(frame: NSRect(x: 150, y: 5, width: 100, height: 28))
        copyButton.title = "Copy Code"
        copyButton.bezelStyle = .rounded
        copyButton.target = self
        copyButton.action = #selector(copyCodeToClipboard(_:))
        copyButton.tag = 999 // Will store the code here
        containerView.addSubview(copyButton)
        
        // Store code in a property we can access from the button action
        self.currentDeviceCode = userCode
        
        alert.accessoryView = containerView
        
        alert.addButton(withTitle: "Open GitHub & Authorize")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Copy code to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(userCode, forType: .string)
            
            // Open GitHub
            if let url = URL(string: verificationUri) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    var currentDeviceCode: String?
    
    @objc func copyCodeToClipboard(_ sender: NSButton) {
        guard let code = currentDeviceCode else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        
        // Visual feedback
        sender.title = "✓ Copied!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            sender.title = "Copy Code"
        }
    }
    
    func validateAndSaveToken(_ token: String) {
        githubService.validateToken(token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let username):
                self.config.saveToken(token)
                self.config.saveUsername(username)
                
                DispatchQueue.main.async {
                    self.updateMenu()
                    self.startPolling()
                    
                    let alert = NSAlert()
                    alert.messageText = "Success!"
                    alert.informativeText = "Connected as @\(username)\n\nSuperReviews is now monitoring your PRs."
                    alert.alertStyle = .informational
                    
                    // Add app icon
                    if let icon = NSImage(named: "AppIcon") {
                        alert.icon = icon
                    }
                    
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Invalid Token"
                    alert.informativeText = "Error: \(error)\n\nPlease verify the token has correct permissions."
                    alert.alertStyle = .critical
                    
                    // Add app icon
                    if let icon = NSImage(named: "AppIcon") {
                        alert.icon = icon
                    }
                    
                    alert.addButton(withTitle: "Try Again")
                    alert.addButton(withTitle: "Cancel")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        self.connect()
                    }
                }
            }
        }
    }
    
    @objc func logout() {
        config.deleteToken()
        stopPolling()
        lastPRIds.removeAll()
        
        if let button = statusItem.button {
            button.title = "SuperReviews"
        }
        
        updateMenu()
        
        let alert = NSAlert()
        alert.messageText = "Disconnected"
        alert.informativeText = "You've been logged out from GitHub."
        alert.alertStyle = .informational
        
        // Add app icon
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func toggleNotifications() {
        // Open System Settings to notifications
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=com.superreviews.app") {
            NSWorkspace.shared.open(url)
        }
        
        // Update menu after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.updateMenu()
        }
    }
    
    @objc func openRepositoryFilter() {
        let currentRepos = config.getRepos().joined(separator: ", ")
        
        let alert = NSAlert()
        alert.messageText = "Repository Filter"
        alert.informativeText = """
        Enter repositories to filter, separated by commas.
        
        Format: owner/repository
        Example: torvalds/linux, acme/web-app
        """
        alert.alertStyle = .informational
        
        // Add app icon
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        inputTextField.stringValue = currentRepos
        inputTextField.placeholderString = "owner/repo1, owner/repo2"
        alert.accessoryView = inputTextField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let reposString = inputTextField.stringValue
            let repos = reposString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            config.saveRepos(repos)
            
            // Refetch PRs with new filter
            if config.hasToken() {
                fetchPRs()
            }
        }
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}
