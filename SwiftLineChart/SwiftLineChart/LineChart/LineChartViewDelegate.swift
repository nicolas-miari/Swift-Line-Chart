//
//  LineChartViewDelegate.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import Foundation

@objc public protocol LineChartViewDelegate: AnyObject {

    /// Labelling for the marks along the x axis. Return nil if the sample
    /// specified does not require a label.
    func lineChartView(_ lineChartView: LineChartView, titleForSampleAt index: Int) -> String?

    /// String formatting of the samples' attained values. Used for both the y
    /// axis labels and highlighting of graph points.
    func lineChartView(_ lineChartView: LineChartView, formattedValue value: Double) -> String

    ///
    func lineChartView(_ lineChartView: LineChartView, shouldhighlightSampleAt index: Int) -> Bool
}
