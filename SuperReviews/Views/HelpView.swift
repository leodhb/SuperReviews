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
                    
                    (Text("Your PRs might not appear if they're from ") +
                     Text("private organization repositories").fontWeight(.medium) +
                     Text(" that require explicit permission. GitHub doesn't grant access to these automatically, even with the ") +
                     Text("repo").fontWeight(.medium) +
                     Text(" scope."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    (Text("Another reason is if you have a ") +
                     Text("Repository Filter").fontWeight(.medium) +
                     Text(" active that's excluding certain repositories."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Possible Solutions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    (Text("1. ") +
                     Text("Add the repository manually").fontWeight(.medium) +
                     Text(" in Repository Filter. This tells GitHub to grant access to that specific private repo."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    (Text("2. ") +
                     Text("Check your filter").fontWeight(.medium) +
                     Text(" in Repository Filter. If it's not empty, only PRs from listed repos will appear. Clear it to see everything."))
                        .font(.system(size: 12))
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
                
                Button("Go to Repository Filter") {
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
