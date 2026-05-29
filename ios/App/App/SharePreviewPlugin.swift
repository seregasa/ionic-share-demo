import Foundation
import Capacitor
import UIKit
import LinkPresentation

class MetadataItemSource: NSObject, UIActivityItemSource {
    let metadata: LPLinkMetadata
    let content: Any

    init(metadata: LPLinkMetadata, content: Any) {
        self.metadata = metadata
        self.content = content
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return content
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                 itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return content
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return metadata
    }
}

@objc(SharePreviewPlugin)
public class SharePreviewPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SharePreviewPlugin"
    public let jsName = "SharePreview"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "share", returnType: CAPPluginReturnPromise)
    ]

    private var shareIcon: UIImage?

    override public func load() {
        DispatchQueue.main.async {
            if let raw = UIImage(named: "ShareIcon") {
                self.shareIcon = self.applySquircleMask(to: raw)
            }
        }
    }

    private func applySquircleMask(to image: UIImage, size: CGFloat = 120) -> UIImage? {
        let targetSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: targetSize)
            let layer = CALayer()
            layer.frame = rect
            layer.contents = image.cgImage
            layer.contentsGravity = .resizeAspectFill
            layer.masksToBounds = true
            layer.cornerRadius = size * 0.225
            layer.cornerCurve = .continuous
            layer.render(in: UIGraphicsGetCurrentContext()!)
        }
    }

    @objc func share(_ call: CAPPluginCall) {
        let title = call.getString("title") ?? ""
        let text  = call.getString("text")
        let urlString = call.getString("url")

        guard urlString != nil || text != nil else {
            call.reject("Provide either 'url' or 'text'")
            return
        }

        DispatchQueue.main.async {
            let content: Any
            let metadata = LPLinkMetadata()
            metadata.title = title

            if let urlString = urlString {
                content = urlString
                // Setting .url makes iOS render the domain as the gray subtitle line.
                if let url = URL(string: urlString) {
                    metadata.url = url
                    metadata.originalURL = url
                }
            } else if let text = text {
                content = text
            } else {
                return
            }

            if let icon = self.shareIcon {
                metadata.iconProvider = NSItemProvider(object: icon)
            }

            let itemSource = MetadataItemSource(metadata: metadata, content: content)
            let activityVC = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.bridge?.viewController?.view
                popover.sourceRect = CGRect(
                    x: UIScreen.main.bounds.midX,
                    y: UIScreen.main.bounds.midY,
                    width: 0, height: 0
                )
                popover.permittedArrowDirections = []
            }

            self.bridge?.viewController?.present(activityVC, animated: true) {
                call.resolve()
            }
        }
    }
}
