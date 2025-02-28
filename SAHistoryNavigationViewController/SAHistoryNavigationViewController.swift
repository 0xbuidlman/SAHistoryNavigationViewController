//
//  SAHistoryNavigationViewController.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/03/26.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit

extension UINavigationController {
    public weak var navigationDelegate: SAHistoryNavigationViewControllerDelegate? {
        set {
            willSetNavigationDelegate(newValue)
        }
        get {
            return willGetNavigationDelegate()
        }
    }
    public weak var navigationTransitioningDelegate: SAHistoryNavigationViewControllerTransitioningDelegate? {
        set {
            willSetNavigationTransitioningDelegate(newValue)
        }
        get {
            return willGetNavigationTransitioningDelegate()
        }
    }
    public var interactivePopGestureEnabled: Bool {
        set {
            willSetInteractivePopGestureEnabled(newValue)
        }
        get {
            return willGetInteractivePopGestureEnabled()
        }
    }
    public func showHistory() {}
    public func setHistoryBackgroundColor(color: UIColor) {}
    public func contentView() -> UIView? { return nil }
    func willSetNavigationDelegate(navigationDelegate: SAHistoryNavigationViewControllerDelegate?) {}
    func willGetNavigationDelegate() -> SAHistoryNavigationViewControllerDelegate? { return nil }
    func willSetNavigationTransitioningDelegate(navigationTransitioningDelegate: SAHistoryNavigationViewControllerTransitioningDelegate?) {}
    func willGetNavigationTransitioningDelegate() -> SAHistoryNavigationViewControllerTransitioningDelegate? { return nil }
    func willSetInteractivePopGestureEnabled(interactivePopGestureEnabled: Bool) {}
    func willGetInteractivePopGestureEnabled() -> Bool { return true }
}

