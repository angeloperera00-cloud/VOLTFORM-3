import SwiftUI
import SwiftData
import PhotosUI
import Vision
import UIKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var manager = OnboardingStateManager()

    var body: some View {
        ZStack {
            Color.voltOffWhite.ignoresSafeArea()

            Group {
                switch manager.step {
                case 1: WelcomeStep(manager: manager)
                case 2: GoalStep(manager: manager)
                case 3: LevelStep(manager: manager)
                case 4: TrainingDaysStep(manager: manager)
                case 5: AboutYouStep(manager: manager)
                case 6: DreamBodyStep(manager: manager)
                case 7: RecoverySetupStep(manager: manager)
                case 8: OnboardingScanStep(manager: manager)
                case 9: CreatingPlanStep(manager: manager, context: context)
                default: AllSetStep(context: context)
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }
    }
}

// MARK: - Shared header

private struct StepHeader: View {
    let manager: OnboardingStateManager
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if manager.step > 1 {
                    Button { manager.back() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.voltTextDark)
                            .frame(width: 38, height: 38)
                            .background(Color.voltCard)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Text("\(manager.step) of 7")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            }
            .padding(.bottom, 12)

            // Progress
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.voltSoftGray)
                    Capsule()
                        .fill(Color.voltLime)
                        .frame(width: geo.size.width * CGFloat(manager.step) / 7)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 20)

            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Color.voltTextMuted)
        }
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    let manager: OnboardingStateManager

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Full-bleed hero
            GeometryReader { geo in
                Image("OnboardingHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Top scrim for headline legibility
            LinearGradient(
                colors: [.black.opacity(0.75), .black.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Your\nAI Fitness\nCompanion")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .padding(.top, 2)

                Text("Personalized workouts, smart meal plans, and real time insights all powered by AI")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineSpacing(3)
                    .padding(.top, 16)
                    .padding(.trailing, 48)

                Spacer()

                PrimaryButton(title: "Get Started", icon: "play.fill", style: .lime) { manager.next() }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Step 2: Goal

private struct GoalStep: View {
    @Bindable var manager: OnboardingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "What's your main goal?", subtitle: "Your plan and recovery targets adapt to this")

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        OptionCard(title: goal.rawValue, subtitle: goal.subtitle, icon: goal.icon, isSelected: manager.goal == goal) {
                            manager.goal = goal
                        }
                    }
                }
                .padding(.top, 24)
            }

            PrimaryButton(title: "Continue", style: .lime, isDisabled: manager.goal == nil) { manager.next() }
        }
        .padding(24)
    }
}

// MARK: - Step 3: Fitness level

private struct LevelStep: View {
    @Bindable var manager: OnboardingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "Your fitness level", subtitle: "Recovery time is personal beginners need more of it")

            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    OptionCard(title: level.rawValue, subtitle: level.subtitle, icon: level.icon, isSelected: manager.level == level) {
                        manager.level = level
                    }
                }
            }
            .padding(.top, 24)

            Spacer()
            PrimaryButton(title: "Continue", style: .lime, isDisabled: manager.level == nil) { manager.next() }
        }
        .padding(24)
    }
}

// MARK: - Step 4: Training days

private struct TrainingDaysStep: View {
    @Bindable var manager: OnboardingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "How often can you train?", subtitle: "We'll build your weekly split around this")

            VStack(spacing: 12) {
                ForEach(3...6, id: \.self) { days in
                    OptionCard(
                        title: "\(days) days a week",
                        subtitle: AIProgramEngine.splitSummary(for: days),
                        icon: "calendar",
                        isSelected: manager.trainingDays == days
                    ) {
                        manager.trainingDays = days
                    }
                }
            }
            .padding(.top, 24)

            Spacer()
            PrimaryButton(title: "Continue", style: .lime, isDisabled: manager.trainingDays == nil) { manager.next() }
        }
        .padding(24)
    }
}

// MARK: - Step 5: About you

