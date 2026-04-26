import UIKit
import HImageViewer

/// Demonstrates using HImageViewerLauncher from a UIKit view controller.
final class UIKitExampleViewController: UIViewController {

    private var items: [MediaAsset] = MediaAsset.from(uiImages: [
        UIImage(systemName: "photo")!,
        UIImage(systemName: "star")!,
        UIImage(systemName: "heart")!,
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "UIKit Launcher"
        setupButtons()
    }

    private func setupButtons() {
        let presentButton = UIButton(configuration: .filled())
        presentButton.setTitle("Present (Modal)", for: .normal)
        presentButton.addTarget(self, action: #selector(presentTapped), for: .touchUpInside)

        let pushButton = UIButton(configuration: .filled())
        pushButton.setTitle("Push (Navigation)", for: .normal)
        pushButton.addTarget(self, action: #selector(pushTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [presentButton, pushButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalToConstant: 220)
        ])
    }

    @objc private func presentTapped() {
        HImageViewerLauncher.present(from: self, mediaAssets: items) { [weak self] updated in
            self?.items = updated
        }
    }

    @objc private func pushTapped() {
        HImageViewerLauncher.push(from: self, mediaAssets: items) { [weak self] updated in
            self?.items = updated
        }
    }
}
