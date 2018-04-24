//
//  LineChartView.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import UIKit

public class LineChartView: UIView {

    @IBOutlet public weak var delegate: LineChartViewDelegate?

    public var appearance: LineChartAppearance = defaultAppearance {
        didSet {
            self.setNeedsLayout()
        }
    }

    /// Setting this property triggers a reset of all subviews and sublayers
    /// (labels, grid, etc.)
    public var dataPoints: [Double] = [] {
        didSet {
            self.setNeedsLayout()
        }
    }

    // MARK: - Metrics

    public var yAxisLabelTextColor: UIColor = .white
    public var yAxisLabelFontSize: CGFloat = 12
    public var yAxisLabelMaximumwidth: CGFloat = 60
    public var yAxisLabelRightMargin: CGFloat = 8
    public var yAxisTopLabelTopMargin: CGFloat = 16
    public var yAxisBottomLabelBottomMargin: CGFloat = 16

    public var xAxisLabelTextColor: UIColor = .white
    public var xAxisLabelFontSize: CGFloat = 12
    public var xAxisLabelTopMargin: CGFloat = 8

    // MARK: - Other Display Settings

    enum LabellingMode {
        /// Displays three labels along the y axis. The top-most one marks the
        /// smalles integer multiple of `roundingUnit` that equals or exceeds
        /// the maximum value attained by the data. Similarly, the bottom-most
        /// lanels marks the largest integer multiple of `roundingUnit` that is
        /// equal or smaller than the minimum value attained by the data.
        /// Finally, the middle label is the exact average of the other two.
        case minMaxAverage(roundingUnit: Double)

        /// Displays equally spaced labels
        case fixed(step: Double)
    }
    var labellingMode: LabellingMode = .minMaxAverage(roundingUnit: 10.0)