private struct AboutYouStep: View {
    @Bindable var manager: OnboardingStateManager
    @State private var isImporting = false
    @State private var importMessage: String?
    @State private var activeField: PickerField?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "About you", subtitle: "Used to estimate your body composition and recovery")

            Button {
                importFromHealth()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isImporting ? "Importing..." : "Import from Apple Health")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    if isImporting {
                        ProgressView()
                            .tint(Color.voltTextDark)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(Color.voltTextDark)
                .padding(14)
                .background(Color.voltCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isImporting)
            .padding(.top, 20)

            if let importMessage {
                Text(importMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.voltLimeDeep)
                    .padding(.top, 8)
            }

            VStack(spacing: 14) {
                fieldRow(field: .age, label: "Age", text: manager.age, unit: "years")
                fieldRow(field: .height, label: "Height", text: manager.height, unit: "cm")
                fieldRow(field: .weight, label: "Weight", text: manager.weight, unit: "kg")

                HStack(spacing: 10) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button {
                            manager.gender = gender
                        } label: {
                            Text(gender.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(manager.gender == gender ? Color.voltLime : Color.voltCard)
                                .foregroundStyle(manager.gender == gender ? Color.voltOnLime : Color.voltTextDark)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 20)

            Spacer()
            PrimaryButton(title: "Continue", style: .lime) { manager.next() }
        }
        .padding(24)
        .sheet(item: $activeField) { field in
            NumberPickerSheet(field: field, manager: manager)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }

    private func importFromHealth() {
        guard HealthKitService.isAvailable else {
            importMessage = "Health isn't available on this device"
            return
        }
        isImporting = true
        importMessage = nil
        Task {
            let imported = await HealthKitService.importProfile()
            await MainActor.run {
                isImporting = false
                var fields: [String] = []
                if let age = imported.age { manager.age = "\(age)"; fields.append("age") }
                if let height = imported.heightCm { manager.height = "\(Int(height.rounded()))"; fields.append("height") }
                if let weight = imported.weightKg { manager.weight = String(format: "%.1f", weight); fields.append("weight") }
                if let gender = imported.gender { manager.gender = gender; fields.append("gender") }
                importMessage = fields.isEmpty
                    ? "No Health data found you can still enter these manually."
                    : "Imported \(fields.joined(separator: ", ")) from Health."
            }
        }
    }

    private func fieldRow(field: PickerField, label: String, text: String, unit: String) -> some View {
        Button {
            activeField = field
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Text(text.isEmpty ? "–" : text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                Text(unit)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
                    .frame(width: 44, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
            }
            .padding(16)
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scroll-wheel picker for Age / Height / Weight

private enum PickerField: Identifiable {
    case age, height, weight
    var id: Self { self }

    var title: String {
        switch self {
        case .age: return "Age"
        case .height: return "Height"
        case .weight: return "Weight"
        }
    }
    var unit: String {
        switch self {
        case .age: return "years"
        case .height: return "cm"
        case .weight: return "kg"
        }
    }
    var range: ClosedRange<Int> {
        switch self {
        case .age: return 13...90
        case .height: return 120...220
        case .weight: return 35...200
        }
    }
    var fallback: Int {
        switch self {
        case .age: return 24
        case .height: return 175
        case .weight: return 70
        }
    }
}

private struct NumberPickerSheet: View {
    let field: PickerField
    @Bindable var manager: OnboardingStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var value: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(field.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button("Done") {
                    commit()
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.voltLime)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Picker("", selection: $value) {
                ForEach(field.range, id: \.self) { n in
                    Text("\(n) \(field.unit)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .tag(n)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(.top, 8)

            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            let current = Int(currentText()) ?? field.fallback
            value = min(max(current, field.range.lowerBound), field.range.upperBound)
        }
    }

    private func currentText() -> String {
        switch field {
        case .age: return manager.age
        case .height: return manager.height
        case .weight: return manager.weight
        }
    }

    private func commit() {
        let text = "\(value)"
        switch field {
        case .age: manager.age = text
        case .height: manager.height = text
        case .weight: manager.weight = text
        }
    }
}

// MARK: - Step 6: Dream body

private struct DreamBodyStep: View {
    @Bindable var manager: OnboardingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "Choose your dream body", subtitle: "Select the physique that matches your goal so we can build your personalized plan")

            VStack(spacing: 12) {
                ForEach(BodyType.dreamOptions, id: \.self) { body in
                    DreamBodyCard(
                        title: body.rawValue,
                        subtitle: body.subtitle,
                        imageName: "DreamBody\(body.rawValue)",
                        isSelected: manager.dreamBody == body
                    ) {
                        manager.dreamBody = body
                    }
                }
            }
            .padding(.top, 24)

            Spacer()
            PrimaryButton(title: "Continue", style: .lime, isDisabled: manager.dreamBody == nil) { manager.next() }
        }
        .padding(24)
    }
}

// MARK: - Dream body image card

private struct DreamBodyCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 118)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .colorMultiply(isSelected ? Color.voltLime : .white)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.voltTextMuted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.voltLime : Color.voltTextMuted.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.voltLime)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(14)
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.voltLime : .clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 7: Recovery setup

private struct RecoverySetupStep: View {
    @Bindable var manager: OnboardingStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(manager: manager, title: "Recovery setup", subtitle: "Sleep, soreness and hydration change how fast your muscles recover")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    pickerSection(title: "Average sleep") {
                        ForEach(SleepAverage.allCases, id: \.self) { sleep in
                            chip(sleep.rawValue, selected: manager.sleep == sleep) { manager.sleep = sleep }
                        }
                    }
                    pickerSection(title: "Usual muscle soreness") {
                        ForEach(SorenessLevel.allCases, id: \.self) { soreness in
                            chip(soreness.rawValue, selected: manager.soreness == soreness) { manager.soreness = soreness }
                        }
                    }
                    pickerSection(title: "Daily hydration") {
                        ForEach(HydrationLevel.allCases, id: \.self) { hydration in
                            chip(hydration.rawValue, selected: manager.hydration == hydration) { manager.hydration = hydration }
                        }
                    }
                }
                .padding(.top, 24)
            }

            PrimaryButton(title: "Continue", style: .lime) { manager.next() }
        }
        .padding(24)
    }

    private func pickerSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.voltTextDark)
            HStack(spacing: 8) { content() }
        }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.voltLime : Color.voltCard)
                .foregroundStyle(selected ? Color.voltOnLime : Color.voltTextDark)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 8: Body scan (camera or photo library, Vision-verified)

