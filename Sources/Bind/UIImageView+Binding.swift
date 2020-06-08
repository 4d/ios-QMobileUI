//
//  UIImageView+Binding.swift
//  QMobileUI
//
//  Created by Eric Marchand on 03/04/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import UIKit

extension UIImageView {

   @objc dynamic public var imageNamed: String? {
        get {
            return self.image?.accessibilityIdentifier
        }
        set {
            guard let name = newValue else {
                self.image = nil
                return
            }
            self.image = UIImage(named: name)
            self.image?.accessibilityIdentifier = name
        }
    }

    /*@objc dynamic public var localizedText: String? {
        get {
            guard let localized = self.text else {
                return nil
            }
            return localized // Cannot undo it...
        }
        set {
            guard let string = newValue else {
                self.text = nil
                return
            }
            self.text = string.localizedBinding
        }
    }*/

}

// MARK: using URL and cache
import Kingfisher
import QMobileAPI
import QMobileDataSync

extension UIImageView {

    public var webURL: URL? {
        get {
            return nil
        }
        set {
            if newValue != nil {
                self.kf.indicatorType = .activity
            }
            self.kf.setImage(with: newValue, placeholder: nil, options: nil)
        }
    }

}

extension UIImageView {

    public typealias ImageCompletionHandler = ((Result<RetrieveImageResult, KingfisherError>) -> Void)

    // Remove image
    fileprivate func unsetImage() {
        self.kf.indicatorType = .none
        self.image = nil
    }

    @objc dynamic public var restImage: [String: Any]? {
        get {
            guard let webURL =  self.webURL else {
                return nil
            }
            var uri = webURL.absoluteString
            uri = uri.replacingOccurrences(of: DataSync.instance.apiManager.base.baseURL.absoluteString, with: "") // remove the base url
            let deffered = Deferred(uri: uri, image: true)
            return deffered.dictionary
        }
        set {
            // Check if passed value is a compatible restImage dictionary
            guard let imageResource = ApplicationImageCache.imageResource(for: newValue) else {
                unsetImage()
                return
            }
            logger.verbose("Setting \(imageResource) to view \(self)")

            // Setup placeHolder image or other options defined by custom builders
            var options = ApplicationImageCache.options()
            var placeHolderImage: UIImage?
            var indicatorType: IndicatorType = .activity
            if let builder = self as? ImageCacheOptionsBuilder {
                options = builder.option(for: imageResource.downloadURL, currentOptions: options)
                placeHolderImage = builder.placeHolderImage
                indicatorType = builder.indicatorType ?? .activity
            }

            // Check cache, bundle
            ApplicationImageCache.checkCached(imageResource)

            // Do the request
            let completionHandler: ImageCompletionHandler = { result in
                switch result {
                case .success:
                    #if DEBUG
                    assert(ApplicationImageCache.isCached(imageResource)) // if failed maybe preprocessor
                    #endif
                    //self.setNeedsDisplay() // force refresh ??
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped))
                    self.addGestureRecognizer(tap)
                    self.isUserInteractionEnabled = true
                case .failure(let error):
                    ApplicationImageCache.log(error: error, for: imageResource.downloadURL)
                    _ = self.kf.setImage(with: imageResource.bundleProvider,
                                         placeholder: placeHolderImage,
                                         options: options,
                                         progressBlock: nil,
                                         completionHandler: nil)
                }
            }
            self.kf.cancelDownloadTask()
            self.kf.indicatorType = indicatorType
            _ = self.kf.setImage(
                with: imageResource,
                placeholder: placeHolderImage,
                options: options,
                progressBlock: nil,
                completionHandler: completionHandler)
        }
    }

    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else {
            return
        }
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        newImageView.addGestureRecognizer(tap)
        self.owningViewController?.view.addSubview(newImageView)

        /*let pinchZoomHandler = PinchZoomHandler(usingSourceImageView: newImageView) // TODO memory retain*/
        self.owningViewController?.navigationController?.isNavigationBarHidden = true
        self.owningViewController?.tabBarController?.tabBar.isHidden = true
    }

    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.owningViewController?.navigationController?.isNavigationBarHidden = false
        self.owningViewController?.tabBarController?.tabBar.isHidden = false
        sender.view?.removeFromSuperview()
    }

    @objc dynamic public var imageData: Data? {
        get {
            guard let image = self.image else {
                return nil
            }
            return image.pngData()
        }
        set {
            if let data = newValue {
                self.image = UIImage(data: data)
            } else {
                self.image = nil
            }
        }
     }

}

public protocol ZoomingDelegate: class {
    func pinchZoomHandlerStartPinching()
    func pinchZoomHandlerEndPinching()
}