    // MARK: - UIView

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = nil
        commonSetup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    public override func layoutSubviews() {
        setupHorizontalAxisLabels()

        super.layoutSubviews() // (Must call after axis labels)

        setupVerticalAxisLabels(labellingMode)
        updateOrdinates()
        setupGridLayer()
        setupGraphLayer()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let sampleIndex = mapCanvasLocationToSample(location)
        if delegate?.lineChartView(self, shouldhighlightSampleAt: sampleIndex) == true {
            graphLayer.highlight(sampleIndex)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let sampleIndex = mapCanvasLocationToSample(location)
        print("Touches moved: \(location)")
        if delegate?.lineChartView(self, shouldhighlightSampleAt: sampleIndex) == true {
            graphLayer.highlight(sampleIndex)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        graphLayer.highlight(nil)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        graphLayer.highlight(nil)
    }

    // MARK: - Implementation Details (Private)

    private var yAxisLabelContainer: UIView!
    private var xAxisLabelContainer: UIView!
    private var gridLayer: CALayer!
    private var graphLayer: LineChartGraphLayer!

    // These are set during layout, and kept around to aid mapping between data
    // values and points on screen:
    private var topLabelCenterY: CGFloat = 0.0
    private var bottomLabelCenterY: CGFloat = 0.0
    private var topLabelValue: Double = 0.0
    private var bottomLabelValue: Double = 0.0

    private var abscissas: [CGFloat] = []
    private var ordinates: [CGFloat] = []

    private static let blue01 = UIColor(red: 0.09, green: 0.09, blue: 0.1, alpha: 1)
    private static let blue02 = UIColor(red: 0.18, green: 0.18, blue: 0.2, alpha: 1)
    private static let blue03 = UIColor(red: 0.27, green: 0.27, blue: 0.3, alpha: 1)
    private static let blue04 = UIColor(red: 0.36, green: 0.36, blue: 0.4, alpha: 1)

    private static var defaultAppearance: LineChartAppearance = {
        let appearance = LineChartAppearance(
            gridAppearance: LineChartGridAppearance(
                axisAppearance: LineAttributes(lineWidth: 2, strokeColor: UIColor(white: 0.7, alpha: 1).cgColor),
                horizontalGridLineAppearance: LineAttributes(lineWidth: 0.5, strokeColor: UIColor(white: 0.5, alpha: 1).cgColor),
                verticalGridLineAppearance: LineAttributes(lineWidth: 0.5, strokeColor: UIColor(white: 0.5, alpha: 1).cgColor),
                //gridFillMode: LineChartGridFillMode.solid(color: UIColor.white.cgColor)
                //gridFillMode: LineChartGridFillMode.alternateRows(primary: blue03.cgColor, secondary: blue04.cgColor)
                gridFillMode: LineChartGridFillMode.alternateColumns(primary: blue03.cgColor, secondary: blue04.cgColor)
            ),
            graphAppearance: LineChartGraphAppearance(
                lineAttributes: LineAttributes(lineWidth: 1, strokeColor: UIColor.black.cgColor),
                fillMode: LineChartGraphFillMode.solid(color: UIColor.brown.cgColor)
            ),
            highlightMode: .abscissa,
            dotRadius: 10,
            dotColor: UIColor.blue.cgColor
        )
        return appearance
    }()

    private func commonSetup() {
        setupLabelContainers()
    }

    private func setupLabelContainers() {
        // Create:
        xAxisLabelContainer?.removeFromSuperview()
        self.xAxisLabelContainer = UIView(frame: CGRect.zero)
        xAxisLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(xAxisLabelContainer)

        yAxisLabelContainer?.removeFromSuperview()
        self.yAxisLabelContainer = UIView(frame: CGRect.zero)
        yAxisLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(yAxisLabelContainer)

        // Constrain:
        yAxisLabelContainer.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        yAxisLabelContainer.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        yAxisLabelContainer.bottomAnchor.constraint(equalTo: xAxisLabelContainer.topAnchor).isActive = true
        yAxisLabelContainer.widthAnchor.constraint(equalToConstant: yAxisLabelMaximumwidth).isActive = true

        xAxisLabelContainer.leftAnchor.constraint(equalTo: yAxisLabelContainer.rightAnchor).isActive = true
        xAxisLabelContainer.topAnchor.constraint(equalTo: yAxisLabelContainer.bottomAnchor).isActive = true
        xAxisLabelContainer.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        xAxisLabelContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    private func setupVerticalAxisLabels(_ mode: LabellingMode) {
        switch mode {
        case .minMaxAverage(let roundingUnit):
            setupMinMaxAvgLabels(roundingUnit: roundingUnit)
        case .fixed(let step):
            setupFixedLabels(step: step)
        }
    }

    private func setupMinMaxAvgLabels(roundingUnit: Double) {
        guard yAxisLabelContainer != nil else {
            return
        }
        yAxisLabelContainer.subviews.forEach { $0.removeFromSuperview() }
        ordinates.removeAll()

        // Calculate values
        guard let min = dataPoints.min(), let max = dataPoints.max() else { return }

        self.topLabelValue = roundingUnit * ceil(max/roundingUnit)
        self.bottomLabelValue = roundingUnit * floor(min/roundingUnit)

        let average = (topLabelValue + bottomLabelValue) / 2
        let values = [topLabelValue, average, bottomLabelValue] // From top to bottom

        // Create labels
        let labels: [UILabel] = values.map { (value) -> UILabel in
            let l = UILabel(frame: CGRect.zero)
            //l.backgroundColor = .yellow // DEBUG
            l.translatesAutoresizingMaskIntoConstraints = false
            l.font = UIFont.systemFont(ofSize: yAxisLabelFontSize)
            l.text = delegate?.lineChartView(self, formattedValue: value) ?? "\(value)"
            l.textColor = yAxisLabelTextColor
            l.textAlignment = .right
            l.sizeToFit()
            l.adjustsFontSizeToFitWidth = true
            return l
        }

        // Add to view
        labels.forEach { yAxisLabelContainer.addSubview($0) }

        // Constrain
        labels[0].topAnchor.constraint(equalTo: yAxisLabelContainer.topAnchor, constant: yAxisTopLabelTopMargin).isActive = true
        labels[0].leftAnchor.constraint(equalTo: yAxisLabelContainer.leftAnchor).isActive = true
        labels[0].rightAnchor.constraint(equalTo: yAxisLabelContainer.rightAnchor, constant: -yAxisLabelRightMargin).isActive = true

        labels[1].leadingAnchor.constraint(equalTo: labels[0].leadingAnchor).isActive = true
        labels[1].trailingAnchor.constraint(equalTo: labels[0].trailingAnchor).isActive = true
        let offset = (yAxisTopLabelTopMargin - yAxisBottomLabelBottomMargin)/2
        labels[1].centerYAnchor.constraint(equalTo: yAxisLabelContainer.centerYAnchor, constant: offset).isActive = true

        labels[2].leadingAnchor.constraint(equalTo: labels[0].leadingAnchor).isActive = true
        labels[2].trailingAnchor.constraint(equalTo: labels[0].trailingAnchor).isActive = true
        labels[2].bottomAnchor.constraint(equalTo: yAxisLabelContainer.bottomAnchor, constant: -yAxisBottomLabelBottomMargin).isActive = true
    }

    private func setupFixedLabels(step: Double) {
        guard yAxisLabelContainer != nil else {
            fatalError("Setup Inconsistency: Attempting to instantiate y axis labels before container view!")
        }
        yAxisLabelContainer.subviews.forEach {
            $0.removeFromSuperview()
        }
        ordinates.removeAll()

        /*
         LABELLING PROCEDURE
         - Place labels at integer multiples of 'step'.
         - The bottom-most label corresponds to the largest multiple of the step
         that is not greater than the minimum value of the data.
         - The top-most label corresponds to the smallest multiple of the step
         that is not smaller than the maximum value of the data.
         */

        // Calculate extreme values of the data:
        guard let min = dataPoints.min(), let max = dataPoints.max() else { return }

        // Calculate upper- and lower-bounding steps:
        self.topLabelValue = step * ceil(max/step)
        self.bottomLabelValue = step * floor(min/step)

        let interval = topLabelValue - bottomLabelValue
        let stepCount = round(interval / step) // (should already be integer - or almost integer, due to rounding errors in the subtraction above)

        let labelValueCount = Int(stepCount) + 1 // (One more marker than gaps)

        var labelValues: [Double] = []
        for index in 0 ..< labelValueCount {
            // Labels are instantiated from top to bottom (in descending value):
            let labelValue = topLabelValue - Double(index) * step
            labelValues.append(labelValue)
        }

        // Create labels, configure and add to hierarchy:
        let labels: [UILabel] = labelValues.map { (value) -> UILabel in
            let l = UILabel(frame: CGRect.zero)
            l.translatesAutoresizingMaskIntoConstraints = false
            l.font = UIFont.systemFont(ofSize: yAxisLabelFontSize)
            l.text = delegate?.lineChartView(self, formattedValue: value) ?? "\(value)"
            l.textColor = yAxisLabelTextColor
            l.textAlignment = .right
            l.sizeToFit()
            l.adjustsFontSizeToFitWidth = true
            yAxisLabelContainer.addSubview(l)
            return l
        }

        // Constrain labels:
        labels[0].topAnchor.constraint(equalTo: yAxisLabelContainer.topAnchor, constant: yAxisTopLabelTopMargin).isActive = true
        labels[0].leftAnchor.constraint(equalTo: yAxisLabelContainer.leftAnchor).isActive = true
        labels[0].rightAnchor.constraint(equalTo: yAxisLabelContainer.rightAnchor, constant: -yAxisLabelRightMargin).isActive = true

        let topCenter = yAxisTopLabelTopMargin + labels[0].frame.height / 2
        let bottomCenter = yAxisLabelContainer.bounds.height - yAxisBottomLabelBottomMargin - (labels.last?.frame.height ?? 0.0)/2
        let deltaY = round((bottomCenter - topCenter) / CGFloat(labels.count - 1))

        for (index, label) in labels.enumerated() {
            if index == 0 {
                continue
            }
            label.leadingAnchor.constraint(equalTo: labels[0].leadingAnchor).isActive = true
            label.trailingAnchor.constraint(equalTo: labels[0].trailingAnchor).isActive = true

            if index == labels.count - 1 {
                break
            }
            // Calculate Y position...

            let centerY = topCenter + CGFloat(index) * deltaY
            let originY = centerY - label.frame.height/2

            label.topAnchor.constraint(equalTo: yAxisLabelContainer.topAnchor, constant: originY).isActive = true
        }
        labels.last?.bottomAnchor.constraint(equalTo: yAxisLabelContainer.bottomAnchor, constant: -yAxisBottomLabelBottomMargin).isActive = true
    }

    private func setupHorizontalAxisLabels() {
        guard xAxisLabelContainer != nil else {
            return
        }
        xAxisLabelContainer.subviews.forEach { $0.removeFromSuperview() }
        abscissas.removeAll()

        let labels: [UILabel] = dataPoints.indices.map { (index) -> UILabel in
            let title = delegate?.lineChartView(self, titleForSampleAt: index) ?? ""
            let l = horizontalAxisLabel(title: title)
            // l.backgroundColor = (index % 2) == 0 ? .red : .green // DEBUG
            xAxisLabelContainer.addSubview(l)
            if index == 0 {
                // first label only, constrained to top (to avoid conflicts if label heights vary slightly)
                l.topAnchor.constraint(equalTo: xAxisLabelContainer.topAnchor, constant: xAxisLabelTopMargin).isActive = true

                // first label only,
            }
            // All labels pinned to bottom:
            l.bottomAnchor.constraint(equalTo: xAxisLabelContainer.bottomAnchor).isActive = true
            return l
        }

        // Distribute label centers evenly
        let totalWidth = self.bounds.width - yAxisLabelMaximumwidth
        let leftCenter = (labels.first?.frame.width ?? 0.0) / 2
        let rightCenter = totalWidth - (labels.last?.frame.width ?? 0.0)/2
        let widthBetweenExtremeCenters = rightCenter - leftCenter
        let step = widthBetweenExtremeCenters / (CGFloat(labels.count) - 1)

        for (index, label) in labels.enumerated() {
            let centerX = leftCenter + CGFloat(index) * step // The center, in points
            abscissas.append(centerX)
            let percentageOfWidth = centerX / totalWidth    //
            let multiplier = 2 * percentageOfWidth     // CenterX multiplier goes from 0 (left) to 2 (right) through 1 (center)

            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: xAxisLabelContainer, attribute: .centerX, multiplier: multiplier, constant: 0.0)
            ])
        }

        if xAxisLabelContainer.subviews.count == 0 {
            xAxisLabelContainer.heightAnchor.constraint(equalToConstant: (xAxisLabelFontSize + xAxisLabelTopMargin)).isActive = true
        }
    }

