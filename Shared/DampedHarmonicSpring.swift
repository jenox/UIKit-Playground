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


/**
 * A type modeling a damped harmonic spring in the real world, offering a more
 * design-friendly interface and additional functionality than UIKit does out of
 * the box.
 */
public struct DampedHarmonicSpring {

    // MARK: - Underlying Physical Parameters

    /// Creates a damped harmonic spring using the specified underlying physical
    /// parameters.
    ///
    /// - parameter mass: The mass `m` attached to the spring, measured in
    /// kilograms.
    /// - parameter stiffness: The spring constant `k`, measured in kilograms
    /// per second squared.
    /// - parameter dampingCoefficient: The viscous damping coefficient `c`,
    /// measured in kilograms per second.
    public init(mass: CGFloat, stiffness: CGFloat, dampingCoefficient: CGFloat) {
        precondition(mass > 0)
        precondition(stiffness > 0)
        precondition(dampingCoefficient >= 0)

        self.mass = mass
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
    }

    /// The mass `m` attached to the spring, measured in kilograms.
    public var mass: CGFloat

    /// The spring constant `k`, measured in kilograms per second squared.
    public var stiffness: CGFloat

    /// The viscous damping coefficient `c`, measured in kilograms per second.
    public var dampingCoefficient: CGFloat


    // MARK: - Design-Friendly Parameters

    /// Creates a damped harmonic spring using the specified design-friendly
    /// parameters.
    ///
    /// - parameter dampingRatio: The ratio of the actual damping coefficient to
    /// the critical damping coeffcient.
    /// - parameter frequencyResponse: The duration of one period in the
    /// undamped system, measured in seconds.
    ///
    /// See https://developer.apple.com/videos/play/wwdc2018/803/ at 33:46.
    public init(dampingRatio: CGFloat, frequencyResponse: CGFloat) {
        precondition(dampingRatio >= 0)
        precondition(frequencyResponse > 0)

        self.mass = 1
        self.stiffness = pow(2 * .pi / frequencyResponse, 2) * self.mass
        self.dampingCoefficient = 4 * .pi * dampingRatio * self.mass / frequencyResponse
    }

    /// The unitless damping ratio `ζ`, i.e. the ratio of the actual damping
    /// coefficient to the critical damping coeffcient.
    public var dampingRatio: CGFloat {
        return self.dampingCoefficient / (2 * sqrt(self.stiffness * self.mass))
    }

    /// The duration of one period in the undamped system, measured in seconds.
    public var frequencyResponse: CGFloat {
        return 2 * .pi / self.undampedNaturalFrequency
    }

    /// The undamped natural frequency `ω_0`, measured in radians per second.
    fileprivate var undampedNaturalFrequency: CGFloat {
        return sqrt(self.stiffness / self.mass)
    }

    /// The damped natural frequency `ω_r`, measured in radians per second.
    fileprivate var dampedNaturalFrequency: CGFloat {
        return self.undampedNaturalFrequency * sqrt(fabs(1 - pow(self.dampingRatio, 2)))
    }


    // MARK: - Evaluation

    /// Calculates the spring's displacement from equilibrium at the specified
    /// time.
    ///
    /// - parameter time: The time after which the displacement from equilibrium
    /// is to be computed, measured in seconds.
    /// - parameter initialPosition: The spring's displacement from equilibrium
    /// at `t = 0`.
    /// - parameter initialVelocity: The spring's velocity at `t = 0`, measured
    /// per second.
    public func position(at time: TimeInterval, initialPosition: CGFloat = 1, initialVelocity: CGFloat = 0) -> CGFloat {
        let ζ = self.dampingRatio
        let λ = self.dampingCoefficient / self.mass / 2
        let ω_d = self.dampedNaturalFrequency
        let s_0 = initialPosition
        let v_0 = initialVelocity
        let t = CGFloat(time)

        if fabs(ζ - 1) < 1e-6 {
            let c_1 = s_0
            let c_2 = v_0 + λ * s_0

            return exp(-λ * t) * (c_1 + c_2 * t)
        }
        else if ζ < 1 {
            let c_1 = s_0
            let c_2 = (v_0 + λ * s_0) / ω_d

            return exp(-λ * t) * (c_1 * cos(ω_d * t) + c_2 * sin(ω_d * t))
        }
        else {
            let c_1 = (v_0 + s_0 * (λ + ω_d)) / (2 * ω_d)
            let c_2 = s_0 - c_1

            return exp(-λ * t) * (c_1 * exp(ω_d * t) + c_2 * exp(-ω_d * t))
        }
    }

    /// Calculates the maximum displacement from equilibrium the spring reaches
    /// when pushed with the specified velocity in its equilibrium state.
    ///
    /// - parameter initialVelocity: The velocity with which the spring is
    /// pushed at `t = 0`.
    fileprivate func maximumDisplacementFromEquilibrium(initialVelocity: CGFloat) -> CGFloat {
        let ζ = self.dampingRatio
        let λ = self.dampingCoefficient / self.mass / 2
        let ω_d = self.dampedNaturalFrequency
        let v_0 = initialVelocity
        let t: TimeInterval

        if fabs(ζ - 1) < 1e-6 {
            t = TimeInterval(1 / λ)
        }
        else if ζ < 1 {
            t = TimeInterval(atan(ω_d / λ) / ω_d)
        }
        else {
            t = TimeInterval(log((λ + ω_d) / (λ - ω_d)) / (2 * ω_d))
        }

        return fabs(self.position(at: t, initialPosition: 0, initialVelocity: v_0))
    }


