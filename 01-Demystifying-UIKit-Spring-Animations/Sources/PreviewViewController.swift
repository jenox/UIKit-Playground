/*
 MIT License

 Copyright (c) 2018 Christian Schnorr

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit


internal class PreviewViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Lifecycle

    public init(spring: DampedHarmonicSpring) {
        self.spring = spring

        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - Configuration

    /// The spring driving animations.
    fileprivate let spring: DampedHarmonicSpring


    // MARK: - State

    fileprivate enum State {
        case idle
        case interaction(with: UIPanGestureRecognizer, from: CGPoint)
        case animating(using: UIViewPropertyAnimator)
    }

    fileprivate var state: State = .idle


    // MARK: - View Management

    fileprivate let pictureInPictureView: PictureInPictureView = .init()
    fileprivate let endpointIndicatorView: EndpointIndicatorView = .init()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        self.view.addSubview(self.endpointIndicatorView)
        self.view.addSubview(self.pictureInPictureView)

        self.configureGestureRecognizers()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.endpointIndicatorView.frame = self.frameForEndpointIndicatorView()

        switch self.state {
        case .idle:
            self.pictureInPictureView.frame = self.frameForEndpointIndicatorView()
        case .animating(using: _):
            self.pictureInPictureView.frame = self.frameForEndpointIndicatorView()
        case .interaction:
            break
        }
    }


    // MARK: - Gesture Management

    fileprivate let panGestureRecognizer: UIPanGestureRecognizer = PanGestureRecognizer()

    fileprivate func configureGestureRecognizers() {
        self.panGestureRecognizer.addTarget(self, action: #selector(self.panGestureDidChange))
        self.panGestureRecognizer.delegate = self

        self.pictureInPictureView.addGestureRecognizer(self.panGestureRecognizer)
    }

    @objc private func panGestureDidChange(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.beginInteractiveTransition(with: gesture)
        case .changed:
            self.updateInteractiveTransition(with: gesture)
        case .ended, .cancelled:
            self.endInteractiveTransition(with: gesture)
        default:
            break
        }
    }

    public func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        if gesture === self.panGestureRecognizer {
            // `UIPanGestureRecognizer`s seem to delay their 'began' callback by
            // up to 0.75sec near the edges of the screen. We want to get
            // notified immediately so that we can properly interrupt an ongoing
            // animation.
            DispatchQueue.main.async(execute: {
                self.panGestureDidChange(self.panGestureRecognizer)
            })
        }

        return true
    }


    // MARK: - Interaction Management

    /// Returns the frame of the single endpoint.
    fileprivate func frameForEndpointIndicatorView() -> CGRect {
        let center = self.view.safeAreaLayoutGuide.layoutFrame.center
        let size = CGSize(width: 100, height: 180)
        let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)

        return CGRect(origin: origin, size: size)
    }

    /// Initiates a new interactive transition that will be driven by the
    /// specified pan gesture recognizer. If an animation is currently in
    /// progress, it is cancelled on the spot.
    fileprivate func beginInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        switch self.state {
        case .idle: break
        case .interaction: return
        case .animating(using: let animator):
            animator.stopAnimation(true)
        }

        let startPoint = self.pictureInPictureView.center

        self.state = .interaction(with: gesture, from: startPoint)
    }

    /// Updates the ongoing interactive transition driven by the specified pan
    /// gesture recognizer.
    fileprivate func updateInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: let startPoint) = self.state else { return }

        let scale = fmax(self.traitCollection.displayScale, 1)
        let translation = gesture.translation(in: self.view)

        var center = startPoint + CGVector(to: translation)
        center.x = round(center.x * scale) / scale
        center.y = round(center.y * scale) / scale

        self.pictureInPictureView.center = center
    }

    /// Finishes the ongoing interactive transition driven by the specified pan
    /// gesture recognizer.
    fileprivate func endInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: _) = self.state else { return }

        let velocity = CGVector(to: gesture.velocity(in: self.view))
        let targetCenter = self.frameForEndpointIndicatorView().center

        let parameters = self.spring.timingFunction(withInitialVelocity: velocity, from: &self.pictureInPictureView.center, to: targetCenter, context: self)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: parameters)

        animator.addAnimations({
            self.pictureInPictureView.center = targetCenter
        })

        animator.addCompletion({ position in
            self.state = .idle
        })

        self.state = .animating(using: animator)

        animator.startAnimation()
    }


    // MARK: - Status Bar Management

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
