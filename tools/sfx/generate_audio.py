#!/usr/bin/env python3
"""Chiptune sound generator for Save the Sheep.

Builds every sound effect and music loop of the game from code, with only the
Python standard library, so the 8-bit sounds match the pixel art style and can
be tweaked and regenerated at any time:

    python3 tools/sfx/generate_audio.py

Effects are written as WAV in assets/audio/sfx, music loops as WAV in
assets/audio/music (converted to OGG when ffmpeg is available).
"""

import math
import os
import random
import shutil
import struct
import subprocess
import wave

RATE = 22050
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")

random.seed(42)


# --- oscillators ------------------------------------------------------------

def square(phase, duty=0.5):
    return 1.0 if (phase % 1.0) < duty else -1.0


def triangle(phase):
    p = phase % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def saw(phase):
    return 2.0 * (phase % 1.0) - 1.0


class Noise:
    """NES like noise: holds a random value, refreshed at the given frequency."""

    def __init__(self):
        self.value = 0.0
        self.acc = 0.0

    def next(self, freq):
        self.acc += freq / RATE
        if self.acc >= 1.0:
            self.acc %= 1.0
            self.value = random.uniform(-1.0, 1.0)
        return self.value


def note(name):
    """'A4' -> frequency, '-' or None -> 0."""
    if not name or name == "-":
        return 0.0
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
             "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    midi = names[pitch] + (octave + 1) * 12
    return 440.0 * 2 ** ((midi - 69) / 12.0)


# --- effect building blocks -------------------------------------------------

def tone(duration, f_start, f_end=None, wave_fn="square", duty=0.5, volume=0.5,
         attack=0.005, release=None, vibrato=0.0, vibrato_rate=0.0, curve=1.0):
    """Single voice with a pitch slide and a linear decay envelope."""
    f_end = f_start if f_end is None else f_end
    n = int(duration * RATE)
    release = duration if release is None else release
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        k = (i / n) ** curve
        freq = f_start + (f_end - f_start) * k
        if vibrato:
            freq *= 1.0 + vibrato * math.sin(2 * math.pi * vibrato_rate * t)
        phase += freq / RATE
        if wave_fn == "square":
            s = square(phase, duty)
        elif wave_fn == "triangle":
            s = triangle(phase)
        else:
            s = saw(phase)
        env = min(1.0, t / attack) if attack > 0 else 1.0
        remaining = duration - t
        if remaining < release:
            env *= remaining / release
        out.append(s * env * volume)
    return out


def noise(duration, f_start, f_end=None, volume=0.5, attack=0.002, curve=1.0):
    f_end = f_start if f_end is None else f_end
    n = int(duration * RATE)
    gen = Noise()
    out = []
    for i in range(n):
        t = i / RATE
        freq = f_start + (f_end - f_start) * (i / n) ** curve
        env = min(1.0, t / attack) if attack > 0 else 1.0
        env *= (1.0 - i / n) ** 1.5
        out.append(gen.next(freq) * env * volume)
    return out


def silence(duration):
    return [0.0] * int(duration * RATE)


def seq(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    return out


def arpeggio(notes, step, wave_fn="square", duty=0.5, volume=0.4, tail=0.0):
    out = []
    for i, name in enumerate(notes):
        length = step + (tail if i == len(notes) - 1 else 0.0)
        out.extend(tone(length, note(name), wave_fn=wave_fn, duty=duty,
                        volume=volume, release=length * 0.6))
    return out


# --- output -----------------------------------------------------------------

def write_wav(path, samples, peak=0.85):
    biggest = max(1e-6, max(abs(s) for s in samples))
    gain = min(1.0, peak / biggest)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767))
                          for s in samples)
        f.writeframes(frames)


# --- sound effects ----------------------------------------------------------

