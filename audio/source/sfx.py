"""Synthesise Bokspring sound effects with the Python standard library only.
Every sound is built from sine/additive oscillators, filtered noise and envelopes.
Output: 44.1 kHz mono 16-bit WAV."""
import math, random, struct, sys, wave, os

SR = 44100
random.seed(7)
OUT = sys.argv[1] if len(sys.argv) > 1 else "sfx"
os.makedirs(OUT, exist_ok=True)


def buf(sec):
    return [0.0] * int(SR * sec)


def note_freq(n):  # MIDI note -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def add(dst, src, at=0.0, gain=1.0):
    o = int(at * SR)
    need = o + len(src)
    if need > len(dst):
        dst.extend([0.0] * (need - len(dst)))
    for i, v in enumerate(src):
        dst[o + i] += v * gain


def bell(freq, dur, decay=6.0, partials=((1, 1.0), (2, 0.35), (3, 0.15), (4.2, 0.08)), attack=0.003):
    n = int(dur * SR)
    out = [0.0] * n
    for mul, amp in partials:
        w = 2 * math.pi * freq * mul / SR
        d = decay * (1 + 0.6 * (mul - 1))  # higher partials die faster
        for i in range(n):
            t = i / SR
            env = math.exp(-d * t) * min(1.0, t / attack)
            out[i] += amp * env * math.sin(w * i)
    return out


def brass(freq, dur, harmonics=9, attack=0.03, release=0.08, vib=0.0, bright=1.0):
    """Band-limited sawtooth-ish tone with swell attack: fanfare/brass feel."""
    n = int(dur * SR)
    out = [0.0] * n
    for h in range(1, harmonics + 1):
        if freq * h > 15000:
            break
        amp = (1.0 / h) * (bright ** (h - 1))
        ph = random.random() * 0.2
        for i in range(n):
            t = i / SR
            f = freq * (1 + vib * math.sin(2 * math.pi * 5.5 * t) * min(1, t / 0.15))
            out[i] += amp * math.sin(2 * math.pi * f * h * t + ph)
    for i in range(n):
        t = i / SR
        a = min(1.0, t / attack)
        r = min(1.0, (dur - t) / release)
        out[i] *= a * max(0.0, r)
    return out


def noise(dur):
    return [random.uniform(-1, 1) for _ in range(int(dur * SR))]


def lowpass(x, cutoff):
    """One-pole lowpass; cutoff may be a function of time (seconds)."""
    y = []
    s = 0.0
    for i, v in enumerate(x):
        fc = cutoff(i / SR) if callable(cutoff) else cutoff
        a = 1 - math.exp(-2 * math.pi * fc / SR)
        s += a * (v - s)
        y.append(s)
    return y


def highpass(x, cutoff):
    lp = lowpass(x, cutoff)
    return [a - b for a, b in zip(x, lp)]


def env_apply(x, f):
    return [v * f(i / SR) for i, v in enumerate(x)]


def sweep_sine(f0, f1, dur, decay, curve=1.0):
    n = int(dur * SR)
    out = []
    ph = 0.0
    for i in range(n):
        t = i / SR
        k = (t / dur) ** curve
        f = f0 * (f1 / f0) ** k
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * math.exp(-decay * t) * min(1, t / 0.002))
    return out


def finish(name, x, peak_db=-3.0, soft_clip=False, fade_in=0.002, fade_out=0.012):
    # trim leading/trailing near-silence
    thr = max(abs(v) for v in x) * 0.0015
    s = 0
    while s < len(x) and abs(x[s]) < thr:
        s += 1
    e = len(x)
    while e > s and abs(x[e - 1]) < thr:
        e -= 1
    x = x[s:e]
    if soft_clip:  # gentle saturation for loud stingers
        m = max(abs(v) for v in x)
        x = [math.tanh(1.8 * v / m) for v in x]
    fi, fo = int(fade_in * SR), int(fade_out * SR)
    for i in range(min(fi, len(x))):
        x[i] *= i / fi
    for i in range(min(fo, len(x))):
        x[len(x) - 1 - i] *= i / fo
    m = max(abs(v) for v in x)
    g = (10 ** (peak_db / 20)) / m
    data = b"".join(struct.pack("<h", int(round(max(-1, min(1, v * g)) * 32767))) for v in x)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(f"{name}: {len(x)/SR:.3f}s")


