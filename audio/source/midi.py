"""Tiny MIDI file writer (format 0) using only struct."""
import struct

TPB = 480  # ticks per beat


def vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.append(0x80 | (n & 0x7F))
        n >>= 7
    return bytes(reversed(out))


class Song:
    def __init__(self, bpm):
        self.bpm = bpm
        self.ev = []  # (tick, prio, bytes)

    def setup(self, ch, program, vol=100, pan=64, reverb=40, bank=0):
        self.ev.append((0, 0, bytes([0xB0 | ch, 0, bank])))
        self.ev.append((0, 0, bytes([0xC0 | ch, program])))
        self.ev.append((0, 0, bytes([0xB0 | ch, 7, vol])))
        self.ev.append((0, 0, bytes([0xB0 | ch, 10, pan])))
        self.ev.append((0, 0, bytes([0xB0 | ch, 91, reverb])))
        self.ev.append((0, 0, bytes([0xB0 | ch, 93, 0])))  # no chorus: keeps renders time-invariant

    def note(self, ch, beat, beats, key, vel):
        t0 = int(round(beat * TPB))
        t1 = int(round((beat + beats) * TPB))
        self.ev.append((t0, 2, bytes([0x90 | ch, key, vel])))
        self.ev.append((max(t0 + 1, t1), 1, bytes([0x80 | ch, key, 0])))

    def write(self, path, end_beat):
        tempo = int(round(60_000_000 / self.bpm))
        trk = bytearray()
        trk += vlq(0) + b"\xFF\x51\x03" + tempo.to_bytes(3, "big")
        last = 0
        for t, _, b in sorted(self.ev, key=lambda e: (e[0], e[1])):
            trk += vlq(t - last) + b
            last = t
        end = int(end_beat * TPB)
        trk += vlq(max(0, end - last)) + b"\xFF\x2F\x00"
        data = b"MThd" + struct.pack(">IHHH", 6, 0, 1, TPB) + b"MTrk" + struct.pack(">I", len(trk)) + trk
        open(path, "wb").write(data)