private struct OnboardingScanStep: View {
    @Bindable var manager: OnboardingStateManager

    @State private var selectedItem: PhotosPickerItem?
    @State private var scanImage: UIImage?
    @State private var showCamera = false
    @State private var isScanning = false
    @State private var bodyDetected = false
    @State private var scanMessage: String?
    @State private var showNoBodyAlert = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { manager.back() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                        .frame(width: 38, height: 38)
                        .background(Color.voltCard)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button("Skip") {
                    BodyImageAnalyzer.lastMetrics = nil
                    manager.didScan = false
                    manager.next()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.voltTextMuted)
            }

            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    ScanCorners()
                        .stroke(Color.voltLime, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 220, height: 300)

                    if let scanImage {
                        Image(uiImage: scanImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 196, height: 276)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                if isScanning { ScanSweepOverlay() }
                            }
                    } else {
                        BodyFigurePlaceholder(dark: false)
                            .frame(height: 220)
                    }
                }

                Text("Body scan")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)

                Text(statusText)
                    .font(.system(size: 14))
                    .foregroundStyle(bodyDetected ? Color.voltLimeDeep : Color.voltTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .animation(.easeInOut, value: statusText)
            }

            Spacer()

            bottomActions
        }
        .padding(24)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                handlePicked(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    handlePicked(image)
                }
                selectedItem = nil
            }
        }
        .alert("No body detected", isPresented: $showNoBodyAlert) {
            Button("Retake") { reset() }
            Button("Use anyway") {
                bodyDetected = true
                scanMessage = "Photo saved we'll fine tune as you train"
            }
        } message: {
            Text("Make sure your full body is visible and well lit, then try again")
        }
    }

    private var statusText: String {
        if isScanning { return "Scanning your photo..." }
        if let scanMessage { return scanMessage }
        return "Take a quick photo or choose one from your library to analyze your current physique. This helps us fine tune your recovery and performance"
    }

    @ViewBuilder
    private var bottomActions: some View {
        if isScanning {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color.voltOnLime)
                Text("Analyzing...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.voltOnLime)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.voltLime.opacity(0.6))
            .clipShape(Capsule())
        } else if bodyDetected {
            VStack(spacing: 10) {
                PrimaryButton(title: "Continue", icon: "checkmark", style: .lime) {
                    manager.didScan = true
                    manager.next()
                }
                Button("Retake photo") { reset() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            }
        } else {
            VStack(spacing: 12) {
                if cameraAvailable {
                    PrimaryButton(title: "Start Body Scan", icon: "camera.fill", style: .lime) {
                        showCamera = true
                    }
                }
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Choose from Library")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(Color.voltTextDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.voltCard)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                Text("You can skip this and do it later")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.voltTextMuted)
                    .padding(.top, 4)
            }
        }
    }

    private func handlePicked(_ image: UIImage) {
        scanImage = image
        analyze(image)
    }

    private func reset() {
        BodyImageAnalyzer.lastMetrics = nil
        scanImage = nil
        bodyDetected = false
        scanMessage = nil
        isScanning = false
    }

    private func analyze(_ image: UIImage) {
        isScanning = true
        bodyDetected = false
        scanMessage = nil

        let cgImage = image.cgImage
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        Task { @MainActor in
            let heightCm = Double(manager.height)
            async let analysis = BodyImageAnalyzer.analyze(cgImage: cgImage, orientation: orientation, userHeightCm: heightCm)
            try? await Task.sleep(nanoseconds: 1_400_000_000) // let the scan sweep play
            let metrics = await analysis

            isScanning = false
            if let metrics {
                BodyImageAnalyzer.lastMetrics = metrics
                bodyDetected = true
                scanMessage = "Body detected — \(metrics.classification.label) build, \(Int(metrics.confidence * 100))% scan confidence"
            } else {
                showNoBodyAlert = true
            }
        }
    }
}

