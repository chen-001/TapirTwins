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
        // 选择更可靠的渲染方法 - 降低高度阈值到2000，确保更稳定的渲染
        if estimatedHeight > 2000 {
            print("⚠️ 内容较高(\(estimatedHeight)pt)，使用分段渲染方法...")
            let result = renderUsingTilingMethod(view: view, width: width, estimatedHeight: estimatedHeight)
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("⏱️ 渲染耗时: \(String(format: "%.2f", timeElapsed))秒")
            logMemoryUsage(context: "渲染完成")
            
            return result
        } else {
            print("📏 内容长度适中，使用标准渲染...")
            let result = renderWithBackground(view: view, size: CGSize(width: width, height: estimatedHeight))
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("⏱️ 渲染耗时: \(String(format: "%.2f", timeElapsed))秒")
            logMemoryUsage(context: "渲染完成")
            
            return result
        }
    }
    
    // 使用平铺方法渲染长内容 - 将长内容分成多个部分渲染，然后合并
    private static func renderUsingTilingMethod(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🧩 使用平铺渲染方法: 宽度=\(width), 总高度=\(estimatedHeight)")
        
        // 设置安全的单块高度限制
        let maxTileHeight: CGFloat = 1600 // 比可靠值稍小，确保安全
        
        // 移除条件判断，始终使用分段渲染以保证完整内容
        print("📐 内容长度为\(estimatedHeight)，使用分段平铺渲染")
        
        // 计算需要的平铺块数
        let tilesCount = Int(ceil(estimatedHeight / maxTileHeight))
        print("🔢 需要渲染\(tilesCount)个内容块")
        
        // 准备画布，预先分配足够的内存
        let finalSize = CGSize(width: width, height: estimatedHeight)
        UIGraphicsBeginImageContextWithOptions(finalSize, true, 0)
        
        // 填充白色背景
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: finalSize))
        
        // 主机控制器设置
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .white
        
        // 添加到窗口以确保正确布局
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 10))
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(hostingController.view)
        window.makeKeyAndVisible()
        
        // 设置主视图尺寸
        hostingController.view.frame = CGRect(x: 0, y: 0, width: width, height: estimatedHeight)
        hostingController.view.layoutIfNeeded()
        
        var success = false
        
        // 尝试使用位图上下文分段渲染
        if let context = UIGraphicsGetCurrentContext() {
            // 遍历渲染每个分段
            for i in 0..<tilesCount {
                let tileY = CGFloat(i) * maxTileHeight
                let tileHeight = min(maxTileHeight, estimatedHeight - tileY)
                let tileRect = CGRect(x: 0, y: tileY, width: width, height: tileHeight)
                
                print("🔍 渲染第\(i+1)/\(tilesCount)块: y=\(tileY), 高度=\(tileHeight)")
                
                // 保存上下文状态
                context.saveGState()
                
                // 裁剪到当前分段
                context.clip(to: tileRect)
                
                // 偏移以适应当前分段
                context.translateBy(x: 0, y: -tileY)
                
                // 渲染视图的这一部分
                hostingController.view.layer.render(in: context)
                
                // 恢复上下文状态
                context.restoreGState()
                
                print("✅ 第\(i+1)块渲染完成")
            }
            success = true
        }
        
        // 获取合并后的图像
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if success && finalImage != nil {
            print("🎉 分段渲染成功: \(finalImage?.size.width ?? 0) x \(finalImage?.size.height ?? 0)")
            return finalImage
        } else {
            print("❌ 分段渲染失败，尝试备用方法...")
            return fallbackForLongContent(view: view, width: width, estimatedHeight: estimatedHeight)
        }
    }
    
    // 超长内容的最后备用渲染方法
    private static func fallbackForLongContent(view: some View, width: CGFloat, estimatedHeight: CGFloat) -> UIImage? {
        print("🆘 使用超长内容备用渲染方法，保持完整高度\(estimatedHeight)")
        
        // 不再限制高度，使用完整估计高度
        let renderHeight = estimatedHeight
        
        // 创建一个滚动视图来容纳内容
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: width, height: renderHeight))
        scrollView.contentSize = CGSize(width: width, height: renderHeight)
        scrollView.backgroundColor = .white
        
        // 创建一个SwiftUI主机控制器
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: width, height: renderHeight)
        hostingController.view.backgroundColor = .white
        
        // 将SwiftUI视图添加到滚动视图
        scrollView.addSubview(hostingController.view)
        
        // 确保布局完成
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // 创建分段渲染的图像
        let maxSegmentHeight: CGFloat = 1200
        let segmentsCount = Int(ceil(renderHeight / maxSegmentHeight))
        
        print("📏 分割为\(segmentsCount)个段进行备用渲染")
        
        // 创建一个大型画布
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: renderHeight), true, 0)
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: width, height: renderHeight))
        
        for i in 0..<segmentsCount {
            let segmentY = CGFloat(i) * maxSegmentHeight
            let segmentHeight = min(maxSegmentHeight, renderHeight - segmentY)
            
            print("📍 备用渲染段\(i+1)/\(segmentsCount): y=\(segmentY), 高度=\(segmentHeight)")
            
            // 设置滚动视图的内容偏移
            scrollView.contentOffset = CGPoint(x: 0, y: segmentY)
            
            // 渲染当前可见部分
            if let context = UIGraphicsGetCurrentContext() {
                context.saveGState()
                context.translateBy(x: 0, y: segmentY)
                scrollView.layer.render(in: context)
                context.restoreGState()
            }
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = finalImage {
            print("✅ 备用渲染成功: \(image.size.width) x \(image.size.height)")
            return image
        } else {
            print("❌ 所有渲染方法都失败，返回空白图像")
            return createEmptyImage(width: width, height: 300) // 创建一个小的空白图像作为最后手段
        }
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