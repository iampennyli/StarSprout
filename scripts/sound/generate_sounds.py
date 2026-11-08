#!/usr/bin/env python3
"""
合成运动星球的背景音乐和音效（全部程序生成，无版权素材）。

用法：python3 scripts/sound/generate_sounds.py
依赖：numpy、scipy、ffmpeg（把背景音乐编码成 m4a）
输出：StarSprout/Resources/Sounds/
  planet_bgm.m4a        星球页背景音乐，约 25 秒，可无缝循环
  sfx_*.wav             各种音效（单声道 44.1kHz）

改了这里的参数后重新运行脚本，再跑 ./scripts/screenshots.sh 或真机试听。
"""
import os
import subprocess
import numpy as np
from scipy.signal import fftconvolve, butter, sosfilt
from scipy.io import wavfile

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "StarSprout", "Resources", "Sounds")
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- helpers

def note(name):
    """'C5' -> 频率"""
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    midi = 12 * (octave + 1) + names[pitch]
    return 440.0 * 2 ** ((midi - 69) / 12)


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def lowpass(x, cutoff, order=2):
    return sosfilt(butter(order, cutoff, btype="low", fs=SR, output="sos"), x)


def highpass(x, cutoff, order=2):
    return sosfilt(butter(order, cutoff, btype="high", fs=SR, output="sos"), x)


def bandpass(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)


def adsr(n, a, d, s, r):
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    sustain = max(0, n - a - d - r)
    env = np.concatenate([
        np.linspace(0, 1, max(a, 1), endpoint=False),
        np.linspace(1, s, max(d, 1), endpoint=False),
        np.full(sustain, s),
        np.linspace(s, 0, max(r, 1)),
    ])
    return env[:n] if len(env) >= n else np.pad(env, (0, n - len(env)))


def bell(freq, dur, amp=1.0, bright=1.0, decay=1.6):
    """FM 合成的音乐盒 / 钢片琴音色"""
    t = t_axis(dur)
    index = bright * 2.2 * np.exp(-t * 6)
    tone = np.sin(2 * np.pi * freq * t + index * np.sin(2 * np.pi * freq * 3.5 * t))
    tone += 0.25 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 5)
    env = np.exp(-t * decay / max(dur, 0.1) * 3) * np.minimum(1, t * 400)
    return amp * tone * env


def place(buf, clip, start, wrap=False):
    """把 clip 叠加到 buf 的 start 秒处；wrap=True 时超出部分折回开头（用于无缝循环）"""
    i = int(start * SR)
    end = i + len(clip)
    if end <= len(buf):
        buf[i:end] += clip
    else:
        cut = len(buf) - i
        buf[i:] += clip[:cut]
        if wrap:
            buf[:end - len(buf)] += clip[cut:]


def reverb_ir(seconds=2.4, decay=0.7, seed=1):
    r = np.random.default_rng(seed)
    t = t_axis(seconds)
    ir = r.standard_normal(len(t)) * np.exp(-t / decay)
    ir = lowpass(ir, 5000)
    ir[0] = 0
    return ir / np.sqrt(np.sum(ir ** 2))


def add_reverb(x, wet=0.25, seconds=1.6, decay=0.45, seed=3, wrap=False):
    ir = reverb_ir(seconds, decay, seed)
    tail = fftconvolve(x, ir)
    if wrap:
        out = tail[:len(x)].copy()
        rest = tail[len(x):]
        out[:len(rest)] += rest
    else:
        out = tail
        x = np.pad(x, (0, len(out) - len(x)))
    return (1 - wet) * x + wet * out


def normalize(x, peak_db=-3.0):
    peak = np.max(np.abs(x)) or 1
    return x / peak * 10 ** (peak_db / 20)


def fade_out(x, seconds=0.05):
    n = int(seconds * SR)
    x[-n:] *= np.linspace(1, 0, n)
    return x


def trim_tail(x, floor_db=-55.0):
    """去掉混响后面听不见的尾巴"""
    above = np.nonzero(np.abs(x) > 10 ** (floor_db / 20))[0]
    return x[: above[-1] + int(0.05 * SR)] if len(above) else x