def build_sfx():
    return {
        # Gordon
        "jump": tone(0.16, 260, 620, duty=0.25, volume=0.45, curve=0.6),
        "land": noise(0.07, 1800, 600, volume=0.35),
        "shoot": mix(noise(0.12, 9000, 3000, volume=0.25),
                     tone(0.1, 900, 380, duty=0.125, volume=0.3)),
        "empty": seq(tone(0.04, 140, duty=0.5, volume=0.35), silence(0.04),
                     tone(0.04, 110, duty=0.5, volume=0.35)),
        "player_hurt": tone(0.28, 420, 140, duty=0.5, volume=0.45,
                            vibrato=0.06, vibrato_rate=30),
        "action": seq(noise(0.03, 6000, volume=0.4), silence(0.05),
                      tone(0.06, 520, 780, duty=0.25, volume=0.35)),

        # sheep: a small 8-bit "bêê"
        "sheep_hurt": mix(tone(0.38, 560, 470, duty=0.25, volume=0.4, attack=0.02,
                               vibrato=0.08, vibrato_rate=22),
                          tone(0.38, 1120, 940, duty=0.5, volume=0.08, attack=0.02,
                               vibrato=0.08, vibrato_rate=22)),

        # water hits
        "splash": noise(0.14, 7000, 1500, volume=0.3),
        "enemy_hit": mix(tone(0.08, 300, 160, duty=0.5, volume=0.35),
                         noise(0.06, 4000, volume=0.2)),
        "enemy_die": seq(mix(noise(0.25, 2500, 300, volume=0.4),
                             tone(0.25, 400, 60, duty=0.5, volume=0.3)),
                         arpeggio(["E5", "G5", "C6"], 0.05, duty=0.25, volume=0.2)),

        # enemies
        "fireball": mix(noise(0.3, 800, 3000, volume=0.3),
                        tone(0.3, 180, 90, wave_fn="saw", volume=0.2)),
        "roar": mix(noise(0.45, 400, 150, volume=0.35, attack=0.03),
                    tone(0.45, 110, 70, wave_fn="saw", volume=0.3, attack=0.03,
                         vibrato=0.15, vibrato_rate=18)),

        # pickups
        "pickup_water": arpeggio(["C5", "E5", "G5", "C6"], 0.045, wave_fn="triangle",
                                 volume=0.5, tail=0.08),
        "pickup_life": arpeggio(["G4", "C5", "E5", "G5", "C6"], 0.05, duty=0.5,
                                volume=0.3, tail=0.1),
        "pickup_key": arpeggio(["E6", "B5", "E6", "G#6", "B6"], 0.05, duty=0.25,
                               volume=0.3, tail=0.12),

        # level objects
        "gate": seq(mix(noise(0.35, 300, 200, volume=0.35, attack=0.02),
                        tone(0.35, 70, 90, duty=0.5, volume=0.2)),
                    noise(0.06, 3000, volume=0.35)),
        "bike_crash": mix(noise(0.4, 3000, 200, volume=0.5),
                          tone(0.3, 200, 50, duty=0.5, volume=0.3)),

        # ui
        "ui_move": tone(0.035, 880, duty=0.25, volume=0.25),
        "ui_select": seq(tone(0.05, 660, duty=0.25, volume=0.3),
                         tone(0.09, 990, duty=0.25, volume=0.3)),
        "pause": seq(tone(0.06, 990, duty=0.5, volume=0.25),
                     tone(0.1, 660, duty=0.5, volume=0.25)),
        "tick": tone(0.04, 1320, duty=0.125, volume=0.25),
        "score_tick": tone(0.025, 1760, duty=0.125, volume=0.15),

        # jingles
        "level_complete": seq(arpeggio(["C5", "E5", "G5"], 0.09, volume=0.3),
                              arpeggio(["C6"], 0.09, volume=0.3, tail=0.05),
                              silence(0.05),
                              mix(arpeggio(["A5", "C6"], 0.1, volume=0.25, tail=0.3),
                                  arpeggio(["F4", "A4"], 0.1, wave_fn="triangle",
                                           volume=0.4, tail=0.3))),
        "game_over": seq(arpeggio(["G4", "F#4", "F4"], 0.18, duty=0.5, volume=0.3),
                         tone(0.7, note("E4"), note("E4"), duty=0.5, volume=0.3,
                              vibrato=0.02, vibrato_rate=6)),
    }


# --- music ------------------------------------------------------------------