# ---------- correct: bright two-note chime (C6 -> G6) ----------
x = buf(0.4)
add(x, bell(note_freq(84), 0.3, decay=9), 0.0, 0.8)
add(x, bell(note_freq(91), 0.32, decay=8), 0.075, 1.0)
add(x, bell(note_freq(103), 0.2, decay=14, partials=((1, 1.0),)), 0.075, 0.12)  # sparkle
finish("correct.wav", x[: int(0.4 * SR)])

# ---------- wrong: soft low bonk ----------
def bonk(f0=200, f1=130, dur=0.45):
    b = sweep_sine(f0, f1, dur, decay=9, curve=0.5)
    b2 = sweep_sine(f0 * 2.01, f1 * 2.01, dur, decay=16, curve=0.5)
    return [u + 0.25 * v for u, v in zip(b, b2)]

x = buf(0.5)
add(x, bonk(), 0.0, 1.0)
thump = lowpass(noise(0.08), 400)
add(x, env_apply(thump, lambda t: math.exp(-40 * t)), 0.0, 1.2)
finish("wrong.wav", x, peak_db=-4)

# ---------- crash: soft thud + low bonk (a bit heavier) ----------
x = buf(0.55)
add(x, sweep_sine(110, 45, 0.3, decay=12, curve=0.6), 0.0, 1.0)  # body thud
add(x, env_apply(lowpass(noise(0.15), lambda t: 900 * math.exp(-15 * t) + 150), lambda t: math.exp(-25 * t)), 0.0, 1.6)
add(x, bonk(180, 115, 0.5), 0.03, 0.75)
finish("crash.wav", x, peak_db=-3)

# ---------- lane: tiny whoosh ----------
dur = 0.13
w = noise(dur)
w = lowpass(w, lambda t: 600 + 5000 * math.sin(math.pi * min(1, t / dur)))
w = highpass(w, 300)
w = env_apply(w, lambda t: math.sin(math.pi * min(1, t / dur)) ** 2)
finish("lane.wav", w, peak_db=-10, fade_out=0.02)


# ---------- combo fanfares ----------
def sparkle(dur, count, lo=88, hi=100, at0=0.0, gain=0.15):
    s = buf(dur + 0.3)
    for k in range(count):
        n = random.randint(lo, hi)
        add(s, bell(note_freq(n), 0.18, decay=18, partials=((1, 1.0), (2.7, 0.2))), at0 + k * dur / count, gain)
    return s

def cymbal(dur, gain=1.0):
    c = highpass(noise(dur), 5000)
    return [v * gain for v in env_apply(c, lambda t: math.exp(-5 * t) * min(1, t / 0.004))]

# combo2: C major rising arpeggio into held chord
x = buf(0.9)
arp = [72, 76, 79]
for k, n in enumerate(arp):
    add(x, brass(note_freq(n), 0.12, attack=0.008, release=0.04), k * 0.07, 0.6)
for n, g in ((72, 0.5), (76, 0.45), (79, 0.45), (84, 0.6)):
    add(x, brass(note_freq(n), 0.62, attack=0.015, release=0.25, vib=0.004), 0.21, g)
add(x, sweep_sine(note_freq(48), note_freq(48), 0.6, decay=4), 0.21, 0.5)  # bass support
add(x, sparkle(0.4, 6), 0.21, 1.0)
add(x, cymbal(0.5, 0.12), 0.21)
finish("combo2.wav", x[: int(0.9 * SR)], peak_db=-1, soft_clip=True, fade_out=0.06)

# combo3: higher (D major), faster 4-note run, bigger chord, more sparkle and a crash
x = buf(1.0)
arp = [74, 78, 81, 86]
for k, n in enumerate(arp):
    add(x, brass(note_freq(n), 0.1, attack=0.006, release=0.03), k * 0.055, 0.6)
    add(x, brass(note_freq(n - 12), 0.1, attack=0.006, release=0.03), k * 0.055, 0.35)
t0 = 0.22
for n, g in ((62, 0.45), (69, 0.4), (74, 0.5), (78, 0.45), (81, 0.45), (86, 0.6)):
    add(x, brass(note_freq(n), 0.72, attack=0.012, release=0.28, vib=0.005), t0, g)
add(x, sweep_sine(note_freq(38), note_freq(38), 0.7, decay=3.5), t0, 0.7)
add(x, sweep_sine(150, 50, 0.2, decay=14), t0, 0.8)  # punch
add(x, sparkle(0.55, 10, 90, 103), t0, 1.2)
add(x, cymbal(0.7, 0.2), t0)
finish("combo3.wav", x[: int(1.0 * SR)], peak_db=-0.8, soft_clip=True, fade_out=0.08)

