import SwiftUI

struct SpaceDreamDetailView: View {
    let dream: Dream
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 梦境标题
                    Text(dream.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // 梦境信息
                    HStack {
                        if let username = dream.username {
                            Text("记录者: \(username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("日期: \(formattedDate(dream.date))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 梦境内容
                    Text(dream.content)
                        .font(.body)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("梦境详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return dateString
        }
        
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return dateFormatter.string(from: date)
    }
}

struct SpaceDreamDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dream = Dream(
            id: "1",
            title: "示例梦境",
            content: "这是一个示例梦境内容，描述了一个奇妙的梦境世界。在梦中，我漫步在一片星空下的草原上，远处有一座发光的城堡。我向城堡走去，但无论走多远，城堡始终保持着同样的距离。突然，我发现自己可以飞翔，于是我飞向了城堡...",
            date: "2023-05-15T00:00:00.000Z",
            createdAt: "2023-05-15T10:30:00.000Z",
            updatedAt: "2023-05-15T10:30:00.000Z",
            spaceId: "space1",
            userId: "user1",
            username: "张三"
        )
        
        return NavigationView {
            SpaceDreamDetailView(dream: dream)
        }
    }
} 