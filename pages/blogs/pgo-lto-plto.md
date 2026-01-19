# Exploring & Experimenting with PGO-LTO-PLTO

## How it all started

It all started when I am downloading CachyOS to run some sched_ext[1]
experiments. While the OS was downloading, I looked into one of their published
blogs - "CachyOS Recap 2026 and Merry Christmas"[2]. One thing that caught my
eye was the feature that they've recently introduced

```
Optimization: The default kernel (linux-cachyos) is now optimized using
Propeller in conjunction with AutoFDO. This combination results in approximately
a 10% throughput improvement and reduced latency, depending on the workload.
```

The performance improvements looks insane. So now the question becomes what are
AutoFDO, Propeller and when did linux kernel started to support it? To answer
the second question, I got to know with a quick search that it was added to
linux kernel build system in 6.13[3] and currently only supported by clang/llvm
compiler[4].

Now coming back to our first question what are AutoFDO & Propeller, I found a
self-explanatory presentation about Optimizing the Linux Kernel using AutoFDO &
Propeller[5]. Now I got introduced new terms - FDO, iFDO, AutoFDO, BOLF &
Propeller. I was barely familiar with FDO/PGO (Feedback directed
optimization/ Profile Guided optimization). We will explore what each of these
terms means and experiment with them.

I am expecting this blog to be a two part series. In the first part we will
run and experiment with these optimizations with a simple binary, later we will
discuss these in the context of Linux kernel.

## Compiler Optimizations

# References
[1] https://github.com/sched-ext/scx/tree/main
[2] https://cachyos.org/blog/2025-christmas-new-year/
[3] https://lore.kernel.org/all/20241102175115.1769468-1-xur@google.com/
[4] https://discourse.llvm.org/t/optimizing-the-linux-kernel-with-autofdo-including-thinlto-and-propeller/79108
[5] https://lpc.events/event/18/contributions/1922/attachments/1450/3084/AutoFDO%20&%20Propeller%20in%20LPC%202024.pdf
