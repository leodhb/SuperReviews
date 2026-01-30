import SwiftUI

struct RepositoryFilterView: View {
    @State private var repositories: [String]
    @State private var newRepo: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let onSave: ([String]) -> Void
    let onCancel: () -> Void
    
    init(repositories: [String], onSave: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        _repositories = State(initialValue: repositories)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Text("Repository Filter")
                    .font(.system(size: 18, weight: .semibold))
                
                VStack(spacing: 8) {
                    Text("Filter which repositories to show PRs from.")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            
                            Text("Empty = all your PRs")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            
                            Text("With repos = only those repos")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Add repository section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Repository")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 6) {
                        TextField("owner/repository", text: $newRepo)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit {
                                addRepository()
                            }
                        
                        Button(action: addRepository) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(newRepo.isEmpty)
                        .help("Add repository")
                    }
                    
                    if showError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                            Text(errorMessage)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.red)
                        .padding(.top, 4)
                    }
                }
                
                // List section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if repositories.isEmpty {
                            Text("No Filter Active")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        } else {
                            Text("Active Filters (\(repositories.count))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }
                        Spacer()
                    }
                    
                    if repositories.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                            
                            Text("Showing all your PRs")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 4) {
                                Text("Add repositories above to filter which ones appear")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Text("(only listed repos will be shown)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                Text("Only PRs from these repositories will be shown")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                            }
                            .padding(.bottom, 4)
                            
                            List {
                                ForEach(repositories, id: \.self) { repo in
                                    HStack(spacing: 8) {
                                        Text(repo)
                                            .font(.system(size: 13))
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            removeRepository(repo)
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .help("Remove filter")
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .listStyle(.inset)
                            .scrollContentBackground(.visible)
                            .frame(height: 160)
                        }
                    }
                }
            }
            .padding(20)
            
            Divider()
            
            // Footer buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    onSave(repositories)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 500, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func addRepository() {
        let trimmed = newRepo.trimmingCharacters(in: .whitespaces)
        
        // Validate format
        guard !trimmed.isEmpty else { return }
        
        let components = trimmed.split(separator: "/")
        guard components.count == 2,
              !components[0].isEmpty,
              !components[1].isEmpty else {
            showError = true
            errorMessage = "Invalid format. Use: owner/repository"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
            return
        }
        
        // Check if already exists
        if repositories.contains(trimmed) {
            showError = true
            errorMessage = "Repository already in the list"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
            return
        }
        
        // Add repository
        withAnimation(.easeInOut(duration: 0.2)) {
            repositories.append(trimmed)
        }
        newRepo = ""
        showError = false
    }
    
    private func removeRepository(_ repo: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            repositories.removeAll { $0 == repo }
        }
    }
}

// Preview
struct RepositoryFilterView_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryFilterView(
            repositories: ["torvalds/linux", "apple/swift"],
            onSave: { _ in },
            onCancel: {}
        )
    }
}
