import SwiftUI

struct HelpView: View {
    let onOpenFilter: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Why aren't my PRs showing up?")
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Possible Reasons")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    (Text("Your PRs might be from ") +
                     Text("private organization repositories").fontWeight(.semibold) +
                     Text(" that require explicit permission from GitHub. Even with the ") +
                     Text("repo").fontWeight(.semibold) +
                     Text(" scope, some private repos need to be added manually."))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    (Text("You might also have ") +
                     Text("specific repositories in your monitored list").fontWeight(.semibold) +
                     Text(", which will hide PRs from other repos."))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Possible Solutions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    (Text("Add the repository manually").fontWeight(.semibold) +
                     Text(" to your monitored list. This tells GitHub you want to track that specific private repo, and Nag will start showing PRs from it."))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    (Text("If you already added repos, ") +
                     Text("remove them from your monitored list").fontWeight(.semibold) +
                     Text(" to see PRs from all repositories. An empty list shows everything you have access to."))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Spacer()
                
                Button("OK") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Manage Monitored Repositories") {
                    onOpenFilter()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// Preview
struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(
            onOpenFilter: {},
            onClose: {}
        )
    }
}