class Track:
    """Step sequencer: every voice is a list of note names, one per step."""

    def __init__(self, bpm, steps_per_beat=4):
        self.step = 60.0 / bpm / steps_per_beat
        self.voices = []

    def add(self, pattern, wave_fn="square", duty=0.5, volume=0.2, gate=0.85,
            vibrato=0.0):
        self.voices.append((pattern, wave_fn, duty, volume, gate, vibrato))

    def add_drums(self, pattern, volume=0.25):
        self.voices.append((pattern, "drums", 0, volume, 1.0, 0))

    def render(self):
        steps = max(len(v[0]) for v in self.voices)
        n = int(steps * self.step * RATE)
        out = [0.0] * n
        for pattern, wave_fn, duty, volume, gate, vibrato in self.voices:
            for i, name in enumerate(pattern):
                if name in ("-", "", None, "."):
                    continue
                start = int(i * self.step * RATE)
                if wave_fn == "drums":
                    sound = drum(name, volume)
                else:
                    # "~" extends the previous note
                    length = 1
                    while i + length < len(pattern) and pattern[i + length] == "~":
                        length += 1
                    if name == "~":
                        continue
                    duration = self.step * length * gate
                    sound = tone(duration, note(name), wave_fn=wave_fn, duty=duty,
                                 volume=volume, attack=0.004, release=min(0.05, duration / 2),
                                 vibrato=vibrato, vibrato_rate=5.5)
                for j, v in enumerate(sound):
                    if start + j < n:
                        out[start + j] += v
                    else:
                        # wrap the tail so the loop stays seamless
                        out[(start + j) % n] += v
        return out


def drum(kind, volume):
    if kind == "k":  # kick: fast triangle drop
        return tone(0.12, 160, 40, wave_fn="triangle", volume=volume * 2.2, curve=0.4)
    if kind == "s":  # snare
        return mix(noise(0.12, 5000, 2500, volume=volume),
                   tone(0.06, 220, 150, wave_fn="triangle", volume=volume))
    if kind == "h":  # closed hat
        return noise(0.03, 11000, volume=volume * 0.45)
    if kind == "o":  # open hat
        return noise(0.12, 11000, volume=volume * 0.4)
    return []


def expand(text):
    """'C4 ~ - E4' -> list of steps, '|' bars are ignored."""
    return [t for t in text.split() if t != "|"]


def chord_bass(chords, pattern):
    """Repeats a per-bar bass pattern ('R' root, 'O' octave, 'F' fifth) over chords."""
    out = []
    for root in chords:
        octave = root[:-1] + str(int(root[-1]) + 1)
        fifth = transpose(root, 7)
        for p in pattern:
            out.append({"R": root, "O": octave, "F": fifth}.get(p, p))
    return out


def arp(chords, shapes, steps_per_bar=16, octave_shift=0):
    out = []
    for root, shape in zip(chords, shapes):
        tones_ = [transpose(root, s + 12 * octave_shift) for s in shape]
        for i in range(steps_per_bar):
            out.append(tones_[i % len(tones_)])
    return out