    private func horizontalAxisLabel(title: String) -> UILabel {
        let l = UILabel(frame: CGRect.zero)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: xAxisLabelFontSize)
        l.text = title
        l.textColor = xAxisLabelTextColor
        l.textAlignment = .center
        l.sizeToFit()
        return l
    }

    private var canvasFrame: CGRect {
        let gridFrame = CGRect(
            x: yAxisLabelContainer.frame.width,
            y: 0,
            width: self.bounds.width - yAxisLabelContainer.frame.width,
            height: self.bounds.height - xAxisLabelContainer.frame.height)
        return gridFrame
    }

    // Must be called after the autolayout constraints of the vertical axis
    // labels have had a chance to update their frames, but before the grid
    // layer is updated.
    private func updateOrdinates() {
        ordinates.removeAll()
        yAxisLabelContainer.layoutIfNeeded() // setNeedsLayout() does NOT work until the next draw update.
        yAxisLabelContainer.subviews.forEach { label in
            ordinates.append(label.center.y)
        }
    }

    private func setupGridLayer() {
        gridLayer?.removeFromSuperlayer()

        self.gridLayer = LineChartGridLayer(
            appearance: appearance.gridAppearance,
            abscissas: abscissas,
            ordinates: ordinates
        )
        gridLayer.frame = canvasFrame
        self.layer.addSublayer(gridLayer)
        gridLayer.setNeedsDisplay()
    }

    private func setupGraphLayer() {
        graphLayer?.removeFromSuperlayer()

        let mappedValues = mapDataValuesToCanvas(dataPoints)
        let xyTuples = zip(abscissas, mappedValues)
        let points: [CGPoint] = xyTuples.map { CGPoint(x: $0.0, y: $0.1 ) }

        self.graphLayer = LineChartGraphLayer(
            appearance: appearance.graphAppearance,
            points: points)
        graphLayer.frame = canvasFrame
        self.layer.addSublayer(graphLayer)
        graphLayer.setNeedsDisplay()
    }

    private func mapDataValuesToCanvas(_ values: [Double]) -> [CGFloat] {

        // Difference between the DATA VALUES displayed on the labels beside the
        // top and bottom horizontal grid lines:
        let dataSpan = topLabelValue - bottomLabelValue

        let topY = yAxisLabelContainer.subviews[0].center.y
        let bottomY = yAxisLabelContainer.subviews.last!.center.y

        // Difference between the Y-POSITIONS of top and bottom horizontal grid lines:
        let canvasSpan = bottomY - topY

        // Conversion ration between the two:
        let scaleFactor = canvasSpan / CGFloat(dataSpan)

        return values.map({ (value) -> CGFloat in
            // How much above the bottom grid line's value:
            let dataOffset = value - bottomLabelValue

            // Convert to canvas coordinate system (distance from bottom-most
            // grid line):
            let canvasOffset = scaleFactor * CGFloat(dataOffset)

            // Composite to obtain Y from origin:
            let y = bottomY - canvasOffset
            return y
        })
    }

    private func mapCanvasLocationToSample(_ location: CGPoint) -> Int {
        // Convert to canvas frame
        let point = CGPoint(x: location.x - canvasFrame.origin.x,
                            y: location.y - canvasFrame.origin.y)
        let x = point.x
        guard let closest = abscissas.enumerated().min(by: { abs($0.1 - x) < abs($1.1 - x)}) else {
            return -1
        }
        return closest.offset
    }
}