# ---------- coin: short sparkle (B6 -> E7) ----------
x = buf(0.25)
add(x, bell(note_freq(95), 0.07, decay=25, partials=((1, 1.0), (3, 0.2))), 0.0, 0.7)
add(x, bell(note_freq(100), 0.18, decay=20, partials=((1, 1.0), (3, 0.15), (5.4, 0.05))), 0.055, 1.0)
finish("coin.wav", x[: int(0.24 * SR)], peak_db=-4)

# ---------- level_complete: happy jingle ----------
x = buf(1.7)
mel = [(72, 0.0, 0.14), (76, 0.12, 0.14), (79, 0.24, 0.14), (84, 0.36, 0.2), (79, 0.54, 0.12),
       (84, 0.66, 0.8)]
for n, at, d in mel:
    add(x, bell(note_freq(n), d + 0.3, decay=5), at, 0.6)
    add(x, brass(note_freq(n), d, harmonics=5, attack=0.01, release=0.05, bright=0.6), at, 0.25)
for n in (60, 64, 67):  # final chord underneath
    add(x, brass(note_freq(n), 0.8, harmonics=5, attack=0.03, release=0.4, bright=0.5), 0.66, 0.2)
add(x, sweep_sine(note_freq(48), note_freq(48), 0.9, decay=3), 0.66, 0.4)
add(x, sparkle(0.5, 8, 91, 103), 0.7, 0.8)
finish("level_complete.wav", x[: int(1.6 * SR)], peak_db=-3, fade_out=0.15)

# ---------- game_over: gentle descending phrase, ends on a warm chord ----------
x = buf(1.8)
mel = [(76, 0.0), (74, 0.22), (72, 0.44), (67, 0.66)]
for n, at in mel:
    add(x, bell(note_freq(n), 0.7, decay=4, partials=((1, 1.0), (2, 0.2), (3, 0.05))), at, 0.6)
for n in (53, 57, 60, 65):  # soft F major (IV) then settle
    add(x, brass(note_freq(n), 0.8, harmonics=4, attack=0.15, release=0.5, bright=0.4), 0.66, 0.12)
add(x, bell(note_freq(60), 0.9, decay=3.5, partials=((1, 1.0), (2, 0.15))), 0.88, 0.55)
finish("game_over.wav", x[: int(1.6 * SR)], peak_db=-4, fade_out=0.25)

# ---------- tap: UI click ----------
x = buf(0.06)
add(x, env_apply([math.sin(2 * math.pi * 1500 * i / SR) for i in range(int(0.05 * SR))], lambda t: math.exp(-90 * t)), 0.0, 1.0)
add(x, env_apply(highpass(noise(0.01), 2000), lambda t: math.exp(-500 * t)), 0.0, 0.4)
finish("tap.wav", x, peak_db=-6, fade_out=0.008)

# ---------- new_record: triumphant flourish ----------
x = buf(1.1)
run = [67, 72, 76, 79]
for k, n in enumerate(run):
    add(x, brass(note_freq(n), 0.1, attack=0.006, release=0.03), k * 0.06, 0.55)
t0 = 0.24
for n, g in ((72, 0.45), (76, 0.4), (79, 0.4), (84, 0.55)):
    add(x, brass(note_freq(n), 0.76, attack=0.01, release=0.3, vib=0.006), t0, g)
# trill on top
for k in range(8):
    n = 88 if k % 2 == 0 else 86
    add(x, bell(note_freq(n), 0.12, decay=16), t0 + 0.05 + k * 0.06, 0.25)
add(x, sweep_sine(note_freq(48), note_freq(48), 0.7, decay=3.5), t0, 0.5)
add(x, cymbal(0.6, 0.12), t0)
finish("new_record.wav", x[: int(1.05 * SR)], peak_db=-2, soft_clip=True, fade_out=0.1)

# ---------- countdown: single beep ----------
d = 0.15
x = [0.0] * int(d * SR)
for i in range(len(x)):
    t = i / SR
    v = math.sin(2 * math.pi * 880 * t) + 0.2 * math.sin(2 * math.pi * 1760 * t) + 0.08 * math.sin(2 * math.pi * 2640 * t)
    x[i] = v * min(1, t / 0.004) * min(1, (d - t) / 0.03)
finish("countdown.wav", x, peak_db=-6, fade_out=0.01)
