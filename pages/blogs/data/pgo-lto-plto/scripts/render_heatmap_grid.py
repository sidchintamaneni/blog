#!/usr/bin/env python3
"""Compose four kernel heatmap PNGs into a single 2x2 grid.

Usage:
  python3 render_heatmap_grid.py <logs_base_dir> <out.png>

Expects <logs_base_dir>/<kver>/heatmap/heatmap.png for the four kvers below.
Edit KVERS if your tags differ.
"""
import sys, os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.image as mpimg

KVERS = [
    ("no-LTO",   "6.18.26.1-plto-nolto-build+"),
    ("ThinLTO",  "6.18.26.1-plto-thinlto-build+"),
    ("AutoFDO",  "6.18.26.1-thinlto-autofdo-profile-build+"),
    ("Propeller","6.18.26.1-plto-propeller-build+"),
]

def main():
    base = sys.argv[1] if len(sys.argv) > 1 else "."
    out  = sys.argv[2] if len(sys.argv) > 2 else "heatmap-grid.png"

    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    for ax, (label, kver) in zip(axes.ravel(), KVERS):
        path = os.path.join(base, kver, "heatmap", "heatmap.png")
        ax.axis("off")
        if os.path.exists(path):
            ax.imshow(mpimg.imread(path))
            ax.set_title(label, fontsize=15, fontweight="bold")
        else:
            ax.set_title(f"{label} (missing:\n{path})", fontsize=9)
    fig.subplots_adjust(wspace=0.02, hspace=0.08, left=0.01, right=0.99, top=0.96, bottom=0.01)
    fig.savefig(out, dpi=150, bbox_inches="tight")
    print("wrote", out)

if __name__ == "__main__":
    main()
