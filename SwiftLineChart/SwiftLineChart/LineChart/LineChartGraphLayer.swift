//
//  LineChartGraphLayer.swift
//  SwiftLineChart
//
//  Created by Nicolás Miari on 2018/04/24.
//  Copyright © 2018 Nicolás Miari. All rights reserved.
//

import UIKit

internal class LineChartGraphLayer: CALayer {

    public let appearance: LineChartGraphAppearance
    private let points: [CGPoint]

    private var highlightedIndex: Int?

    init(appearance: LineChartGraphAppearance, points: [CGPoint]) {
        self.appearance = appearance
        self.points = points
        super.init()

        contentsScale = UIScreen.main.scale
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in ctx: CGContext) {

        switch appearance.fillMode {
        case .none:
            break

        case .solid(let color):
            var extendedPoints = points

            let left = CGPoint(x: points[0].x, y: 2*bounds.height)
            let right = CGPoint(x: points.last!.x, y: 2*bounds.height)

            extendedPoints.insert(left, at: 0)
            extendedPoints.append(right)

            ctx.beginPath()
            ctx.addLines(between: extendedPoints)
            ctx.closePath()
            ctx.setFillColor(color)
            ctx.drawPath(using: .fill)

        case .gradient:
            break // unsupported yet (maybe one day...)
        }

        ctx.beginPath()
        ctx.setLineWidth(appearance.lineAttributes.lineWidth)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(appearance.lineAttributes.strokeColor)
        ctx.addLines(between: points)
        ctx.drawPath(using: .stroke)

        if let highlighted = highlightedIndex, highlighted < points.count {
            let point = points[highlighted]

            ctx.beginPath()
            ctx.move(to: CGPoint(x: point.x, y: bounds.height))
            ctx.addLine(to: CGPoint(x: point.x, y: 0))
            ctx.closePath()

            ctx.setStrokeColor(UIColor.yellow.cgColor)
            ctx.setLineWidth(2)
            ctx.drawPath(using: .stroke)

            ctx.beginPath()
            let topLeft = CGPoint(x: point.x - 10, y: point.y - 10)
            let rect = CGRect(origin: topLeft, size: CGSize(width: 20, height: 20))
            ctx.addEllipse(in: rect)
            ctx.setFillColor(UIColor.yellow.cgColor)
            ctx.drawPath(using: .fill)
        }
    }

    func highlight(_ index: Int?) {
        highlightedIndex = index
        setNeedsDisplay()
    }
}
