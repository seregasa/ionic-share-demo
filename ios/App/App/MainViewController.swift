import UIKit
import Capacitor

// NOTE: Class is named MainViewController, NOT "ViewController".
// The generic name "ViewController" collides at runtime class resolution
// and causes a black screen (the storyboard resolves the wrong class).
class MainViewController: CAPBridgeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Show white (not black) during the WebKit cold-start before the page paints.
        view.backgroundColor = .white
        webView?.backgroundColor = .white
        webView?.scrollView.backgroundColor = .white
    }

    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(SharePreviewPlugin())
    }
}
