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


internal class ConfigurationViewController: UIViewController {

    // MARK: - Spring Management

    fileprivate func readSpringParametersFromControls() {
        let dampingRatio = CGFloat(self.dampingRatioSlider.value)
        let frequencyResponse = CGFloat(self.frequencyResponseSlider.value)

        self.spring = DampedHarmonicSpring(dampingRatio: dampingRatio, frequencyResponse: frequencyResponse)
    }

    fileprivate var spring: DampedHarmonicSpring = DampedHarmonicSpring(dampingRatio: 0.25, frequencyResponse: 0.5) {
        didSet { self.graphView.spring = self.spring }
    }


    // MARK: - View Management

    @IBOutlet fileprivate var graphView: GraphView!
    @IBOutlet fileprivate var previewButton: UIButton!

    @IBOutlet fileprivate var dampingRatioLabel: UILabel!
    @IBOutlet fileprivate var dampingRatioSlider: UISlider!
    @IBOutlet fileprivate var dampingRatioTextField: UITextField!

    @IBOutlet fileprivate var frequencyResponseLabel: UILabel!
    @IBOutlet fileprivate var frequencyResponseSlider: UISlider!
    @IBOutlet fileprivate var frequencyResponseTextField: UITextField!

    public override func viewDidLoad() {
        self.graphView.spring = self.spring

        self.dampingRatioSlider.minimumValue = 0.0
        self.dampingRatioSlider.maximumValue = 1.5
        self.dampingRatioSlider.value = Float(self.spring.dampingRatio)

        self.frequencyResponseSlider.minimumValue = 0.1
        self.frequencyResponseSlider.maximumValue = 1.0
        self.frequencyResponseSlider.value = Float(self.spring.frequencyResponse)

        self.performFormattingUpdate()
        self.performStylingUpdate()
    }


    // MARK: - User Actions

    @IBAction fileprivate func dampingRatioSliderDidChange() {
        self.readSpringParametersFromControls()
        self.performFormattingUpdate()
    }

    @IBAction fileprivate func frequencyResponseSliderDidChange() {
        self.readSpringParametersFromControls()
        self.performFormattingUpdate()
    }

    @IBAction fileprivate func previewButtonWasTapped() {
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneButtonItem.target = self
        doneButtonItem.action = #selector(self.dismissPresentedViewController)

        let previewViewController = PreviewViewController(spring: self.spring)
        previewViewController.navigationItem.rightBarButtonItem = doneButtonItem

        let navigationController = UINavigationController(rootViewController: previewViewController)
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.barStyle = .black
        navigationController.navigationBar.tintColor = UIColor.white
        navigationController.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        self.present(navigationController, animated: true, completion: nil)
    }

    @objc private func dismissPresentedViewController() {
        self.dismiss(animated: true, completion: nil)
    }


    // MARK: - Formatting & Styling

    fileprivate func performFormattingUpdate() {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 4

        self.dampingRatioLabel.text = "Damping Ratio"
        self.dampingRatioTextField.text = formatter.string(from: self.spring.dampingRatio as NSNumber)!

        self.frequencyResponseLabel.text = "Frequency Response"
        self.frequencyResponseTextField.text = formatter.string(from: self.spring.frequencyResponse as NSNumber)! + "s"

        self.previewButton.setTitle("Preview Animation", for: .normal)
    }

    fileprivate func performStylingUpdate() {
        let labelFont = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        let valueFont = UIFont.monospacedDigitSystemFont(ofSize: 16.0, weight: .regular)

        self.dampingRatioLabel.font = labelFont
        self.dampingRatioTextField.font = valueFont
        self.dampingRatioTextField.isEnabled = false

        self.frequencyResponseLabel.font = labelFont
        self.frequencyResponseTextField.font = valueFont
        self.frequencyResponseTextField.isEnabled = false
    }
}
