#include <bpf/bpf_helpers.h>
#include <linux/version.h>
#include <uapi/linux/bpf.h>
#include <bpf/bpf_tracing.h>

SEC("fentry/__x64_sys_execve")
int testing_func5(void *ctx){
    bpf_printk("inside tail-call 5");
    return 0;
}

struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 10);
	__uint(key_size, sizeof(__u32));
	__array(values, int (void *));
} prog_array_init5 SEC(".maps") = {
	.values = {
		[1] = (void *)&testing_func5,
	},
};
SEC("fentry/__x64_sys_execve")
int testing_func4(void *ctx){
    bpf_printk("inside tail-call 4");
    bpf_tail_call(ctx, &prog_array_init5, 1);
    return 0;
}

struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 10);
	__uint(key_size, sizeof(__u32));
	__array(values, int (void *));
} prog_array_init4 SEC(".maps") = {
	.values = {
		[1] = (void *)&testing_func4,
	},
};

#define RTAIL_CALL(X, Y) \
SEC("fentry/__x64_sys_execve") \
int testing_func ## X(void *ctx){ \
    bpf_printk("inside tail-call %s",#X); \
    bpf_tail_call(ctx, &prog_array_init##Y, 1); \
    return 0; \
} \
struct { \
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY); \
	__uint(max_entries, 2); \
	__uint(key_size, sizeof(__u32)); \
	__array(values, int (void *)); \
} prog_array_init##X SEC(".maps") = { \
	.values = { \
		[1] = (void *)&testing_func##X, \
	}, \
} \

RTAIL_CALL(3, 4);
RTAIL_CALL(2, 3);


SEC("fentry/__x64_sys_execve")
int testing_func(void *ctx){
    bpf_printk("inside tail-call 1");

    bpf_tail_call(ctx, &prog_array_init2, 1);
    return 0;
}


struct {
	__uint(type, BPF_MAP_TYPE_PROG_ARRAY);
	__uint(max_entries, 10);
	__uint(key_size, sizeof(__u32));
	__array(values, int (void *));
} prog_array_init SEC(".maps") = {
	.values = {
		[1] = (void *)&testing_func,
	},
};

SEC("fentry/__x64_sys_execve")
int trace_enter_execve(struct pt_regs *ctx)
{	
    bpf_printk("Inside Kernel Main Function");

    bpf_tail_call(ctx, &prog_array_init, 1);

    return 0;	
}

char _license[] SEC("license") = "GPL";
u32 _version SEC("version") = LINUX_VERSION_CODE;