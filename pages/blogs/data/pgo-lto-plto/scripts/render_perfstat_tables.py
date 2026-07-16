#!/usr/bin/env python3
"""Render the two perf stat tables (1-inst, 112-inst) as PNGs, incl. a combined side-by-side."""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

COLS = ["Metric", "no-LTO", "ThinLTO", "AutoFDO", "+Propeller"]
ROWS = ["Instructions (T)", "Cycles (T)", "IPC", "L1-icache misses (B)", "iTLB misses (B)"]

ONE = {
    "Instructions (T)":     ["130.0", "129.9", "129.2", "160.2"],
    "Cycles (T)":           ["1,011.6", "1,011.6", "1,011.1", "1,011.6"],
    "IPC":                  ["0.13", "0.13", "0.13", "0.16"],
    "L1-icache misses (B)": ["176.9", "179.0", "119.6", "108.0"],
    "iTLB misses (B)":      ["1.16", "1.11", "1.13", "1.13"],
}

HI = {
    "Instructions (T)":     ["486.2", "484.0", "474.2", "496.8"],
    "Cycles (T)":           ["1,018.7", "1,019.0", "1,018.4", "1,019.1"],
    "IPC":                  ["0.48", "0.47", "0.47", "0.49"],
    "L1-icache misses (B)": ["3,086.5", "2,953.8", "1,543.5", "1,436.7"],
    "iTLB misses (B)":      ["9.30", "9.46", "8.56", "8.27"],
}

BG = "#faf6ec"; HDR = "#f1ead9"; EDGE = "#d9d0be"; TEXT = "#2e2a26"
EMPH = {"IPC", "L1-icache misses (B)"}   # bold the two headline rows


def _fill(ax, data, title):
    cells = [[r] + data[r] for r in ROWS]
    ax.set_facecolor(BG); ax.axis("off")
    ax.set_title(title, fontsize=13, fontweight="bold", color=TEXT, pad=10)
    tbl = ax.table(cellText=cells, colLabels=COLS, loc="center", cellLoc="center",
                   colWidths=[0.38, 0.155, 0.155, 0.155, 0.155])
    tbl.auto_set_font_size(False); tbl.set_fontsize(11); tbl.scale(1, 1.7)
    for (r, c), cell in tbl.get_celld().items():
        cell.set_edgecolor(EDGE); cell.set_linewidth(0.7); cell.set_text_props(color=TEXT)
        if r == 0:
            cell.set_facecolor(HDR); cell.set_text_props(color=TEXT, fontweight="bold")
        else:
            cell.set_facecolor(BG)
            if ROWS[r - 1] in EMPH:
                cell.set_text_props(fontweight="bold")
        if c == 0 and r > 0:
            cell.set_text_props(ha="left")
    for r in range(1, len(ROWS) + 1):
        tbl[(r, 0)].get_text().set_ha("left")


def render(data, title, out):
    plt.rcParams["font.family"] = "serif"
    fig, ax = plt.subplots(figsize=(8.5, 3.2))
    fig.patch.set_facecolor(BG)
    _fill(ax, data, title)
    fig.savefig(out, dpi=200, bbox_inches="tight", facecolor=BG)
    print("wrote", out)


def render_side_by_side(out):
    plt.rcParams["font.family"] = "serif"
    fig, axes = plt.subplots(1, 2, figsize=(17, 3.4))
    fig.patch.set_facecolor(BG)
    _fill(axes[0], ONE, "perf stat — 1 instance")
    _fill(axes[1], HI,  "perf stat — 112 instances")
    fig.subplots_adjust(wspace=0.06)
    fig.savefig(out, dpi=200, bbox_inches="tight", facecolor=BG)
    print("wrote", out)


if __name__ == "__main__":
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    render(ONE, "perf stat — 1 instance", f"{outdir}/perfstat-1inst.png")
    render(HI,  "perf stat — 112 instances", f"{outdir}/perfstat-112inst.png")
    render_side_by_side(f"{outdir}/perfstat-combined.png")
