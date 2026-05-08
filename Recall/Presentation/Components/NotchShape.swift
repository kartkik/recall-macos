//
//  NotchShape.swift
//  Recall
//
//  Exact MacBook notch silhouette with camera cutout.
//

import SwiftUI

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
          var path = Path()
          let width = rect.size.width
          let height = rect.size.height
          path.move(to: CGPoint(x: 0, y: 0))
          path.addLine(to: CGPoint(x: 0.99801*width, y: 0))
          path.addLine(to: CGPoint(x: 0.93476*width, y: 0))
          path.addCurve(to: CGPoint(x: 0.91367*width, y: 0.14962*height), control1: CGPoint(x: 0.92311*width, y: 0), control2: CGPoint(x: 0.91367*width, y: 0.06699*height))
          path.addLine(to: CGPoint(x: 0.91367*width, y: 0.74811*height))
          path.addCurve(to: CGPoint(x: 0.87853*width, y: 0.99747*height), control1: CGPoint(x: 0.91367*width, y: 0.88583*height), control2: CGPoint(x: 0.89794*width, y: 0.99747*height))
          path.addLine(to: CGPoint(x: 0.12651*width, y: 0.99747*height))
          path.addCurve(to: CGPoint(x: 0.08434*width, y: 0.69823*height), control1: CGPoint(x: 0.10322*width, y: 0.99747*height), control2: CGPoint(x: 0.08434*width, y: 0.8635*height))
          path.addLine(to: CGPoint(x: 0.08434*width, y: 0.14962*height))
          path.addCurve(to: CGPoint(x: 0.06325*width, y: 0), control1: CGPoint(x: 0.08434*width, y: 0.06699*height), control2: CGPoint(x: 0.0749*width, y: 0))
          path.addLine(to: CGPoint(x: 0, y: 0))
          path.closeSubpath()
          return path
      }
}
