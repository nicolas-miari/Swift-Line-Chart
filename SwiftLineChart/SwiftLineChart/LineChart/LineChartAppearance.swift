//
//  LineChartAppearance.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import CoreGraphics

// MARK: - Grid

public struct LineAttributes {
    let lineWidth: CGFloat
    let strokeColor: CGColor
}

public enum LineChartGridFillMode {
    case solid(color: CGColor)
    case alternateRows(primary: CGColor, secondary: CGColor)
    case alternateColumns(primary: CGColor, secondary: CGColor)
}

public struct LineChartGridAppearance {
    let axisAppearance: LineAttributes
    let horizontalGridLineAppearance: LineAttributes
    let verticalGridLineAppearance: LineAttributes
    let gridFillMode: LineChartGridFillMode
}

// MARK: - Graph

public enum LineChartGraphFillMode {
    case none // line only

    case solid(color: CGColor)

    case gradient(CGGradient) // vertical or horizontal
}

/// To draw fill only (no stroke), set `fillMode` to .solid or gradient, but
/// also set `lineAttributes.lineWidth` to `0`.
public struct LineChartGraphAppearance {
    let lineAttributes: LineAttributes
    let fillMode: LineChartGraphFillMode
}

// MARK: - Highlighting

public enum LineChartHighlightMode {

    /// Vertical column spanned by the abscissas midway between the selected
    /// sample and each of its immediate neighbours.
    case column

    /// Vertical line passing throught the selected value
    case abscissa
}

// MARK: - Aggregate Configuration

public struct LineChartAppearance {

    // Grid (background)
    let gridAppearance: LineChartGridAppearance

    // Graph (foreground)
    let graphAppearance: LineChartGraphAppearance

    // Value Selection (highlighting)

    let highlightMode: LineChartHighlightMode
    let dotRadius: CGFloat
    let dotColor: CGColor
}
