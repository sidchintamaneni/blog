# BPF Tailcalls

This is an old blog that I wrote when I was in grad school. I moved it from
*[old
website](https://raw.githubusercontent.com/sidchintamaneni/archived_blog/refs/heads/main/content/posts/tailcalls.md)*
to here.
Some of the details mentioned in this blog post might be outdated.

This blog expects you to have basic understanding of BPF programs and the verifier.

## If you want to understand...

-   Tail calls? 

-   BPF-to-BPF calls?

-   Why each BPF program is restricted to 256 bytes by the verifier when both
BPF-to-BPF and Tail calls are used together, why the number of tailcalls is
restricted to 33, and how runtime restrictions are enforced?

-   How to write BPF programs with Tail calls?

## Tail calls in BPF

In a BPF program, Tail calls are used to call another BPF program during
runtime without returning to the previous program. Similar to tailcall recursion/
optimization/ elimination, a BPF tailcall program uses the same stack frame as the
caller program.

If you are not familiar with tailcall optimization, check out
*[wikipedia](https://en.wikipedia.org/wiki/Tail_call)*, *[eklitzke blog
post](https://eklitzke.org/how-tail-call-optimization-works)* and *[computerphile
youtube video](https://www.youtube.com/watch?v=_JtPhF8MshA)*.

## BPF-to-BPF calls

These operate like regular function calls in BPF programs. When a BPF program
invokes another function, it creates a new stack frame. The verifier ensures
that the combined stack size of the BPF program and its callee functions does
not exceed 512 bytes.

## Now to the Q3, the weird limits?

BPF programs reuse the same kernel stack (not true anymore, but tail calls are
still an exception), so to avoid stack overflows, the verifier limits a BPF program to
512 bytes.

The number of Tail calls in BPF programs is restricted to 33 (counting the main
program) to avoid longer execution times and CPU stalls. Later, we'll see how this
limit is used to avoid stack overflow.

When both BPF-to-BPF and Tail calls are used together, each BPF program size is
restricted to 256 bytes. Now the maximum stack size of the BPF program is
restricted to 33 * 256 ~ 8 KB, which is less than the kernel stack size of 16 KB in
x86_64 bit kernels, preventing overflow (The assumption here is that
there is always 8 KB of stack space available for BPF programs to run).

The *[Verifier](https://elixir.bootlin.com/linux/v6.13.1/source/kernel/bpf/verifier.c#L6156)*
restricts the size of BPF programs to 256 bytes and JIT limits Tail call count
to 33 (Explained below). 

## Tail call program

*[Kernel Source](https://github.com/sidchintamaneni/blog/tree/main/pages/blogs/code/bpf_tailcall/tailcall_prog.kern.c):*
```c
struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 1);
	__uint(key_size, sizeof(__u32));
	__array(values, int(void *));
} prog_array SEC(".maps") = {
	.values = {
		[1] = (void *)&testing_tailcall,
	},
};

int testing_tailcall(void *ctx){
	return 0;
}

int trace_enter_execve(void *ctx){
	
	bpf_tail_call(ctx, &prog_array, 1);
	return 0;
}
```

*[Userspace source](https://github.com/sidchintamaneni/blog/tree/main/pages/blogs/code/bpf_tailcall/tailcall_prog.user.c)*


**Command to attach the BPF program using BPFTOOL**
```bash
bpftool prog loadAll tailcall_kern.o /sys/fs/bpf/test autoattach
```

To trigger the BPF program, you'll need to write a userspace program based on
the attached hook. With the example code provided, a simple ls command will
trigger the program.

For print output
```bash
cat /sys/kernel/debug/tracing/trace_pipe

or

bpftool prog tracelog
```

## Calling Tail calls within BPF-to-BPF calls

*[Kernel code](https://github.com/sidchintamaneni/blog/blob/main/pages/blogs/code/bpf_tailcall/tailcalls_prog2.kern.c)*

- Attaching and triggering mechanism is similar to the above program, so I am
not including the Userspace and trigger Code.

## Program with multiple Tail calls

*[Kernel code](https://github.com/sidchintamaneni/blog/tree/main/pages/blogs/code/bpf_tailcall/tailcall_max_prog.kern.c)*

## Now let's see how jited code enforces Tail call limit

Below are asm snapshots of jited BPF code during runtime.

```asm
     1	   0xffffffffa00020a8:	endbr64
     2	   0xffffffffa00020ac:	nopl   0x0(%rax,%rax,1)
     3	   0xffffffffa00020b1:	xor    %eax,%eax
     4	   0xffffffffa00020b3:	push   %rbp
     5	   0xffffffffa00020b4:	mov    %rsp,%rbp
     6	   0xffffffffa00020b7:	endbr64
     7	   0xffffffffa00020bb:	push   %rax
     8	   0xffffffffa00020ed:	mov    -0x4(%rbp),%eax
     9	   0xffffffffa00020f3:	cmp    $0x21,%eax
    10	   0xffffffffa00020f6:	jae    0xffffffffa000210d
    11	   0xffffffffa00020f8:	add    $0x1,%eax
    12	   0xffffffffa00020fb:	mov    %eax,-0x4(%rbp)
    13	   0xffffffffa0002101:	nopl   0x0(%rax,%rax,1)
    14	   0xffffffffa0002106:	pop    %rbx
    15	   0xffffffffa0002107:	pop    %rax
    16	   0xffffffffa0002108:	jmp    0xffffffffa0002007
    17	   0xffffffffa000210d:	xor    %eax,%eax
    18	   0xffffffffa000210f:	pop    %rbx
```

The above is an abridged snapshot of the jitted code of the starting program that
is calling a tailcall. In instruction 3, we can see that eax is set to 0, and in instructions 4
and 7, both rbp and rax values are pushed onto the stack. In instruction 8, the earlier
pushed rax value is accessed and moved to eax. Then it is compared to see if its
count is equal to 33. If it is 33, then it jumps to instruction 17; otherwise, eax is
incremented by 1 and updates the stack value.

```asm
     1	   0xffffffffa0002007:	endbr64
     2	   0xffffffffa000200b:	push   %rax
     3	   0xffffffffa000200c:	push   %rbx
     4	   0xffffffffa000200d:	mov    %rdi,%rbx
     5	   0xffffffffa0002010:	movabs $0xffff88800712a530,%rdi
     6	   0xffffffffa000201a:	mov    $0x13,%esi
     7	   0xffffffffa000201f:	mov    -0x8(%rbp),%rax
     8	   0xffffffffa0002026:	call   0xffffffff811cd720
     9	   0xffffffffa000202b:	mov    %rbx,%rdi
    10	   0xffffffffa000202e:	movabs $0xffff888006af0000,%rsi
    11	   0xffffffffa0002038:	mov    $0x1,%edx
    12	   0xffffffffa000203d:	mov    -0x4(%rbp),%eax
    13	   0xffffffffa0002043:	cmp    $0x21,%eax
    14	   0xffffffffa0002046:	jae    0xffffffffa000205d
    15	   0xffffffffa0002048:	add    $0x1,%eax
    16	   0xffffffffa000204b:	mov    %eax,-0x4(%rbp)
    17	   0xffffffffa0002051:	nopl   0x0(%rax,%rax,1)
    18	   0xffffffffa0002056:	pop    %rbx
    19	   0xffffffffa0002057:	pop    %rax
    20	   0xffffffffa0002058:	jmp    0xffffffffa0001f27
    21	   0xffffffffa000205d:	xor    %eax,%eax
    22	   0xffffffffa000205f:	pop    %rbx
```

The above assembly code is a snapshot taken after the jump instruction. When the
tail call count value stored inside reaches 32, the BPF program will be
terminated.

## References
* [Cloud Fare Blog by Jakub Sitnicki](https://blog.cloudflare.com/assembly-within-bpf-tail-calls-on-x86-and-arm/#:~:text=Tail%20calls%20can%20be%20seen,reusing%20the%20same%20stack%20frame)
* [Cilium Docs](https://docs.cilium.io/en/stable/bpf/architecture/#tail-calls)