private struct PinchZoomHandlerConstants {
    fileprivate static let kMinZoomScaleDefaultValue: CGFloat = 1.0
    fileprivate static let kMaxZoomScaleDefaultValue: CGFloat = 3.0
    fileprivate static let kResetAnimationDurationDefaultValue = 0.3
    fileprivate static let kIsZoomingActiveDefaultValue: Bool = false
}
/*
private class PinchZoomHandler {

    // Configurable
    var minZoomScale: CGFloat = PinchZoomHandlerConstants.kMinZoomScaleDefaultValue
    var maxZoomScale: CGFloat = PinchZoomHandlerConstants.kMaxZoomScaleDefaultValue
    var resetAnimationDuration = PinchZoomHandlerConstants.kResetAnimationDurationDefaultValue
    var isZoomingActive: Bool = PinchZoomHandlerConstants.kIsZoomingActiveDefaultValue
    weak var delegate: ZoomingDelegate?
    weak var sourceImageView: UIImageView?

    private var zoomImageView: UIImageView = UIImageView()
    private var initialRect: CGRect = CGRect.zero
    private var zoomImageLastPosition: CGPoint = CGPoint.zero
    private var lastTouchPoint: CGPoint = CGPoint.zero
    private var lastNumberOfTouch: Int?

    // MARK: Initialization

    init(usingSourceImageView sourceImageView: UIImageView) {
        self.sourceImageView = sourceImageView

        setupPinchGesture(on: sourceImageView)
    }

    // MARK: Private Methods

    private func setupPinchGesture(on pinchContainer: UIView) {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(pinch:)))
        pinchGesture.cancelsTouchesInView = false
        pinchContainer.isUserInteractionEnabled = true
        pinchContainer.addGestureRecognizer(pinchGesture)
    }

    @objc private func handlePinchGesture(pinch: UIPinchGestureRecognizer) {

        guard let pinchableImageView = sourceImageView else { return }
        handlePinchMovement(pinchGesture: pinch, sourceImageView: pinchableImageView)
    }

    private func handlePinchMovement(pinchGesture: UIPinchGestureRecognizer, sourceImageView: UIImageView) {

        switch pinchGesture.state {
        case .began:

            guard !isZoomingActive, pinchGesture.scale >= minZoomScale else { return }

            guard let point = sourceImageView.superview?.convert(sourceImageView.frame.origin, to: nil) else { return }
            initialRect = CGRect(x: point.x, y: point.y, width: sourceImageView.frame.size.width, height: sourceImageView.frame.size.height)

            lastTouchPoint = pinchGesture.location(in: sourceImageView)

            zoomImageView = UIImageView(image: sourceImageView.image)
            zoomImageView.contentMode = sourceImageView.contentMode
            zoomImageView.frame = initialRect

            let anchorPoint = CGPoint(x: lastTouchPoint.x/initialRect.size.width, y: lastTouchPoint.y/initialRect.size.height)
            zoomImageView.layer.anchorPoint = anchorPoint
            zoomImageView.center = lastTouchPoint
            zoomImageView.frame = initialRect

            sourceImageView.alpha = 0.0
            UIApplication.shared.keyWindow?.addSubview(zoomImageView)

            zoomImageLastPosition = zoomImageView.center

            self.delegate?.pinchZoomHandlerStartPinching()

            isZoomingActive = true
            lastNumberOfTouch = pinchGesture.numberOfTouches

        case .changed:
            let isNumberOfTouchChanged = pinchGesture.numberOfTouches != lastNumberOfTouch

            if isNumberOfTouchChanged {
                let newTouchPoint = pinchGesture.location(in: sourceImageView)
                lastTouchPoint = newTouchPoint
            }

            let scale = zoomImageView.frame.size.width / initialRect.size.width
            let newScale = scale * pinchGesture.scale

            if scale.isNaN || scale == CGFloat.infinity || CGFloat.nan == initialRect.size.width {
                return
            }

            zoomImageView.frame = CGRect(x: zoomImageView.frame.origin.x,
                                         y: zoomImageView.frame.origin.y,
                                         width: min(max(initialRect.size.width * newScale, initialRect.size.width * minZoomScale), initialRect.size.width * maxZoomScale),
                                         height: min(max(initialRect.size.height * newScale, initialRect.size.height * minZoomScale), initialRect.size.height * maxZoomScale))

            let centerXDif = lastTouchPoint.x - pinchGesture.location(in: sourceImageView).x
            let centerYDif = lastTouchPoint.y - pinchGesture.location(in: sourceImageView).y

            zoomImageView.center = CGPoint(x: zoomImageLastPosition.x - centerXDif, y: zoomImageLastPosition.y - centerYDif)
            pinchGesture.scale = 1.0

            // Store last values
            lastNumberOfTouch = pinchGesture.numberOfTouches
            zoomImageLastPosition = zoomImageView.center
            lastTouchPoint = pinchGesture.location(in: sourceImageView)

        case .ended, .cancelled, .failed:
            resetZoom()
        default:
            break
        }
    }

    private func resetZoom() {
        UIView.animate(withDuration: resetAnimationDuration, animations: {
            self.zoomImageView.frame = self.initialRect
        }) { _ in
            self.zoomImageView.removeFromSuperview()
            self.sourceImageView?.alpha = 1.0
            self.initialRect = .zero
            self.lastTouchPoint = .zero
            self.isZoomingActive = false
            self.delegate?.pinchZoomHandlerEndPinching()
        }
    }
}
*/
