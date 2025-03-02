import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 用户头像
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.top, 30)
            
            // 用户信息
            if let user = viewModel.currentUser {
                VStack(spacing: 10) {
                    Text(user.username)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 10)
            }
            
            Spacer()
            
            // 登出按钮
            Button(action: {
                viewModel.logout()
            }) {
                Text("退出登录")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .navigationTitle("个人信息")
    }
} 