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


internal class FacetimeViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Lifecycle

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }


    // MARK: - Configuration

    /// The spring driving animations of the PIP view.
    fileprivate let spring: DampedHarmonicSpring = .init(dampingRatio: 0.75, frequencyResponse: 0.25)


    // MARK: - State

    /// The different states the PIP view can be in.
    fileprivate enum State {

        /// The PIP view is at rest at the specified endpoint.
        case idle(at: Endpoint)

        /// The user is actively moving the PIP view starting from the specified
        /// initial position using the specified gesture recognizer.
        case interaction(with: UIPanGestureRecognizer, from: CGPoint)

        /// The PIP view is being animated towards the specified endpoint with
        /// the specified animator.
        case animating(to: Endpoint, using: UIViewPropertyAnimator)
    }

    /// The current state of the PIP view.
    fileprivate var state: State = .idle(at: .bottomRight)


    // MARK: - View Management

    fileprivate let pictureInPictureView: PictureInPictureView = .init()
    fileprivate let topLeftEndpointIndicatorView: EndpointIndicatorView = .init()
    fileprivate let topRightEndpointIndicatorView: EndpointIndicatorView = .init()
    fileprivate let bottomLeftEndpointIndicatorView: EndpointIndicatorView = .init()
    fileprivate let bottomRightEndpointIndicatorView: EndpointIndicatorView = .init()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        self.view.addSubview(self.topLeftEndpointIndicatorView)
        self.view.addSubview(self.topRightEndpointIndicatorView)
        self.view.addSubview(self.bottomLeftEndpointIndicatorView)
        self.view.addSubview(self.bottomRightEndpointIndicatorView)
        self.view.addSubview(self.pictureInPictureView)

        self.configureGestureRecognizers()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.topLeftEndpointIndicatorView.frame = self.frame(for: .topLeft)
        self.topRightEndpointIndicatorView.frame = self.frame(for: .topRight)
        self.bottomLeftEndpointIndicatorView.frame = self.frame(for: .bottomLeft)
        self.bottomRightEndpointIndicatorView.frame = self.frame(for: .bottomRight)

        switch self.state {
        case .idle(at: let endpoint):
            self.pictureInPictureView.frame = self.frame(for: endpoint)
        case .animating(to: let endpoint, using: _):
            self.pictureInPictureView.frame = self.frame(for: endpoint)
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

    /// The possible locations at which the PIP view can rest.
    fileprivate enum Endpoint: CaseIterable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    /// Returns the frame of the specified endpoint.
    fileprivate func frame(for endpoint: Endpoint) -> CGRect {
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let rect = self.view.safeAreaLayoutGuide.layoutFrame.inset(by: padding)
        let size = CGSize(width: 100, height: 180)

        switch endpoint {
        case .topLeft: return CGRect(x: rect.minX, y: rect.minY, width: size.width, height: size.height).standardized
        case .topRight: return CGRect(x: rect.maxX, y: rect.minY, width: -size.width, height: size.height).standardized
        case .bottomLeft: return CGRect(x: rect.minX, y: rect.maxY, width: size.width, height: -size.height).standardized
        case .bottomRight: return CGRect(x: rect.maxX, y: rect.maxY, width: -size.width, height: -size.height).standardized
        }
    }

    /// Initiates a new interactive transition that will be driven by the
    /// specified pan gesture recognizer. If an animation is currently in
    /// progress, it is cancelled on the spot.
    fileprivate func beginInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        switch self.state {
        case .idle: break
        case .interaction: return
        case .animating(to: _, using: let animator):
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
        let currentCenter = self.pictureInPictureView.center
        let endpoint = self.intendedEndpoint(with: velocity, from: currentCenter)
        let targetCenter = self.frame(for: endpoint).center

        let parameters = self.spring.timingFunction(withInitialVelocity: velocity, from: &self.pictureInPictureView.center, to: targetCenter, context: self)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: parameters)

        animator.addAnimations({
            self.pictureInPictureView.center = targetCenter
        })

        animator.addCompletion({ position in
            self.state = .idle(at: endpoint)
        })

        self.state = .animating(to: endpoint, using: animator)

        animator.startAnimation()
    }

    /// Calculates the endpoint to which the PIP view should move from the
    /// specified current position with the specified velocity.
    private func intendedEndpoint(with velocity: CGVector, from currentPosition: CGPoint) -> Endpoint {
        var velocity = velocity

        // Reduce movement along the secondary axis of the gesture.
        if velocity.dx != 0 || velocity.dy != 0 {
            let velocityInPrimaryDirection = fmax(abs(velocity.dx), abs(velocity.dy))

            velocity.dx *= abs(velocity.dx / velocityInPrimaryDirection)
            velocity.dy *= abs(velocity.dy / velocityInPrimaryDirection)
        }

        let projectedPosition = UIGestureRecognizer.project(velocity, onto: currentPosition)
        let endpoint = self.endpoint(closestTo: projectedPosition)

        return endpoint
    }

    /// Returns the endpoint closest to the specified point.
    private func endpoint(closestTo point: CGPoint) -> Endpoint {
        return Endpoint.allCases.min(by: { point.distance(to: self.frame(for: $0).center) })!
    }


    // MARK: - Status Bar Management

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


// MARK: - Miscellaneous

extension Sequence {
    public func min<T>(by closure: (Element) throws -> T) rethrows -> Element? where T: Comparable {
        let tuples = try self.lazy.map({ (element: $0, value: try closure($0)) })
        let minimum = tuples.min(by: { $0.value < $1.value })

        return minimum?.element
    }
}