    // MARK: - Creating Timing Functions

    /// Creates an animation timing function using the spring's parameters and
    /// the specified relative initial velocity towards equilibrium, measured as
    /// fraction complete per second.
    public func timingFunction(withRelativeInitialVelocity initialVelocity: CGVector) -> UISpringTimingParameters {
        let m = self.mass
        let k = self.stiffness
        let c = self.dampingCoefficient
        let v_0 = initialVelocity

        return UISpringTimingParameters(mass: m, stiffness: k, damping: c, initialVelocity: v_0)
    }

    /// Creates an animation timing function using the spring's parameters and
    /// the specified relative initial velocity towards equilibrium, measured as
    /// fraction complete per second.
    public func timingFunction(withRelativeInitialVelocity initialVelocity: CGFloat) -> UISpringTimingParameters {

        // If we happen to animate a two-dimensional property with the created
        // timing parameters, we want both dimensions to be affected by the
        // initial velocity.
        let initialVelocity = CGVector(dx: initialVelocity, dy: initialVelocity)

        return self.timingFunction(withRelativeInitialVelocity: initialVelocity)
    }

    /// Creates an animation timing function using the spring's parameters,
    /// intended to be used for an animation with the specified endpoints and
    /// initial velocity.
    ///
    /// If the current and target values match already, the current value is
    /// slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property
    /// initially changes, measured per second.
    public func timingFunction(withInitialVelocity initialVelocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat) -> UISpringTimingParameters {

        // A thousandth of the velocity is far less than the change in a single
        // frame and is therefore negligible regardless of the semantics of the
        // start and end values.
        let epsilon = fabs(1e-3 * initialVelocity)
        let relativeVelocity = self.relativeVelocity(forVelocity: initialVelocity, from: &currentValue, to: targetValue, epsilon: epsilon)

        return self.timingFunction(withRelativeInitialVelocity: relativeVelocity)
    }

    /// Creates an animation timing function using the spring's parameters,
    /// intended to be used for an animation with the specified endpoints and
    /// initial velocity.
    ///
    /// If the current and target values match already, the current value is
    /// slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property
    /// initially changes, measured per second.
    /// - parameter context: The context in which the animation takes place,
    /// used to align values on pixel boundaries.
    public func timingFunction(withInitialVelocity initialVelocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat, context: UITraitEnvironment) -> UISpringTimingParameters {

        // We want to align values on pixel boundaries.
        let epsilon = 1 / fmax(1, context.traitCollection.displayScale)
        let relativeVelocity = self.relativeVelocity(forVelocity: initialVelocity, from: &currentValue, to: targetValue, epsilon: epsilon)

        return self.timingFunction(withRelativeInitialVelocity: relativeVelocity)
    }

    /// Creates an animation timing function using the spring's parameters,
    /// intended to be used for an animation with the specified endpoints and
    /// initial velocity.
    ///
    /// If on an axis the current and target values match already, the current
    /// value is slightly displaced so that the initial velocity can be
    /// respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property
    /// initially changes, measured per second.
    /// - parameter context: The context in which the animation takes place,
    /// used to align values on pixel boundaries.
    public func timingFunction(withInitialVelocity initialVelocity: CGVector, from currentValue: inout CGPoint, to targetValue: CGPoint, context: UITraitEnvironment) -> UISpringTimingParameters {

        // We want to align values on pixel boundaries.
        let epsilon = 1 / fmax(1, context.traitCollection.displayScale)
        let relativeXVelocity = self.relativeVelocity(forVelocity: initialVelocity.dx, from: &currentValue.x, to: targetValue.x, epsilon: epsilon)
        let relativeYVelocity = self.relativeVelocity(forVelocity: initialVelocity.dy, from: &currentValue.y, to: targetValue.y, epsilon: epsilon)
        let relativeVelocity = CGVector(dx: relativeXVelocity, dy: relativeYVelocity)

        return self.timingFunction(withRelativeInitialVelocity: relativeVelocity)
    }

    /// Transforms the specified velocity to a relative velocity with a value of
    /// `1.0` indicating that the distance from the specified current value to
    /// the specified target value is covered in one second.
    ///
    /// If the current and target values match already, the current value is
    /// slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter velocity: The velocity at which the property currently
    /// changes, measured per second.
    /// - parameter currentValue: The current value of some property.
    /// - parameter targetValue: The target value of the property.
    /// - parameter epsilon: The distance up to which the current and target
    /// values are considered to be equal. If the current value needs to be
    /// tweaked, it is displaced by integral multiples of this parameter.
    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat, epsilon: CGFloat) -> CGFloat {
        precondition(epsilon > 0)

        if fabs(targetValue - currentValue) >= epsilon {
            return velocity / (targetValue - currentValue)
        }
        else if self.maximumDisplacementFromEquilibrium(initialVelocity: velocity) >= 2 * epsilon {
            if velocity >= 0 {
                currentValue = targetValue + epsilon
            }
            else {
                currentValue = targetValue - epsilon
            }

            return velocity / (targetValue - currentValue)
        }
        else {
            return 0
        }
    }
}
