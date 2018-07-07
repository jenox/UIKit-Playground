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


internal final class EndpointIndicatorView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.isOpaque = false
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }

    public override func draw(_ rect: CGRect) {
        let radius = 15 as CGFloat
        let thickness = 4 as CGFloat

        let bounds = CGRect(origin: .zero, size: self.bounds.size).insetBy(dx: thickness / 2, dy: thickness / 2)
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: radius)

        let context = UIGraphicsGetCurrentContext()!
        context.beginPath()
        context.addPath(path.cgPath)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.setLineDash(phase: 0, lengths: [7])
        context.setLineWidth(thickness)
        context.strokePath()
    }
}
