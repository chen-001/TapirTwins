import SwiftUI
import UIKit
import CoreGraphics
import PDFKit
import QuartzCore
import Darwin

struct ViewToImageRenderer {
    // 将SwiftUI视图转换为UIImage
    static func render<Content: View>(view: Content, size: CGSize) -> UIImage? {
        print("开始渲染视图为图片，尺寸: \(size.width) x \(size.height)")
        
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        
        // 使视图适应指定大小
        controller.view.backgroundColor = .clear
        
        // 确保视图已经布局
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        
        // 渲染视图
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
        print("视图渲染完成，图片尺寸: \(image.size.width) x \(image.size.height)")
        return image
    }
    
    // 带背景色的渲染
    static func renderWithBackground<Content: View>(view: Content, size: CGSize, backgroundColor: Color = .white) -> UIImage? {
        print("开始带背景渲染，尺寸: \(size.width) x \(size.height)")
        
        // 不再限制高度，根据内容需要渲染完整图片
        let wrappedView = ZStack {
            backgroundColor
            view
        }
        return render(view: wrappedView, size: size)
    }
    
    // 保存图片到相册
    static func saveToPhotoAlbum(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        print("开始保存图片到相册，图片尺寸: \(image.size.width) x \(image.size.height)")
        
        // 图片尺寸检查
        if image.size.width > 8000 || image.size.height > 8000 {
            print("警告: 图片尺寸过大，可能导致保存失败")
        }
        
        // 创建一个SaveToPhotoAlbumHelper实例来管理回调
        let helper = SaveToPhotoAlbumHelper(completion: completion)
        UIImageWriteToSavedPhotosAlbum(image, helper, #selector(SaveToPhotoAlbumHelper.image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        // 保留helper引用，防止被提前释放
        objc_setAssociatedObject(image, "SaveToPhotoAlbumHelper", helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // 分享图片
    static func shareImage(image: UIImage, from viewController: UIViewController) {
        print("准备分享图片，图片尺寸: \(image.size.width) x \(image.size.height)")
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        viewController.present(activityViewController, animated: true)
    }
    
    // 处理长内容，使用简单可靠的方法
    static func renderLongContent(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🚀 开始renderLongContent: 宽度=\(width), 预估高度=\(estimatedHeight)")
        logMemoryUsage(context: "渲染开始")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 使用更安全的分块渲染方法，不再区分长短内容
        print("📐 使用高安全性分段渲染方法...")
        let result = renderUsingSegmentMethod(view: view, width: width, estimatedHeight: estimatedHeight)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱️ 渲染耗时: \(String(format: "%.2f", timeElapsed))秒")
        logMemoryUsage(context: "渲染完成")
        
        return result
    }
    
    // 使用更安全的分段渲染方法 - 每次只渲染一小部分内容
    private static func renderUsingSegmentMethod(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🔄 使用分段渲染方法: 宽度=\(width), 总高度=\(estimatedHeight)")
        
        // 使用较小的段高度，确保每段都能可靠渲染
        let maxSegmentHeight: CGFloat = 800 // 更小的分段高度，增加稳定性
        
        // 计算需要的段数
        let segmentsCount = Int(ceil(estimatedHeight / maxSegmentHeight))
        print("🔢 需要渲染\(segmentsCount)个内容段")
        
        // 创建一个带有背景的最终画布
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: estimatedHeight), true, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: width, height: estimatedHeight)))
        
        // 成功标志
        var success = true
        
