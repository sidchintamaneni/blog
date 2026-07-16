#!/usr/bin/env python3
"""Temporal instruction-access heatmap (the "instruction offset access" figures from Part 1).

Reads a `perf script -F time,ip,dso` dump and renders a 2-D density histogram:
    x = sample time (normalized 0..1 over the run)
    y = instruction-pointer offset into .text (relative to the lowest sampled address)
    color = number of samples in that (time, offset) bin (log-scaled)

Hot code packed tightly (BOLT/Propeller/PGO) shows as a narrow bright band; code spread
across the whole address range (plain LTO) scatters over the full height. A few sparse
samples sit far above the main .text (modules / BPF-JIT / vsyscall); by default the y-axis
is zoomed to the 0-99th percentile so the hot band fills the plot (--pmax 100 to disable).

Usage:
    python3 plot_heatmap.py heatmap.txt -o heatmap.png --title "Propeller 6.18"
    python3 plot_heatmap.py heatmap.txt --pmax 95               # tighter zoom
    python3 plot_heatmap.py heatmap.txt --dso '[kernel.kallsyms]'   # filter one module
    # compare two builds side by side on a shared offset axis:
    python3 plot_heatmap.py a.txt b.txt -o pair.png --labels "AutoFDO" "Propeller"
"""
import argparse
import re
import sys

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import LogNorm  # noqa: E402

# a perf-script line looks like:  "   1234.567890:   ffffffff81abcd00 [kernel.kallsyms]"
LINE_RE = re.compile(r"^\s*([0-9]+\.[0-9]+):\s*([0-9a-fA-F]+)\b(.*)$")


def load(path, dso_filter=None):
    """Return (times, ips) float arrays parsed from a perf-script dump."""
    times, ips = [], []
    with open(path, "r", errors="ignore") as fh:
        for line in fh:
            if dso_filter and dso_filter not in line:
                continue
            m = LINE_RE.match(line)
            if not m:
                continue
            times.append(float(m.group(1)))
            ips.append(int(m.group(2), 16))
    if not ips:
        sys.exit(f"no samples parsed from {path} "
                 f"(check the file is `perf script -F time,ip,dso` output"
                 + (f", dso filter '{dso_filter}'" if dso_filter else "") + ")")
    return np.array(times, dtype=np.float64), np.array(ips, dtype=np.float64)


def render(ax, times, ips, bins, title, y_base=None, y_span=None):
    t0, t1 = times.min(), times.max()
    x = (times - t0) / (t1 - t0) if t1 > t0 else np.zeros_like(times)
    base = y_base if y_base is not None else ips.min()
    y = (ips - base) / 1e6  # offset into .text, in MB
    span = y_span if y_span is not None else (y.max() if y.max() > 0 else 1.0)

    h, xe, ye = np.histogram2d(
        x, y, bins=bins, range=[[0, 1], [0, span]]
    )
    h = h.T  # rows = y (offset), cols = x (time)
    masked = np.ma.masked_where(h == 0, h)
    im = ax.imshow(
        masked, origin="lower", aspect="auto",
        extent=[0, 1, 0, span], cmap="inferno",
        norm=LogNorm(vmin=1, vmax=max(h.max(), 1)),
        interpolation="nearest",
    )
    ax.set_facecolor("black")
    ax.set_xlabel("Time (normalized)")
    ax.set_ylabel("Instruction offset into .text (MB)")
    ax.set_title(title)
    return im, base, span


def zoom_span(data, pmax):
    """Upper y-limit (MB) = pmax-percentile of offsets across all inputs."""
    base = min(d[1].min() for d in data)
    offs = np.concatenate([(d[1] - base) / 1e6 for d in data])
    return base, float(np.percentile(offs, pmax))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+", help="one or two perf-script dumps")
    ap.add_argument("-o", "--out", default="heatmap.png", help="output PNG")
    ap.add_argument("--dso", default=None, help="only keep lines containing this DSO string")
    ap.add_argument("--bins", type=int, default=1000, help="histogram bins per axis")
    ap.add_argument("--pmax", type=float, default=99.0,
                    help="zoom y-axis to this offset percentile (100 = no zoom)")
    ap.add_argument("--title", default=None, help="title (single-input mode)")
    ap.add_argument("--labels", nargs="+", default=None, help="per-panel titles")
    ap.add_argument("--dpi", type=int, default=140)
    args = ap.parse_args()

    if len(args.inputs) > 2:
        sys.exit("at most two inputs (single plot or side-by-side comparison)")

    data = [load(p, args.dso) for p in args.inputs]
    labels = args.labels or ([args.title] if args.title else args.inputs)

    # shared offset base + zoom span so panels are comparable and the hot band fills view
    shared_base, span = zoom_span(data, args.pmax)
    print(f"zoom y=[0, {span:.3f}] MB (p{args.pmax:g})")

    if len(data) == 1:
        fig, ax = plt.subplots(figsize=(6, 6))
        im, _, _ = render(ax, data[0][0], data[0][1], args.bins, labels[0],
                          y_base=shared_base, y_span=span)
        fig.colorbar(im, ax=ax, label="samples / bin (log)")
    else:
        fig, axes = plt.subplots(1, 2, figsize=(12, 6), sharey=True)
        im = None
        for ax, (t, ip), lab in zip(axes, data, labels):
            im, _, _ = render(ax, t, ip, args.bins, lab,
                              y_base=shared_base, y_span=span)
        fig.colorbar(im, ax=axes, label="samples / bin (log)")

    fig.savefig(args.out, dpi=args.dpi, bbox_inches="tight")
    print(f"wrote {args.out}  ({sum(len(d[1]) for d in data)} samples)")


if __name__ == "__main__":
    main()