def write_wav(name, x, peak_db=-3.0):
    x = fade_out(trim_tail(normalize(x, peak_db)))
    wavfile.write(os.path.join(OUT, name), SR, (x * 32767).astype(np.int16))
    print(f"  {name}  {len(x) / SR:.2f}s")


# ---------------------------------------------------------------- 背景音乐

def planet_bgm():
    """星空摇篮曲：76 BPM，C–Am–F–G 各两小节，音乐盒旋律 + 柔和铺底 + 低音，首尾无缝"""
    bpm = 76
    beat = 60 / bpm
    bars = 8
    length = bars * 4 * beat
    n = int(length * SR)
    left, right = np.zeros(n), np.zeros(n)

    chords = [
        (["C3", "G3", "E4", "B4", "D5"], "C2"),
        (["A2", "E3", "C4", "G4", "B4"], "A1"),
        (["F2", "C3", "A3", "E4", "G4"], "F1"),
        (["G2", "D3", "B3", "E4", "A4"], "G1"),
    ]
    scale_by_chord = [
        ["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6"],
        ["A4", "C5", "D5", "E5", "G5", "A5", "C6", "E6"],
        ["A4", "C5", "E5", "F5", "G5", "A5", "C6", "E6"],
        ["B4", "D5", "E5", "G5", "A5", "B5", "D6", "E6"],
    ]

    # 铺底：每个和弦 8 拍，起落都很慢，交叠过渡
    for ci, (tones, bass) in enumerate(chords):
        start = ci * 8 * beat
        dur = 8 * beat + 2.5
        t = t_axis(dur)
        env = adsr(len(t), 1.6, 0.5, 0.85, 2.6)
        pad = np.zeros(len(t))
        for k, name in enumerate(tones):
            f = note(name)
            for det in (-0.004, 0.0, 0.004):
                ff = f * (1 + det)
                vib = 0.002 * np.sin(2 * np.pi * (0.25 + 0.05 * k) * t)
                pad += np.sin(2 * np.pi * ff * (1 + vib) * t) + 0.18 * np.sin(4 * np.pi * ff * t)
        pad = lowpass(pad * env, 1800) * 0.045
        place(left, pad * 0.95, start, wrap=True)
        place(right, pad * 1.05, start, wrap=True)

        # 低音：每小节第一拍一个柔和的根音
        for b in range(2):
            t2 = t_axis(3.0)
            fb = note(bass) * 2
            low = (np.sin(2 * np.pi * fb * t2) + 0.2 * np.sin(4 * np.pi * fb * t2)) * np.exp(-t2 * 1.4) * np.minimum(1, t2 * 60)
            place(left, low * 0.22, start + b * 4 * beat, wrap=True)
            place(right, low * 0.22, start + b * 4 * beat, wrap=True)

    # 音乐盒旋律：八分音符，带休止，级进为主
    idx = 3
    for step in range(bars * 8):
        ci = step // 16
        scale = scale_by_chord[ci]
        if step % 8 in (3, 7) and rng.random() < 0.7:
            continue  # 每小节留两个呼吸
        if rng.random() < 0.18:
            continue
        idx = int(np.clip(idx + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(scale) - 1))
        if step % 16 == 0:
            idx = min(idx, 4)
        f = note(scale[idx])
        swing = 0.03 * beat if step % 2 else 0
        when = step * beat / 2 + swing
        amp = 0.22 if step % 2 == 0 else 0.15
        b = bell(f, 2.2, amp, bright=0.8, decay=1.4)
        pan = 0.5 + 0.35 * np.sin(step * 0.9)
        place(left, b * (1 - pan) * 2, when, wrap=True)
        place(right, b * pan * 2, when, wrap=True)

    # 偶尔一颗星星眨眼（很高很轻的铃音）
    for k in range(10):
        when = rng.uniform(0, length)
        f = note(rng.choice(["E7", "G7", "A6", "C7"]))
        tw = bell(f, 1.5, 0.05, bright=0.4, decay=2.0)
        if rng.random() < 0.5:
            place(left, tw, when, wrap=True)
        else:
            place(right, tw, when, wrap=True)

    left = add_reverb(left, wet=0.32, seconds=2.6, decay=0.9, seed=11, wrap=True)
    right = add_reverb(right, wet=0.32, seconds=2.6, decay=0.9, seed=12, wrap=True)
    stereo = np.stack([left, right], axis=1)
    stereo = stereo / np.max(np.abs(stereo)) * 10 ** (-4 / 20)

    wav = os.path.join(OUT, "_bgm.wav")
    wavfile.write(wav, SR, (stereo * 32767).astype(np.int16))
    m4a = os.path.join(OUT, "planet_bgm.m4a")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "aac", "-b:a", "112k", m4a], check=True)
    os.remove(wav)
    print(f"  planet_bgm.m4a  {length:.2f}s（循环）")


