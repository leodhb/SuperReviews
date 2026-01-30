import SwiftUI

struct RepoInput: Identifiable {
    let id = UUID()
    var value: String
}

struct RepoInputRow: View {
    @Binding var value: String
    let isInvalid: Bool
    let showRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("owner/repository", text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 1)
                )
            
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(showRemove ? "Remove" : "Clear")
        }
    }
}

struct MonitoredRepositoriesView: View {
    @State private var repoInputs: [RepoInput]
    @State private var showError: Bool = false
    @State private var invalidIDs: Set<UUID> = []
    
    let onSave: ([String]) -> Void
    let onCancel: () -> Void
    
    init(repositories: [String], onSave: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        let inputs = repositories.isEmpty 
            ? [RepoInput(value: "")] 
            : repositories.map { RepoInput(value: $0) }
        _repoInputs = State(initialValue: inputs)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                Text("Manage Monitored Repositories")
                    .font(.system(size: 18, weight: .semibold))
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        Text("Empty = monitors all repos you have access to")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("With repos = monitors only those repos")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("Repositories")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                // Repository inputs
                ForEach($repoInputs) { $input in
                    RepoInputRow(
                        value: $input.value,
                        isInvalid: invalidIDs.contains(input.id),
                        showRemove: repoInputs.count > 1,
                        onRemove: { removeOrClear(id: input.id) }
                    )
                }
                
                // Add repository button
                Button(action: addInput) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add repository")
                            .font(.system(size: 13))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .padding(.top, 4)
                
                // Error message
                if showError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text("All fields must be empty or use format: owner/repository")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.red)
                    .padding(.top, 4)
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
                    validateAndSave()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func addInput() {
        repoInputs.append(RepoInput(value: ""))
    }
    
    private func removeOrClear(id: UUID) {
        if repoInputs.count == 1 {
            if let index = repoInputs.firstIndex(where: { $0.id == id }) {
                repoInputs[index].value = ""
            }
        } else {
            repoInputs.removeAll { $0.id == id }
        }
        invalidIDs.remove(id)
        showError = false
    }
    
    private func isValidRepo(_ repo: String) -> Bool {
        let trimmed = repo.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        let parts = trimmed.split(separator: "/")
        return parts.count == 2 && !parts[0].isEmpty && !parts[1].isEmpty
    }
    
    private func validateAndSave() {
        invalidIDs.removeAll()
        
        for input in repoInputs {
            if !isValidRepo(input.value) {
                invalidIDs.insert(input.id)
            }
        }
        
        if !invalidIDs.isEmpty {
            showError = true
            return
        }
        
        let validRepos = repoInputs
            .map { $0.value.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        onSave(validRepos)
    }
}

struct MonitoredRepositoriesView_Previews: PreviewProvider {
    static var previews: some View {
        MonitoredRepositoriesView(
            repositories: ["torvalds/linux", "apple/swift"],
            onSave: { _ in },
            onCancel: {}
        )
    }
}
