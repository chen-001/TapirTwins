import SwiftUI

struct InviteMemberView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SpaceViewModel
    let spaceId: String
    
    @State private var username = ""
    @State private var selectedRole: MemberRole = .submitter
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("成员信息")) {
                    TextField("用户名", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Picker("角色", selection: $selectedRole) {
                        Text("打卡者").tag(MemberRole.submitter)
                        Text("审批者").tag(MemberRole.approver)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Text("打卡者可以提交任务，审批者可以审核任务")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let space = viewModel.currentSpace, let inviteCode = space.inviteCode {
                    Section(header: Text("或者分享邀请码")) {
                        VStack(alignment: .center, spacing: 10) {
                            Text(inviteCode)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            Button(action: {
                                UIPasteboard.general.string = inviteCode
                            }) {
                                Label("复制邀请码", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("邀请成员")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("邀请") {
                    viewModel.inviteMember(spaceId: spaceId, username: username, role: selectedRole)
                    isPresented = false
                }
                .disabled(username.isEmpty)
            )
        }
    }
} 