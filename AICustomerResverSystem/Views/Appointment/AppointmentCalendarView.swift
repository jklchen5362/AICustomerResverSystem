//  AppointmentCalendarView.swift
//  AICustomerResverSystem

import SwiftUI
import SwiftData

struct AppointmentCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AppointmentViewModel()
    @Query private var allAppointments: [Appointment]
    
    @State private var showingForm = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control for Day/Week/Month
                Picker("檢視模式", selection: $viewModel.viewMode) {
                    ForEach(CalendarViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color.white)
                
                Divider()
                
                switch viewModel.viewMode {
                case .day:
                    AppointmentDayView(selectedDate: $viewModel.selectedDate, appointments: allAppointments)
                        .padding(.top, AppTheme.Spacing.md)
                case .week:
                    AppointmentWeekView(selectedDate: $viewModel.selectedDate, appointments: allAppointments)
                        .padding(.top, AppTheme.Spacing.md)
                case .month:
                    monthView
                }
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("預約排程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                AppointmentFormView(appointment: nil)
            }
        }
    }
    
    // MARK: - Month view implementation
    private var monthView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Month navigation header
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                
                Spacer()
                
                Text(monthYearString(viewModel.selectedDate))
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.sm)
            
            // Weekday labels
            HStack {
                let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            
            // 6x7 Grid of Days
            let dates = viewModel.monthGridDatesFor(viewModel.selectedDate)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(dates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                    let isToday = date.isToday
                    let isCurrentMonth = Calendar.current.isDate(date, equalTo: viewModel.selectedDate, toGranularity: .month)
                    let dayAppts = allAppointments.filter { Calendar.current.isDate($0.appointmentDate, inSameDayAs: date) && $0.status != .cancelled }
                    
                    VStack(spacing: 4) {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                            .foregroundStyle(isSelected ? .white : (isToday ? AppTheme.Colors.accent : (isCurrentMonth ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isSelected ? AppTheme.Colors.accent : (isToday ? AppTheme.Colors.accent.opacity(0.12) : Color.clear))
                            )
                        
                        // Dots
                        HStack(spacing: 2) {
                            ForEach(Array(dayAppts.prefix(3).enumerated()), id: \.offset) { _, appt in
                                Circle()
                                    .fill(isSelected ? .white : appt.status.color)
                                    .frame(width: 3, height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(AppTheme.Animations.quick) {
                            viewModel.selectedDate = date
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xs)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 3)
            .padding(.horizontal, AppTheme.Spacing.md)
            
            // Bottom list of today's appointments
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("\(viewModel.selectedDate.formattedShortDate) 預約清單")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                
                let dayAppts = viewModel.appointmentsForDate(viewModel.selectedDate, appointments: allAppointments)
                
                if dayAppts.isEmpty {
                    HStack {
                        Spacer()
                        Text("此日尚無登記預約項目")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.vertical, AppTheme.Spacing.lg)
                        Spacer()
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
                    .padding(.horizontal, AppTheme.Spacing.md)
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            ForEach(dayAppts) { appointment in
                                AppointmentCardView(appointment: appointment)
                                    .onTapGesture {
                                        viewModel.viewMode = .day
                                    }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.md)
                    }
                }
            }
        }
    }
    
    private func changeMonth(by value: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: value, to: viewModel.selectedDate) {
            withAnimation(AppTheme.Animations.standard) {
                viewModel.selectedDate = newDate
            }
        }
    }
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
}

#Preview {
    AppointmentCalendarView()
        .modelContainer(for: [Customer.self, Appointment.self, TreatmentPackage.self, Branch.self, Invoice.self, ConsumptionRecord.self, AppNotification.self, UserAccount.self, ChatMessage.self], inMemory: true)
}