# ---------------------------------------------------------------- 音效

def sfx_water():
    """浇水：一阵细细的水声 + 一串圆润的水滴「咕嘟」"""
    dur = 1.3
    out = np.zeros(int(dur * SR))
    wash = bandpass(rng.standard_normal(len(out)), 900, 5000) * adsr(len(out), 0.15, 0.3, 0.6, 0.6) * 0.06
    out += wash
    times = np.sort(rng.uniform(0.05, 0.95, 9))
    for i, start in enumerate(times):
        d = 0.12
        t = t_axis(d)
        f0 = rng.uniform(500, 900)
        f = f0 * (1 + 1.3 * (t / d) ** 0.6)  # 水滴：音高快速上扬
        phase = 2 * np.pi * np.cumsum(f) / SR
        drop = np.sin(phase) * np.exp(-t * 28) * np.minimum(1, t * 900)
        place(out, drop * rng.uniform(0.35, 0.6), start)
    write_wav("sfx_water.wav", add_reverb(out, wet=0.18, seconds=0.8, decay=0.25))


def sfx_fertilize():
    """施肥：魔法撒粉，上行琶音 + 闪烁颗粒"""
    out = np.zeros(int(1.6 * SR))
    for i, n in enumerate(["G5", "C6", "E6", "G6", "C7"]):
        place(out, bell(note(n), 1.2, 0.35 - i * 0.03, bright=1.1, decay=1.8), i * 0.07)
    sparkle = highpass(rng.standard_normal(len(out)), 6000) * adsr(len(out), 0.05, 0.2, 0.35, 0.9)
    grains = (rng.random(len(out)) < 0.0025) * rng.uniform(0.3, 1.0, len(out))
    out += lowpass(grains, 9000) * 0.25 + sparkle * 0.035
    write_wav("sfx_fertilize.wav", add_reverb(out, wet=0.3, seconds=1.2, decay=0.4))


def sfx_levelup():
    """升级：明亮的上行号角 + 大和弦 + 星光"""
    out = np.zeros(int(2.4 * SR))
    for i, n in enumerate(["C5", "E5", "G5", "C6"]):
        place(out, bell(note(n), 0.5, 0.4, bright=1.0, decay=2.5), i * 0.11)
    for n in ["C5", "E5", "G5", "C6", "E6"]:
        t = t_axis(1.9)
        f = note(n)
        tone = (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t))
        place(out, tone * adsr(len(t), 0.03, 0.4, 0.55, 1.2) * 0.12, 0.46)
        place(out, bell(f * 2, 1.6, 0.12, bright=0.6), 0.46)
    for k in range(12):
        place(out, bell(note(rng.choice(["C7", "E7", "G7"])), 0.6, 0.06, bright=0.3), 0.5 + k * 0.1)
    write_wav("sfx_levelup.wav", add_reverb(out, wet=0.3, seconds=1.6, decay=0.5))


def sfx_tap_tree():
    """摸摸小树：软软的「啵嘤」，小树被逗笑了"""
    dur = 0.45
    t = t_axis(dur)
    f = 420 + 260 * np.sin(np.minimum(t / 0.12, 1) * np.pi / 2) + 30 * np.sin(2 * np.pi * 18 * t) * np.exp(-t * 6)
    phase = 2 * np.pi * np.cumsum(f) / SR
    boing = (np.sin(phase) + 0.3 * np.sin(2 * phase)) * np.exp(-t * 8) * np.minimum(1, t * 300)
    out = boing * 0.7
    place(out, bell(note("E6"), 0.35, 0.18, bright=0.5), 0.06)
    write_wav("sfx_tap_tree.wav", out, peak_db=-6)


