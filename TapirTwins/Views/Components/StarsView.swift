import SwiftUI

struct StarsView: View {
    let starsCount = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<starsCount, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: randomSize(), height: randomSize())
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.1...0.7))
                        .blur(radius: 0.2)
                }
            }
        }
    }
    
    private func randomSize() -> CGFloat {
        let sizes: [CGFloat] = [1, 1.5, 2]
        return sizes.randomElement() ?? 1
    }
}

#Preview {
    StarsView()
        .background(Color.black)
        .frame(height: 300)
} 