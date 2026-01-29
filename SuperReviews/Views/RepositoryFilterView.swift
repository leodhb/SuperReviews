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
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Add repository section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        TextField("owner/repository", text: $newRepo)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                            .onSubmit {
                                addRepository()
                            }
                        
                        Button(action: addRepository) {
                            Image(systemName: "plus")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                        .disabled(newRepo.isEmpty)
                        .help("Add repository")
                    }
                    
                    if showError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(errorMessage)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.red)
                        .padding(.top, 2)
                    }
                }
                
                // List section
                VStack(alignment: .leading, spacing: 8) {
                    if !repositories.isEmpty {
                        HStack {
                            Text("Repositories (\(repositories.count))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    if repositories.isEmpty {
                        VStack(spacing: 6) {
                            Text("No filters")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("All your assigned PRs will be shown")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
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
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .listStyle(.inset)
                        .scrollContentBackground(.visible)
                        .frame(height: 200)
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
        .frame(width: 460, height: 380)
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
