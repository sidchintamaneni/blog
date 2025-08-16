# Start of the series on locking in Linux kernel

## Why This Series?

Synchronization is something that I'm always interested in, maybe because it
belongs to this weird list of algorithms where there is no one right answer and
you can always say "it depends." There are lots of cool things that you can
reason about when implementing a new locking mechanism, such as performance and
fairness—similar to congestion control and scheduling algorithms.

I'm expecting this blog series not to be a walkthrough of the existing code in
the Linux kernel. I'm planning to port all the existing kernel locking
mechanisms to kernel modules, maybe in Rust (let's see—there's no real research
motivation for this, TBH I thought it would be cool), and measure performance and
reason about fairness. What I expect to come out of this journey is to see if I
can draw insights on whether I can develop static/dynamic mechanisms to test the
existing locking mechanisms for bugs.


## What I am planning to blog on

- Atomics
- Spin locks
- Ticketing spin locks
- Queued spin locks
- Read-Copy-Update (RCU) locks
- Mutexes
- Semaphores
- Reader-writer locks
- Resilient spin locks

*This list may change*

If you are interested contributing to this journey, feel free to reach out to me
we can co-ordinate and work together.
