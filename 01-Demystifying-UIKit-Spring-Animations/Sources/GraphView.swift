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


internal final class GraphView: UIView {

    // MARK: - Configuration

    public var spring: DampedHarmonicSpring? = nil {
        didSet { self.setNeedsDisplay() }
    }

    public var horizontalRange: ClosedRange<TimeInterval> = 0.0...1.5 {
        didSet { self.setNeedsDisplay() }
    }

    public var verticalRange: ClosedRange<CGFloat> = -0.5...1.0 {
        didSet { self.setNeedsDisplay() }
    }

    public var padding: UIEdgeInsets = UIEdgeInsets(top: 5.0, left: 20.0, bottom: 5.0, right: 20.0)


    // MARK: - Rendering

    public override func draw(_ rect: CGRect) {
        self.drawAxes()
        self.drawEquationOfMotion()
    }

    private func drawAxes() {
        let context = UIGraphicsGetCurrentContext()!

        context.saveGState()
        context.beginPath()
        context.move(to: self.point(for: 0, self.verticalRange.lowerBound) + CGVector(dx: 0.5, dy: 0))
        context.addLine(to: self.point(for: 0, self.verticalRange.upperBound) + CGVector(dx: 0.5, dy: 0))
        context.move(to: self.point(for: self.horizontalRange.lowerBound, 0))
        context.addLine(to: self.point(for: self.horizontalRange.upperBound, 0))

        func mark(x: TimeInterval) {
            context.move(to: self.point(for: x, 0) - CGVector(dx: 0, dy: 5))
            context.addLine(to: self.point(for: x, 0) + CGVector(dx: 0, dy: 5))
        }

        func mark(y: CGFloat) {
            context.move(to: self.point(for: 0, y) - CGVector(dx: 5, dy: 0))
            context.addLine(to: self.point(for: 0, y) + CGVector(dx: 5, dy: 0))
        }

        func draw(_ text: String, at t: TimeInterval, _ s: CGFloat) {
            NSString(string: text).draw(at: self.point(for: t, s) + CGVector(dx: 2, dy: 2), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.lightGray,
            ])
        }

        mark(x: 0.5)
        mark(x: 1.0)
        mark(x: 1.5)
        mark(y: 1.0)
        mark(y: 0.5)
        mark(y: -0.5)
        draw("0.5s", at: 0.5, 0)
        draw("1.0s", at: 1.0, 0)

        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.strokePath()
        context.restoreGState()
    }

    private func drawEquationOfMotion() {
        guard let spring = self.spring else { return }

        let minT = self.horizontalRange.lowerBound
        let maxT = self.horizontalRange.upperBound
        let dt = (maxT - minT) / Double(self.bounds.width)

        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.beginPath()
        context.move(to: self.point(for: maxT, spring.position(at: maxT)))

        for t in stride(from: minT, through: maxT, by: dt).reversed() {
            context.addLine(to: self.point(for: t, spring.position(at: t)))
        }

        context.setLineCap(.square)
        context.setStrokeColor(UIColor.red.cgColor)
        context.strokePath()
        context.restoreGState()
    }

    private func point(for t: TimeInterval, _ s: CGFloat) -> CGPoint {
        let minT = self.horizontalRange.lowerBound
        let maxT = self.horizontalRange.upperBound
        let minS = self.verticalRange.lowerBound
        let maxS = self.verticalRange.upperBound
        let padding = self.padding

        let x = CGFloat((t - minT) / (maxT - minT)) * (self.bounds.width - padding.left - padding.right) + padding.left
        let y = CGFloat(1 - ((s - minS) / (maxS - minS))) * (self.bounds.height - padding.top - padding.bottom) + padding.top

        return CGPoint(x: x, y: y)
    }
}
