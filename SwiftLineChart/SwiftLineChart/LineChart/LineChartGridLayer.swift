//
//  LineChartGridLayer.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import UIKit

internal class LineChartGridLayer: CALayer {

    private(set) public var appearance: LineChartGridAppearance
    private(set) public var abscissas: [CGFloat]
    private(set) public var ordinates: [CGFloat]

    init(appearance: LineChartGridAppearance, abscissas: [CGFloat], ordinates: [CGFloat]) {
        self.appearance = appearance
        self.abscissas = abscissas.map { round($0) }
        self.ordinates = ordinates.map { round($0) }

        super.init()
        contentsScale = UIScreen.main.scale
        self.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in ctx: CGContext) {
        drawFill(in: ctx)
        drawLines(in: ctx)
    }

    private func drawFill(in ctx: CGContext) {
        switch appearance.gridFillMode {
        case .solid(let color):
            ctx.beginPath()
            ctx.addRect(self.bounds)
            ctx.closePath()

            ctx.setFillColor(color)
            ctx.drawPath(using: .fill)

        case .alternateRows(let primary, let secondary):
            var yValues = ordinates
            if yValues[0] != 0.0 {
                yValues.insert(0, at: 0)
            }
            if yValues[yValues.count - 1] != self.bounds.height {
                yValues.append(self.bounds.height)
            }

            for index in 0 ..< yValues.count - 1 {
                let thisValue = yValues[index]
                let nextValue = yValues[index + 1]
                let rect = CGRect(x: 0, y: thisValue, width: self.bounds.width, height: nextValue - thisValue)
                ctx.addRect(rect)

                if (index % 2) == 0 {
                    ctx.setFillColor(primary)
                } else {
                    ctx.setFillColor(secondary)
                }
                ctx.drawPath(using: .fill)
            }

        case .alternateColumns(let primary, let secondary):
            var xValues = abscissas
            if xValues[0] != 0.0 {
                xValues.insert(0, at: 0)
            }
            if xValues.last != self.bounds.width {
                xValues.append(self.bounds.width)
            }

            for index in 0 ..< xValues.count - 1 {
                let thisValue = xValues[index]
                let nextValue = xValues[index + 1]
                let rect = CGRect(x: thisValue, y: 0, width: nextValue - thisValue, height: self.bounds.height)
                ctx.addRect(rect)

                if (index % 2) == 0 {
                    ctx.setFillColor(primary)
                } else {
                    ctx.setFillColor(secondary)
                }
                ctx.drawPath(using: .fill)
            }
        }
    }

    private func drawLines(in ctx: CGContext) {
        // Axes
        ctx.beginPath()
        ctx.move(to: CGPoint.zero)
        ctx.addLine(to: CGPoint(x: 0, y: self.bounds.height))
        ctx.addLine(to: CGPoint(x: self.bounds.width, y: self.bounds.height))

        ctx.setLineWidth(appearance.axisAppearance.lineWidth)
        ctx.setStrokeColor(appearance.axisAppearance.strokeColor)

        ctx.drawPath(using: .stroke)

        if abscissas.count > 0 {
            let height = self.bounds.height
            ctx.beginPath()
            for abscissa in abscissas {
                ctx.move(to: CGPoint(x: abscissa, y: 0))
                ctx.addLine(to: CGPoint(x: abscissa, y: height))
            }
            ctx.setLineWidth(appearance.verticalGridLineAppearance.lineWidth)
            ctx.setStrokeColor(appearance.verticalGridLineAppearance.strokeColor)
            ctx.drawPath(using: .stroke)
        }

        if ordinates.count > 0 {
            let width = self.bounds.width

            ctx.beginPath()
            for ordinate in ordinates {
                ctx.move(to: CGPoint(x: 0, y: ordinate))
                ctx.addLine(to: CGPoint(x: width, y: ordinate))
            }
            ctx.setLineWidth(appearance.horizontalGridLineAppearance.lineWidth)
            ctx.setStrokeColor(appearance.horizontalGridLineAppearance.strokeColor)
            ctx.drawPath(using: .stroke)
        }
    }
}
