import UIKit

extension UIAlertController {

    func addImagePicker(flow: UICollectionView.ScrollDirection, paging: Bool, images: [UIImage], selection: ImagePickerViewController.SelectionType? = nil) {
        let viewController = ImagePickerViewController(flow: flow, paging: paging, images: images, selection: selection)

        if UIDevice.current.userInterfaceIdiom == .pad {
            viewController.preferredContentSize.height = viewController.preferredSize.height * 0.9
            viewController.preferredContentSize.width = viewController.preferredSize.width * 0.9
        } else {
            viewController.preferredContentSize.height = viewController.preferredSize.height
        }

        set(viewController: viewController)
    }
}

// MARK: controller

final class ImagePickerViewController: UIViewController {

    public typealias SingleSelection = (UIImage?) -> Swift.Void
    public typealias MultipleSelection = ([UIImage]) -> Swift.Void

    public enum SelectionType {
        case single(action: SingleSelection?)
        case multiple(action: MultipleSelection?)
    }

    var preferredSize: CGSize {
        return UIScreen.main.bounds.size
    }

    var columns: CGFloat {
        switch layout.scrollDirection {
        case .vertical: return UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        case .horizontal: return 1
        @unknown default:
            fatalError("unknown scroll direction \(layout.scrollDirection)")
        }
    }

    var itemSize: CGSize {
        switch layout.scrollDirection {
        case .vertical:
            return CGSize(width: view.bounds.width / columns, height: view.bounds.width / columns)
        case .horizontal:
            return CGSize(width: view.bounds.width, height: view.bounds.height / columns)
        @unknown default:
            fatalError("unknown scroll direction \(layout.scrollDirection)")
        }
    }

    // MARK: Properties

    fileprivate lazy var collectionView: UICollectionView = { [unowned self] in
        $0.dataSource = self
        $0.delegate = self
        $0.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.decelerationRate = UIScrollView.DecelerationRate.fast
        $0.contentInsetAdjustmentBehavior = .never
        $0.bounces = false
        $0.backgroundColor = .clear
        $0.layer.masksToBounds = false
        $0.clipsToBounds = false
        return $0
    }(UICollectionView(frame: .zero, collectionViewLayout: layout))

    fileprivate lazy var layout: UICollectionViewFlowLayout = {
        $0.minimumInteritemSpacing = 0
        $0.minimumLineSpacing = 0
        $0.sectionInset = .zero
        return $0
    }(UICollectionViewFlowLayout())

    fileprivate var selection: SelectionType?
    fileprivate var images: [UIImage] = []
    fileprivate var selectedImages: [UIImage] = []

    // MARK: Initialize

    required init(flow: UICollectionView.ScrollDirection, paging: Bool, images: [UIImage], selection: SelectionType?) {
        super.init(nibName: nil, bundle: nil)
        self.images = images
        self.selection = selection
        self.layout.scrollDirection = flow

        collectionView.isPagingEnabled = paging

        switch selection {
        case .single?: collectionView.allowsSelection = true
        case .multiple?: collectionView.allowsMultipleSelection = true
        case .none: break }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("has deinitialized")
    }

    override func loadView() {
        view = collectionView
    }
}

// MARK: - CollectionViewDelegate

extension ImagePickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = images[indexPath.item]
        switch selection {

        case .single(let action)?:
            action?(images[indexPath.row])

        case .multiple(let action)?:
            selectedImages.contains(image)
                ? selectedImages.removeAll(where: { return $0 == image})
                : selectedImages.append(image)
            action?(selectedImages)

        case .none: break }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let image = images[indexPath.item]
        switch selection {
        case .multiple(let action)?:
            selectedImages.contains(image)
                ? selectedImages.removeAll(where: { return $0 == image})
                : selectedImages.append(image)
            action?(selectedImages)
        default: break }
    }
}

// MARK: - CollectionViewDataSource

extension ImagePickerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else { return UICollectionViewCell() }
        item.imageView.image = images[indexPath.row]
        return item
    }
}

// MARK: - CollectionViewDelegateFlowLayout

extension ImagePickerViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        logger.debug("view size = \(view.bounds), collectionView = \(collectionView.frame.size), itemSize = \(itemSize)")
        return itemSize
    }
}

class ImageCollectionViewCell: UICollectionViewCell {

    static let identifier = String(describing: ImageCollectionViewCell.self)

    lazy var imageView: UIImageView = {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFill
        $0.layer.masksToBounds = true
        return $0
    }(UIImageView())

    lazy var unselectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.masksToBounds = false
        return $0
    }(UIView())

    lazy var selectedCircle: UIView = {
        $0.backgroundColor = .clear
        $0.layer.borderWidth = 2
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.masksToBounds = false
        return $0
    }(UIView())

    lazy var selectedPoint: UIView = {
        $0.layer.backgroundColor = UIColor(hex: 0x007AFF).cgColor
        return $0
    }(UIView())

    fileprivate let inset: CGFloat = 8

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    fileprivate func setup() {
        backgroundColor = .clear

        let unselected: UIView = UIView()
        unselected.addSubview(imageView)
        unselected.addSubview(unselectedCircle)
        backgroundView = unselected

        let selected: UIView = UIView()
        selected.addSubview(selectedCircle)
        selected.addSubview(selectedPoint)
        selectedBackgroundView = selected
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }

    func layout() {
        imageView.frame = contentView.frame
        updateAppearance(forCircle: unselectedCircle)
        updateAppearance(forCircle: selectedCircle)
        updateAppearance(forPoint: selectedPoint)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.frame.size = size
        layout()
        return size
    }

    func updateAppearance(forCircle view: UIView) {
        view.frame.size = CGSize(width: 28, height: 28)
        view.frame.origin.x = imageView.bounds.width - unselectedCircle.bounds.width - inset
        view.frame.origin.y = inset
        view.circleCorner = true
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.2
        view.layer.shadowPath = UIBezierPath(roundedRect: unselectedCircle.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: unselectedCircle.bounds.width / 2, height: unselectedCircle.bounds.width / 2)).cgPath
        view.layer.shouldRasterize = true
        view.layer.rasterizationScale = UIScreen.main.scale
    }

    func updateAppearance(forPoint view: UIView) {
        view.frame.size = CGSize(width: unselectedCircle.frame.width - unselectedCircle.layer.borderWidth * 2, height: unselectedCircle.frame.height - unselectedCircle.layer.borderWidth * 2)
        view.center = selectedCircle.center
        view.circleCorner = true
    }
}

extension UIView {

    var circleCorner: Bool {
        get {
            return min(bounds.size.height, bounds.size.width) / 2 == layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue ? min(bounds.size.height, bounds.size.width) / 2 : layer.cornerRadius
        }
    }

}
