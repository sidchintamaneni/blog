#!/usr/bin/env python3
"""Render the two consolidated UnixBench tables (1-inst, 112-inst) as PNGs."""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

COLS = ["Test", "no-LTO", "ThinLTO", "AutoFDO", "+Propeller"]

TESTS = [
    "Dhrystone 2", "Double-Precision Whetstone", "Execl Throughput",
    "File Copy 1024", "File Copy 256", "File Copy 4096",
    "Pipe Throughput", "Pipe-based Context Switching", "Process Creation",
    "Shell Scripts (1 concurrent)", "Shell Scripts (8 concurrent)",
    "System Call Overhead",
]

ONE = {
    "Dhrystone 2": ["3,379.8", "3,371.7", "3,379.0", "3,351.9"],
    "Double-Precision Whetstone": ["1,192.2", "1,192.8", "1,193.1", "1,192.5"],
    "Execl Throughput": ["787.0", "789.7", "817.7", "839.6"],
    "File Copy 1024": ["3,071.1", "2,851.1", "3,556.4", "3,588.3"],
    "File Copy 256": ["2,012.2", "1,918.3", "2,384.8", "2,429.7"],
    "File Copy 4096": ["6,248.8", "5,909.8", "6,843.5", "6,833.0"],
    "Pipe Throughput": ["1,705.8", "1,687.6", "1,897.7", "1,908.0"],
    "Pipe-based Context Switching": ["454.8", "426.6", "505.1", "506.4"],
    "Process Creation": ["481.3", "483.2", "500.9", "498.6"],
    "Shell Scripts (1 concurrent)": ["1,562.8", "1,563.1", "1,636.5", "1,637.5"],
    "Shell Scripts (8 concurrent)": ["8,679.2", "8,691.4", "9,060.4", "9,037.7"],
    "System Call Overhead": ["1,086.3", "1,081.1", "1,118.2", "1,126.4"],
    "Index Score": ["1,720.7", "1,685.1", "1,841.7", "1,849.8"],
    "% vs no-LTO (Index)": ["—", "-2.1%", "+7.0%", "+7.5%"],
}

HI = {
    "Dhrystone 2": ["369,165.2", "369,548.7", "369,488.8", "367,911.0"],
    "Double-Precision Whetstone": ["132,693.4", "132,807.9", "132,794.8", "132,833.4"],
    "Execl Throughput": ["5,453.2", "5,680.8", "5,654.8", "5,715.7"],
    "File Copy 1024": ["199,240.3", "197,098.5", "229,722.3", "228,758.1"],
    "File Copy 256": ["206,374.9", "196,936.0", "245,057.0", "250,718.7"],
    "File Copy 4096": ["75,548.5", "74,427.3", "76,772.4", "77,662.8"],
    "Pipe Throughput": ["184,586.4", "182,164.1", "206,974.6", "208,787.5"],
    "Pipe-based Context Switching": ["35,643.6", "35,249.1", "41,617.5", "41,643.8"],
    "Process Creation": ["9,824.3", "9,953.2", "9,435.1", "8,891.1"],
    "Shell Scripts (1 concurrent)": ["28,849.4", "29,918.6", "30,608.1", "30,908.1"],
    "Shell Scripts (8 concurrent)": ["25,619.3", "26,322.6", "27,086.2", "27,771.7"],
    "System Call Overhead": ["118,934.5", "118,041.0", "122,440.1", "123,353.3"],
    "Index Score": ["63,987.5", "64,068.9", "68,066.7", "68,232.6"],
    "% vs no-LTO (Index)": ["—", "+0.1%", "+6.4%", "+6.6%"],
}


def _fill(ax, data, title):
    rows = TESTS + ["Index Score", "% vs no-LTO (Index)"]
    cells = [[t] + data[t] for t in rows]
    BG = "#faf6ec"; HDR = "#f1ead9"; EDGE = "#d9d0be"; TEXT = "#2e2a26"
    ax.set_facecolor(BG)
    ax.axis("off")
    ax.set_title(title, fontsize=13, fontweight="bold", color=TEXT, pad=10)
    tbl = ax.table(cellText=cells, colLabels=COLS, loc="center", cellLoc="center",
                   colWidths=[0.34, 0.165, 0.165, 0.165, 0.165])
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.scale(1, 1.5)
    for (r, c), cell in tbl.get_celld().items():
        cell.set_edgecolor(EDGE); cell.set_linewidth(0.7); cell.set_text_props(color=TEXT)
        if r == 0:
            cell.set_facecolor(HDR); cell.set_text_props(color=TEXT, fontweight="bold")
        else:
            cell.set_facecolor(BG)
            if rows[r - 1] in ("Index Score", "% vs no-LTO (Index)"):
                cell.set_text_props(fontweight="bold")
        if c == 0 and r > 0:
            cell.set_text_props(ha="left")
    for r in range(1, len(rows) + 1):
        tbl[(r, 0)].get_text().set_ha("left")


def render(data, title, out):
    plt.rcParams["font.family"] = "serif"
    BG = "#faf6ec"
    fig, ax = plt.subplots(figsize=(9.5, 6.4))
    fig.patch.set_facecolor(BG)
    _fill(ax, data, title)
    fig.savefig(out, dpi=200, bbox_inches="tight", facecolor=BG)
    print("wrote", out)


def render_side_by_side(out):
    plt.rcParams["font.family"] = "serif"
    BG = "#faf6ec"
    fig, axes = plt.subplots(1, 2, figsize=(18, 6.6))
    fig.patch.set_facecolor(BG)
    _fill(axes[0], ONE, "UnixBench Index — 1 instance (mean of 3 runs)")
    _fill(axes[1], HI,  "UnixBench Index — 112 instances (mean of 3 runs)")
    fig.subplots_adjust(wspace=0.04)
    fig.savefig(out, dpi=200, bbox_inches="tight", facecolor=BG)
    print("wrote", out)


if __name__ == "__main__":
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    render(ONE, "UnixBench Index — 1 instance (mean of 3 runs)", f"{outdir}/unixbench-1inst.png")
    render(HI,  "UnixBench Index — 112 instances (mean of 3 runs)", f"{outdir}/unixbench-112inst.png")
    render_side_by_side(f"{outdir}/unixbench-combined.png")
