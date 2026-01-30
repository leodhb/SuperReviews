import Cocoa
import SwiftUI
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
            
            // Help submenu
            let helpSubmenu = NSMenu()
            helpSubmenu.addItem(NSMenuItem(title: "Why aren't my PRs showing up?", action: #selector(showHelp), keyEquivalent: ""))
            
            let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
            helpItem.submenu = helpSubmenu
            menu.addItem(helpItem)
            
            // Settings submenu (no separator)
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
        let contentView = DeviceCodeView(
            userCode: userCode,
            verificationUri: verificationUri,
            onOpenGitHub: { [weak self] in
                // Copy code to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(userCode, forType: .string)
                
                // Open GitHub
                if let url = URL(string: verificationUri) {
                    NSWorkspace.shared.open(url)
                }
                
                // Close the window
                self?.deviceCodeWindow?.close()
            },
            onCancel: { [weak self] in
                self?.deviceCodeWindow?.close()
            }
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.deviceCodeWindow = window
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var deviceCodeWindow: NSWindow?
    
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
        let currentRepos = config.getRepos()
        
        let contentView = RepositoryFilterView(
            repositories: currentRepos,
            onSave: { [weak self] repos in
                guard let self = self else { return }
                self.config.saveRepos(repos)
                
                // Refetch PRs with new filter and update menu
                if self.config.hasToken() {
                    self.fetchPRs()
                    // Update menu after a short delay to ensure PRs are fetched
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.updateMenu()
                    }
                }
                
                // Close the window
                self.repositoryFilterWindow?.close()
            },
            onCancel: { [weak self] in
                self?.repositoryFilterWindow?.close()
            }
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Repository Filter"
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.repositoryFilterWindow = window
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var repositoryFilterWindow: NSWindow?
    var helpWindow: NSWindow?
    
    @objc func showHelp() {
        let contentView = HelpView(
            onOpenFilter: { [weak self] in
                self?.helpWindow?.close()
                self?.openRepositoryFilter()
            },
            onClose: { [weak self] in
                self?.helpWindow?.close()
            }
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Help"
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.helpWindow = window
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quit() {
        NSApp.terminate(nil)
    }
}
