import AVFoundation
import SwiftUI

/// 音效
enum SFX: String, CaseIterable {
    case water, fertilize, levelup, tapTree = "tap_tree", bunny, nope, checkin, coin, medal, tick, go
}

/// 背景音乐 + 音效。素材由 scripts/sound/generate_sounds.py 合成，放在 Resources/Sounds。
///
/// - 音频会话用 `.ambient`：遵从静音键，不打断孩子或家长正在听的其他音频。
/// - 开关存在 UserDefaults（`musicOn` / `sfxOn`），家长在「奖励设置 → 声音」里改。
/// - 背景音乐用 AVAudioEngine 循环 PCM 缓冲，首尾无缝；音效用预加载的 AVAudioPlayer。
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    nonisolated static let musicKey = "musicOn"
    nonisolated static let sfxKey = "sfxOn"

    private var players: [SFX: AVAudioPlayer] = [:]
    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private var musicBuffer: AVAudioPCMBuffer?
    private var musicWanted = false
    private var musicScheduled = false
    private var fadeTask: Task<Void, Never>?

    /// 背景音乐音量：衬底，不抢音效
    private let musicVolume: Float = 0.16

    private init() {
        UserDefaults.standard.register(defaults: [Self.musicKey: true, Self.sfxKey: true])
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        for s in SFX.allCases {
            if let url = Bundle.main.url(forResource: "sfx_\(s.rawValue)", withExtension: "wav"),
               let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[s] = p
            }
        }
        if let url = Bundle.main.url(forResource: "planet_bgm", withExtension: "m4a"),
           let file = try? AVAudioFile(forReading: url),
           let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) {
            try? file.read(into: buf)
            musicBuffer = buf
            engine.attach(musicNode)
            engine.connect(musicNode, to: engine.mainMixerNode, format: buf.format)
            musicNode.volume = 0
        }
        // 插拔耳机等会让引擎停掉，需要重新排程
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.musicScheduled = false
                self?.resumeIfWanted()
            }
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).flatMap(AVAudioSession.InterruptionType.init),
                  type == .ended else { return }
            Task { @MainActor in self?.resumeIfWanted() }
        }
    }

    private var sfxOn: Bool { UserDefaults.standard.bool(forKey: Self.sfxKey) }
    private var musicOn: Bool { UserDefaults.standard.bool(forKey: Self.musicKey) }

    // MARK: SFX

    func play(_ s: SFX, volume: Float = 1) {
        guard sfxOn, !DemoMode.isOn, let p = players[s] else { return }
        p.volume = volume
        p.currentTime = 0
        p.play()
    }

    // MARK: Music

    /// 进入星球页时调用；会淡入
    func startMusic() {
        musicWanted = true
        guard musicOn, !DemoMode.isOn, let buf = musicBuffer else { return }
        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }
        if !musicScheduled {
            musicNode.scheduleBuffer(buf, at: nil, options: .loops)
            musicScheduled = true
        }
        if !musicNode.isPlaying { musicNode.play() }
        fade(to: musicVolume, seconds: 1.5)
    }

    /// 离开星球页、App 进入后台、家长关掉音乐时调用；淡出后暂停
    func stopMusic(remember: Bool = false) {
        if !remember { musicWanted = false }
        guard musicNode.isPlaying else { return }
        fade(to: 0, seconds: 0.8) { [weak self] in
            self?.musicNode.pause()
            self?.engine.pause()
        }
    }

    /// App 回到前台 / 打断结束 / 家长重新打开音乐
    func resumeIfWanted() {
        if musicWanted { startMusic() }
    }

    /// 家长切换开关后调用
    func settingsChanged() {
        if musicOn { resumeIfWanted() } else { stopMusic(remember: true) }
    }

    private func fade(to target: Float, seconds: Double, then done: (() -> Void)? = nil) {
        fadeTask?.cancel()
        let start = musicNode.volume
        fadeTask = Task { @MainActor [weak self] in
            let steps = 30
            for i in 1...steps {
                try? await Task.sleep(for: .seconds(seconds / Double(steps)))
                if Task.isCancelled { return }
                self?.musicNode.volume = start + (target - start) * Float(i) / Float(steps)
            }
            done?()
        }
    }
}