// MARK: - Scan sweep animation

private struct ScanSweepOverlay: View {
    @State private var progress: CGFloat = -0.25

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.voltLime.opacity(0.85), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 56)
                .offset(y: progress * geo.size.height)
                .onAppear {
                    withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                        progress = 1.05
                    }
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Camera capture

private struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Step 9: Creating plan

private struct CreatingPlanStep: View {
    let manager: OnboardingStateManager
    let context: ModelContext

    @State private var completedSteps = 0
    private let steps = [
        "Analyzing your body data",
        "Calculating recovery windows",
        "Selecting your training split",
        "Building your weekly plan"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RecoveryRing(
                percentage: Double(completedSteps) / Double(steps.count) * 100,
                size: 120,
                lineWidth: 10,
                showLabel: true
            )

            Text("Creating your plan")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
                .padding(.top, 28)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        Image(systemName: index < completedSteps ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(index < completedSteps ? Color.voltLimeDeep : Color.voltTextMuted.opacity(0.4))
                        Text(steps[index])
                            .font(.system(size: 15, weight: index < completedSteps ? .semibold : .regular))
                            .foregroundStyle(index < completedSteps ? Color.voltTextDark : Color.voltTextMuted)
                    }
                }
            }
            .padding(.top, 28)

            Spacer()
            Spacer()
        }
        .padding(24)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        for index in 1...steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.7) {
                withAnimation(.easeInOut) { completedSteps = index }
                if index == steps.count {
                    finalize()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        manager.next()
                    }
                }
            }
        }
    }

    private func finalize() {
        let profile = manager.buildProfile()
        context.insert(profile)

        if manager.didScan {
            let scan = BodyAnalysisEngine.analyze(profile: profile)
            context.insert(scan)
            profile.currentBodyType = scan.bodyType
        }

        let plan = WorkoutPlan(
            name: "\(profile.dreamBody.rawValue) Plan",
            goal: profile.goal,
            daysPerWeek: profile.trainingDaysPerWeek,
            splitSummary: AIProgramEngine.splitSummary(for: profile.trainingDaysPerWeek)
        )
        context.insert(plan)

        StorageService.seedSampleDataIfNeeded(context: context, profile: profile)
        NotificationService.requestAuthorization()
        try? context.save()
    }
}

// MARK: - Step 10: All set

private struct AllSetStep: View {
    let context: ModelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.voltLime.opacity(0.25))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.voltOnLime)
                    .frame(width: 96, height: 96)
                    .background(Color.voltLime)
                    .clipShape(Circle())
            }

            Text("You're all set")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
                .padding(.top, 28)

            Text("Your plan, recovery forecast and body profile are ready")
                .font(.system(size: 15))
                .foregroundStyle(Color.voltTextMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)

            Spacer()

            PrimaryButton(title: "Enter VOLTFORM", icon: "bolt.fill", style: .lime) {
                if let profile = profiles.first {
                    profile.onboardingComplete = true
                    try? context.save()
                }
            }
        }
        .padding(24)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(PreviewSupport.container)
}
