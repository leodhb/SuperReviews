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
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Public repositories")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    
                    Text("PRs from public repositories are automatically tracked when you're assigned as a reviewer.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        Text("Private repositories")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    
                    Text("GitHub requires explicit permission for private repos. Add them manually in Repository Filter.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        Text("How the filter works")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Empty filter = shows all public PRs")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("• With repos listed = shows only those repos (public or private)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("• To see public + private = add both to the filter")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
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
