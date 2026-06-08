////
////  HorizontalCalendarView.swift
////  Recall
////
////  Created by twixx  on 03/06/26.
////
//

 import SwiftUI


struct HorizontalCalendarView: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)?
    
    private let calendar = Calendar.current
    
    private var dates: [Date] {
        let today = Date()
        return (-180...180).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday   = calendar.isDateInToday(date)
                        
                        DayChipView(
                            date: date,
                            isSelected: isSelected,
                            isToday: isToday
                        )
                        .id(date)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedDate = date
                                onDateSelected?(date)
                                proxy.scrollTo(date, anchor: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selectedDate, anchor: .center)
                }
            }
        }
    }
    
    
    private struct DayChipView : View {
        
        
        let date : Date
        let isSelected : Bool
        let isToday : Bool
        
        private let calender = Calendar.current
        var body : some View {
            VStack(spacing : 2){
                Text(dayAbbrev)
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.75): .white.opacity(0.22))
                
                Text("\(calender.component(.day, from: date))")
                    .font(.system(size: 7, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.black : (isToday ? Color.white : Color.white.opacity(0.38)))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.white : (isToday ? Color.white.opacity(12) : Color.clear))
                    )
                
                
            }.contentShape(Rectangle())
        }
        
        private var dayAbbrev : String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EE"
            return formatter.string(from: date).uppercased()
        }
    }
}