        // 一次性创建完整的根视图
        let rootView = ZStack {
            Color.white
            view
        }
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: width, height: estimatedHeight)
        
        // 将视图添加到临时窗口，确保它正确布局
        let window = UIApplication.shared.windows.first ?? UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: estimatedHeight))
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(hostingController.view)
        
        // 确保视图已经布局
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // 检查获取的图形上下文
        guard let context = UIGraphicsGetCurrentContext() else {
            print("❌ 无法获取图形上下文")
            return createEmptyImage(width: width, height: estimatedHeight)
        }
        
        // 对每个分段分别进行渲染
        for i in 0..<segmentsCount {
            let segmentY = CGFloat(i) * maxSegmentHeight
            let segmentHeight = min(maxSegmentHeight, estimatedHeight - segmentY)
            let segmentRect = CGRect(x: 0, y: segmentY, width: width, height: segmentHeight)
            
            print("🔍 渲染第\(i+1)/\(segmentsCount)段: y=\(segmentY), 高度=\(segmentHeight)")
            
            // 保存当前图形状态
            context.saveGState()
            
            // 裁剪到当前分段范围
            context.clip(to: segmentRect)
            
            // 设置适当的偏移，使视图在正确位置渲染
            context.translateBy(x: 0, y: -segmentY)
            
            // 渲染视图
            hostingController.view.layer.render(in: context)
            
            // 恢复图形状态
            context.restoreGState()
            
            print("✅ 第\(i+1)段渲染完成")
            
            // 每渲染几段后刷新上下文，减少内存压力
            if i % 3 == 2 {
                UIGraphicsGetCurrentContext()?.flush()
                logMemoryUsage(context: "渲染\(i+1)段后")
            }
        }
        
        // 获取最终图像
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = finalImage {
            print("🎉 分段渲染成功: \(image.size.width) x \(image.size.height)")
            return image
        } else {
            print("❌ 分段渲染失败，尝试备用方法")
            return renderUsingMultipleImages(view: view, width: width, estimatedHeight: estimatedHeight)
        }
    }
    
    // 使用多个小图片拼接的方法渲染长内容
    private static func renderUsingMultipleImages(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🧩 使用多图拼接渲染: 宽度=\(width), 总高度=\(estimatedHeight)")
        
        // 使用更小的段高度，确保每段都能可靠渲染
        let segmentHeight: CGFloat = 600
        
        // 使用更科学的方法计算段数和总高度
        // 向上取整以确保覆盖全部内容
        let segmentsCount = Int(ceil(estimatedHeight / segmentHeight))
        // 重新计算实际总高度，确保没有多余空白
        let actualTotalHeight = CGFloat(segmentsCount) * segmentHeight
        
        print("📊 将内容分为\(segmentsCount)个段进行独立渲染，实际总高度=\(actualTotalHeight)")
        
        // 创建一个数组来存储每个段的图像
        var segmentImages: [UIImage] = []
        
        // 创建一个固定尺寸的视图容器，用于准确裁切
        let fixedSizeContainer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: estimatedHeight))
        fixedSizeContainer.backgroundColor = .white
        
        // 创建主视图控制器
        let hostingController = UIHostingController(rootView: ZStack {
            Color.white
            view
        })
        hostingController.view.frame = CGRect(x: 0, y: 0, width: width, height: estimatedHeight)
        
        // 添加主视图到容器
        fixedSizeContainer.addSubview(hostingController.view)
        
        // 确保视图已完全布局
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // 渲染每个段
        for i in 0..<segmentsCount {
            // 计算当前段的起始位置和高度
            let startY = CGFloat(i) * segmentHeight
            // 确保最后一段不超出总高度
            let currentHeight = min(segmentHeight, estimatedHeight - startY)
            
            print("🔍 渲染段\(i+1)/\(segmentsCount): 起始位置y=\(startY), 高度=\(currentHeight)")
            
            // 使用简单直接的图像提取方法
            let segmentRenderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: currentHeight))
            let segmentImage = segmentRenderer.image { context in
                // 填充白色背景
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: currentHeight)))
                
                // 平移上下文以显示正确部分
                context.cgContext.translateBy(x: 0, y: -startY)
                
                // 剪裁到当前段
                context.cgContext.clip(to: CGRect(x: 0, y: startY, width: width, height: currentHeight))
                
                // 渲染整个视图，但只保留当前段
                hostingController.view.layer.render(in: context.cgContext)
            }
            
            segmentImages.append(segmentImage)
            print("✅ 段\(i+1)渲染完成: \(segmentImage.size.width) x \(segmentImage.size.height)")
        }
        
        // 创建最终图像画布
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: estimatedHeight), true, 0)
        
        // 填充白色背景
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: width, height: estimatedHeight)))
        
        // 准确放置每个段
        for i in 0..<segmentImages.count {
            let exactYPosition = CGFloat(i) * segmentHeight
            print("📌 放置段\(i+1)到位置y=\(exactYPosition)")
            
            // 在精确位置绘制图像段
            segmentImages[i].draw(at: CGPoint(x: 0, y: exactYPosition))
        }
        
        // 获取最终合成图像
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = finalImage {
            print("🎉 多图片拼接成功: \(image.size.width) x \(image.size.height)")
            return image
        } else {
            print("❌ 图片拼接失败，尝试备用方法")
            // 尝试使用单片段渲染
            return renderSinglePiece(view: view, width: width, estimatedHeight: estimatedHeight)
        }
    }
    
    // 单片段渲染方法 - 最终的备用方案
    private static func renderSinglePiece(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("⚠️ 使用单片段渲染方法")
        
        // 创建一个简单的视图
        let simpleView = ZStack {
            Color.white
            view
        }
        
        // 使用最基本的方法渲染
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: estimatedHeight))
        
        let image = renderer.image { ctx in
            // 填充白色背景
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: width, height: estimatedHeight)))
            
            // 创建主机控制器并设置视图
            let hostingController = UIHostingController(rootView: simpleView)
            hostingController.view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: estimatedHeight))
            
            // 确保视图已布局
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            
            // 如果内容超过2000像素，分段渲染
            if estimatedHeight > 2000 {
                // 分段渲染上半部分
                let topPart = min(1800, estimatedHeight * 0.6)
                ctx.cgContext.saveGState()
                ctx.cgContext.clip(to: CGRect(x: 0, y: 0, width: width, height: topPart))
                hostingController.view.layer.render(in: ctx.cgContext)
                ctx.cgContext.restoreGState()
                
                // 渲染下半部分
                if estimatedHeight > topPart {
                    ctx.cgContext.saveGState()
                    ctx.cgContext.clip(to: CGRect(x: 0, y: topPart, width: width, height: estimatedHeight - topPart))
                    ctx.cgContext.translateBy(x: 0, y: -topPart)
                    hostingController.view.layer.render(in: ctx.cgContext)
                    ctx.cgContext.restoreGState()
                }
            } else {
                // 直接渲染整个内容
                hostingController.view.layer.render(in: ctx.cgContext)
            }
        }
        
        return image
    }
    
    // 极度简化的渲染方法 - 最后的后备方案
    private static func renderSimplifiedVersion(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("⚠️ 使用极度简化方法")
        
        // 创建一个带有最小内容的视图
        let simplifiedView = ZStack {
            Color.white
            VStack(spacing: 20) {
                Text("报告内容过长")
                    .font(.system(size: 20, weight: .bold))
                Text("请尝试分享较短的报告")
                    .font(.system(size: 16))
                
                // 尽可能显示原视图的顶部内容
                view
                    .frame(width: width, height: min(estimatedHeight, 1200))
                    .clipped()
            }
            .padding()
        }
        
        // 使用标准渲染方法
        return render(view: simplifiedView, size: CGSize(width: width, height: min(estimatedHeight, 1600)))
    }
    
    // 创建空白图像的辅助方法
    private static func createEmptyImage(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // 使用UIKit绘制内容的可靠方法
    private static func renderUsingUIKit(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🎨 使用UIKit渲染方法: 宽度=\(width), 高度=\(estimatedHeight)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. 创建SwiftUI主机控制器
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .white
        
        // 2. 设置视图尺寸约束
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.widthAnchor.constraint(equalToConstant: width).isActive = true
        
        // 3. 添加到临时窗口以确保布局
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 10))
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(hostingController.view)
        window.makeKeyAndVisible()
        
        // 4. 强制SwiftUI视图完成布局
        hostingController.view.layoutIfNeeded()
        
        // 5. 确定实际尺寸
        var actualHeight = hostingController.sizeThatFits(in: CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)).height
        if actualHeight > estimatedHeight {
            print("⚠️ 实际内容高度(\(actualHeight))超过预估高度(\(estimatedHeight))，将使用预估高度")
            actualHeight = estimatedHeight
        }
        if actualHeight < 100 {
            print("⚠️ 计算出的高度(\(actualHeight))异常，使用安全值")
            actualHeight = max(estimatedHeight * 0.8, 800) // 使用预估高度的80%或最小800pt
        }
        
        print("📐 最终渲染尺寸: \(width) x \(actualHeight)")
        
        // 6. 更新约束以设置高度
        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: actualHeight)
        heightConstraint.isActive = true
        hostingController.view.layoutIfNeeded()
        
        // 7. 使用PDF渲染器绘制 (更可靠的方法)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: width, height: actualHeight))
        
        do {
            let data = try renderer.pdfData { context in
                context.beginPage()
                hostingController.view.layer.render(in: context.cgContext)
            }
            
            // 8. 从PDF转回UIImage
            guard let page = PDFDocument(data: data)?.page(at: 0) else {
                print("❌ PDF创建失败")
                return fallbackRendering(view: view, width: width, height: actualHeight)
            }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: pageRect.size))
                
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            print("✅ PDF渲染成功: \(image.size.width) x \(image.size.height)")
            return image
        } catch {
            print("❌ PDF渲染失败: \(error.localizedDescription)")
            return fallbackRendering(view: view, width: width, height: actualHeight)
        }
    }
    
    // 备用渲染方法作为最后的尝试
    private static func fallbackRendering(view: some View, width: CGFloat, height: CGFloat) -> UIImage? {
        print("🆘 使用备用图像渲染方法")
        
        // 使用传统UIGraphicsImageRenderer
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        return renderer.image { ctx in
            // 先填充白色背景
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)))
            
            // 绘制SwiftUI视图
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            hostingController.view.backgroundColor = .clear
            
            // 确保视图已布局
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            
            // 绘制到上下文 - 修复条件绑定错误
            let layer = hostingController.view.layer.presentation() ?? hostingController.view.layer
            layer.render(in: ctx.cgContext)
        }
    }
    
    // 添加更详细的日志记录功能
    private static func logMemoryUsage(context: String) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Float(info.resident_size) / 1048576.0
            print("🧠 内存使用情况【\(context)】: \(String(format: "%.2f", usedMB))MB")
        }
    }
}

// 辅助类，用于处理保存照片的回调
class SaveToPhotoAlbumHelper: NSObject {
    let completion: (Bool, Error?) -> Void
    
    init(completion: @escaping (Bool, Error?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("保存图片失败: \(error.localizedDescription)")
            completion(false, error)
        } else {
            print("图片已成功保存到相册")
            completion(true, nil)
        }
    }
}

// UIViewControllerRepresentable用于在SwiftUI中显示UIKit的活动视图控制器
struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// SwiftUI扩展，用于共享内容
extension View {
    func shareSheet(items: [Any], isPresented: Binding<Bool>) -> some View {
        return self.sheet(isPresented: isPresented) {
            ActivityViewControllerRepresentable(items: items)
        }
    }
} 