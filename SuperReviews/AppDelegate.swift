import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var githubService: GitHubService!
    var notificationService: NotificationService!
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
            
            // Notifications status - check current status
            // Check notification status asynchronously and update menu
            let notifItem = NSMenuItem(title: "🔄 Checking notifications...", action: nil, keyEquivalent: "")
            menu.addItem(notifItem)
            
            // Update notification status asynchronously
            notificationService.checkAuthorizationStatus { [weak self] isEnabled in
                DispatchQueue.main.async {
                    let title = isEnabled ? "🔔 Notifications ON" : "🔕 Notifications OFF - click to enable"
                    notifItem.title = title
                    notifItem.action = #selector(self?.toggleNotifications)
                    notifItem.target = self
                }
            }
            
            // Logout
            menu.addItem(NSMenuItem(title: "Logout from GitHub", action: #selector(logout), keyEquivalent: ""))
            
            menu.addItem(NSMenuItem.separator())
        } else {
            // Not logged in
            menu.addItem(NSMenuItem(title: "Connect with GitHub", action: #selector(connect), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        // Settings
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ""))
        
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
        // Open GitHub token creation page
        if let url = URL(string: "https://github.com/settings/tokens/new?scopes=read:user,repo&description=SuperReviews") {
            NSWorkspace.shared.open(url)
        }
        
        // Show dialog to enter token
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.promptForToken()
        }
    }
    
    func promptForToken() {
        let alert = NSAlert()
        alert.messageText = "Enter GitHub Token"
        alert.informativeText = """
        1. Create a token with 'read:user' and 'repo' scopes
        2. Paste it here
        """
        alert.alertStyle = .informational
        
        // Add app icon to dialog
        if let icon = NSImage(named: "AppIcon") {
            alert.icon = icon
        }
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = "ghp_..."
        alert.accessoryView = inputTextField
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let token = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !token.isEmpty {
                validateAndSaveToken(token)
            }
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
                        self.promptForToken()
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
    
    @objc func openSettings() {
        let currentRepos = config.getRepos().joined(separator: ", ")
        
        let alert = NSAlert()
        alert.messageText = "Repositories Filter"
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
