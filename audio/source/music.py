"""Original compositions for Bokspring, written as MIDI.
Each loop is written REPS times back to back; the renderer keeps only the middle
repetition so reverb/release tails from the previous pass are already present at
the start, making the loop seamless."""
import random
from midi import Song

REPS = 3


# ---------------------------------------------------------------- run loop
def run_loop(path):
    random.seed(3)
    bpm = 125
    s = Song(bpm)
    LEAD, MAR, BASS, CHOP, PAD, DR = 0, 1, 2, 3, 4, 9
    s.setup(LEAD, 37, vol=82, pan=60, reverb=45)   # Sine Whistle (pennywhistle-ish)
    s.setup(5, 34, vol=38, pan=70, reverb=45)       # Square Pop Flute, doubles lead softly
    s.setup(MAR, 120, vol=127, pan=40, reverb=35)    # Delicate Marimba
    s.setup(BASS, 121, vol=96, pan=64, reverb=10)  # Woody Bass
    s.setup(CHOP, 86, vol=127, pan=88, reverb=25)    # Sustained Harp, short off-beat chops
    s.setup(DR, 4, vol=127, pan=64, reverb=20, bank=128)  # Analog drumset

    G, C, D = "G", "C", "D"
    prog = [G, C, G, D, G, C, G, D,
            C, G, D, G, C, G, D, D,
            G, C, G, D, G, C, G, D]
    root = {G: 43, C: 48, D: 50}
    triad = {G: (67, 71, 74), C: (67, 72, 76), D: (66, 69, 74)}
    arp_tones = {G: (55, 59, 62, 67), C: (55, 60, 64, 67), D: (54, 57, 62, 66)}

    # melody: per bar list of (eighth position, length in eighths, MIDI note)
    A = [
        [(0, 2, 74), (2, 1, 79), (3, 1, 81), (4, 2, 83), (6, 1, 81), (7, 1, 79)],
        [(0, 2, 84), (2, 1, 83), (3, 1, 81), (4, 3, 79), (7, 1, 76)],
        [(0, 1, 74), (1, 1, 79), (2, 1, 83), (3, 1, 86), (4, 2, 83), (6, 2, 79)],
        [(0, 2, 81), (2, 1, 78), (3, 1, 81), (4, 4, 74)],
        None, None,
        [(0, 1, 83), (1, 1, 86), (2, 2, 88), (4, 1, 86), (5, 1, 83), (6, 2, 79)],
        [(0, 2, 81), (2, 2, 78), (4, 3, 81), (7, 1, 83)],
    ]
    A[4], A[5] = A[0], A[1]
    B = [
        [(0, 3, 88), (3, 1, 86), (4, 2, 84), (6, 2, 88)],
        [(0, 3, 86), (3, 1, 83), (4, 4, 79)],
        [(0, 1, 78), (1, 1, 81), (2, 1, 86), (3, 1, 81), (4, 2, 78), (6, 2, 74)],
        [(0, 2, 79), (2, 2, 83), (4, 2, 86), (6, 1, 83), (7, 1, 86)],
        [(0, 1, 84), (1, 1, 86), (2, 2, 88), (4, 1, 86), (5, 1, 84), (6, 2, 79)],
        [(0, 2, 83), (2, 1, 81), (3, 1, 79), (4, 3, 83), (7, 1, 81)],
        [(0, 2, 81), (2, 1, 78), (3, 1, 81), (4, 2, 86), (6, 2, 84)],
        [(0, 3, 81), (3, 1, 78), (4, 4, 74)],
    ]
    A2 = list(A[:7]) + [[(0, 2, 81), (2, 2, 78), (4, 1, 74), (5, 1, 78), (6, 1, 81), (7, 1, 78)]]
    melody = A + B + A2
    bars = len(prog)

    for rep in range(REPS):
        for b in range(bars):
            bar = rep * bars + b
            beat0 = bar * 4
            ch = prog[b]
            section = 0 if b < 8 else (1 if b < 16 else 2)
            # lead (with a little swing on off-beat eighths)
            for pos, ln, n in melody[b]:
                sw = 0.06 if pos % 2 == 1 else 0.0
                v = 104 if pos % 2 == 0 else 92
                s.note(LEAD, beat0 + pos / 2 + sw, ln / 2 * 0.92, n, v)
                s.note(5, beat0 + pos / 2 + sw, ln / 2 * 0.85, n, 70)
            # bass: root - root - fifth - octave - fifth
            r = root[ch]
            for pos, ln, n in [(0, 2, r), (3, 1, r), (4, 2, r + 7), (6, 1, r + 12), (7, 1, r + 7)]:
                s.note(BASS, beat0 + pos / 2, ln / 2 * 0.9, n, 112 if pos == 0 else 98)
            # kwela off-beat chop
            for pos in (1, 3, 5, 7):
                for n in triad[ch]:
                    s.note(CHOP, beat0 + pos / 2 + 0.06, 0.2, n, 96)
            # marimba: rolling eighths; in the last section it doubles the tune an octave down
            t = arp_tones[ch]
            pattern = [t[0], t[2], t[1], t[3], t[2], t[1], t[3], t[2]]
            for i, n in enumerate(pattern):
                vel = 96 if i % 2 == 0 else 78
                s.note(MAR, beat0 + i / 2 + (0.06 if i % 2 else 0), 0.45, n + 12, vel)
            if section == 2:
                for pos, ln, n in melody[b]:
                    s.note(MAR, beat0 + pos / 2 + (0.06 if pos % 2 else 0), ln / 2, n - 12, 82)
            # drums
            for i in range(8):
                sw = 0.06 if i % 2 else 0
                s.note(DR, beat0 + i / 2 + sw, 0.2, 42, 84 if i % 2 else 64)  # closed hat
                if i % 2:
                    s.note(DR, beat0 + i / 2 + sw, 0.2, 70, 60)  # maracas on the "and"
            s.note(DR, beat0 + 0, 0.3, 36, 110)
            s.note(DR, beat0 + 2, 0.3, 36, 100)
            s.note(DR, beat0 + 2.75, 0.2, 36, 72)
            s.note(DR, beat0 + 1, 0.3, 38, 100)
            s.note(DR, beat0 + 3, 0.3, 39, 108)
            if section == 1:
                s.note(DR, beat0 + 1.5 + 0.06, 0.2, 54, 70)  # tambourine lift in section B
                s.note(DR, beat0 + 3.5 + 0.06, 0.2, 54, 70)
            # conga fill on the 4th bar of every 4
            if b % 4 == 3:
                for k, (bt, n) in enumerate([(3.0, 63), (3.25, 63), (3.5, 64), (3.75, 62)]):
                    s.note(DR, beat0 + bt, 0.2, n, 80 + 6 * k)
    s.write(path, REPS * bars * 4 + 8)
    return bpm, bars


