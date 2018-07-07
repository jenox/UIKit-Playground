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


extension UIGestureRecognizer {

    /// Calculates the value at which a property settles when intially changing
    /// with a specified velocity and some degree of friction is applied.
    ///
    /// The friction causing the property to change slower and slower and
    /// eventually come to rest is modeled after the familiar `UIScrollView`
    /// deceleration behavior.
    ///
    /// - parameter velocity: The velocity at which some property intitially
    /// changes, measured per second.
    /// - parameter position: The initial value of the property.
    /// - parameter decelerationRate: The rate at which the velocity decreases,
    /// measured as the fraction of the velocity that remains per millisecond.
    public static func project(_ velocity: CGFloat, onto position: CGFloat, decelerationRate: UIScrollView.DecelerationRate = .normal) -> CGFloat {
        let velocity = CGVector(dx: velocity, dy: 0)
        let position = CGPoint(x: position, y: 0)

        return self.project(velocity, onto: position).x
    }

    /// Calculates the position at which an object comes to rest when initially
    /// moving with a specified velocity and some degree of friction is applied.
    ///
    /// The friction causing the object to move slower and slower and eventually
    /// come to rest is modeled after the familiar `UIScrollView` deceleration
    /// behavior.
    ///
    /// - parameter velocity: The velocity at which the object intitially moves,
    /// measured per second.
    /// - parameter position: The initial position of the object.
    /// - parameter decelerationRate: The rate at which the velocity decreases,
    /// measured as the fraction of the velocity that remains per millisecond.
    public static func project(_ velocity: CGVector, onto position: CGPoint, decelerationRate: UIScrollView.DecelerationRate = .normal) -> CGPoint {

        // The distance traveled is the integral over the exponentially
        // decreasing velocity from `t = 0` to infinity, which comes down to a
        // constant factor in front of the initial velocity. Thus we can threat
        // the projection along each axis individually.
        let factor = -1 / (1000 * log(decelerationRate.rawValue))
        let x = position.x + factor * velocity.dx
        let y = position.y + factor * velocity.dy

        return CGPoint(x: x, y: y)
    }
}
