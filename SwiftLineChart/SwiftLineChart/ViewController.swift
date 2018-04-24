//
//  ViewController.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import UIKit

struct DataSet {

    /// The values to display
    let values: [Double]

    let roundingUnit: Double

    /// The distance between markings on the Y axis.
    let step: Double
}

class ViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!

    var dataSets: [DataSet] = []
    var index = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        let set0 = DataSet(
            values: [1, 10, 10, 11, 15],
            roundingUnit: 10,
            step: 2)

        let set1 = DataSet(
            values: [1, 13, 40, -22],
            roundingUnit: 5,
            step: 5)

        dataSets = [set0, set1]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let gridAppearance = LineChartGridAppearance(
            axisAppearance: LineAttributes(lineWidth: 2, strokeColor: .gray50),
            horizontalGridLineAppearance: LineAttributes(lineWidth: 0.5, strokeColor: .gray70),
            verticalGridLineAppearance: LineAttributes(lineWidth: 0.5, strokeColor: .gray70),
            gridFillMode: .alternateRows(primary: .gray80, secondary: .gray90))
            //gridFillMode: .alternateColumns(primary: .gray80, secondary: .gray90))

        let graphappearance = LineChartGraphAppearance(
            lineAttributes: LineAttributes(lineWidth: 4, strokeColor: .solidBlue),
            //fillMode: .none
            fillMode: LineChartGraphFillMode.solid(color: .translucentBlue)
        )

        lineChartView.appearance = LineChartAppearance(
            gridAppearance: gridAppearance,
            graphAppearance: graphappearance,
            highlightMode: .abscissa,
            dotRadius: 10.0,
            dotColor: .gray50)

        lineChartView.xAxisLabelTextColor = UIColor.darkText
        lineChartView.yAxisLabelTextColor = UIColor.darkText

        //lineChartView.labellingMode = .minMaxAverage
        let set0 = dataSets[0]

        lineChartView.labellingMode = .fixed(step: set0.step)
        lineChartView.dataPoints = set0.values
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - Actions

    @IBAction func swapData(_ sender: UIButton) {
        index = (index + 1) % 2

        let set = dataSets[index]

        lineChartView.labellingMode = .minMaxAverage(roundingUnit: set.step)
        //lineChartView.labellingMode = .fixed(step: set.step)
        lineChartView.dataPoints = set.values
    }
}

// MARK: - LineChartViewDelegate

extension ViewController: LineChartViewDelegate {
    func lineChartView(_ lineChartView: LineChartView, titleForSampleAt index: Int) -> String? {
        //let set = dataSets[self.index]
        //if index == 0 || index == set.values.count - 1 {
            return "Sample \(index)"
        //} else {
        //    return nil
        //}
    }

    func lineChartView(_ lineChartView: LineChartView, formattedValue value: Double) -> String {
        return "\(value)"
    }

    func lineChartView(_ lineChartView: LineChartView, shouldhighlightSampleAt index: Int) -> Bool {
        return true
    }
}

extension CGColor {
    static let gray90 = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1).cgColor
    static let gray80 = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1).cgColor
    static let gray70 = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1).cgColor
    static let gray60 = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1).cgColor
    static let gray50 = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1).cgColor
    static let orange = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1).cgColor

    static let solidBlue = UIColor.blue.cgColor
    static let translucentBlue = UIColor(red: 0, green: 0, blue: 1, alpha: 0.25).cgColor
}
