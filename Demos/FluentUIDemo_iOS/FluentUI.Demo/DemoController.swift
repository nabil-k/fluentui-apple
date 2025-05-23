//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import FluentUI
import UIKit

class DemoController: UIViewController {
    struct Constants {
        static let margin: CGFloat = 16
        static let horizontalSpacing: CGFloat = 40
        static let horizontalContainerItemSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 16
        static let rowTextWidth: CGFloat = 75
        static let stackViewSpacing: CGFloat = 10
    }

    class func createVerticalContainer() -> UIStackView {
        let container = UIStackView(frame: .zero)
        container.axis = .vertical
        container.layoutMargins = UIEdgeInsets(top: Constants.margin, left: Constants.margin, bottom: Constants.margin, right: Constants.margin)
        container.isLayoutMarginsRelativeArrangement = true
        container.spacing = Constants.verticalSpacing
        return container
    }

    class func createHorizontalContainer() -> UIStackView {
        let container = UIStackView(frame: .zero)
        container.axis = .horizontal
        container.distribution = .fillEqually
        container.spacing = Constants.horizontalContainerItemSpacing
        return container
    }

    let container: UIStackView = createVerticalContainer()
    let scrollingContainer = DemoControllerScrollView(frame: .zero)

    var allowsContentToScroll: Bool { return true }

    func createButton(title: String, action: Selector) -> Button {
        let button = Button()
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @discardableResult
    func addDescription(text: String, textAlignment: NSTextAlignment = .natural) -> Label {
        let description = Label()
        description.numberOfLines = 0
        description.text = text
        description.textAlignment = textAlignment
        description.numberOfLines = 0
        container.addArrangedSubview(description)
        return description
    }

    func addTitle(text: String) {
        let titleLabel = Label(textStyle: .body1Strong)
        titleLabel.text = text
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits.insert(.header)
        titleLabel.numberOfLines = 0
        container.addArrangedSubview(titleLabel)
    }

    func addRow(text: String = "", items: [UIView], textStyle: FluentTheme.TypographyToken = .body1Strong, textWidth: CGFloat = Constants.rowTextWidth, itemSpacing: CGFloat = Constants.horizontalSpacing, stretchItems: Bool = false, centerItems: Bool = false) {
        let itemsContainer = UIStackView()
        itemsContainer.axis = .vertical
        itemsContainer.alignment = stretchItems ? .fill : (centerItems ? .center : .leading)

        let itemRow = UIStackView()
        itemRow.axis = .horizontal
        itemRow.distribution = stretchItems ? .fillEqually : .fill
        itemRow.alignment = .center
        itemRow.spacing = itemSpacing

        if !text.isEmpty {
            let label = Label(textStyle: textStyle, colorStyle: .regular)
            label.text = text
            label.widthAnchor.constraint(equalToConstant: textWidth).isActive = true
            itemRow.addArrangedSubview(label)
        }

        items.forEach { itemRow.addArrangedSubview($0) }
        itemsContainer.addArrangedSubview(itemRow)
        itemRow.accessibilityElements = itemRow.arrangedSubviews
        container.addArrangedSubview(itemsContainer)
    }

    func showMessage(_ message: String, autoDismiss: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        present(alert, animated: true)

        if autoDismiss {
            let delay: TimeInterval = UIAccessibility.isVoiceOverRunning ? 3 : 1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.dismiss(animated: true)
            }
        } else {
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: completion)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
        }

    }

    func createLabelAndViewsRow(labelText: String, views: [UIView]) -> UIView {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.stackViewSpacing

        let label = Label()
        label.text = labelText
        stackView.addArrangedSubview(label)

        for view in views {
            stackView.addArrangedSubview(view)
        }

        return stackView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = view.fluentTheme.color(.background1)

        if allowsContentToScroll {
            view.addSubview(scrollingContainer)
            scrollingContainer.translatesAutoresizingMaskIntoConstraints = true
            scrollingContainer.frame = view.bounds
            scrollingContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.translatesAutoresizingMaskIntoConstraints = false
            scrollingContainer.addSubview(container)
            // UIScrollView in RTL mode still have leading on the left side, so we cannot rely on leading/trailing-based constraints
            NSLayoutConstraint.activate([container.topAnchor.constraint(equalTo: scrollingContainer.topAnchor),
                                         container.bottomAnchor.constraint(equalTo: scrollingContainer.bottomAnchor),
                                         container.leftAnchor.constraint(equalTo: scrollingContainer.leftAnchor),
                                         container.widthAnchor.constraint(equalTo: scrollingContainer.widthAnchor)])
        } else {
            view.addSubview(container)
            container.frame = view.bounds
            container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        // Child scroll views interfere with largeTitleDisplayMode, so let's
        // disable it for all DemoController subclasses.
        self.navigationItem.largeTitleDisplayMode = .never

        configureBarButtonItems()
    }

    // MARK: - Demo Appearance Popover

    func configureBarButtonItems() {
        let settingsButton = UIBarButtonItem(customView: appearanceControlView)
        let readmeButton = UIBarButtonItem(image: UIImage(systemName: "info.circle.fill"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(showReadmePopover(_:)))
        navigationItem.rightBarButtonItems = [readmeButton, settingsButton]
    }

    @objc func showReadmePopover(_ sender: UIBarButtonItem) {
        readmeViewController.popoverPresentationController?.barButtonItem = sender
        readmeViewController.popoverPresentationController?.delegate = self
        self.present(readmeViewController, animated: true, completion: nil)
    }

    var readmeString: String?

    lazy var appearanceControlView: DemoAppearanceControlView = .init(delegate: self as? DemoAppearanceDelegate)
    lazy var readmeViewController: ReadmeViewController = .init(readmeString: readmeString)
}

extension DemoController: UIPopoverPresentationControllerDelegate {
    /// Overridden to allow for popover-style modal presentation on compact (e.g. iPhone) devices.
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
