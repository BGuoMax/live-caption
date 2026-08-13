import SwiftUI
@preconcurrency import Translation

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var showSettings = true

    var body: some View {
        VStack(spacing: 10) {
            dragBar

            if showSettings {
                controls
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            captionContent

            HStack(spacing: 8) {
                Circle()
                    .fill(model.isRunning ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text(model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .frame(width: 760)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial.opacity(model.panelOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.13))
        }
        .padding(8)
        .background(WindowConfigurator())
        .translationTask(source: model.translationSource, target: model.translationTarget) { session in
            await model.configureTranslation(session)
        }
        .onDisappear {
            Task { await model.stop() }
        }
    }

    private var dragBar: some View {
        HStack(spacing: 8) {
            ZStack {
                WindowDragArea()

                HStack(spacing: 7) {
                    Image(systemName: "line.3.horizontal")
                    Text("拖动字幕位置")
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary.opacity(0.72))
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .contentShape(Rectangle())
            .help("按住这里拖动字幕窗口")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: showSettings ? "chevron.up" : "slider.horizontal.3")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(showSettings ? "收起设置" : "展开设置")
        }
        .padding(.leading, 2)
        .padding(.trailing, 4)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Picker("声音来源", selection: $model.audioSource) {
                    ForEach(AudioSource.allCases) { source in
                        Label(source.rawValue, systemImage: source.symbol).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                .disabled(model.isRunning)

                languagePicker("原语言", selection: $model.sourceLanguage)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                languagePicker("翻译为", selection: $model.targetLanguage)

                Spacer(minLength: 4)

                Button(action: model.toggleCapture) {
                    Label(
                        model.isRunning ? "停止" : "开始",
                        systemImage: model.isRunning ? "stop.fill" : "play.fill"
                    )
                    .frame(minWidth: 58)
                }
                .buttonStyle(.borderedProminent)
                .tint(model.isRunning ? .red : .accentColor)
                .keyboardShortcut(.space, modifiers: [.command])
            }

            appearanceControls
            featureControls
        }
    }

    private var appearanceControls: some View {
        HStack(spacing: 10) {
            Label("字幕字号", systemImage: "textformat.size")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $model.fontSize, in: 20...52, step: 1)
                .frame(width: 150)
                .help("同时调整原文和译文的字号")

            Text("\(Int(model.fontSize))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            Divider()
                .frame(height: 18)

            Label("背景透明度", systemImage: "circle.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { 1 - model.panelOpacity },
                    set: { model.panelOpacity = 1 - $0 }
                ),
                in: 0...0.75,
                step: 0.05
            )
                .frame(width: 150)
                .help("向右拖动使字幕面板背景更透明")

            Text("\(Int((1 - model.panelOpacity) * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)

            Spacer(minLength: 2)

            Toggle("原文", isOn: $model.showOriginal)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.caption)
        }
        .padding(.horizontal, 2)
    }

    private var featureControls: some View {
        HStack(spacing: 18) {
            Toggle("CS2 词库", isOn: $model.cs2GlossaryEnabled)
                .help("提高 CS2 解说术语、武器和地图名称的识别与翻译一致性")
                .disabled(model.isRunning)

            Toggle("保存复盘", isOn: $model.saveTranscripts)
                .help("每次开始后持续保存原文和译文；停止时生成完整记录")
                .disabled(model.isRunning)

            Spacer()

            Button(action: model.openRecordsFolder) {
                Label("打开记录", systemImage: "folder")
            }
            .buttonStyle(.borderless)
            .help("打开文稿中的 Live Caption Records 文件夹")
        }
        .font(.caption)
        .padding(.horizontal, 2)
    }

    private func languagePicker(
        _ title: String,
        selection: Binding<CaptionLanguage>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(CaptionLanguage.supported) { language in
                Text(language.name).tag(language)
            }
        }
        .labelsHidden()
        .frame(width: 105)
        .disabled(model.isRunning)
    }

    private var captionContent: some View {
        VStack(spacing: 8) {
            if model.showOriginal {
                Text(model.sourceText)
                    .font(.system(size: model.fontSize, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.72)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: max(48, model.fontSize * 1.45),
                        maxHeight: max(72, model.fontSize * 2.45)
                    )
                    .textSelection(.enabled)
            }

            LastLineEmphasizedText(
                text: model.translatedText.isEmpty ? "…" : model.translatedText,
                fontSize: model.fontSize,
                maximumLines: 3
            )
                .frame(
                    maxWidth: .infinity,
                    minHeight: max(54, model.fontSize * 1.6),
                    maxHeight: max(78, model.fontSize * 3.45)
                )
        }
        .padding(.horizontal, 8)
        .fixedSize(horizontal: false, vertical: true)
    }
}