extension UIView {
    func screenshotImage(scale: CGFloat = 0.0) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        drawViewHierarchyInRect(bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIViewController {
    func screenshotFromWindow(scale: CGFloat = 0.0) -> UIImage? {
        guard let window = UIApplication.sharedApplication().windows.first else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, scale)
        window.drawViewHierarchyInRect(window.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

@objc public protocol SAHistoryNavigationViewControllerDelegate : NSObjectProtocol {
    
    optional func navigationController(navigationController: SAHistoryNavigationViewController, willShowViewController viewController: UIViewController, animated: Bool)
    optional func navigationController(navigationController: SAHistoryNavigationViewController, didShowViewController viewController: UIViewController, animated: Bool)
    
    optional func navigationControllerSupportedInterfaceOrientations(navigationController: SAHistoryNavigationViewController) -> UIInterfaceOrientationMask
    
    optional func navigationControllerPreferredInterfaceOrientationForPresentation(navigationController: SAHistoryNavigationViewController) -> UIInterfaceOrientation
    
    optional func navigationController(navigationController: SAHistoryNavigationViewController, willHandleEdgeSwipe gesture: UIScreenEdgePanGestureRecognizer)
    optional func navigationController(navigationController: SAHistoryNavigationViewController, didHandleEdgeSwipe gesture: UIScreenEdgePanGestureRecognizer)
}

@objc public protocol SAHistoryNavigationViewControllerTransitioningDelegate : NSObjectProtocol {
    
    optional func navigationController(navigationController: SAHistoryNavigationViewController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    
    optional func navigationController(navigationController: SAHistoryNavigationViewController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
}

public class SAHistoryNavigationViewController: UINavigationController {
    
    private static let kImageScale: CGFloat = 1.0
    
    var historyViewController = SAHistoryViewController()
    
    public var historyContentView = UIView()
    
    private var coverView = UIView()
    private var screenshotImages = [UIImage]()
    
    private let defaultInteractiveTransition = UIPercentDrivenInteractiveTransition()
    private var edgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var animationController: UIViewControllerAnimatedTransitioning?
    private var edgeSwiping = false
    
    private weak var _navigationDelegate: SAHistoryNavigationViewControllerDelegate?
    private weak var _navigationTransitioningDelegate: SAHistoryNavigationViewControllerTransitioningDelegate?
    private var _interactivePopGestureEnabled = true

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override public init(navigationBarClass: AnyClass!, toolbarClass: AnyClass!) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        coverView.backgroundColor = .grayColor()
        coverView.hidden = true
        NSLayoutConstraint.applyAutoLayout(view, target: coverView, index: nil, top: 0.0, left: 0.0, right: 0.0, bottom: 0.0, height: nil, width: nil)
        
        historyContentView.backgroundColor = .clearColor()
        historyContentView.hidden = true
        NSLayoutConstraint.applyAutoLayout(view, target: historyContentView, index: nil, top: 0.0, left: 0.0, right: 0.0, bottom: 0.0, height: nil, width: nil)
        
        historyViewController.delegate = self
        historyViewController.view.alpha = 0.0
        let width = UIScreen.mainScreen().bounds.size.width
        NSLayoutConstraint.applyAutoLayout(view, target: historyViewController.view, index: nil, top: 0.0, left: Float(-width), right: Float(-width), bottom: 0.0, height: nil, width: Float(width * 3))
        
        let  longPressGesture = UILongPressGestureRecognizer(target: self, action: "detectLongTap:")
        longPressGesture.delegate = self
        navigationBar.addGestureRecognizer(longPressGesture)
        
        let edgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleEdgeSwipe:")
        edgePanGestureRecognizer.edges = .Left
        view.addGestureRecognizer(edgePanGestureRecognizer)
        interactivePopGestureRecognizer?.requireGestureRecognizerToFail(edgePanGestureRecognizer)
        self.edgePanGestureRecognizer = edgePanGestureRecognizer
        
        delegate = self
    }
    
    override public func pushViewController(viewController: UIViewController, animated: Bool) {
        if let image = visibleViewController?.screenshotFromWindow(SAHistoryNavigationViewController.kImageScale) {
            screenshotImages += [image]
        }
        
        super.pushViewController(viewController, animated: animated)
    }
    
    override public func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        if !edgeSwiping {
            screenshotImages.removeLast()
        }
        return super.popViewControllerAnimated(animated)
    }
    
    public override func popToRootViewControllerAnimated(animated: Bool) -> [UIViewController]? {
        screenshotImages.removeAll(keepCapacity: false)
        return super.popToRootViewControllerAnimated(animated)
    }
    
    public override func popToViewController(viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        var index: Int?
        for (currentIndex, currentViewController) in viewControllers.enumerate() {
            if currentViewController == viewController {
                index = currentIndex
                break
            }
        }
        
        var removeList = [Bool]()
        for (currentIndex, _) in screenshotImages.enumerate() {
            if currentIndex >= index {
                removeList += [true]
            } else {
                removeList += [false]
            }
        }
        for shouldRemove in removeList {
            if shouldRemove {
                if let index = index {
                    screenshotImages.removeAtIndex(index)
                }
            }
        }
        return super.popToViewController(viewController, animated: animated)
    }
    
    public override func setViewControllers(viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        for (currentIndex, viewController) in viewControllers.enumerate() {
            if currentIndex == viewControllers.endIndex {
                break
            }
            if let image = viewController.screenshotFromWindow(SAHistoryNavigationViewController.kImageScale) {
                screenshotImages += [image]
            }
        }
    }
    
    override func willSetNavigationDelegate(navigationDelegate: SAHistoryNavigationViewControllerDelegate?) {
        _navigationDelegate = navigationDelegate
    }
    
    override func willGetNavigationDelegate() -> SAHistoryNavigationViewControllerDelegate? {
        return _navigationDelegate
    }
    
    override func willSetNavigationTransitioningDelegate(transitionDelegate: SAHistoryNavigationViewControllerTransitioningDelegate?) {
        _navigationTransitioningDelegate = transitionDelegate
    }
    
    override func willGetNavigationTransitioningDelegate() -> SAHistoryNavigationViewControllerTransitioningDelegate? {
        return _navigationTransitioningDelegate
    }
    
    override func willSetInteractivePopGestureEnabled(interactivePopGestureEnabled: Bool) {
        _interactivePopGestureEnabled = interactivePopGestureEnabled
    }
    
    override func willGetInteractivePopGestureEnabled() -> Bool {
        return _interactivePopGestureEnabled
    }
}

extension SAHistoryNavigationViewController {

    func handleEdgeSwipe(gesture: UIScreenEdgePanGestureRecognizer) {

        navigationDelegate?.navigationController?(self, willHandleEdgeSwipe: gesture)
        
        if screenshotImages.count > 0 {
            var progress = gesture.translationInView(view).x / view.bounds.size.width
            progress = min(1.0, max(0.0, progress))
            
            switch gesture.state {
                case .Began:
                    edgeSwiping = true
                    popViewControllerAnimated(true)
                    
                case .Changed:
                    defaultInteractiveTransition.updateInteractiveTransition(progress)
                    
                case .Ended, .Cancelled:
                    if progress > 0.5 {
                        screenshotImages.removeLast()
                        defaultInteractiveTransition.finishInteractiveTransition()
                    } else {
                        defaultInteractiveTransition.cancelInteractiveTransition()
                    }
                    edgeSwiping = false
                    
                    if let animationController = animationController as? SAHistoryNavigationTransitionController {
                        animationController.forceFinish()
                    }
                    animationController = nil
                    
                case .Failed, .Possible:
                    break
            }
        }
        
        navigationDelegate?.navigationController?(self, didHandleEdgeSwipe: gesture)
    }
    
    override public func showHistory() {
        
        super.showHistory()
        
        //screenshotImages += [visibleViewController.view.screenshotImage(scale: kImageScale)]
        if let image = visibleViewController?.screenshotFromWindow(SAHistoryNavigationViewController.kImageScale) {
            screenshotImages += [image]
        }

        
        historyViewController.images = screenshotImages
        historyViewController.currentIndex = viewControllers.count - 1
        historyViewController.reload()
        historyViewController.view.alpha = 1.0
        
        coverView.hidden = false
        historyContentView.hidden = false
        
       setNavigationBarHidden(true, animated: false)
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
            self.historyViewController.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.7, 0.7)
        }) { (finished) in
                    
        }
    }
    
    override public func setHistoryBackgroundColor(color: UIColor) {
        coverView.backgroundColor = color
    }
    
    override public func contentView() -> UIView? {
        return historyContentView
    }
    
    func detectLongTap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            showHistory()
        }
    }
}

