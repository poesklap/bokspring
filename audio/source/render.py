"""Render MIDI with fluidsynth, cut out the middle repetition as a seamless loop."""
import struct, subprocess, sys, wave

SF2 = "/opt/homebrew/share/fluid-synth/sf2/VintageDreamsWaves-v2.sf2"
SR = 44100


def render(mid, wav, bpm, bars, out, peak_db=-1.5):
    subprocess.run(["fluidsynth", "-ni", "-C0", "-R1", "-g", "0.3", "-r", str(SR), "-F", wav, SF2, mid],
                   check=True, capture_output=True)
    w = wave.open(wav)
    assert w.getframerate() == SR and w.getnchannels() == 2
    raw = w.readframes(w.getnframes())
    a = struct.unpack("<%dh" % (len(raw) // 2), raw)
    loop_sec = bars * 4 * 60 / bpm
    L = round(loop_sec * SR)
    assert abs(L - loop_sec * SR) < 1e-6, "loop length is not a whole number of samples"
    seg = a[2 * L: 4 * L]           # repetition 2 (stereo interleaved)
    nxt = a[4 * L: 4 * L + 2 * 2000]  # start of repetition 3 = what should follow
    diff = max(abs(x - y) for x, y in zip(seg[:len(nxt)], nxt))
    # crossfade the last XF frames toward repetition 1's ending (whose natural successor is
    # repetition 2's first sample), so the wrap point is sample-continuous even though
    # fluidsynth's modulated reverb is not perfectly time-invariant.
    XF = int(0.4 * SR)
    seg = list(seg)
    for i in range(XF):
        k = (i + 1) / XF
        for c in range(2):
            j = 2 * (L - XF + i) + c
            seg[j] = (1 - k) * seg[j] + k * a[j]  # a[j] = same position in repetition 1
    wrap = max(abs(seg[-2 + c] - a[2 * L - 2 + c]) for c in range(2))
    print("wrap check (out end vs rep1 end, raw units):", wrap)
    peak = max(abs(x) for x in seg)
    g = (10 ** (peak_db / 20)) * 32767 / peak
    data = struct.pack("<%dh" % len(seg), *[int(round(x * g)) for x in seg])
    with wave.open(out, "wb") as o:
        o.setnchannels(2); o.setsampwidth(2); o.setframerate(SR); o.writeframes(data)
    print(f"{out}: L={L} samples = {L/SR} s, seam max diff (raw units) {diff}, peak raw {peak}")


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4]), sys.argv[5])
