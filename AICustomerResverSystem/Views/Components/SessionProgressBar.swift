
//  SessionProgressBar.swift
//  AICustomerResverSystem

import SwiftUI

struct SessionProgressBar: View {
    let used: Int
    let total: Int
    var showLabel: Bool = true
    var height: CGFloat = 8
    
    private var remaining: Int {
        max(0, total - used)
    }
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }
    
    private var progressColor: Color {
        AppTheme.Colors.sessionColor(percentage: percentage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                HStack {
                    Text("剩餘 \(remaining)/\(total) 堂")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(percentage.formattedPercentage)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(progressColor)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color(.systemGray5))
                        .frame(height: height)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * percentage), height: height)
                        .animation(AppTheme.Animations.smooth, value: percentage)
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - Circular Progress
struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    var size: CGFloat = 60
    
    private var color: Color {
        AppTheme.Colors.sessionColor(percentage: progress)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animations.smooth, value: progress)
            
            Text(progress.formattedPercentage)
                .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        SessionProgressBar(used: 2, total: 10)
        SessionProgressBar(used: 6, total: 10)
        SessionProgressBar(used: 9, total: 10)
        
        HStack(spacing: 20) {
            CircularProgressView(progress: 0.8)
            CircularProgressView(progress: 0.4)
            CircularProgressView(progress: 0.1)
        }
    }
    .padding()
}