extension SAHistoryNavigationViewController: SAHistoryViewControllerDelegate {
    func didSelectIndex(index: Int) {
        var destinationViewController: UIViewController?
        for (currentIndex, viewController) in viewControllers.enumerate() {
            if currentIndex == index {
                destinationViewController = viewController
                break
            }
        }
    
        if let viewController = destinationViewController {
            popToViewController(viewController, animated: false)
        }
        
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
            self.historyViewController.view.transform = CGAffineTransformIdentity
            self.historyViewController.scrollToIndex(index, animated: false)
        }) { finished in
            self.coverView.hidden = true
            self.historyContentView.hidden = true
            self.historyViewController.view.alpha = 0.0
            self.setNavigationBarHidden(false, animated: false)
        }
    }
}

extension SAHistoryNavigationViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let _ = visibleViewController?.navigationController?.navigationBar.backItem {
            var height = 64.0
            if visibleViewController?.navigationController?.navigationBarHidden == true {
                height = 44.0
            }
            let backButtonFrame = CGRect(x: 0.0, y :0.0,  width: 100.0, height: height)
            let touchPoint = gestureRecognizer.locationInView(gestureRecognizer.view)
            if CGRectContainsPoint(backButtonFrame, touchPoint) {
                return true
            }
        }
        
        if let gestureRecognizer = gestureRecognizer as? UIScreenEdgePanGestureRecognizer {
            if view == gestureRecognizer.view {
                return true
            }
        }
        
        return false
    }
}

extension SAHistoryNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        _navigationDelegate?.navigationController?(self, willShowViewController: viewController, animated: animated)
    }
    public func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        _navigationDelegate?.navigationController?(self, didShowViewController: viewController, animated: animated)
    }
    
    public func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        if let supportedInterfaceOrientations = _navigationDelegate?.navigationControllerSupportedInterfaceOrientations?(self) {
            return supportedInterfaceOrientations
        }
        return .All
    }
    
    public func navigationControllerPreferredInterfaceOrientationForPresentation(navigationController: UINavigationController) -> UIInterfaceOrientation {
        if let preferredInterfaceOrientationForPresentation = _navigationDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(self) {
            return preferredInterfaceOrientationForPresentation
        }
        return .Unknown
    }
    
    public func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        if let interactiveTransition = _navigationTransitioningDelegate?.navigationController?(self, interactionControllerForAnimationController: animationController) {
            return interactiveTransition
        }
        
        self.animationController = animationController
        
        if let animationController = animationController as? SAHistoryNavigationTransitionController {
            if animationController.navigationControllerOperation == .Push {
                return nil
            }
        }
    
        if !edgeSwiping || !interactivePopGestureEnabled {
            return nil
        }
    
        return defaultInteractiveTransition
    }
    
    public func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let animationController = _navigationTransitioningDelegate?.navigationController?(self, animationControllerForOperation: operation, fromViewController: fromVC, toViewController: toVC) {
            return animationController
        }

        return SAHistoryNavigationTransitionController(operation: operation)
    }
}