"""Synthesize the bundled alert sounds in PallySealCooldowns/Sounds/.

Every sound is generated from scratch (additive sine partials, simple pitch
sweeps, and seeded noise), so none carries a third-party recording or license.
Standard library only. Output goes next to the addon regardless of the
current directory:

    python scripts/make_alert_sounds.py

The cat meow has its own script (make_cat_meow.py); the original gentle chime
(RefreshChime.wav) predates these scripts and is not regenerated here.
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 44100
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "PallySealCooldowns" / "Sounds"
PEAK_CAP = 0.6       # never louder than about -4.4 dBFS
TARGET_RMS = 0.107   # roughly the cat meow's level; quieter sounds keep PEAK_CAP


def buffer(seconds):
    return [0.0] * int(RATE * seconds)


def strike(out, start, freq, partials, decay, attack=0.004, amp=1.0):
    """Add a struck tone: partials are (frequency ratio, level); higher partials fade faster."""
    first = int(start * RATE)
    for ratio, level in partials:
        f = freq * ratio
        if f >= RATE / 2 * 0.9:
            continue
        tau = decay / math.sqrt(ratio)
        step = 2 * math.pi * f / RATE
        for n in range(first, len(out)):
            t = (n - first) / RATE
            env = min(1.0, t / attack) * math.exp(-t / tau)
            if env < 1e-4 and t > attack:
                break
            out[n] += amp * level * env * math.sin(step * (n - first))


def sweep(out, start, f_from, f_to, length, decay, amp=1.0):
    """Add a sine whose pitch glides exponentially, as in a bubble."""
    first = int(start * RATE)
    phase = 0.0
    for n in range(first, min(len(out), first + int(length * RATE))):
        t = (n - first) / RATE
        f = f_from * (f_to / f_from) ** min(1.0, t / length)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.003) * math.exp(-t / decay)
        out[n] += amp * env * math.sin(phase)


def bright_bell():
    out = buffer(1.4)
    strike(out, 0, 880, [(1, 1), (2.0, 0.6), (2.76, 0.5), (5.4, 0.25), (8.93, 0.12)], 0.9)
    return out


def double_chime():
    out = buffer(1.0)
    chime = [(1, 1), (2, 0.3), (3, 0.1)]
    strike(out, 0.0, 1318.5, chime, 0.45)
    strike(out, 0.18, 1046.5, chime, 0.5)
    return out


def rising_arpeggio():
    out = buffer(0.95)
    for index, freq in enumerate([523.25, 659.25, 783.99, 1046.5]):
        strike(out, index * 0.09, freq, [(1, 1), (2, 0.25)], 0.35)
    return out


def holy_shimmer():
    out = buffer(1.3)
    length = len(out)
    # A detuned major chord beats gently; the swell keeps it soft.
    voices = [(f + d, 0.5 if d else 1.0) for f in (523.25, 659.25, 783.99, 1046.5) for d in (0, -1.6, 1.6)]
    for n in range(length):
        t = n / RATE
        env = min(1.0, t / 0.25) * min(1.0, (1.3 - t) / 0.6)
        out[n] += env * sum(level * math.sin(2 * math.pi * f * t) for f, level in voices) / len(voices)
    rng = random.Random(7)
    for _ in range(9):
        strike(out, rng.uniform(0.05, 0.8), rng.choice([2093, 2349.3, 2637, 3136]), [(1, 1)], 0.12, amp=0.18)
    return out


def soft_gong():
    out = buffer(1.8)
    strike(out, 0, 165, [(1, 1), (1.47, 0.6), (2.09, 0.5), (2.56, 0.35), (3.14, 0.25), (4.2, 0.15)],
           1.2, attack=0.03)
    return out


def harp_pluck():
    out = buffer(1.0)
    harmonics = [(k, 1 / k ** 1.2) for k in range(1, 9)]
    strike(out, 0.0, 783.99, harmonics, 0.5, attack=0.002)
    strike(out, 0.14, 1174.66, harmonics, 0.55, attack=0.002)
    return out


def wood_block():
    out = buffer(0.4)
    rng = random.Random(3)
    for start, freq in ((0.0, 900), (0.16, 750)):
        strike(out, start, freq, [(1, 1), (2.3, 0.4), (3.9, 0.15)], 0.045, attack=0.001)
        first = int(start * RATE)
        for n in range(first, first + int(0.006 * RATE)):  # the knock's click
            out[n] += 0.3 * rng.uniform(-1, 1) * (1 - (n - first) / (0.006 * RATE))
    return out


def bubble_pop():
    out = buffer(0.35)
    sweep(out, 0.0, 300, 1200, 0.06, 0.08)
    sweep(out, 0.12, 400, 1600, 0.06, 0.08)
    return out


def glass_ping():
    out = buffer(0.9)
    strike(out, 0, 2093, [(1, 1), (2.32, 0.3), (4.25, 0.1)], 0.6, attack=0.002)
    return out


def urgent_beeps():
    out = buffer(0.45)
    for index in range(3):
        first = int(index * 0.14 * RATE)
        count = int(0.08 * RATE)
        for i in range(count):
            t = i / RATE
            env = min(1.0, i / 120, (count - i) / 120)  # soft edges, no clicks
            square = sum(math.sin(2 * math.pi * 1000 * k * t) / k for k in (1, 3, 5))
            out[first + i] += env * square
    return out


SOUNDS = {
    "BrightBell.wav": bright_bell,
    "DoubleChime.wav": double_chime,
    "RisingArpeggio.wav": rising_arpeggio,
    "HolyShimmer.wav": holy_shimmer,
    "SoftGong.wav": soft_gong,
    "HarpPluck.wav": harp_pluck,
    "WoodBlock.wav": wood_block,
    "BubblePop.wav": bubble_pop,
    "GlassPing.wav": glass_ping,
    "UrgentBeeps.wav": urgent_beeps,
}


def finish(samples):
    fade = int(0.02 * RATE)  # end on silence to avoid a click
    for i in range(fade):
        samples[-1 - i] *= i / fade
    peak = max(abs(s) for s in samples) or 1.0
    rms = math.sqrt(sum(s * s for s in samples) / len(samples)) or 1.0
    gain = min(PEAK_CAP / peak, TARGET_RMS / rms)
    return [s * gain for s in samples]


def write(path, samples):
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(round(s * 32767))) for s in samples))


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        samples = finish(make())
        write(OUTPUT_DIR / name, samples)
        print(f"Wrote {OUTPUT_DIR / name} ({len(samples) / RATE:.2f} s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
