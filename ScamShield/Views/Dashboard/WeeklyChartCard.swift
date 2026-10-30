//
//  WeeklyChartCard.swift
//  ScamShield
//
//  Created by student2 on 2026-10-24.
//

import SwiftUI
import Charts

//a stacked bar for each of the last seven days, split by how the scans turned out
struct WeeklyChartCard: View {

    let breakdown: [DayRiskCount]
    let total: Int
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

            Group {
                if total == 0 {
                    Label("No scans in the last 7 days. Check a link to start your chart.", systemImage: "chart.bar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    chart
                }
            }
            .padding()
            .cardBackground()
        }
    }

    private var chart: some View {
        Chart(breakdown) { item in
            BarMark(
                x: .value("Day", item.day, unit: .day),
                y: .value("Scans", item.count)
            )
            .foregroundStyle(by: .value("Result", item.level.title))
        }
        .chartForegroundStyleScale(
            domain: RiskLevel.allCases.map(\.title),
            range: RiskLevel.allCases.map(\.color)
        )
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3))
        }
        .frame(height: 170)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scans in the last 7 days")
        .accessibilityValue(summary)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let scans = [
        ScanResult(type: .link, input: "a.com", riskLevel: .safe, trustScore: 95),
        ScanResult(type: .link, input: "b.com", riskLevel: .risky, trustScore: 20),
        ScanResult(type: .qr, input: "c.com", riskLevel: .unknown, trustScore: 60,
                   date: calendar.date(byAdding: .day, value: -2, to: today) ?? today)
    ]
    let breakdown = DashboardViewModel.weeklyBreakdown(from: scans, now: Date(), calendar: calendar)

    return WeeklyChartCard(breakdown: breakdown, total: 3, summary: "3 scans in the last 7 days")
        .padding()
        .background(Color(.systemGroupedBackground))
}
