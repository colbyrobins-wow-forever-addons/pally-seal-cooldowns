"""Synthesize the bundled cat meow alert (PallySealCooldowns/Sounds/CatMeow.wav).

The sound is generated from scratch (additive harmonics shaped by moving
vowel formants), so it carries no third-party recording or license. Standard
library only. Output goes next to the addon regardless of the current directory:

    python scripts/make_cat_meow.py
"""
import math
import struct
import sys
import wave
from pathlib import Path

RATE = 44100
DURATION = 0.72
PEAK = 0.35  # keeps the meow noticeable without being much louder than the chime
OUTPUT = Path(__file__).resolve().parent.parent / "PallySealCooldowns" / "Sounds" / "CatMeow.wav"


def lerp_points(points, t):
    """Piecewise-linear interpolation through (time, value) points."""
    if t <= points[0][0]:
        return points[0][1]
    for (t0, v0), (t1, v1) in zip(points, points[1:]):
        if t <= t1:
            x = (t - t0) / (t1 - t0)
            x = x * x * (3 - 2 * x)  # smoothstep for natural glides
            return v0 + (v1 - v0) * x
    return points[-1][1]


# Pitch glides up into the "eee", then falls through "ow".
PITCH = [(0.0, 520), (0.18, 700), (0.34, 780), (0.55, 660), (0.72, 470)]
# Formants (F1, F2, F3) move m -> ee -> aa -> ow, scaled up for a small cat.
F1 = [(0.0, 400), (0.10, 700), (0.30, 1150), (0.50, 1100), (0.72, 750)]
F2 = [(0.0, 1500), (0.10, 2700), (0.30, 2000), (0.50, 1500), (0.72, 1100)]
F3 = [(0.0, 3200), (0.10, 3800), (0.30, 3400), (0.72, 3000)]
# Quiet nasal onset, full open vowel, soft fade.
AMP = [(0.0, 0.0), (0.04, 0.25), (0.11, 0.85), (0.30, 1.0), (0.52, 0.8), (0.72, 0.0)]


def resonance(freq, center, bandwidth):
    """Magnitude of a simple resonant peak."""
    return 1.0 / math.sqrt(1.0 + ((freq - center) / (bandwidth / 2.0)) ** 2)


def synthesize():
    total = int(RATE * DURATION)
    samples = []
    phases = [0.0] * 40
    for n in range(total):
        t = n / RATE
        f0 = lerp_points(PITCH, t) * (1 + 0.012 * math.sin(2 * math.pi * 6.5 * t))
        f1, f2, f3 = lerp_points(F1, t), lerp_points(F2, t), lerp_points(F3, t)
        value = 0.0
        for k in range(1, len(phases) + 1):
            freq = k * f0
            if freq > 9000:
                break
            phases[k - 1] += 2 * math.pi * freq / RATE
            gain = (1.0 / k) * (resonance(freq, f1, 260) + 0.7 * resonance(freq, f2, 320)
                                + 0.3 * resonance(freq, f3, 450))
            value += gain * math.sin(phases[k - 1])
        samples.append(value * lerp_points(AMP, t))
    peak = max(abs(s) for s in samples) or 1.0
    return [s / peak * PEAK for s in samples]


def main():
    samples = synthesize()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(round(s * 32767))) for s in samples))
    print(f"Wrote {OUTPUT} ({len(samples)} frames, {DURATION:.2f} s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