def transpose(name, semitones):
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    pitch, octave = name[:-1], int(name[-1])
    idx = names.index(pitch) + semitones + octave * 12
    return names[idx % 12] + str(idx // 12)


MAJ = [0, 4, 7, 12]
MIN = [0, 3, 7, 12]


def music_menu():
    # bouncy pastoral theme in C major, 112 bpm
    t = Track(112)
    chords = ["C3", "A2", "F2", "G2"] * 2
    shapes = [MAJ, MIN, MAJ, MAJ] * 2
    lead = expand(
        "E5 ~ G5 ~ C6 ~ B5 A5 | G5 ~ ~ ~ E5 ~ - - "
        "| A5 ~ G5 ~ E5 ~ C5 ~ | D5 ~ ~ ~ - - - - "
        "| F5 ~ A5 ~ C6 ~ A5 ~ | G5 ~ E5 ~ C5 ~ E5 ~ "
        "| F5 ~ E5 ~ D5 ~ B4 ~ | C5 ~ ~ ~ - - G4 ~ ")
    # 8 steps per bar on the lead line -> stretch to 16 steps
    lead16 = []
    for s in lead:
        lead16 += [s, "~" if s != "-" else "-"]
    t.add(lead16, duty=0.25, volume=0.16, vibrato=0.004)
    t.add(chord_bass(chords, ["R", "-", "-", "-", "F", "-", "-", "-",
                              "O", "-", "-", "-", "F", "-", "R", "-"]),
          wave_fn="triangle", volume=0.4, gate=0.9)
    t.add(arp(chords, shapes, octave_shift=1), duty=0.125, volume=0.05, gate=0.6)
    t.add_drums(expand("k - h - s - h - k - h k s - h h") * 8, volume=0.18)
    return t.render()


def music_level():
    # night city chase in A minor, 140 bpm
    t = Track(140)
    chords = ["A2", "A2", "F2", "G2", "A2", "A2", "D3", "E2"]
    shapes = [MIN, MIN, MAJ, MAJ, MIN, MIN, MIN, MAJ]
    lead = expand(
        "A4 ~ C5 ~ E5 ~ A5 ~ G5 ~ E5 ~ D5 ~ E5 ~ "
        "| - - E5 ~ D5 ~ C5 ~ B4 ~ C5 ~ D5 ~ E5 ~ "
        "| F5 ~ ~ ~ A5 ~ F5 ~ G5 ~ ~ ~ B5 ~ G5 ~ "
        "| A5 ~ ~ ~ ~ ~ - - E5 ~ ~ ~ - - - - "
        "| A4 ~ C5 ~ E5 ~ A5 ~ G5 ~ E5 ~ D5 ~ E5 ~ "
        "| - - E5 ~ G5 ~ A5 ~ C6 ~ B5 ~ A5 ~ G5 ~ "
        "| F5 ~ ~ ~ E5 ~ D5 ~ C5 ~ ~ ~ D5 ~ E5 ~ "
        "| G#5 ~ ~ ~ E5 ~ ~ ~ B4 ~ ~ ~ G#4 ~ ~ ~ ")
    t.add(lead, duty=0.25, volume=0.13, vibrato=0.005)
    t.add(chord_bass(chords, ["R", "-", "R", "O", "R", "-", "R", "O",
                              "R", "-", "R", "O", "F", "-", "O", "-"]),
          wave_fn="triangle", volume=0.42, gate=0.7)
    t.add(arp(chords, shapes, octave_shift=1), duty=0.125, volume=0.045, gate=0.5)
    t.add_drums(expand("k - h - s - h k - k h - s - h o") * 8, volume=0.2)
    return t.render()


def music_bonus():
    # fast motorbike run in E major, 168 bpm
    t = Track(168)
    chords = ["E2", "E2", "C#3", "C#3", "A2", "B2", "E2", "B2"]
    shapes = [MAJ, MAJ, MIN, MIN, MAJ, MAJ, MAJ, MAJ]
    lead = expand(
        "E5 ~ B4 ~ E5 ~ G#5 ~ B5 ~ ~ ~ G#5 ~ E5 ~ "
        "| F#5 ~ ~ ~ E5 ~ D#5 ~ E5 ~ ~ ~ - - B4 ~ "
        "| C#5 ~ E5 ~ G#5 ~ C#6 ~ B5 ~ ~ ~ G#5 ~ ~ ~ "
        "| E5 ~ F#5 ~ G#5 ~ E5 ~ C#5 ~ ~ ~ - - - - "
        "| A5 ~ ~ ~ G#5 ~ F#5 ~ E5 ~ ~ ~ C#5 ~ E5 ~ "
        "| F#5 ~ ~ ~ D#5 ~ ~ ~ B4 ~ ~ ~ D#5 ~ F#5 ~ "
        "| G#5 ~ ~ ~ B5 ~ G#5 ~ E5 ~ ~ ~ G#5 ~ B5 ~ "
        "| B5 ~ A5 ~ G#5 ~ F#5 ~ D#5 ~ ~ ~ B4 ~ - - ")
    t.add(lead, duty=0.5, volume=0.11, vibrato=0.004)
    t.add(chord_bass(chords, ["R", "O", "R", "O", "R", "O", "R", "O",
                              "R", "O", "R", "O", "F", "O", "F", "O"]),
          wave_fn="triangle", volume=0.4, gate=0.6)
    t.add(arp(chords, shapes, octave_shift=1), duty=0.125, volume=0.045, gate=0.5)
    t.add_drums(expand("k h h h s h h k k h k h s h o h") * 8, volume=0.2)
    return t.render()


def export_music(name, samples):
    wav = os.path.join(MUSIC_DIR, name + ".wav")
    write_wav(wav, samples, peak=0.7)
    if shutil.which("ffmpeg"):
        ogg = os.path.join(MUSIC_DIR, name + ".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
                        "-c:a", "libvorbis", "-q:a", "3", ogg], check=True)
        os.remove(wav)


def main():
    for name, samples in build_sfx().items():
        write_wav(os.path.join(SFX_DIR, name + ".wav"), samples)
        print("sfx  ", name)
    for name, builder in (("menu", music_menu), ("level", music_level), ("bonus", music_bonus)):
        export_music(name, builder())
        print("music", name)


if __name__ == "__main__":
    main()
