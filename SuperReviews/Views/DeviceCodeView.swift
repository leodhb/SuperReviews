import SwiftUI

struct DeviceCodeView: View {
    let userCode: String
    let verificationUri: String
    let onOpenGitHub: () -> Void
    let onCancel: () -> Void
    
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Connect to GitHub")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Follow these steps to connect:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // Steps
            VStack(alignment: .leading, spacing: 12) {
                StepRow(number: "1", text: "Copy your code (click the button below)")
                StepRow(number: "2", text: "Click 'Open GitHub' and paste the code")
                StepRow(number: "3", text: "Click 'Authorize SuperReviews'")
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
            
            // Code section
            VStack(spacing: 10) {
                Text("Your code:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // Code display
                HStack {
                    Spacer()
                    Text(userCode)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .tracking(1.5)
                        .textSelection(.enabled)
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
                
                // Copy button
                Button(action: {
                    copyToClipboard()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy Code")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(copied ? .green : .accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Hint
                VStack(spacing: 4) {
                    (Text("You can skip ")
                        .foregroundColor(.secondary) +
                     Text("\"Organization access\"")
                        .fontWeight(.medium)
                        .foregroundColor(.primary) +
                     Text(" - it's not needed.")
                        .foregroundColor(.secondary))
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    
                    Text("SuperReviews uses the 'repo' scope (GitHub limitation),")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("but only reads PRs assigned to you.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
            
            Divider()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)
                
                Button("Open GitHub & Authorize") {
                    onOpenGitHub()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(16)
        }
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(userCode, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            copied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copied = false
            }
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}


// Preview
struct DeviceCodeView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceCodeView(
            userCode: "ABCD-1234",
            verificationUri: "https://github.com/login/device",
            onOpenGitHub: {},
            onCancel: {}
        )
    }
}