# ---------------------------------------------------------------- menu loop
def menu_loop(path):
    bpm = 90
    s = Song(bpm)
    VIB, HARP, PAD, BASS = 0, 1, 2, 3
    s.setup(VIB, 32, vol=127, pan=58, reverb=70)    # Cosmic Vibraphone (melody)
    s.setup(HARP, 86, vol=76, pan=80, reverb=60)    # Sustained Harp (arpeggio)
    s.setup(PAD, 90, vol=70, pan=64, reverb=80)     # Dreamy Pad
    s.setup(BASS, 121, vol=76, pan=64, reverb=20)   # Woody Bass

    prog = ["F", "Dm", "Bb", "C", "F", "Am", "Bb", "C", "Dm", "Bb", "Gm", "C"]
    chords = {"F": (53, 57, 60), "Dm": (50, 53, 57), "Bb": (46, 50, 53), "C": (48, 52, 55),
              "Am": (45, 48, 52), "Gm": (43, 46, 50)}
    mel = [
        [(0, 4, 72), (4, 2, 69), (6, 2, 72)],
        [(0, 6, 74), (6, 2, 72)],
        [(0, 3, 70), (3, 1, 72), (4, 4, 74)],
        [(0, 2, 76), (2, 2, 74), (4, 4, 72)],
        [(0, 4, 77), (4, 2, 76), (6, 2, 74)],
        [(0, 6, 72), (6, 2, 69)],
        [(0, 2, 70), (2, 2, 74), (4, 2, 77), (6, 2, 74)],
        [(0, 8, 76)],
        [(0, 4, 74), (4, 2, 77), (6, 2, 76)],
        [(0, 6, 74), (6, 2, 72)],
        [(0, 4, 70), (4, 4, 67)],
        [(0, 4, 72), (4, 2, 70), (6, 2, 67)],
    ]
    bars = len(prog)
    for rep in range(REPS):
        for b in range(bars):
            beat0 = (rep * bars + b) * 4
            c = chords[prog[b]]
            for pos, ln, n in mel[b]:
                s.note(VIB, beat0 + pos / 2, ln / 2 * 0.95, n, 92)
            # harp: gentle eighth-note arpeggio, two octaves
            arp = [c[0] + 12, c[1] + 12, c[2] + 12, c[0] + 24, c[2] + 12, c[1] + 24, c[2] + 12, c[1] + 12]
            for i, n in enumerate(arp):
                s.note(HARP, beat0 + i / 2, 0.9, n, 70 if i % 2 else 80)
            for n in c:  # pad holds the chord
                s.note(PAD, beat0, 3.95, n + 12, 70)
            s.note(BASS, beat0, 1.8, c[0] - 12 if c[0] > 47 else c[0], 96)
            s.note(BASS, beat0 + 2, 1.6, c[2] - 12 if c[0] > 47 else c[2], 84)
    s.write(path, REPS * bars * 4 + 8)
    return bpm, bars


if __name__ == "__main__":
    print("run", run_loop("run.mid"))
    print("menu", menu_loop("menu.mid"))