def sfx_bunny():
    """小兔子跳：两声轻快的上滑「噗噗」"""
    out = np.zeros(int(0.5 * SR))
    for i, base in enumerate([500, 680]):
        t = t_axis(0.14)
        f = base * (1 + 1.2 * (t / 0.14))
        phase = 2 * np.pi * np.cumsum(f) / SR
        place(out, np.sin(phase) * np.exp(-t * 22) * np.minimum(1, t * 600) * 0.6, i * 0.13)
    write_wav("sfx_bunny.wav", out, peak_db=-6)


def sfx_nope():
    """没水 / 没金币：温和的下行两音，不带批评感"""
    out = np.zeros(int(0.6 * SR))
    for i, n in enumerate(["E5", "C5"]):
        t = t_axis(0.35)
        f = note(n)
        tone = (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)) * np.exp(-t * 9) * np.minimum(1, t * 300)
        place(out, tone * 0.5, i * 0.13)
    write_wav("sfx_nope.wav", out, peak_db=-8)


def sfx_checkin():
    """打卡成功：欢快的「叮咚」+ 金币"""
    out = np.zeros(int(1.4 * SR))
    for i, (n, a) in enumerate([("G5", 0.45), ("C6", 0.45), ("E6", 0.4), ("G6", 0.35)]):
        place(out, bell(note(n), 1.0, a, bright=1.2, decay=1.8), i * 0.09)
    t = t_axis(0.5)
    coin = np.sign(np.sin(2 * np.pi * note("B6") * t)) * 0.3
    coin = lowpass(coin, 6000) * np.exp(-t * 10)
    place(out, coin * 0.4, 0.4)
    write_wav("sfx_checkin.wav", add_reverb(out, wet=0.22, seconds=1.0, decay=0.35))


def sfx_coin():
    """金币：经典的两音「叮叮」"""
    out = np.zeros(int(0.45 * SR))
    for i, (n, d) in enumerate([("B5", 0.07), ("E6", 0.38)]):
        t = t_axis(d)
        sq = np.sign(np.sin(2 * np.pi * note(n) * t))
        place(out, lowpass(sq, 5000) * np.exp(-t * (14 if i else 30)) * 0.25, i * 0.07)
    write_wav("sfx_coin.wav", out, peak_db=-7)


def sfx_medal():
    """勋章解锁：闪亮的扫弦 + 庄重的大和弦，比升级更有仪式感"""
    out = np.zeros(int(3.0 * SR))
    swell = highpass(rng.standard_normal(int(0.7 * SR)), 3000)
    swell *= np.linspace(0, 1, len(swell)) ** 2 * 0.05
    place(out, swell, 0.0)
    for i, n in enumerate(["C5", "E5", "G5", "B5", "D6", "E6", "G6"]):
        place(out, bell(note(n), 2.0, 0.22, bright=0.9, decay=1.2), 0.62 + i * 0.045)
    for n in ["C4", "G4", "C5", "E5", "G5"]:
        t = t_axis(2.3)
        f = note(n)
        tone = sum(np.sin(2 * np.pi * f * (1 + d) * t) for d in (-0.003, 0, 0.003))
        place(out, lowpass(tone * adsr(len(t), 0.08, 0.5, 0.6, 1.5), 3000) * 0.06, 0.62)
    write_wav("sfx_medal.wav", add_reverb(out, wet=0.35, seconds=2.0, decay=0.6))


def sfx_tick():
    """倒计时：短促的「嘀」"""
    t = t_axis(0.15)
    tone = np.sin(2 * np.pi * 880 * t) * np.exp(-t * 30) * np.minimum(1, t * 800)
    write_wav("sfx_tick.wav", tone, peak_db=-8)


def sfx_go():
    """开始 / 时间到：更长更亮的「嘀——」"""
    t = t_axis(0.5)
    f = 1320
    tone = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * adsr(len(t), 0.005, 0.1, 0.6, 0.3)
    write_wav("sfx_go.wav", tone, peak_db=-6)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("生成到", OUT)
    planet_bgm()
    for fn in [sfx_water, sfx_fertilize, sfx_levelup, sfx_tap_tree, sfx_bunny, sfx_nope,
               sfx_checkin, sfx_coin, sfx_medal, sfx_tick, sfx_go]:
        fn()
