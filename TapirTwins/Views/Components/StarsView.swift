import SwiftUI

struct Star: Identifiable, Hashable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct StarsView: View {
    @State private var stars: [Star] = []
    @State private var timer: Timer?
    
    init(starCount: Int = 50) {
        _stars = State(initialValue: createStars(count: starCount))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color.clear
                
                // 星星
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geometry.size.width, y: star.y * geometry.size.height)
                        .opacity(star.opacity)
                        .blur(radius: star.size / 4)
                }
            }
            .onAppear {
                startTwinkling()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .drawingGroup() // 使用Metal渲染以提高性能
    }
    
    private func createStars(count: Int) -> [Star] {
        var newStars: [Star] = []
        
        for _ in 0..<count {
            let star = Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.1...0.8),
                speed: Double.random(in: 0.3...1.5)
            )
            newStars.append(star)
        }
        
        return newStars
    }
    
    private func startTwinkling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                for i in 0..<stars.count {
                    if Double.random(in: 0...100) < 5 { // 5%的几率闪烁
                        stars[i] = Star(
                            x: stars[i].x,
                            y: stars[i].y,
                            size: stars[i].size,
                            opacity: Double.random(in: 0.1...0.8),
                            speed: stars[i].speed
                        )
                    }
                }
            }
        }
    }
}

struct StarsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            StarsView()
        }
    }
} 