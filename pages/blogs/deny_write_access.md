# Tales of ETXBSY error in exec.

I started exploring and understanding the problems caused by `deny_write_access()` in the exec syscall by following the *[issue thread](https://github.com/rui314/mold/issues/1361)* in mold linker raised by my labmate and friend *[Jinghao Jia](https://jinghao-jia.github.io/)*.


## Fork and Exec system calls

In Linux or Unix-based operating systems, it is common to use fork and exec system calls in combination to spawn a new process:

- The Fork system call creates a new child process which inherits the file descriptors from the parent. It does a little more than that; read more at the *[man page](https://man7.org/linux/man-pages/man2/fork.2.html)*.

- The Exec system call, which takes a path to a binary as one of its arguments, replaces the child process. Similar to fork, exec inherits the file descriptors from the caller process. The `FD_CLOEXEC` flag can be used while opening a file to avoid the inheritance. Read more at the *[man page](https://man7.org/linux/man-pages/man2/execve.2.html)*. 

If you scroll down to the error section in the exec man page, you will find `ETXBSY`. Exec returns `ETXBSY` when some other process has opened the same file with write access. This makes sense because changing the contents of a running executable is unsafe. So internally, inside the exec system, it checks for *[deny_write_access](https://elixir.bootlin.com/linux/v6.13.2/source/fs/exec.c#L915)* to avoid such conflicts.


## How is the deny_write_access() check seems to be a problem for multi-threaded program

A few years back, an *[issue](https://github.com/golang/go/issues/22315)* was reported in the golang repo by *[Russ Cox](https://github.com/rsc)*. In the issue, he described how the interactions of fork and exec are creating a problem while executing a new process.

The example provided in the issue is quite simple to follow. I will try to explain it at a high level. When multiple threads are spawning a child process using fork, all the child processes inherit all the file descriptors opened by the parent process. After closing an fd in a child process, the exec on that file may still fail because child processes from different threads may still have access to the opened fd. Opening a file with the `FD_CLOEXEC` flag will also not help in this scenario because of the same reason.

There are some weird workarounds mentioned in the issue to solve this problem, which I thought I would never see in systems programming because the weirdness here is not because of bad implementation of a userspace library or program. It is due to how the system-level interfaces are provided to perform a task, and I consider it a design flaw.

## Are people working to fix this?

In May 2024, *[Christian Brauner](https://github.com/brauner)* sent a *[kernel patch](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=2a010c412853)* to fix this problem. I highly suggest you go over the patch cover letter. He mentioned possible attacks because of allowing write access to running executables and how `deny_write_access()` is not solving the problem.

**At this point, you might be thinking how this change is related to the issue raised in mold:**

As mentioned in this *[comment](https://github.com/rui314/mold/issues/1361#issuecomment-2439427338)* by the mold maintainer *[Rui Ueyama](https://github.com/rui314)*, mold *[internally](https://github.com/rui314/mold/blob/143d447a66fcb03ace1debf92cc10e5ccd0b9f8f/src/output-file-unix.cc#L19)* reuses an existing file instead of a new one because the former is faster. The above change by Christian Brauner broke a userspace program.

If you're not familiar, there is this famous quote by Linus Torvalds:
`Never break userspace`

So the patches were withdrawn.

## Why is this interesting to analyze?

Because of an interface provided by the kernel, userspace programs are facing some weird problems; in this scenario, exec is returning `ETXBSY` error. To work around this problem, people are coming up with weird hacks, and good programmers never like weird hacks. An attempt to fix the problem is breaking Linux's longstanding policy of `Never break userspace`.

I am neither supporting nor opposing the kernel's policy because there are upsides and downsides to it. Upsides are that userspace programs never have to think about the kernel except for the interfaces it provides. Downsides are that userspace programs must take care of corner cases (which are never documented) like these and come up with weird hacks. Along with this example, if you have ever done socket programming and ended up calling too many syscalls with lots of flags, you know what to blame. 

I don't have an answer on how to resolve this problem, but it raises interesting questions in the area of Operating Systems design.