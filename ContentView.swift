//
//  ContentView.swift
//  SplitBill
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI

struct ContentView: View {
    @State private var totalAmount = ""
    @State private var tipPercentage = 10.0
    @State private var numberOfPeople = 2
    @State private var showHistory = false
    
    var calculatedTotal: Double {
        guard let amount = Double(totalAmount) else { return 0 }
        return amount + (amount * tipPercentage / 100)
    }
    
    var perPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return calculatedTotal / Double(numberOfPeople)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 金额输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("总金额")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $totalAmount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 36, weight: .bold))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 小费比例
                VStack(alignment: .leading, spacing: 12) {
                    Text("小费比例")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach([0, 10, 15, 20], id: \.self) { percent in
                            Button(action: { tipPercentage = Double(percent) }) {
                                Text("\(percent)%")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(tipPercentage == Double(percent) ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(tipPercentage == Double(percent) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // 人数选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("人数")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button(action: { if numberOfPeople > 1 { numberOfPeople -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("\(numberOfPeople) 人")
                            .font(.system(size: 32, weight: .bold))
                        
                        Spacer()
                        
                        Button(action: { numberOfPeople += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider()
                
                // 结果展示
                VStack(spacing: 16) {
                    ResultRow(title: "总计（含小费）", value: calculatedTotal, bold: true)
                    ResultRow(title: "每人应付", value: perPerson, bold: true, large: true)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("账单分割")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
        }
    }
}

struct ResultRow: View {
    let title: String
    let value: Double
    var bold: Bool = false
    var large: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(bold ? .headline : .body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("¥\(value, specifier: large ? "%.2f" : "%.2f")")
                .font(.system(size: large ? 36 : 24, weight: bold ? .bold : .regular))
                .foregroundColor(.primary)
        }
    }
}

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Text("历史记录功能待实现...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
