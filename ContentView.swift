//
//  ContentView.swift
//  SplitBill
//
//  Created by AI Agent on 2026-03-27.
//

import SwiftUI

struct ContentView: View {
    @State private var subtotalText = ""
    @State private var taxText = ""
    @State private var note = ""
    @State private var tipPercentage = 15
    @State private var peopleCount = 2
    @State private var roundingMode: SplitRoundingMode = .exact
    @State private var history = SplitHistoryStore.load()
    @State private var showHistory = false
    @State private var copyFeedback = ""

    private let tipPresets = [0, 10, 12, 15, 18, 20]

    private var subtotal: Decimal {
        CurrencyParsing.decimal(from: subtotalText) ?? 0
    }

    private var tax: Decimal {
        CurrencyParsing.decimal(from: taxText) ?? 0
    }

    private var calculation: SplitCalculation? {
        guard subtotal > 0 else { return nil }

        return SplitCalculation(
            subtotal: subtotal,
            tax: tax,
            tipPercentage: tipPercentage,
            peopleCount: peopleCount,
            roundingMode: roundingMode
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    amountSection
                    splitSection
                    resultSection
                    settlementSection
                    saveSection
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.91),
                        Color(red: 0.88, green: 0.93, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("SplitBill")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("清空", role: .destructive, action: resetInputs)
                        .disabled(!hasAnyInput)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                    .accessibilityLabel("查看历史记录")
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(
                    records: history,
                    onSelect: { record in
                        apply(record)
                        showHistory = false
                    },
                    onDelete: deleteRecords
                )
            }
            .safeAreaInset(edge: .bottom) {
                if !copyFeedback.isEmpty {
                    Text(copyFeedback)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.78))
                        )
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("离线分账，不依赖注册或网络。")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            Text(calculation.map { CurrencyFormatting.currency($0.perPerson) } ?? CurrencyFormatting.currency(0))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("每人应付")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            if let calculation {
                Text(calculation.roundingExplanation)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.78))
            } else {
                Text("输入账单金额后即可得到含税、小费和分摊结果。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.29, blue: 0.32),
                            Color(red: 0.15, green: 0.49, blue: 0.47)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var amountSection: some View {
        cardSection("账单信息", subtitle: "支持小费、税费和备注，保留完整上下文。") {
            VStack(spacing: 14) {
                MoneyInputRow(title: "餐前金额", placeholder: "0.00", text: $subtotalText)
                MoneyInputRow(title: "税费", placeholder: "0.00", text: $taxText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextField("例如：周五晚餐 / 公司聚餐", text: $note)
                        .textInputAutocapitalization(.sentences)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var splitSection: some View {
        cardSection("分摊设置", subtitle: "常用小费预设 + 四舍五入策略，适合餐厅结账场景。") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("小费比例")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                        ForEach(tipPresets, id: \.self) { preset in
                            Button {
                                tipPercentage = preset
                            } label: {
                                Text("\(preset)%")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(SelectableCapsuleStyle(isSelected: preset == tipPercentage))
                        }
                    }

                    HStack {
                        Text("自定义")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(tipPercentage) },
                                set: { tipPercentage = Int($0.rounded()) }
                            ),
                            in: 0 ... 30,
                            step: 1
                        )

                        Text("\(tipPercentage)%")
                            .font(.headline.monospacedDigit())
                            .frame(width: 54, alignment: .trailing)
                    }
                }

                Stepper(value: $peopleCount, in: 2 ... 20) {
                    HStack {
                        Text("分摊人数")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(peopleCount) 人")
                            .font(.headline.monospacedDigit())
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("取整策略")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("取整策略", selection: $roundingMode) {
                        ForEach(SplitRoundingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let calculation {
            cardSection("结果明细", subtitle: "让用户知道数字是怎么来的，降低信任成本。") {
                VStack(spacing: 14) {
                    ResultLine(title: "餐前金额", value: calculation.subtotal)
                    ResultLine(title: "税费", value: calculation.tax)
                    ResultLine(title: "小费", value: calculation.tipAmount)
                    Divider()
                    ResultLine(title: "总金额", value: calculation.total, emphasis: .strong)
                    ResultLine(title: "每人应付", value: calculation.perPerson, emphasis: .hero)

                    if calculation.adjustment != 0 {
                        Divider()
                        Text(calculation.adjustmentNote)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: copySummary) {
                        Label("复制分账摘要", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryActionStyle())
                }
            }
        } else {
            cardSection("结果明细", subtitle: "输入有效金额后显示。") {
                EmptyStateView(
                    title: "等待账单金额",
                    systemImage: "list.clipboard",
                    message: "当前不会保存空白记录，也不会展示误导性的 0 元结果。"
                )
            }
        }
    }

    @ViewBuilder
    private var settlementSection: some View {
        if let calculation {
            cardSection("收款方案", subtitle: "不是只给平均数，而是直接告诉你每个人该转多少。") {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(calculation.recommendedShares) { share in
                        HStack(alignment: .top, spacing: 12) {
                            Text(share.personLabel)
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 58, alignment: .leading)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(CurrencyFormatting.currency(share.amount))
                                    .font(.headline.monospacedDigit())
                                Text(share.note)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if share.isAdjustmentCarrier {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(Color(red: 0.87, green: 0.38, blue: 0.21))
                                    .accessibilityLabel("承担补差")
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text(calculation.settlementFootnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var saveSection: some View {
        VStack(spacing: 12) {
            Button(action: saveCurrentRecord) {
                Label("保存这次分账", systemImage: "tray.and.arrow.down.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionStyle())
            .disabled(calculation == nil)

            Text("历史记录仅保存在本机，用于快速复用相似场景。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var hasAnyInput: Bool {
        !subtotalText.isEmpty || !taxText.isEmpty || !note.isEmpty || tipPercentage != 15 || peopleCount != 2 || roundingMode != .exact
    }

    private func saveCurrentRecord() {
        guard let calculation else { return }

        let record = SplitRecord(
            timestamp: .now,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            subtotal: calculation.subtotal,
            tax: calculation.tax,
            tipPercentage: calculation.tipPercentage,
            peopleCount: calculation.peopleCount,
            roundingMode: calculation.roundingMode,
            total: calculation.total,
            perPerson: calculation.perPerson
        )

        history = SplitHistoryStore.insert(record, into: history)
        SplitHistoryStore.save(history)
    }

    private func deleteRecords(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        SplitHistoryStore.save(history)
    }

    private func apply(_ record: SplitRecord) {
        subtotalText = CurrencyFormatting.plainNumber(record.subtotal)
        taxText = CurrencyFormatting.plainNumber(record.tax)
        note = record.note
        tipPercentage = record.tipPercentage
        peopleCount = record.peopleCount
        roundingMode = record.roundingMode
    }

    private func resetInputs() {
        subtotalText = ""
        taxText = ""
        note = ""
        tipPercentage = 15
        peopleCount = 2
        roundingMode = .exact
    }

    private func copySummary() {
        guard let calculation else { return }

        UIPasteboard.general.string = calculation.shareSummary(note: note)
        withAnimation(.easeOut(duration: 0.2)) {
            copyFeedback = "分账摘要已复制"
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) {
                    copyFeedback = ""
                }
            }
        }
    }

    private func cardSection<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct MoneyInputRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct ResultLine: View {
    enum Emphasis {
        case regular
        case strong
        case hero
    }

    let title: String
    let value: Decimal
    var emphasis: Emphasis = .regular

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatting.currency(value))
                .font(font)
        }
    }

    private var font: Font {
        switch emphasis {
        case .regular:
            return .body.monospacedDigit()
        case .strong:
            return .headline.monospacedDigit()
        case .hero:
            return .system(size: 30, weight: .bold, design: .rounded).monospacedDigit()
        }
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let records: [SplitRecord]
    let onSelect: (SplitRecord) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        NavigationStack {
            List {
                if records.isEmpty {
                    EmptyStateView(
                        title: "还没有保存记录",
                        systemImage: "clock.badge.xmark",
                        message: "先完成一笔分账，再保存到本地历史。"
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(records) { record in
                        Button {
                            onSelect(record)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(record.note.isEmpty ? "未命名账单" : record.note)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(CurrencyFormatting.currency(record.perPerson))
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(.primary)
                                }

                                Text(record.summaryLine)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete(perform: onDelete)
                }
            }
            .navigationTitle("历史记录")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SelectableCapsuleStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color(red: 0.13, green: 0.45, blue: 0.44) : Color.white.opacity(configuration.isPressed ? 0.55 : 0.78))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PrimaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.87, green: 0.38, blue: 0.21))
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SecondaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .foregroundStyle(Color(red: 0.08, green: 0.29, blue: 0.32))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(red: 0.08, green: 0.29, blue: 0.32).opacity(0.22), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(configuration.isPressed ? 0.45 : 0.62))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

#Preview {
    ContentView()
}

struct SplitCalculation {
    let subtotal: Decimal
    let tax: Decimal
    let tipPercentage: Int
    let peopleCount: Int
    let roundingMode: SplitRoundingMode

    var tipAmount: Decimal {
        (subtotal * Decimal(tipPercentage) / 100).rounded(scale: 2)
    }

    var total: Decimal {
        (subtotal + tax + tipAmount).rounded(scale: 2)
    }

    var exactPerPerson: Decimal {
        (total / Decimal(peopleCount)).rounded(scale: 2)
    }

    var perPerson: Decimal {
        switch roundingMode {
        case .exact:
            return exactPerPerson
        case .nearestWhole:
            return exactPerPerson.rounded(scale: 0, mode: .plain)
        case .roundUpWhole:
            return exactPerPerson.rounded(scale: 0, mode: .up)
        }
    }

    var adjustment: Decimal {
        ((perPerson * Decimal(peopleCount)) - total).rounded(scale: 2)
    }

    var roundingExplanation: String {
        switch roundingMode {
        case .exact:
            return "按精确金额平分，适合电子支付。"
        case .nearestWhole:
            return "按最接近整数取整，方便口头报数。"
        case .roundUpWhole:
            return "向上取整，每个人都给整额现金时更省心。"
        }
    }

    var adjustmentNote: String {
        if adjustment == 0 {
            return "无需补差。"
        }

        let formatted = CurrencyFormatting.currency(adjustment.magnitude)
        if adjustment > 0 {
            return "按当前取整策略，合计会多出 \(formatted)。可作为零钱或额外小费。"
        } else {
            return "按当前取整策略，合计会少 \(formatted)。建议由其中一人补齐差额。"
        }
    }

    var recommendedShares: [SettlementShare] {
        let baseShare: Decimal

        switch roundingMode {
        case .exact:
            baseShare = exactPerPerson
        case .nearestWhole:
            baseShare = exactPerPerson.rounded(scale: 0, mode: .plain)
        case .roundUpWhole:
            baseShare = exactPerPerson.rounded(scale: 0, mode: .up)
        }

        let leadingCount = max(peopleCount - 1, 0)
        var shares = (0 ..< leadingCount).map { index in
            SettlementShare(
                personIndex: index + 1,
                amount: baseShare,
                note: roundingMode == .exact ? "标准均分金额" : "按当前取整策略付款",
                isAdjustmentCarrier: false
            )
        }

        let remaining = (total - (baseShare * Decimal(leadingCount))).rounded(scale: 2)
        let carrierNote: String
        if roundingMode == .exact {
            carrierNote = "标准均分金额"
        } else if remaining == baseShare {
            carrierNote = "与其他人一致，无需补差"
        } else if remaining > baseShare {
            carrierNote = "承担补差，确保合计准确"
        } else {
            carrierNote = "少付一点，用来抵消取整误差"
        }

        shares.append(
            SettlementShare(
                personIndex: peopleCount,
                amount: remaining,
                note: carrierNote,
                isAdjustmentCarrier: roundingMode != .exact
            )
        )

        return shares
    }

    var settlementFootnote: String {
        if roundingMode == .exact {
            return "精确模式下，每个人支付相同金额。"
        }

        return "已自动把取整误差压到 1 人身上，方便现场直接收款。"
    }

    func shareSummary(note: String) -> String {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedNote.isEmpty ? "SplitBill 分账摘要" : "\(trimmedNote) 分账摘要"
        let lines = recommendedShares.map { "\($0.personLabel)：\(CurrencyFormatting.currency($0.amount))（\($0.note)）" }

        return ([title,
                 "总金额：\(CurrencyFormatting.currency(total))",
                 "税费：\(CurrencyFormatting.currency(tax))",
                 "小费：\(tipPercentage)%",
                 "人数：\(peopleCount)",
                 "策略：\(roundingMode.title)"] + lines).joined(separator: "\n")
    }
}

struct SettlementShare: Identifiable {
    let personIndex: Int
    let amount: Decimal
    let note: String
    let isAdjustmentCarrier: Bool

    var id: Int { personIndex }

    var personLabel: String {
        "成员\(personIndex)"
    }
}

enum SplitRoundingMode: String, CaseIterable, Codable, Identifiable {
    case exact
    case nearestWhole
    case roundUpWhole

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exact:
            return "精确"
        case .nearestWhole:
            return "四舍五入"
        case .roundUpWhole:
            return "向上取整"
        }
    }
}

struct SplitRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let note: String
    let subtotal: Decimal
    let tax: Decimal
    let tipPercentage: Int
    let peopleCount: Int
    let roundingMode: SplitRoundingMode
    let total: Decimal
    let perPerson: Decimal

    init(
        id: UUID = UUID(),
        timestamp: Date,
        note: String,
        subtotal: Decimal,
        tax: Decimal,
        tipPercentage: Int,
        peopleCount: Int,
        roundingMode: SplitRoundingMode,
        total: Decimal,
        perPerson: Decimal
    ) {
        self.id = id
        self.timestamp = timestamp
        self.note = note
        self.subtotal = subtotal
        self.tax = tax
        self.tipPercentage = tipPercentage
        self.peopleCount = peopleCount
        self.roundingMode = roundingMode
        self.total = total
        self.perPerson = perPerson
    }

    var summaryLine: String {
        "\(peopleCount) 人 · 小费 \(tipPercentage)% · 总计 \(CurrencyFormatting.currency(total))"
    }
}

enum SplitHistoryStore {
    private static let storageKey = "split_records_v1"
    private static let limit = 20

    static func load() -> [SplitRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let records = try? JSONDecoder().decode([SplitRecord].self, from: data)
        else {
            return []
        }

        return records
    }

    static func save(_ records: [SplitRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func insert(_ record: SplitRecord, into records: [SplitRecord]) -> [SplitRecord] {
        Array(([record] + records).prefix(limit))
    }
}

enum CurrencyParsing {
    static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current

        if let number = formatter.number(from: trimmed) {
            return number.decimalValue
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }
}

enum CurrencyFormatting {
    static func currency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? number.stringValue
    }

    static func plainNumber(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? number.stringValue
    }
}

private extension Decimal {
    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, mode)
        return result
    }

    var magnitude: Decimal {
        self < 0 ? -self : self
    }
}
