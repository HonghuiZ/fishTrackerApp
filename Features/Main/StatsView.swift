import SwiftUI
import Charts

struct StatsView: View {
    let photos: [PhotoMetadata]
    
    // Compute monthly counts
    private var monthlyData: [(month: String, count: Int)] {
        let calendar = Calendar.current
        var monthlyCounts: [Int: Int] = [:]  // [month number: count]
        
        // Count photos for each month
        for photo in photos {
            let month = calendar.component(.month, from: photo.timestamp)
            monthlyCounts[month, default: 0] += 1
        }
        
        // Create array of tuples with month names
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        return (1...12).map { month in
            let date = calendar.date(from: DateComponents(month: month))!
            let monthName = dateFormatter.string(from: date)
            return (month: monthName, count: monthlyCounts[month] ?? 0)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Monthly Fish Catches")
                    .font(.headline)
                    .padding(.horizontal)
                
                Chart(monthlyData, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 300)
                .padding()
                
                // Additional statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        StatBox(
                            title: "Total Catches",
                            value: "\(photos.count)"
                        )
                        
                        StatBox(
                            title: "Best Month",
                            value: monthlyData.max(by: { $0.count < $1.count })?.month ?? "-"
                        )
                        
                        StatBox(
                            title: "Unique Species",
                            value: "\(Set(photos.map { $0.species }).count)"
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top) // Add padding to align with other views
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 