---
layout: article
title: Notes - Xv6
date: 2022-07-01
authors:
  - GentleTomZerg
tags:
  - operating system
categories:
  - Computer Science
mathjax: true
---

## Chapter1. Operating Systems Interfaces

When a **process** needs to invoke a **kernel service**, it invokes a **system call**, one of the calls in the operating system’s interface. The system call enters the kernel; the kernel performs the service and returns. Thus a process alternates between executing in user space and kernel space.

The **kernel** uses the **hardware protection** mechanisms provided by a CPU to ensure that **each process executing in user space can access only its own memory**. The kernel executes with the hardware privileges required to implement these protections; user programs execute without those privileges.

When a user program invokes a system call, the hardware raises the privilege level and starts executing a pre-arranged function in the kernel.

<!-- more -->

![image-20220307213809995](assets/Operating Systems.assets/image-20220307213809995.png)

### 1.1 Process and Memory

#### Xv6 System Calls Table

![image-20220307214019798](assets/Operating Systems.assets/image-20220307214019798.png)

#### System Call Example : fork()

`fork` **creates a new process**, called the child process, with **exactly the same memory contents as the calling process**, called the parent process. Fork **returns in both the parent and the child**.

In the `parent`, fork **returns the child’s PID**;

in the `child`, fork **returns zero**.

`exit` system call causes the calling process to **stop executing** and to **release resources such as memory and open files**. Exit takes an integer status argument, conventionally **0 to indicate success and 1 to indicate failure**.

`wait` system call **returns the PID of an exited (or killed) child of the current process** and copies the exit status of the child to the address `(int *)0` passed to wait;

if none of the caller’s children has exited, wait waits for one to do so.

If the caller has no children, wait immediately returns -1.

If the parent doesn’t care about the exit status of a child, it can pass a 0 address to wait.

```c
##include <stdio.h>
##include <stdlib.h>

int main(int argc, char const *argv[])
{
    int pid = fork();

    if (pid > 0)
    {
        printf("parent: child=%d\n", pid);
        pid = wait((int *)0);
        printf("child %d is done\n", pid);
    }
    else if (pid == 0)
    {
        printf("child: exiting\n");
        exit(0);
    }
    else
    {
        printf("fork error\n");
    }

    return 0;
}

//Output:
//parent: child=4821
//child: exiting
//child 4821 is done
```

#### System Call Example: shell

When `exec` succeeds, it **does not return to the calling program**; instead, the instructions loaded from the file **start executing at the entry point declared in the ELF header**.

```c
// Read and run input commands.
  while(getcmd(buf, sizeof(buf)) >= 0){
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
      // Chdir must be called by the parent, not the child.
      buf[strlen(buf)-1] = 0;  // chop \n
      if(chdir(buf+3) < 0)
        fprintf(2, "cannot cd %s\n", buf+3);
      continue;
    }
    //shell创建子进程去runcmd，shell（父进程）进入等待状态
    //shell给runcmd让出CPU
    if(fork1() == 0)
      runcmd(parsecmd(buf));
    wait(0);
  }
  exit(0);
}

int
fork1(void)
{
  int pid;

  pid = fork();
  if(pid == -1)
    panic("fork");
  return pid;
}
```

#### How does system calls shown above allocate memory

Xv6 allocates most user-space memory implicitly: **fork** allocates the memory required **for the child’s copy of the parent’s memory**, and **exec** allocates enough memory to **hold the executable file**. A process that needs more memory at run-time (perhaps for malloc) can call **`sbrk(n)`** to grow its data memory by n bytes; **`sbrk`** returns the location of the new memory.

### 1.2 I/O and File descriptors

A **`file descriptor`** is a small integer representing **a kernel-managed object** that a process may read from or write to.

A process may obtain a file descriptor by opening a file, directory, or device, or by creating a pipe, or by duplicating an existing descriptor. For simplicity we’ll often refer to the object a file descriptor refers to as a “file”; the **file descriptor interface abstracts away the differences between files, pipes, and devices, making them all look like streams of bytes**.

Internally, the **xv6 kernel uses the file descriptor as an index into a `per-process table`**, so that **every process has a private space of file descriptors starting at zero**. By convention, a process

reads from file descriptor **0 (standard input)**,

writes output to file descriptor **1 (standard output)**,

writes error messages to file descriptor **2 (standard error)**.

#### read(), write(), close()

**`Each file descriptor that refers to a file has an offset associated with it`**

call **`read(fd, buf, n)`** reads at most n bytes from the file descriptor `fd`, copies them into `buf`, and returns the number of bytes read.

call **`write(fd, buf, n)`** writes n bytes from `buf` to the file descriptor `fd` and returns the number of bytes written.

The **`close`** system call releases a file descriptor, making it free for reuse by a future open, pipe, or dup system call (see below). **A newly allocated file descriptor is always the <u>lowest numbered unused descriptor</u> of the current process**.

#### `cat` source code

```c
##include "kernel/types.h"
##include "kernel/stat.h"
##include "user/user.h"

char buf[512];

void
cat(int fd)
{
  int n;

  while((n = read(fd, buf, sizeof(buf))) > 0) {
    if (write(1, buf, n) != n) {
      fprintf(2, "cat: write error\n");
      exit(1);
    }
  }
  if(n < 0){
    fprintf(2, "cat: read error\n");
    exit(1);
  }
}

int
main(int argc, char *argv[])
{
  int fd, i;
  //未给出文件名，输入流默认为0（标准输入流）
  if(argc <= 1){
    cat(0);
    exit(0);
  }
//有文件名，用open打开，获得kernel给该文件分配的具有最小值的fd
  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
      fprintf(2, "cat: cannot open %s\n", argv[i]);
      exit(1);
    }
    cat(fd);
    close(fd);
  }
  exit(0);
}
```

#### I/O Redirection

`Fork` copies the parent’s **file descriptor table** along with its memory, so that the **child starts with exactly the same open files as the parent**.

system call `exec` replaces the calling process’s memory but **preserves its file table**

`shell$ cat < input.txt`: 将file descriptor 0 重定向到了`input.txt`，从而`cat`接收到的输入不再从键盘来。

```c
char *argv[2];
argv[0] = "cat";
argv[1] = 0;
//shell进程wait，子进程执行cat
//子进程 release 0（standard input）
//从而input.txt一定能拿到0作为fd
//子进程cat的输入流就从键盘变为了input.txt
if(fork() == 0) {
close(0);
open("input.txt", O_RDONLY);
exec("cat", argv);
}
```

The **parent process’s file descriptors are not changed by this sequence**, since it modifies only the child’s descriptors.

这样做，shell的file descriptor(指向显存)依然被shell进程保存着，但是cat进程的file descriptor已经被改变了（指向文件）。但**两个进程并没有受到该值改变的影响，这也是为什么fork和execute要分开写的原因**。

Now it should be clear why it is helpful that fork and exec are separate calls: between the two, the **shell has a chance to redirect the child’s I/O <u>without disturbing the I/O setup of the main shell</u>**.

#### Shared file offset(?)

```tex
My Question
file的offset被共享的话，如果父进程fp指向显存，子进程fp指向了一个文件，子进程改变了偏移量，当转到父进程的时候，父进程会空出一定量的offset继续输出嘛？需要知道file descriptors table究竟是咋回事。
```

Although fork copies the file descriptor table, **each underlying file offset is shared between parent and child**. **Two file descriptors share an offset** if they were derived from the same original file descriptor by a sequence of **fork and dup calls**.

```c
if(fork() == 0) {
write(1, "hello ", 6);
exit(0);
} else {
wait(0);
write(1, "world\n", 6);
}
//Output
//Hello World
```

### 1.3 Pipes(\*)

#### Definition

A pipe is a small kernel buffer **exposed to processes** as **a pair of file descriptors**, one for reading and one for writing. Writing data to one end of the pipe makes that data available for reading from the other end of the pipe. **Pipes provide a way for processes to communicate**.

#### Example

pipe()函数由内核提供。

The following example code runs the program `wc` with `standard input` connected to the read end of a pipe.

```c
int p[2];
char *argv[2];
argv[0] = "wc";
argv[1] = 0;
pipe(p);//创建一个pipe，用p来记录read和write端口
if(fork() == 0) {
close(0);
dup(p[0]);//standard input现在和p[0]（read端口连接）
close(p[0]);
close(p[1]);
exec("/bin/wc", argv);
} else {
close(p[0]);
write(p[1], "hello world\n", 12);
close(p[1]);
}
```

下图和上述举例无关。

<img src="assets/Operating Systems.assets/20161223173958916.png" alt="img"  />

### 1.4 File system

#### `chdir()`

```c
//The first fragment changes the process’s current directory to /a/b;
chdir("/a");
chdir("b");
open("c", O_RDONLY);
//the second neither refers to nor changes the process’s current directory.
open("/a/b/c", O_RDONLY);
```

#### `mknod`

```c
mkdir("/dir");
fd = open("/dir/file", O_CREATE|O_WRONLY);
close(fd);

mknod("/console", 1, 1);
```

`Mknod` creates a special file that refers to a device. Associated with a device file are the major and minor device numbers (the two arguments to `mknod`), which uniquely identify a kernel device. When a process later opens a device file, t**he kernel diverts read and write system calls to the kernel device implementation** instead of passing them to the file system

## Chapter2. Operating system organization

An operating system must fulfill three requirements: **multiplexing**, **isolation**, and **interaction**

- For example, even if there are more processes than there are hardware CPUs, the operating system must ensure that a**ll of the processes get a chance to execute**.

- The operating system must also arrange for isolation between the processes. That is, if one process has a bug and malfunctions, **it shouldn’t affect processes that don’t depend on the buggy process**.

- Complete isolation, however, is too strong, since **it should be possible for processes to intentionally interact**;

### 2.1 Abstracting physical resources

**It’s more typical for applications to not trust each other**, **and to have bugs**, so one often wants stronger isolation than a cooperative scheme provides. **To achieve strong isolation it’s helpful to forbid applications from directly accessing sensitive hardware resources, and instead to abstract the resources into services**.

For example, Unix applications interact with storage only through the file system’s open, read, write, and close system calls, instead of reading and writing the disk directly.

### 2.2 User mode, supervisor mode, and system calls

To achieve strong **isolation**, the operating system must arrange that applications **cannot modify (or even read) the operating system’s data structures and instructions** and that **applications cannot access other processes’ memory**.

**CPUs provide hardware support for strong isolation**. For example, RISC-V has **three modes** in which the CPU can execute instructions: **machine mode**, **supervisor mode**, and **user mode**.

- a CPU starts in **machine mode**. Machine mode is mostly intended for configuring a computer. Xv6 executes a few lines in machine mode and then changes to supervisor mode.
- In **supervisor mode** the CPU is allowed to execute **privileged instructions**: for example, enabling and disabling interrupts, reading and writing the register that holds the address of a page table.
- An application can execute only **user-mode** instructions (e.g., adding numbers, etc.) and is said to be **running in user space**, while the software in supervisor mode can also execute **privileged instruction**s and is said to be **running in kernel space**. The **software running in kernel space (or in supervisor mode) is called the `kernel`**.

**CPUs provide a special instruction** that switches the CPU from user mode to supervisor mode and enters the kernel at **an entry point** **specified by the kernel**. (RISC-V provides the **`ecall`** instruction for this purpose.)

Once the CPU has switched to supervisor mode, the **kernel can then validate the arguments of the system call**, <u>decide whether the application is allowed to perform the requested operation, and then deny it or execute it</u>. It is important that the **kernel control the entry point for transitions to supervisor mode**; if the application could decide the kernel entry point, a malicious application could, for example, enter the kernel at a point where the validation of arguments is skipped.

### 2.3 Kernel organization

**`monolithic kernel`**. the **entire operating system resides in the kernel**, so that the implementations of all system calls run in supervisor mode.

1. This organization is convenient because

- the OS designer doesn’t have to decide which part of the operating system doesn’t need full hardware privilege.
- Furthermore, it is **easier for different parts of the operating system to cooperate**. For example, an operating system might have a buffer cache that can be shared both by the file system and the virtual memory system.

2. A downside of the monolithic organization is that

- the interfaces between different parts of the operating system are often complex, and therefore **it is easy for an operating system developer to make a mistake**.
- In a monolithic kernel, a mistake is fatal, because an error in supervisor mode will often cause the kernel to fail. **If the kernel fails,the computer stops working, and thus all applications fail too. The computer must reboot to start again**.

**`microkernel`**. To reduce the risk of mistakes in the kernel, OS designers can **minimize the amount of operating system code that runs in supervisor mode, and execute the bulk of the operating system in user mode**.

![image-20220311165258588](assets/Operating Systems.assets/image-20220311165258588.png)

### 2.5 Process overview

**The unit of isolation in xv6 (as in other Unix operating systems) is a process**.

- The process abstraction prevents one process from wrecking or spying on another process’s memory, CPU, file descriptors, etc.
- It also prevents a process from wrecking the kernel itself, so that a process can’t subvert the kernel’s isolation mechanisms.

The **mechanisms used by the kernel to implement processes** include the **user/supervisor mode flag**, **address spaces**, and **time-slicing of threads**. To help enforce isolation, the process abstraction provides the illusion to a program that it has its own private machine. A process provides a program with what appears to be a private memory system, or address space, which other processes cannot read or write. A process also provides the program with what appears to be its own CPU to execute the program’s instructions.

#### Page Tables Brief Introduction

Xv6 uses **page tables** (which are implemented by hardware) to **give each process its own address space**. The <u>RISC-V page table translates (or “maps”) a virtual address (the address that an RISC-V instruction manipulates) to a physical address (an address that the CPU chip sends to main memory).</u>

<img src="assets/Operating Systems.assets/image-20220311170706075.png" alt="image-20220311170706075" style="zoom: 67%;" />

an **address space** includes the process’s user memory **starting at virtual address zero**. Instructions come first, followed by global variables, then the stack, and finally a “heap” area (for malloc) that the process can expand as needed.

There are a number of factors that limit the maximum size of a process’s address space: pointers on the RISC-V are 64 bits wide; **the hardware only uses the low 39 bits when looking up virtual addresses in page tables; and xv6 only uses 38 of those 39 bits.** Thus, the maximum address is `2^38 − 1 = 0x3fffffffff`, which is MAXVA.

At the top of the address space xv6 reserves a page for a **trampoline** and a page mapping the process’s **trapframe** to switch to the kernel, as we will explain in Chapter 4.

#### Thread Brief Introduction

**Each process has a thread of execution (or thread for short) that executes the process’s instructions**. A thread can be suspended and later resumed. **To switch transparently between processes, the kernel suspends the currently running thread and resumes another process’s thread**. Much of **the state of a thread (local variables, function call return addresses) is stored on the thread’s stacks.**

**Each process has two stacks**: a **user stack** and a **kernel stack** (p->kstack).

- When the process is executing user instructions, only its user stack is in use, and its kernel stack is empty.
- When the process enters the kernel (for a system call or interrupt), the kernel code executes on the process’s kernel stack;
- A process’s thread alternates between actively using its user stack and its kernel stack.

#### System Call Start and End

A process can make a system call by executing the RISC-V **`ecall`** instruction.

This instruction

- **raises the hardware privilege level** and

- changes the program counter to a **kernel-defined entry point**.

  **The code at the entry point switches to a kernel stack** and **executes the kernel instructions** that implement the system call.

When the system call completes, the kernel switches back to the user stack and returns to user space by calling the **`sret`** instruction,

- which **lowers the hardware privilege level** and resumes executing user instructions just after the system call instruction.
- **A process’s thread can “block” in the kernel to wait for I/O**, and resume where it left off when the I/O has finished.

### 2.6 Code: starting xv6 and the first process

#### Machine Mode

The loader loads the xv6 kernel into memory at physical address 0x80000000. The reason it places the kernel at 0x80000000 rather than 0x0 is because the address range 0x0:0x80000000 contains I/O devices.

`entry.S`

The instructions at \_entry set up a stack so that xv6 can run C code. **Xv6 declares space for an initial stack, stack0, in the file `start.c` (`kernel/start.c:11`). The code at \_entry loads the stack pointer register sp with the address stack0+4096**, the top of the stack, because the stack on RISC-V grows down. Now that the kernel has a stack, \_entry calls into C code at start (kernel/start.c:21).

```assembly
## qemu -kernel loads the kernel at 0x80000000
        # and causes each CPU to jump there.
        # kernel.ld causes the following code to
        # be placed at 0x80000000.
.section .text
_entry:
	# set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la sp, stack0
        li a0, 1024*4
		csrr a1, mhartid
        addi a1, a1, 1
        mul a0, a0, a1
        add sp, sp, a0
	# jump to start() in start.c
        call start
spin:
        j spin
```

`start.c`

The function start performs some configuration that is only allowed in machine mode, and then switches to supervisor mode.

**To enter supervisor mode, RISC-V provides the instruction `mret`.** This instruction is most often used to return from a previous call from supervisor mode to machine mode.

start isn’t returning from such a call, and instead sets things up as if there had been one(`mret`本质上是从supervisor mode跳转回machine mode，为了能够让`mret`指令使我们跳转到supervisor mode，需要做如下事情):

it **sets the previous privilege mode to supervisor** in the register `mstatus`, it **sets the return address to main** by writing main’s address into the register `mepc`, **disables virtual address translation** in supervisor mode by writing 0 into the page-table register `satp`, and **delegates all interrupts and exceptions to supervisor mode**. Before jumping into supervisor mode, start performs one more task: **it programs the clock chip to generate timer interrupts**. With this housekeeping out of the way, start “returns” to supervisor mode by calling `mret`. This causes the program counter to change to main (kernel/main.c:11).

```c
// entry.S needs one stack per CPU.
__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

// scratch area for timer interrupt, one per CPU.
uint64 mscratch0[NCPU * 32];

// assembly code in kernelvec.S for machine-mode timer interrupt.
extern void timervec();

// entry.S jumps here in machine mode on stack0.
void
start()
{
  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  x |= MSTATUS_MPP_S;
  w_mstatus(x);

  // set M Exception Program Counter to main, for mret.
  // requires gcc -mcmodel=medany
  w_mepc((uint64)main);

  // disable paging for now.
  w_satp(0);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);

  // ask for clock interrupts.
  timerinit();

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
}
```

#### Supervisor Mode

`main.c`

`main` (kernel/main.c:11) initializes several devices and subsystems, **it creates the first process by calling `userinit`** (kernel/proc.c:212).

The first process executes a small program written in RISC-V assembly, **`initcode.S`** (user/initcode.S:1), which **re-enters the kernel by invoking the exec system call**(系统开启后的第一次system call).

```assembly
## Initial process that execs /init.
## This code runs in user space.

##include "syscall.h"

## exec(init, argv)
.globl start
start:
        la a0, init
        la a1, argv
        li a7, SYS_exec
        ecall

## for(;;) exit();
exit:
        li a7, SYS_exit
        ecall
        jal exit

## char init[] = "/init\0";
init:
  .string "/init\0"

## char *argv[] = { init, 0 };
.p2align 2
argv:
  .long init
  .long 0
```

`initcode.S`本质上就是`exec(init, argv)`, 因为此时没有文件系统，所以只能用这种方式运行`user/init.c`.

#### User Mode

`Init `(user/init.c:15) creates a new console device file if needed and then **opens it as file descriptors 0, 1, and 2**. Then it **starts a shell** on the console. The system is up.

## Chapter3. Page tables

**Page tables** are the mechanism through which the operating system **provides each process** with its **own private address space and memory**.

Page tables determine **what memory addresses mean**, and **what parts of physical memory can be accessed.**

They allow xv6 to **<u>isolate</u> different process’s address spaces and to <u>multiplex</u> them onto a single physical memory**.

Page tables also provide a level of indirection that allows xv6 to perform a few tricks:

- mapping the same memory (a trampoline page) in several address spaces,
- guarding kernel and user stacks with an unmapped page.

### 3.1 Paging hardware

#### Terminology

- **PTE**: page table entry
- **PPN**: physical page number

**As a reminder, RISC-V instructions <u>(both user and kernel)</u> manipulate <u>virtual addresses</u>.**

#### Logical Page Table

The RISC-V **page table hardware** connects these two kinds of addresses, by mapping each virtual address to a physical address.

xv6 runs on Sv39 RISC-V, which means that **only the bottom 39 bits of a 64-bit virtual address are used**; the top 25 bits are not used.

In this Sv39 configuration, a RISC-V page table is logically an array of `2^27` (134,217,728) page table entries (PTEs). **Each PTE contains a 44-bit physical page number (PPN) and some flags**.

**The paging hardware translates a virtual address by using the top 27 bits of the 39 bits to index into the page table to find a PTE, and making a 56-bit physical address whose top 44 bits come from the PPN in the PTE and whose bottom 12 bits are copied from the original virtual address.**

**A Page**: A page table gives the operating system control over virtual-to-physical address translations at the **granularity of aligned chunks of 4096 (`2^12`) bytes**. 操作系统可控的是虚拟地址里的12位的offset。

In Sv39 RISC-V, the top 25 bits of a virtual address are not used for translation; in the future, RISC-V may use those bits to define more levels of translation. **The physical address also has room for growth: there is room in the PTE format for the physical page number to grow by another 10 bits**.（64 - 44 - 10 = 10）

![image-20220319004042706](assets/Operating Systems.assets/image-20220319004042706.png)

如果每个进程都有自己的page table，那么每个page table表会有多大呢？

这个page table最多会有2^27个条目（虚拟内存地址中的index长度为27）。**如果每个进程都使用这么大的page table，进程需要为page table消耗大量的内存，并且很快物理内存就会耗尽。**

#### Actual Translation

The actual translation happens in **three steps**.

**A page table is stored in physical memory as a three-level tree**.

**The root of the tree is a 4096-byte(516 \* 64bit=4096B) page-table page that contains 512 PTEs**, which contain the physical addresses for page-table pages in the next level of the tree. Each of those pages contains 512 PTEs for the final level in the tree. The paging hardware uses the top 9 bits of the 27 bits to select a PTE in the root page-table page, the middle 9 bits to select a PTE in a page-table page in the next level of the tree, and the bottom 9 bits to select the final PTE.

This three-level structure allows a page table to **omit entire page table pages in the common case in which large ranges of virtual addresses have no mappings.**

To tell the hardware to use a page table, t**he kernel must write the physical address of the root page-table page into the `satp` register**. **Each CPU has its own `satp`**. A CPU will translate all addresses generated by subsequent instructions using the page table pointed to by its own `satp`. Each CPU has its own `satp` so that different CPUs can run different processes, each with a private address space described by its own page table.

![image-20220319155658381](assets/Operating Systems.assets/image-20220319155658381.png)

这种方式的主要优点是，**如果地址空间中大部分地址都没有使用，你不必为每一个index准备一个条目**。

**在前一个方案中，虽然我们只使用了一个page，还是需要`2^27`个PTE。这个方案中，我们只需要`3 * 512`个PTE。所需的空间大大减少了。这是实际上硬件采用这种层次化的3级page directory结构的主要原因。**

#### PPN+Flags

Each PTE contains **flag bits that tell the paging hardware how the associated virtual address is allowed to be used**.

- **PTE_V** indicates <u>whether the PTE is present</u>: if it is not set, a reference to the page causes an exception.

- **PTE_R** controls whether instructions are allowed to <u>read</u> to the page.

- **PTE_W** controls whether instructions are allowed to <u>write</u> to the page.

- **PTE_X** controls whether the CPU may interpret the content of the page as instructions and <u>execute</u> them.

- **PTE_U** controls <u>whether instructions in user mode are allowed to access the page</u>; if PTE_U is not set, the PTE can be used only in supervisor mode.

![image-20220319161110245](assets/Operating Systems.assets/image-20220319161110245.png)

### 3.2 Kernel address space

**Xv6 maintains one page table per process, describing each process’s user address space, plus a single page table that describes the kernel’s address space**.

The kernel configures the layout of its address space to give itself access to physical memory and various hardware resources at predictable virtual addresses.

QEMU simulates a computer that includes **RAM (physical memory) starting at physical address 0x80000000 and continuing through at least 0x86400000**, which xv6 calls PHYSTOP. The QEMU simulation also includes I/O devices such as a disk interface.

QEMU exposes the **device interfaces to software as memory-mapped control registers that sit below 0x80000000** in the physical address space. **The kernel can interact with the devices by reading/writing these special physical addresses**; such reads and writes communicate with the device hardware rather than with RAM.

The kernel gets at RAM and memory-mapped device registers using **“direct mapping;”** that is, mapping the resources at virtual addresses that are equal to the physical address.

![image-20220319161821600](assets/Operating Systems.assets/image-20220319161821600.png)

#### kernel virtual addresses that aren’t direct-mapped

There are a couple of **kernel virtual addresses that aren’t direct-mapped**:

- **The trampoline page**. It is mapped at the top of the virtual address space; user page tables have this same mapping. we see here an interesting use case of page tables; **a physical page (holding the trampoline code) is mapped twice in the virtual address space of the kernel**: **once at top of the virtual address space and once with a direct mapping**.

- **The kernel stack pages**. **Each process has its own kernel stack**, which is mapped high so that **below it xv6 can leave an <u>unmapped guard page</u>**.

  **The guard page’s PTE is invalid (PTE_V is not set), so that if the kernel overflows a kernel stack, it will likely cause an exception and the kernel will panic**.

### 3.3 Code: creating an address space

#### What is in `kernel/vm.c`

- The **central data structure** is `pagetable_t`, which is really <u>a **pointer to** a RISC-V **root page-table page**</u>;

  ```c
  typedef uint64 *pagetable_t; // 512 PTEs
  ```

  a `pagetable_t` may be **either the kernel page table, or one of the per-process page tables**.

- The **central functions** are：

  - **`walk`**, which finds the PTE for a virtual address.
  - **`mappages`**, which installs PTEs for new mappings.
  - Functions starting with **`kvm`** manipulate the kernel page table;
  - functions starting with `uvm` manipulate a user page table;
  - other functions are used for both.
  - **`copyout`** and **`copyin`** copy **data to and from user virtual addresses provided as system call arguments**; they are in `vm.c` because **they need to explicitly translate those addresses in order to find the corresponding physical memory**. (内核态和用户态数据交互的原理)

#### Kernel Page Table Initialization

- Early in the boot sequence, `main` calls `kvminit` (kernel/vm.c:22) to **create the kernel’s page table**. This call occurs **before xv6 has enabled paging** on the RISC-V, **so addresses refer directly to physical memory**.

  - `Kvminit` first allocates a page of physical memory to hold the root page-table page.

  - Then it calls `kvmmap` to install the translations that the kernel needs. The translations include the kernel’s instructions and data, physical memory up to PHYSTOP, and memory ranges which are actually devices.

    ```c
    /*
     * create a direct-map page table for the kernel.
     */
    void
    kvminit()
    {
      kernel_pagetable = (pagetable_t) kalloc();
      memset(kernel_pagetable, 0, PGSIZE);

      // uart registers
      kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

      // virtio mmio disk interface
      kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

      // CLINT
      kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

      // PLIC
      kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

      // map kernel text executable and read-only.
      kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

      // map kernel data and the physical RAM we'll make use of.
      kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

      // map the trampoline for trap entry/exit to
      // the highest virtual address in the kernel.
      kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    }
    ```

- `kvmmap` (kernel/vm.c:118) calls `mappages` (kernel/vm.c:149), which **installs mappings into a page table for a range of virtual addresses to a corresponding range of physical addresses**.

  - It does this separately for each virtual address in the range, at page intervals.

    For each virtual address to be mapped, **`mappages` calls `walk` to find the address of the PTE for that address. It then initializes the PTE to hold the relevant physical page number, the desired permissions** (PTE_W, PTE_X, and/or PTE_R), and PTE_V to mark the PTE as valid (kernel/vm.c:161).

    ```c
    // add a mapping to the kernel page table.
    // only used when booting.
    // does not flush TLB or enable paging.
    void
    kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
    {
      if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
        panic("kvmmap");
    }

    // Create PTEs for virtual addresses starting at va that refer to
    // physical addresses starting at pa. va and size might not
    // be page-aligned. Returns 0 on success, -1 if walk() couldn't
    // allocate a needed page-table page.
    int
    mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
    {
      uint64 a, last;
      pte_t *pte;

      a = PGROUNDDOWN(va);
      last = PGROUNDDOWN(va + size - 1);
      for(;;){
        if((pte = walk(pagetable, a, 1)) == 0)
          return -1;
        if(*pte & PTE_V)
          panic("remap");
        *pte = PA2PTE(pa) | perm | PTE_V;
        if(a == last)
          break;
        a += PGSIZE;
        pa += PGSIZE;
      }
      return 0;
    }
    ```

- `walk` (kernel/vm.c:72) **mimics the RISC-V paging hardware** as it looks up the PTE for a virtual address (see Figure 3.2). `walk` descends the 3-level page table 9 bits at the time.

  - It uses each level’s 9 bits of virtual address to find the PTE of either the next-level page table or the final page(kernel/vm.c:78). If the PTE isn’t valid, then the required page hasn’t yet been allocated;
  - if the `alloc` argument is set, `walk` allocates a new page-table page and puts its physical address in the PTE.
  - It returns the address of the PTE in the lowest layer in the tree (kernel/vm.c:88).

  ```c
  // Return the address of the PTE in page table pagetable
  // that corresponds to virtual address va.  If alloc!=0,
  // create any required page-table pages.
  //
  // The risc-v Sv39 scheme has three levels of page-table
  // pages. A page-table page contains 512 64-bit PTEs.
  // A 64-bit virtual address is split into five fields:
  //   39..63 -- must be zero.
  //   30..38 -- 9 bits of level-2 index.
  //   21..29 -- 9 bits of level-1 index.
  //   12..20 -- 9 bits of level-0 index.
  //    0..11 -- 12 bits of byte offset within the page.
  pte_t *
  walk(pagetable_t pagetable, uint64 va, int alloc)
  {
    if(va >= MAXVA)
      panic("walk");

    for(int level = 2; level > 0; level--) {
      pte_t *pte = &pagetable[PX(level, va)];
      if(*pte & PTE_V) {
        pagetable = (pagetable_t)PTE2PA(*pte);
      } else {
        if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
          return 0;
        memset(pagetable, 0, PGSIZE);
        *pte = PA2PTE(pagetable) | PTE_V;
      }
    }
    return &pagetable[PX(0, va)];
  }
  ```

  The above code depends on physical memory being direct-mapped into the kernel virtual address space. For example, as walk descends levels of the page table, it pulls the (physical) address of the next-level-down page table from a PTE (kernel/vm.c:80), and then uses that address as a virtual address to fetch the PTE at the next level down (kernel/vm.c:78).

#### User Page Table Initialization

- main calls `kvminithart` (kernel/vm.c:53) to install the kernel page table. **It writes the physical address of the root page-table page into the register `satp`.** After this the CPU will translate addresses using the kernel page table. Since the kernel uses an identity mapping, the now virtual address of the next instruction will map to the right physical memory address.

  Each RISC-V **CPU caches page table entries** in a **Translation Look-aside Buffer (TLB)**, and **when xv6 changes a page table, it must tell the CPU to invalidate corresponding cached TLB entries**. If it didn’t, then at some point later the TLB might use an old cached mapping, pointing to a physical page that in the meantime has been allocated to another process, and as a result, a process might be able to scribble(乱涂) on some other process’s memory. The **RISC-V has an instruction `sfence.vma` that flushes the current CPU’s TLB**. xv6 executes `sfence.vma` in `kvminithart` after reloading the `satp` register, and in the trampoline code that switches to a user page table before returning to user space.

  ```c
  // Switch h/w page table register to the kernel's page table,
  // and enable paging.
  void
  kvminithart()
  {
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();
  }
  ```

- `procinit` (kernel/proc.c:26), which is called from main, **allocates a kernel stack for each process**. It maps each stack at the virtual address generated by KSTACK, which leaves room for the invalid stack-guard pages. `kvmmap` adds the mapping PTEs to the kernel page table, and the call to `kvminithart` reloads the kernel page table into `satp` so that the hardware knows about the new PTEs.

  ```c
  // initialize the proc table at boot time.
  void
  procinit(void)
  {
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    for(p = proc; p < &proc[NPROC]; p++) {
        initlock(&p->lock, "proc");

        // Allocate a page for the process's kernel stack.
        // Map it high in memory, followed by an invalid
        // guard page.
        char *pa = kalloc();
        if(pa == 0)
          panic("kalloc");
        uint64 va = KSTACK((int) (p - proc));
        kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
        p->kstack = va;
    }
    kvminithart();
  }
  ```

### 3.4 Physical memory allocation

The kernel must allocate and free physical memory at run-time for page tables, user memory, kernel stacks, and pipe buffers. xv6 uses the physical memory between the end of the kernel and PHYSTOP for run-time allocation. It allocates and frees whole 4096-byte pages at a time. It keeps track of which pages are free by threading a linked list through the pages themselves. **Allocation consists of removing a page from the linked list; freeing consists of adding the freed page to the list.**

### 3.5 Code: Physical memory allocator

- The allocator resides in `kalloc.c` (kernel/kalloc.c:1).

  - The **allocator’s data structure is a free list of physical memory pages that are available for allocation**. Each free page’s list element is a struct run (kernel/kalloc.c:17).

    ```c
    struct run {
      struct run *next;
    };
    ```

  - **Where does the allocator get the memory to hold that data structure?** **It store each free page’s run structure in the free page itself, since there’s nothing else stored there.**

  - The function main calls `kinit` to initialize the allocator (kernel/kalloc.c:27). **kinit initializes the free list to hold every page between the end of the kernel and `PHYSTOP`**. xv6 ought to determine how much physical memory is available by parsing configuration information provided by the hardware. Instead xv6 assumes that the machine has 128 megabytes of RAM.

    ```c
    void
    kinit()
    {
      initlock(&kmem.lock, "kmem");
      freerange(end, (void*)PHYSTOP);
    }
    ```

  - kinit calls `freerange` to add memory to the free list via per-page calls to `kfree`. **A PTE can only refer to a physical address that is aligned on a 4096-byte boundary (is a multiple of 4096)**, so `freerange` uses `PGROUNDUP` to ensure that it frees only aligned physical addresses.

    ```c
    void
    freerange(void *pa_start, void *pa_end)
    {
      char *p;
      p = (char*)PGROUNDUP((uint64)pa_start);
      for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
        kfree(p);
    }
    ```

  - The function `kfree` (kernel/kalloc.c:47) **begins by setting every byte in the memory being freed to the value 1**. This will cause code that uses memory after freeing it (uses “dangling references”) to read garbage instead of the old valid contents; hopefully that will cause such code to break faster. **Then `kfree` prepends the page to the free list:** it casts pa to a pointer to struct run, records the old start of the free list in r->next, and sets the free list equal to r. `kalloc` removes and returns the first element in the free list.

    ```c
    // Free the page of physical memory pointed at by v,
    // which normally should have been returned by a
    // call to kalloc().  (The exception is when
    // initializing the allocator; see kinit above.)
    void
    kfree(void *pa)
    {
      struct run *r;

      if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree");

      // Fill with junk to catch dangling refs.
      memset(pa, 1, PGSIZE);

      r = (struct run*)pa;

      acquire(&kmem.lock);
      r->next = kmem.freelist;
      kmem.freelist = r;
      release(&kmem.lock);
    }
    ```

### 3.6 Process address space

**Each process has a separate page table**, and **when xv6 switches between processes, it also changes page tables**. As Figure 2.3 shows, a process’s user memory starts at virtual address zero and can grow up to MAXVA (kernel/riscv.h:348), allowing a process to address in principle 256 Gigabytes of memory (`#define MAXVA (1L << (9 + 9 + 9 + 12 - 1))`).

<img src="assets/Operating Systems.assets/image-20220311170706075.png" alt="image-20220311170706075" style="zoom: 67%;" />

#### How Does a Process Obtain Memory

When a process asks xv6 for more user memory,

1. xv6 first uses `kalloc` to **allocate physical pages**.
2. It then **adds PTEs to the process’s page table that point to the new physical pages**. Xv6 sets the PTE_W, PTE_X, PTE_R, PTE_U, and PTE_V flags in these PTEs. Most processes do not use the entire user address space; xv6 leaves PTE_V clear in unused PTEs.

#### Use of Page Tables

We see here a few nice examples of use of page tables.

1. First, different processes’ page tables translate user addresses to different pages of physical memory, so that **each process has private user memory**.
2. Second, each process sees its memory as having contiguous virtual addresses starting at zero, while **the process’s physical memory can be non-contiguous**.
3. Third, the kernel maps a page with trampoline code at the top of the user address space, thus **a single page of physical memory shows up in all address spaces**.

#### Layout of the User Memory of an Executing Process

Figure 3.4 shows the layout of the user memory of an executing process in xv6 in more detail. **The stack is a single page**, and is shown with the initial contents as created by exec. Strings containing the command-line arguments, as well as an array of pointers to them, are at the very top of the stack. Just under that are values that allow a program to start at main as if the function `main(argc, argv)` had just been called.

![image-20220322233318284](assets/Operating Systems.assets/image-20220322233318284.png)

To detect **a user stack overflowing the allocated stack memory**, **xv6 places an invalid guard page right below the stack**. If the user stack overflows and the process tries to use an address below the stack, the hardware will generate a page-fault exception because the mapping is not valid. A real-world operating system might instead automatically allocate more memory for the user stack when it overflows.

### 3.7 Code: `sbrk`

`Sbrk` **is the system call for a process to shrink or grow its memory**. `sbrk()` change the location of the **program break**, which defines the end of the process's data segment (i.e., the program break is the first location after the end of the uninitialized data segment).

The system call is implemented by the function `growproc` (kernel/proc.c:239). `growproc` calls `uvmalloc` or `uvmdealloc`, depending on whether n is positive or negative.

```c
// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}
```

`uvmalloc` (kernel/vm.c:229) allocates physical memory with `kalloc`, and adds PTEs to the user page table with `mappages`.

```c
// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}
```

`uvmdealloc` calls `uvmunmap` (kernel/vm.c:174), which uses `walk` to find PTEs and `kfree` to free the physical memory they refer to.

```c
// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
```

#### Why use page table

xv6 uses a process’s page table

1. tell the hardware how to map user virtual addresses,
2. the only record of which physical memory pages are allocated to that process. That is the reason why freeing user memory (in `uvmunmap`) requires examination of the user page table.

### 3.8 Code: `exec`

`Exec` is the system call that **creates the user part of an address space**.

1. It initializes the user part of an address space from a file stored in the file system.
2. `Exec` (kernel/exec.c:13) opens the named binary path using `namei` (kernel/exec.c:26), which is explained in Chapter 8. Then, it reads the ELF header.

#### ELF format

Xv6 applications are described in the widely-used ELF format, defined in (`kernel/elf.h`).

**An ELF binary consists of <u>an ELF header, struct `elfhdr`</u> **(kernel/elf.h:6), **<u>followed by a sequence of program section headers</u>**, struct `proghdr` (kernel/elf.h:25).

Each `proghdr` **describes a section of the application that must be loaded into memory**;

xv6 programs have only one program section header, but other systems might have separate sections for instructions and data.

```c
// File header
struct elfhdr {
  uint magic;  // must equal ELF_MAGIC
  uchar elf[12];
  ushort type;
  ushort machine;
  uint version;
  uint64 entry;
  uint64 phoff;
  uint64 shoff;
  uint flags;
  ushort ehsize;
  ushort phentsize;
  ushort phnum;
  ushort shentsize;
  ushort shnum;
  ushort shstrndx;
};

// Program section header
struct proghdr {
  uint32 type;
  uint32 flags;
  uint64 off;
  uint64 vaddr;
  uint64 paddr;
  uint64 filesz;
  uint64 memsz;
  uint64 align;
};
```

#### How to check the file probably contains an ELF binary

An ELF binary starts with the four-byte “**magic number”** 0x7F, ‘E’, ‘L’, ‘F’, or ELF_MAGIC (kernel/elf.h:3). If the ELF header has the right magic number, exec assumes that the binary is well-formed.

```c
##define ELF_MAGIC 0x464C457FU  // "\x7FELF" in little endian
```

#### `exec.c`

`exec(char *path, char **argv)`

- **allocates a new page table with no user mappings** with `proc_pagetable` (kernel/exec.c:38),

- **allocates memory for each ELF segment** with `uvmalloc` (kernel/exec.c:52), and

- **loads each segment into memory** with `loadseg` (kernel/exec.c:10). `loadseg` uses `walkaddr` to find the physical address of the allocated memory at which to write each page of the ELF segment, and `readi` to read from the file.

#### Example of `exec("/init", argv)`

The program section header for `/init`, the first user program created with exec, looks like this:

![image-20220326210922620](assets/Operating Systems.assets/image-20220326210922620.png)

- The program section header’s `filesz` may be less than the `memsz`, indicating that the gap between them should be filled with zeroes (for C global variables) rather than read from the file. For `/init`, `filesz` is 2112 bytes and `memsz` is 2136 bytes, and thus **`uvmalloc` allocates enough physical memory to hold 2136 bytes, but reads only 2112 bytes from the file` /init`.**

- Now `exec` **allocates and initializes the user stack**. It allocates just one stack page. `Exec` copies the argument strings to the top of the stack one at a time, recording the pointers to them in `ustack`. It places a null pointer at the end of what will be the `argv` list passed to main. The first three entries in `ustack` are the fake return program counter, `argc`, and `argv` pointer.

- `Exec` **places an inaccessible page just below the stack page**, so that programs that try to use more than one page will fault. This inaccessible page also allows exec to deal with arguments that are too large; in that situation, the `copyout` (kernel/vm.c:355) function that exec uses to copy arguments to the stack will notice that the destination page is not accessible, and will return -1.

#### Error handling

During the preparation of the new memory image,

if exec detects an error like an invalid program segment, it jumps to the label bad, frees the new image, and returns -1.

Exec must wait to free the old image until it is sure that the system call will succeed: if the old image is gone, the system call cannot return -1 to it.

The only error cases in exec happen during the creation of the image. Once the image is complete, exec can commit to the new page table (kernel/exec.c:113) and free the old one (kernel/exec.c:117).

#### Risk of `exec()`

**Exec loads bytes from the ELF file into memory at addresses specified by the ELF file**. Users or processes **can place whatever addresses they want into an ELF file**. Thus exec is risky, because the addresses in the ELF file may refer to the kernel, accidentally or on purpose. The consequences for an unwary kernel could range from a crash to a malicious subversion of the kernel’s isolation mechanisms (i.e., a security exploit). xv6 performs a number of checks to avoid these risks. For example `if (ph.vaddr + ph.memsz < ph.vaddr)` checks for whether the sum overflows a 64-bit integer. The danger is that a user could construct an ELF binary with a `ph.vaddr` that points to a user-chosen address, and `ph.memsz` large enough that the sum overflows to 0x1000, which will look like a valid value. In an older version of xv6 in which the user address space also contained the kernel (but not readable/writable in user mode), the user could choose an address that corresponded to kernel memory and would thus copy data from the ELF binary into the kernel. In the RISC-V version of xv6 this cannot happen, because the kernel has its own separate page table; `loadseg` loads into the process’s page table, not in the kernel’s page table.

## Chapter4. Traps and system calls

### Trap

There are **three** kinds of event which cause the CPU to set aside ordinary execution of instructions and force a transfer of control to special code that handles the event.

- One situation is a **system call**, when a user program executes the `ecall` instruction to ask the kernel to do something for it.
- Another situation is an **exception**: an instruction (user or kernel) does something illegal, such as divide by zero or use an invalid virtual address.
- The third situation is a **device interrupt**, when a device signals that it needs attention, for example when the disk hardware finishes a read or write request.

This book uses **`trap`** as a generic term for these situations.

Typically whatever code was executing at the time of the trap will later need to resume, and shouldn’t need to be aware that anything special happened. That is, we often want traps to be transparent; this is particularly important for interrupts, which the interrupted code typically doesn’t expect.

The usual sequence is that

- a trap **forces a transfer of control into the kernel**;
- the kernel **saves registers and other state** so that execution can be resumed;
- the kernel **executes appropriate handler code** (e.g., a system call implementation or device driver);
- the kernel **restores the saved state and returns from the trap**; and the original code resumes where it left off.

### 4.1 RISC-V trap machinery

#### Registers for Trap

Each **RISC-V CPU has a set of control registers that the kernel writes to tell the CPU how to handle traps**, **and that the kernel can read to find out about a trap that has occurred**. The RISC-V documents contain the full story. `riscv.h` (kernel/riscv.h:1) contains definitions that xv6 uses. Here’s an outline of the most important registers:

- `stvec`: The kernel writes the address of its trap handler here; the RISC-V jumps here to handle a trap.

- `sepc`: When a trap occurs, RISC-V saves the program counter here (since the pc is then overwritten with `stvec`). The `sret` (return from trap) instruction copies `sepc` to the pc. The kernel can write to `sepc` to control where `sret` goes.

- `scause`: The RISC-V puts a number here that describes the reason for the trap.

- `sscratch`: The kernel places a value here that comes in handy at the very start of a trap handler.

- `sstatus`: The SIE bit in `sstatus` controls whether device interrupts are enabled. If the kernel clears SIE, the RISC-V will defer device interrupts until the kernel sets SIE. The SPP bit indicates whether a trap came from user mode or supervisor mode, and controls to what mode `sret` returns.

The above registers relate to traps handled in supervisor mode, and **they cannot be read or written in user mode**. There is an equivalent set of control registers for traps handled in machine mode; xv6 uses them only for the special case of timer interrupts. Each CPU on a multi-core chip has its own set of these registers, and more than one CPU may be handling a trap at any given time.

#### CPU hardware’s trap handling sequence

When it needs to force a trap, the RISC-V hardware does the following for all trap types (other than timer interrupts):

1. If the trap is a device interrupt, and the sstatus SIE bit is clear, don’t do any of the following.
2. Disable interrupts by clearing SIE.
3. **Copy the pc to `sepc`.**
4. Save the current mode (user or supervisor) in the SPP bit in sstatus.
5. **Set `scause` to reflect the trap’s cause.**
6. Set the mode to supervisor.
7. **Copy `stvec` to the pc.**
8. Start executing at the new pc.

---

Note that the **CPU doesn’t switch to the kernel page table, doesn’t switch to a stack in the kernel, and doesn’t save any registers other than the pc**.

**Kernel software must perform these tasks**.

One reason that the CPU does minimal work during a trap is to provide flexibility to software; for example, some operating systems don’t require a page table switch in some situations, which can increase performance.

You might wonder whether the CPU hardware’s trap handling sequence could be further simplified. For example, suppose that the CPU didn’t switch program counters. Then a trap could switch to supervisor mode while still running user instructions. Those user instructions could break the user/kernel isolation, for example by modifying the `satp` register to point to a page table that allowed accessing all of physical memory. It is thus important that the CPU switch to a kernel specified instruction address, namely `stvec`.

### 4.2 Traps from user space

> CPU对于trap所做的事其实很少，他只设置了一些flag并保存了pc值，然后让pc指向了本章内容的开端`uservec`。`uservec`就要想办法切换页表并保存用户态占有的寄存器。从而为执行trap的handler代码提供运行环境。

A trap may occur while executing in user space if the user program makes a system call (`ecall` instruction), or does something illegal, or if a device interrupts. The high-level path of a trap from user space is `uservec` (kernel/trampoline.S:16), then `usertrap` (kernel/trap.c:37); and when returning, `usertrapret` (kernel/trap.c:90) and then `userret` (kernel/trampoline.S:16).

---

Traps from user code are more challenging than from the kernel, since `satp` points to a user page table that doesn’t map the kernel, and the stack pointer may contain an invalid or even malicious value.

Because the **RISC-V hardware doesn’t switch page tables during a trap**, **the user page table must include a mapping for `uservec`, the trap vector instructions that `stvec` points to.** `uservec` must switch `satp` to point to the kernel page table;

**in order to continue executing instructions after the switch**, **`uservec` must be mapped at the same address in the kernel page table as in the user page table.**

> 因为`uservec`使命是要做CPU没有做的事，最重要的就是页表的切换。那么再切换了页表之后，为了让用户页表里的代码在切换到内核页表后也能运行，我们在两者相同的虚拟地址处预先放入了一样的代码。这个相同的地址区域如下所述。

---

Xv6 satisfies these constraints with a trampoline page that contains `uservec`. **Xv6 maps the trampoline page at the same virtual address in the kernel page table and in every user page table**. This virtual address is `TRAMPOLINE` (as we saw in Figure 2.3 and in Figure 3.3). The trampoline contents are set in `trampoline.S`, and (when executing user code) `stvec` is set to `uservec` (kernel/trampoline.S:16).

```assembly
uservec:
	#
        # trap.c sets stvec to point here, so
        # traps from user space start here,
        # in supervisor mode, but with a
        # user page table.
        #
        # sscratch points to where the process's p->trapframe is
        # mapped into user space, at TRAPFRAME.
        #

	# swap a0 and sscratch
        # so that a0 is TRAPFRAME
        csrrw a0, sscratch, a0

        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
        sd sp, 48(a0)
        sd gp, 56(a0)
        sd tp, 64(a0)
        sd t0, 72(a0)
        sd t1, 80(a0)
        .
        .
        .
```

When `uservec` starts, all 32 registers contain values owned by the interrupted code. But `uservec` needs to be able to modify some registers in order to set `satp` and generate addresses at which to save the registers. RISC-V provides a helping hand in the form of the `sscratch` register. The `csrrw ` instruction at the start of `uservec` swaps the contents of a0 and `sscratch`. Now the user code’s a0 is saved; `uservec` has one register (a0) to play with; and a0 contains the value the kernel previously placed in `sscratch`.

> 上面讲的是当用户态程序触发中断时，当前的32个寄存器都被用户占有，所以一开始用了`sscratch`寄存器先将`a0`保存下来，让`a0`指向`trapframe`，这样就可以把当前用户态所占有的所有寄存器依次保存下来。

`uservec`’s next task is to save the user registers. **Before entering user space, the kernel previously set** `sscratch` **to point to a per-process** `trapframe` **that (among other things) has space to save all the user registers** (kernel/proc.h:44). Because `satp` still refers to the user page table, `uservec` needs the `trapframe` to be mapped in the user address space. When creating each process, xv6 allocates a page for the process’s `trapframe`, and arranges for **it always to be mapped at user virtual address TRAPFRAME**, which is just below TRAMPOLINE. The process’s `p->trapframe` also points to the `trapframe`, though at its physical address so the kernel can use it through the kernel page table.

> `sscratch`在内核态中预先被设置的应该是用户态下`trapframe`的统一虚拟地址，每个process内部存储了一个他所拥有的`trapframe`的物理地址。当然，这个物理地址和统一虚拟地址的映射被记录在process的用户页表之中。

```assembly
static struct proc*
allocproc(void)
{
  struct proc *p;

 ................................

found:
  p->pid = allocpid();

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    release(&p->lock);
    return 0;
  }
```

![image-20220525234504924](assets/Operating Systems.assets/image-20220525234504924.png)

Thus after swapping a0 and `sscratch`, a0 holds a pointer to the current process’s `trapframe`. `uservec` now saves all user registers there, including the user’s a0, read from `sscratch`. The `trapframe` contains pointers to the current process’s kernel stack, the current CPU’s `hartid`, the address of `usertrap`, and the address of the kernel page table. `uservec` retrieves these values, switches `satp` to the kernel page table, and calls `usertrap`。

```c
struct trapframe {
  /*   0 */ uint64 kernel_satp;   // kernel page table
  /*   8 */ uint64 kernel_sp;     // top of process's kernel stack
  /*  16 */ uint64 kernel_trap;   // usertrap()
  /*  24 */ uint64 epc;           // saved user program counter
  /*  32 */ uint64 kernel_hartid; // saved kernel tp
    ...............
}
```

```assembly
uservec:
	#
        # trap.c sets stvec to point here, so
        # traps from user space start here,
        # in supervisor mode, but with a
        # user page table.
        #
        # sscratch points to where the process's p->trapframe is
        # mapped into user space, at TRAPFRAME.
        #

	# swap a0 and sscratch
        # so that a0 is TRAPFRAME
        csrrw a0, sscratch, a0

        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
        sd sp, 48(a0)
        sd gp, 56(a0)
        sd tp, 64(a0)
        sd t0, 72(a0)
        sd t1, 80(a0)
        .
        .
        .
        # save the user a0 in p->trapframe->a0
        csrr t0, sscratch
        sd t0, 112(a0)

        # restore kernel stack pointer from p->trapframe->kernel_sp
        ld sp, 8(a0)

        # make tp hold the current hartid, from p->trapframe->kernel_hartid
        ld tp, 32(a0)

        # load the address of usertrap(), p->trapframe->kernel_trap
        ld t0, 16(a0)

        # restore kernel page table from p->trapframe->kernel_satp
        ld t1, 0(a0)
        csrw satp, t1
        sfence.vma zero, zero

        # a0 is no longer valid, since the kernel page
        # table does not specially map p->tf.

        # jump to usertrap(), which does not return
        jr t0
```

> 保存完了用户态占有的所有寄存器，`uservec`最后通过`a0`（此时指向的是`trapframe`）,将其中的重要数据依次取出并覆盖相应的寄存器，切换到内核页表，此时，trap handler代码的运行环境就已经准备好了。接下来，pc指向`usertrap()`.

---

**The job of `usertrap` is to determine the cause of the trap, process it, and return** (kernel/- trap.c:37).

As mentioned above, it first changes `stvec` so that a trap while in the kernel will be handled by `kernelvec`. **It saves the `sepc` (the saved user program counter), again because there might be a process switch in `usertrap` that could cause `sepc` to be overwritten.**

If the trap is a system call, `syscall` handles it;

if a device interrupt, `devintr`;

otherwise it’s an exception, and the kernel kills the faulting process.

**The system call path adds four to the saved user pc because RISC-V, in the case of a system call, leaves the program pointer pointing to the `ecall` instruction**. On the way out, `usertrap` checks if the process has been killed or should yield the CPU (if this trap is a timer interrupt).

```c
//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void
usertrap(void)
{
  int which_dev = 0;

  if((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if(r_scause() == 8){
    // system call

    if(p->killed)
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sstatus &c registers,
    // so don't enable until done with those registers.
    intr_on();

    syscall();
  } else if((which_dev = devintr()) != 0){
    // ok
  } else {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    p->killed = 1;
  }

  if(p->killed)
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2)
    yield();

  usertrapret();
}
```

> 这一部分就是内核态如何处理trap的代码了，这里存有一个没有理解的地方：为什么pc要加4？(因为`ecall`的机器指令是4字节，加4就会跳到`ecall`的下一个指令去)
>
> 接下来当trap处理完毕，就要着手回到用户态了。

---

The first step in returning to user space is the call to `usertrapret` (kernel/trap.c:90). This function sets up the RISC-V control registers to prepare for a future trap from user space.

This involves changing `stvec` to refer to `uservec`,

preparing the `trapframe` fields that `uservec` relies on, and

setting `sepc` to the previously saved user program counter. At the end,

`usertrapret` calls `userret` on the trampoline page that is mapped in both user and kernel page tables; the reason is that assembly code in `userret` will switch page tables.

> `stvec`保存着解决trap的代码位置，此时将他恢复到`uservec`, 为下一次用户态中断做好准备
>
> 恢复`trapframe`保存的与kernel相关的特殊数据，这些数据在处理中断的过程中(切换内核页表，内核栈等)都被`trampoline.S`用到。

```c
//
// return to user space
//
void
usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
}
```

`usertrapret`’s call to `userret` passes a pointer to the process’s user page table in `a0` and TRAPFRAME in `a1` (kernel/trampoline.S:88).

`userret` switches `satp` to the process’s user page table. Recall that the user page table maps both the trampoline page and TRAPFRAME, but nothing else from the kernel. Again, the fact that the trampoline page is mapped at the same virtual address in user and kernel page tables is what allows `uservec` to keep executing after changing `satp`.

`userret` copies the `trapframe`’s saved user a0 to `sscratch` in preparation for a later swap with TRAPFRAME. From this point on, the only data `userret` can use is the register contents and the content of the `trapframe`. Next `userret` restores saved user registers from the `trapframe`, does a final swap of a0 and `sscratch` to restore the user a0 and save TRAPFRAME for the next trap, and uses `sret` to return to user space.

> 这里我们就又回到了TRAMPOLINE.S汇编代码部分了，这里总结一下4.2节的整个调用过程
>
> 当trap发生后，CPU会将pc指向`trampoline.S`的`uservec`部分, 接着
>
> `uservec` -> `usertrap` -> `usertrapret` -> `userret`
>
> `userret`主要做的事就是将页表切换为用户页表，恢复之前保存的用户态寄存器的值，恢复用户态的运行环境。这里边需要说明的是，此时`p->trapframe->a0`存储着trap handler运行后的返回值，所以先用`sscrach`将其保存，然后`a0`继续充当TRAPFRAME来逐一恢复用户态trap前的寄存器值。最后再将trap后的返回值给`a0`。

```assembly
.globl userret
userret:
        # userret(TRAPFRAME, pagetable)
        # switch from kernel to user.
        # usertrapret() calls here.
        # a0: TRAPFRAME, in user page table.
        # a1: user page table, for satp.

        # switch to the user page table.
        csrw satp, a1
        sfence.vma zero, zero

        # put the saved user a0 in sscratch, so we
        # can swap it with our a0 (TRAPFRAME) in the last step.
        ld t0, 112(a0)
        csrw sscratch, t0

        # restore all but a0 from TRAPFRAME
        ld ra, 40(a0)
        ld sp, 48(a0)
        ld gp, 56(a0)
        ld tp, 64(a0)
        ld t0, 72(a0)
    ...................................

	# restore user a0, and save TRAPFRAME in sscratch
        csrrw a0, sscratch, a0

        # return to user mode and user pc.
        # usertrapret() set up sstatus and sepc.
        sret
```

### 4.3 Code: Calling system calls

Chapter 2 ended with `initcode.S` invoking the exec system call (user/initcode.S:11).

```assembly
##include "syscall.h"

## exec(init, argv)
.globl start
start:
        la a0, init
        la a1, argv
        li a7, SYS_exec
        ecall

## for(;;) exit();
exit:
        li a7, SYS_exit
        ecall
        jal exit

## char init[] = "/init\0";
init:
  .string "/init\0"

## char *argv[] = { init, 0 };
.p2align 2
argv:
  .long init
  .long 0
```

Let’s look at how the user call makes its way to the exec system call’s implementation in the kernel. The user code places the arguments for exec in registers `a0` and `a1`, and puts the system call number in `a7`.

System call numbers match the entries in the `syscalls` array, a table of function pointers (kernel/syscall.c:108).

```c
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
..........................
};
```

The `ecall` instruction traps into the kernel and executes `uservec`, `usertrap`, and then `syscall`, as we saw above. `syscall `(kernel/syscall.c:133) retrieves the system call number from the saved a7 in the `trapframe` and uses it to index into `syscalls`.

```c
void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    p->trapframe->a0 = syscalls[num]();
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
```

For the first system call, a7 contains SYS_exec (kernel/syscall.h:8), resulting in a call to the system call implementation function sys_exec. When the system call implementation function returns, `syscall` records its return value in `p->trapframe->a0`. This will cause the original user-space call to exec() to return that value, since the C calling convention on RISC-V places return values in a0. System calls conventionally return negative numbers to indicate errors, and zero or positive numbers for success. If the system call number is invalid, `syscall` prints an error and returns −1.

### 4.4 Code: System call arguments

> 系统调用的参数在哪里呢？当然是存在寄存器里，然而，在我们进入trap handler之前，我们用`trapframe`保存了所有的用户态的寄存器，从而，系统调用函数需要在`p->trapframe`中获取自己需要的参数。

System call implementations in the kernel need to find the arguments passed by user code. **Because user code calls system call wrapper functions, the arguments are initially where the RISC-V C calling convention places them: in registers.** The kernel trap code saves user registers to the current process’s trap frame, where kernel code can find them. The functions `argint`, `argaddr`, and `argfd` retrieve the `n’th` system call argument from the trap frame as an integer, pointer, or a file descriptor. They all call `argraw` to retrieve the appropriate saved user register (kernel/syscall.c:35)

```c
static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
  *ip = argraw(n);
  return 0;
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
  return 0;
}
```

---

> 我们在使用命令行时，向`exec()`系统调用输入的是一组指向字符串的指针。这里最核心的难点就是用户态的指针地址只能被用户页表解析，如何让内核页表知道这个指针指向哪一块物理内存呢？
>
> 页表章节的实验做到了这一点，每个进程都拥有一张内核页表和一张用户页表，用户页表的映射会同时存储在内核页表上，从而用户传来的指针可以直接被内核态使用。

Some system calls pass pointers as arguments, and the kernel must use those pointers to read or write user memory. The `exec`system call, for example, passes the kernel an array of pointers referring to string arguments in user space. **These pointers pose two challenges**.

**First,** the user program may be buggy or malicious, and may pass the kernel an invalid pointer or a pointer intended to trick the kernel into accessing kernel memory instead of user memory. **Second,** the xv6 <u>kernel page table mappings are not the same as the user page table mappings</u>, so the kernel **cannot use ordinary instructions to load or store from user-supplied addresses**.

The kernel implements functions that safely transfer data to and from user-supplied addresses. `fetchstr` is an example (kernel/syscall.c:25). File system calls such as exec use `fetchstr` to retrieve string file-name arguments from user space. `fetchstr` calls `copyinstr` to do the hard work.

```c
// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  int err = copyinstr(p->pagetable, buf, addr, max);
  if(err < 0)
    return err;
  return strlen(buf);
}
```

---

> 这里我们面对的是一个每个进程共享内核页表的操作系统，这里解决上述问题的方法就是依靠代码而不是CPU的物理机制去找到用户地址所对应的物理地址。

`copyinstr` (kernel/vm.c:406) copies up to max bytes to `dst` from virtual address `srcva` in the user page table `pagetable`. It uses `walkaddr` (which calls walk) to walk the page table in software to determine the physical address pa0 for `srcva`. Since the kernel maps all physical RAM addresses to the same kernel virtual address, `copyinstr` can directly copy string bytes from `pa0` to `dst`. **`walkaddr` (kernel/vm.c:95) checks that the user-supplied virtual address is part of the process’s user address space, so programs cannot trick the kernel into reading other memory.** A similar function, `copyout`, copies data from the kernel to a user-supplied address.

```c
// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}
```

### 4.5 Traps from kernel space

Xv6 configures the CPU trap registers somewhat differently depending on whether user or kernel code is executing. When the kernel is executing on a CPU, the kernel points `stvec` to the assembly code at `kernelvec` (kernel/kernelvec.S:10). Since xv6 is already in the kernel, `kernelvec` can rely on `satp` being set to the kernel page table, and on the stack pointer referring to a valid kernel stack. `kernelvec` saves all registers so that the interrupted code can eventually resume without disturbance.

`kernelvec` **saves the registers on the stack of the interrupted kernel thread**, which makes sense because the register values belong to that thread. <u>This is particularly important if the trap causes a switch to a different thread – in that case the trap will actually return on the stack of the new thread, leaving the interrupted thread’s saved registers safely on its stack.</u>

```assembly
	#
        # interrupts and exceptions while in supervisor
        # mode come here.
        #
        # push all registers, call kerneltrap(), restore, return.
        #
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        // make room to save registers.
        addi sp, sp, -256

        // save the registers.
        sd ra, 0(sp)
        sd sp, 8(sp)
        sd gp, 16(sp)
        sd tp, 24(sp)
        sd t0, 32(sp)
        sd t1, 40(sp)
      ....................................

	// call the C trap handler in trap.c
        call kerneltrap
```

`kernelvec` jumps to `kerneltrap` (kernel/trap.c:134) after saving registers. `kerneltrap` is prepared for two types of traps: `device interrupts` and `exceptions`. It calls `devintr` (kernel/- trap.c:177) to check for and handle the former. If the trap isn’t a device interrupt, it must be an exception, and that is always a fatal error if it occurs in the xv6 kernel; the kernel calls panic and stops executing.

```c
// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void
kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if((which_dev = devintr()) == 0){
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}
```

> 这里讨论了线程和trap之间的关系，需要在学完第七章后来这里补充

If `kerneltrap` was called due to a timer interrupt, and a process’s kernel thread is running (rather than a scheduler thread), `kerneltrap` calls yield to give other threads a chance to run. At some point one of those threads will yield, and let our thread and its `kerneltrap` resume again. Chapter 7 explains what happens in yield.

When `kerneltrap`’s work is done, it needs to return to whatever code was interrupted by the trap. Because a yield may have disturbed the saved `sepc` and the saved previous mode in `sstatus`, `kerneltrap` saves them when it starts. It now restores those control registers and returns to `kernelvec` (kernel/kernelvec.S:48). `kernelvec` pops the saved registers from the stack and executes `sret`, which copies `sepc` to pc and resumes the interrupted kernel code.

It’s worth thinking through how the trap return happens if `kerneltrap` called yield due to a timer interrupt.

```assembly
// call the C trap handler in trap.c
        call kerneltrap

        // restore registers.
        ld ra, 0(sp)
        ld sp, 8(sp)
        ld gp, 16(sp)
        // not this, in case we moved CPUs: ld tp, 24(sp)
        ld t0, 32(sp)
        ld t1, 40(sp)
        ld t2, 48(sp)
        ld s0, 56(sp)
        ld s1, 64(sp)
       ..........................................

        addi sp, sp, 256

        // return to whatever we were doing in the kernel.
        sret
```

Xv6 sets a CPU’s `stvec` to `kernelvec` when that CPU enters the kernel from user space; you can see this in `usertrap` (kernel/trap.c:29). **There’s a window of time when the kernel is executing but `stvec` is set to `uservec`, and it’s crucial that device interrupts be disabled during that window**. Luckily the RISC-V always disables interrupts when it starts to take a trap, and xv6 doesn’t enable them again until after it sets `stvec`.

### 4.6 Page-fault exceptions

Xv6’s response to exceptions is quite boring: if an exception happens in user space, the kernel kills the faulting process. If an exception happens in the kernel, the kernel panics. Real operating systems often respond in much more interesting ways.

As an example, many kernels use page faults to implement **`copy-on-write (COW) fork`**. To explain copy-on-write fork, consider xv6’s fork, described in Chapter 3. fork causes the child to have the same memory content as the parent, by calling `uvmcopy` (kernel/vm.c:309) to allocate physical memory for the child and copy the parent’s memory into it. It would be more efficient if the child and parent could share the parent’s physical memory. A straightforward implementation of this would not work, however, since it would cause the parent and child to disrupt each other’s execution with their writes to the shared stack and heap.

Parent and child can safely share `phyical` memory using copy-on-write fork, driven by page faults. When a CPU cannot translate a virtual address to a physical address, the CPU generates a page-fault exception. RISC-V has **three different kinds of page fault:** `load page faults` (when a load instruction cannot translate its virtual address), `store page faults` (when a store instruction cannot translate its virtual address), and `instruction page faults` (when the address for an instruction doesn’t translate). The value in the `scause` register indicates the type of the page fault and the `stval` register contains the address that couldn’t be translated.

The basic plan in COW fork is for the parent and child to **initially share all physical pages**, but to map them **read-only**. Thus, when the child or parent executes a store instruction, the RISC-V **CPU raises a page-fault exception**. In response to this exception, the **kernel makes a copy of the page that contains the faulted address**. It maps one copy read/write in the child’s address space and the other copy read/write in the parent’s address space. After updating the page tables, **the kernel resumes the faulting process at the instruction that caused the fault**. Because the kernel has updated the relevant PTE to allow writes, the faulting instruction will now execute without a fault.

This COW plan works well for fork, because often the child calls `exec` immediately after the fork, replacing its address space with a new address space. In that common case, the child will experience only a few page faults, and the kernel can avoid making a complete copy. Furthermore, COW fork is transparent: no modifications to applications are necessary for them to benefit.

The combination of page tables and page faults opens up a wide-range of interesting possibilities other than COW fork. Another widely-used feature is called **`lazy allocation`**, which has two parts. First, when an application calls `sbrk`, the **kernel grows the address space, but marks the new addresses as not valid in the page table.** Second, **on a page fault on one of those new addresses, the kernel allocates physical memory and maps it into the page table**. Since applications often ask for more memory than they need, lazy allocation is a win: the kernel allocates memory only when the application actually uses it. Like COW fork, the kernel can implement this feature transparently to applications.

Yet another widely-used feature that exploits page faults is **`paging from disk`**. <u>If applications need more memory than the available physical RAM, the kernel can evict some pages: write them to a storage device such as a disk and mark their PTEs as not valid</u>. If an application reads or writes an evicted page, the CPU will experience a page fault. The kernel can then inspect the faulting address. If the address belongs to a page that is on disk, the kernel allocates a page of physical memory, reads the page from disk to that memory, updates the PTE to be valid and refer to that memory, and resumes the application. To make room for the page, the kernel may have to evict another page. This feature requires no changes to applications, and works well if applications have locality of reference (i.e., they use only a subset of their memory at any given time).

Other features that combine paging and page-fault exceptions include automatically extending stacks and memory-mapped files.

## Chapter5. Interrupts and device drivers

A driver is the code in an operating system that manages a particular device: it configures the device hardware, tells the device to perform operations, handles the resulting interrupts, and interacts with processes that may be waiting for I/O from the device. Driver code can be tricky because a driver executes concurrently with the device that it manages. In addition, the driver must understand the device’s hardware interface, which can be complex and poorly documented. Devices that need attention from the operating system can usually be configured to generate interrupts, which are one type of trap. The kernel trap handling code recognizes when a device has raised an interrupt and calls the driver’s interrupt handler; in xv6, this dispatch happens in `devintr` (kernel/trap.c:177).

Many **device drivers** execute code in two contexts: **a top half that runs in a process’s kernel thread, and a bottom half that executes at interrupt time.**

- **The top half** is called via system calls such as read and write that want the device to perform I/O. This code may ask the hardware to start an operation (e.g., ask the disk to read a block); then the code waits for the operation to complete. Eventually the device completes the operation and raises an interrupt.

- The driver’s interrupt handler, acting as **the bottom half**, figures out what operation has completed, wakes up a waiting process if appropriate, and tells the hardware to start work on any waiting next operation.

```c
// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
     (scause & 0xff) == 9){
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if(cpuid() == 0){
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
  }
}
```

### 5.1 Code: Console input

The console driver (`console.c`) is a simple illustration of driver structure.

The **console driver accepts characters typed by a human, via the UART** serial-port hardware attached to the RISC-V. The console driver accumulates a line of input at a time, processing special input characters such as backspace and control-u.

User processes, such as the **shell, use the read system call to fetch lines of input from the console**. When you type input to xv6 in QEMU, your keystrokes are delivered to xv6 by way of QEMU’s simulated UART hardware. The UART hardware that the driver talks to is a 16550 chip [11] emulated by QEMU. On a real computer, a 16550 would manage an RS232 serial link connecting to a terminal or other computer. When running QEMU, it’s connected to your keyboard and display.

**The UART hardware appears to software as a set of memory-mapped control registers.** That is, there are some physical addresses that RISC-V hardware connects to the UART device, so that loads and stores interact with the device hardware rather than RAM. The memory-mapped addresses for the UART start at 0x10000000, or UART0 (kernel/memlayout.h:21). There are a handful of UART control registers, each the width of a byte. Their offsets from UART0 are defined in (kernel/uart.c:22). For example, the LSR register contain bits that indicate whether input characters are waiting to be read by the software. These characters (if any) are available for reading from the RHR register. Each time one is read, the UART hardware deletes it from an internal FIFO of waiting characters, and clears the “ready” bit in LSR when the FIFO is empty. The UART transmit hardware is largely independent of the receive hardware; if software writes a byte to the THR, the UART transmit that byte.

```c
// the UART control registers.
// some have different meanings for
// read vs write.
// see http://byterunner.com/16550.html
##define RHR 0                 // receive holding register (for input bytes)
##define THR 0                 // transmit holding register (for output bytes)
##define IER 1                 // interrupt enable register
##define IER_RX_ENABLE (1<<0)
##define IER_TX_ENABLE (1<<1)
##define FCR 2                 // FIFO control register
##define FCR_FIFO_ENABLE (1<<0)
##define FCR_FIFO_CLEAR (3<<1) // clear the content of the two FIFOs
##define ISR 2                 // interrupt status register
##define LCR 3                 // line control register
##define LCR_EIGHT_BITS (3<<0)
##define LCR_BAUD_LATCH (1<<7) // special mode to set baud rate
##define LSR 5                 // line status register
##define LSR_RX_READY (1<<0)   // input is waiting to be read from RHR
##define LSR_TX_IDLE (1<<5)    // THR can accept another character to send
```

Xv6’s main calls `consoleinit` (kernel/console.c:184) to initialize the UART hardware. This code configures the UART to

- **generate a receive interrupt when the UART receives each byte of input,** and
- **a transmit complete interrupt each time the UART finishes sending a byte of output** (kernel/uart.c:53).

> UART是device和console之间交互的桥梁，这里主要说明了UART和device之间的关系，每当我们使用keyboard按下一个按键时，UART就会触发一个接收中断；每当UART进行了一次传输时，就会触发一次传输完成的中断。

```c
void
consoleinit(void)
{
  initlock(&cons.lock, "cons");

  uartinit();

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}

void
uartinit(void)
{
  // disable interrupts.
  WriteReg(IER, 0x00);

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);

  initlock(&uart_tx_lock, "uart");
}
```

The xv6 **shell reads from the console by way of a file descriptor opened by `init.c`** (user/init.c:19). Calls to the read system call make their way through the kernel to `consoleread` (kernel/console.c:82). `consoleread` waits for input to arrive (via interrupts) and be buffered in `cons.buf`, copies the input to user space, and (after a whole line has arrived) returns to the user process. **If the user hasn’t typed a full line yet, any reading processes will wait in the sleep call (kernel/console.c:98)** (Chapter 7 explains the details of sleep).

> 系统调用`read()`最后的真正实现是`consoleread()`. console是连接用户和UART的桥梁。

```c
// user/init.c:19
int
main(void)
{
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  ...........
}

// kernel/console.c:82
// user read()s from the console go here.
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    }

    c = cons.buf[cons.r++ % INPUT_BUF];
      .......

  release(&cons.lock);

  return target - n;
}
```

When the user types a character, the UART hardware asks the RISC-V to raise an interrupt, which activates xv6’s trap handler. The trap handler calls `devintr` (kernel/trap.c:177), which looks at the RISC-V `scause` register to discover that the interrupt is from an external device. Then it asks a hardware unit called the PLIC [1] to tell it which device interrupted (kernel/trap.c:186). If it was the UART, `devintr` calls `uartintr`.

> 这里对device --> UART之间的关系作了说明。用户键入一个字符，UART触发接收中断从而触发trap handler。这类外部device中断都会被交给`devintr()`处理，它会询问PLIC是哪一个外部device做出了这个中断。

```c
// irq indicates which device interrupted.
    int irq = plic_claim();

    if(irq == UART0_IRQ){
      uartintr();
    } else if(irq == VIRTIO0_IRQ){
      virtio_disk_intr();
    } else if(irq){
      printf("unexpected interrupt irq=%d\n", irq);
    }
```

`uartintr` (kernel/uart.c:180) reads any waiting input characters from the UART hardware and hands them to `consoleintr` (kernel/console.c:138); it doesn’t wait for characters, since future input will raise a new interrupt. **The job of `consoleintr` is to accumulate input characters in `cons.buf` until a whole line arrives.** `consoleintr` treats backspace and a few other characters specially. When a newline arrives, `consoleintr` wakes up a waiting `consoleread` (if there is one).

Once woken, `consoleread` will observe a full line in `cons.buf`, copy it to user space, and return (via the system call machinery) to user space.

> 这里对UART-->console之间的关系作了说明。在上一步UART触发了接收中断后，`trap.c`中的代码将他引入到相应的handler函数中。`uartintr()`为UART发起的外部中断的处理函数, 他的主要工作就是通过`uartgetc()`从相应的外部设备中的寄存器中读取输入的字符，读到后立刻传入`consoleintr(c)`. `consoleintr()`中的代码会先处理一些特殊字符指令，但其核心功能就是维护`cons.buf`, 这个缓冲区就是一个积累字符的地方，当它积累了一行时，它就需要唤醒`consoleread`来消费他在buffer中已经存入的内容。
>
> **这里用buffer体现了一种生产者-消费者的模式**
>
> ---
>
> 举个例子：
>
> 这里可以想想`ls`指令，我们分别输入了`l,s`两个字符，他们触发了两次中断，每次中断分别将`l`,`s`加入到console的buffer之中，然后我们敲击回车，又引发了中断，这时console发现它获得了一个完整的句子，他就会唤醒`consoleread()`把buffer中的`ls`指令发给他，进而系统调用read也就得到了`ls`，接着shell就可以开启ls进程了。

```c
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
      break;
    consoleintr(c);
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
  uartstart();
  release(&uart_tx_lock);
}

//
// the console input interrupt handler.
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
  acquire(&cons.lock);

  switch(c){
  case C('P'):  // Print process list.
    procdump();
    break;
  case C('U'):  // Kill line.
    while(cons.e != cons.w &&
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f':
    if(cons.e != cons.w){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
      c = (c == '\r') ? '\n' : c;

      // echo back to the user.
      consputc(c);

      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF] = c;

      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
        // wake up consoleread() if a whole line (or end-of-file)
        // has arrived.
        cons.w = cons.e;
        wakeup(&cons.r);
      }
    }
    break;
  }

  release(&cons.lock);
}
```

### 5.2 Code: Console output

> 上一节说的是系统调用`read()`是怎么读到用户输入的`ls`并返回给内核的，这一节说的是，我们在shell命令行输入`l,s`时，他是如何被一个一个的打印在命令行中的。这里和`console.c`没有什么关系，这里时UART会将buffer中的字符发送给其他的device，例如显存。

A **write system call** on a file descriptor connected to the console eventually arrives at **`uartputc` (kernel/uart.c:87).** The device driver maintains an output buffer (`uart_tx_buf`) so that writing processes do not have to wait for the UART to finish sending; instead, `uartputc` appends each character to the buffer, calls `uartstart` to start the device transmitting (if it isn’t already), and returns. The only situation in which `uartputc` waits is if the buffer is already full.

> 可以看到UART这部分的代码也用到了**消费者-生产者模式**，他也维护了一个buffer用来暂存像`printf()`这样的函数发来的字符。

```c
// add a character to the output buffer and tell the
// UART to start sending if it isn't already.
// blocks if the output buffer is full.
// because it may block, it can't be called
// from interrupts; it's only suitable for use
// by write().

##define UART_TX_BUF_SIZE 32
char uart_tx_buf[UART_TX_BUF_SIZE];
uint64 uart_tx_w; // write next to uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE]
uint64 uart_tx_r; // read next from uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE]

void
uartputc(int c)
{
  acquire(&uart_tx_lock);

  if(panicked){
    for(;;)
      ;
  }

  while(1){
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
      // buffer is full.
      // wait for uartstart() to open up space in the buffer.
      sleep(&uart_tx_r, &uart_tx_lock);
    } else {
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
      uart_tx_w += 1;
      uartstart();
      release(&uart_tx_lock);
      return;
    }
  }
}
```

**Each time the UART finishes sending a byte, it generates an interrupt**. `uartintr` calls `uartstart`, which checks that the device really has finished sending, and hands the device the next buffered output character. Thus if a process writes multiple bytes to the console, typically the first byte will be sent by `uartputc’s` call to `uartstart`, and the remaining buffered bytes will be sent by `uartstart` calls from `uartintr` as transmit complete interrupts arrive.

> 下面说明了生产者消费者模型的重要性

<u>**A general pattern to note is the decoupling of device activity from process activity via buffering and interrupts.**</u>

<u>**The console driver can process input even when no process is waiting to read it; a subsequent read will see the input. Similarly, processes can send output without having to wait for the device.**</u>

This decoupling can increase performance by allowing processes to execute concurrently with device I/O, and is particularly important when the device is slow (as with the UART) or needs immediate attention (as with echoing typed characters). This idea is sometimes called I/O concurrency.

### 5.3 Concurrency in drivers

You may have noticed calls to acquire in `consoleread` and in `consoleintr`. These calls acquire a lock, which protects the console driver’s data structures from concurrent access.

There are **three concurrency dangers** here:

- two processes on different CPUs might call `consoleread` at the same time;
- the hardware might ask a CPU to deliver a console (really UART) interrupt while that CPU is already executing inside `consoleread`;
- the hardware might deliver a console interrupt on a different CPU while `consoleread` is executing.

Another way in which concurrency requires care in drivers is that **one process may be waiting for input from a device, but the interrupt signaling arrival of the input may arrive when a different process (or no process at all) is running.** Thus interrupt handlers are not allowed to think about the process or code that they have interrupted. For example, an interrupt handler cannot safely call `copyout` with the current process’s page table. Interrupt handlers typically do relatively little work (e.g., just copy the input data to a buffer), and wake up top-half code to do the rest.

### 5.4 Timer interrupts

Xv6 uses timer interrupts to maintain its clock and to enable it to switch among compute-bound processes; the yield calls in usertrap and kerneltrap cause this switching. Timer interrupts come from clock hardware attached to each RISC-V CPU. Xv6 programs this clock hardware to interrupt each CPU periodically.

**RISC-V requires that timer interrupts be taken in machine mode, not supervisor mode.** RISCV machine mode executes without paging, and with a separate set of control registers, so it’s not practical to run ordinary xv6 kernel code in machine mode. **As a result, xv6 handles timer interrupts completely separately from the trap mechanism laid out above.**

**Code executed in machine mode in `start.c`, before main,** sets up to receive timer interrupts (kernel/start.c:57). Part of the job is to program the **CLINT hardware (core-local `interruptor`) to generate an interrupt after a certain delay.** Another part is to set up a `scratch area`, analogous to the `trapframe`, to help the timer interrupt handler save registers and the address of the CLINT registers. Finally, start sets `mtvec` to `timervec` and enables timer interrupts.

**A timer interrupt can occur at any point when user or kernel code is executing;** there’s no way for the kernel to disable timer interrupts during critical operations. Thus the <u>timer interrupt handler must do its job in a way guaranteed not to disturb interrupted kernel code.</u> The basic strategy is for the handler to ask the RISC-V to raise a “software interrupt” and immediately return. The RISC-V delivers software interrupts to the kernel with the ordinary trap mechanism, and allows the kernel to disable them. The code to handle the software interrupt generated by a timer interrupt can be seen in `devintr` (kernel/trap.c:204).

The machine-mode timer interrupt vector is `timervec` (kernel/kernelvec.S:93). It saves a few registers in the scratch area prepared by start, tells the CLINT when to generate the next timer interrupt, asks the RISC-V to raise a software interrupt, restores registers, and returns. There’s no C code in the timer interrupt handler.

### 5.5 Real world

- DMA

  The UART driver retrieves data a byte at a time by reading the UART control registers; this pattern is called programmed I/O, since software is driving the data movement. Programmed I/O is simple, but too slow to be used at high data rates. Devices that need to move lots of data at high speed typically use **direct memory access** **(DMA**). **DMA device hardware directly writes incoming data to RAM, and reads outgoing data from RAM.** Modern disk and network devices use DMA. A driver for a DMA device would prepare data in RAM, and then use a single write to a control register to tell the device to process the prepared data.

- Polling

  Interrupts make sense when a device needs attention at unpredictable times, and not too often. But **interrupts have high CPU overhead**. Thus **high speed devices, such networks and disk controllers, use tricks that <u>reduce the need for interrupts</u>.**

  - One trick is to raise a single interrupt for a whole batch of incoming or outgoing requests.
  - Another trick is for the driver to **disable interrupts entirely, and to check the device <u>periodically</u> to see if it needs attention**. This technique is called `polling`. Polling makes sense if the device performs operations very quickly, but it wastes CPU time if the device is mostly idle. Some drivers dynamically switch between polling and interrupts depending on the current device load.

## Chapter6. Locking

Most kernels, including xv6, interleave the execution of multiple activities. One source of interleaving is multiprocessor hardware: computers with multiple CPUs executing independently, such as xv6’s RISC-V. These multiple CPUs share physical RAM, and xv6 exploits the sharing to maintain data structures that all CPUs read and write. **This sharing raises the possibility of one CPU reading a data structure while another CPU is mid-way through updating it, or even multiple CPUs updating the same data simultaneously;** without careful design such parallel access is likely to yield incorrect results or a broken data structure. Even on a uniprocessor, the kernel may switch the CPU among a number of threads, causing their execution to be interleaved. Finally, a device interrupt handler that modifies the same data as some interruptible code could damage the data if the interrupt occurs at just the wrong time. **The word concurrency refers to situations in which multiple instruction streams are interleaved, due to multiprocessor parallelism, thread switching, or interrupts.**

Kernels are full of concurrently-accessed data. For example, two CPUs could simultaneously call `kalloc`, thereby concurrently popping from the head of the free list. Kernel designers like to allow for lots of concurrency, since it can yield increased performance though parallelism, and increased responsiveness. However, as a result kernel designers spend a lot of effort convincing themselves of correctness despite such concurrency. There are many ways to arrive at correct code, some easier to reason about than others. Strategies aimed at correctness under concurrency, and abstractions that support them, are called **concurrency control techniques**.

Xv6 uses a number of concurrency control techniques, depending on the situation; many more are possible. This chapter focuses on a widely used technique: **the lock**. A lock provides **mutual exclusion, ensuring that only one CPU at a time can hold the lock**. If the programmer associates a lock with each shared data item, and the code always holds the associated lock when using an item, then the item will be used by only one CPU at a time. In this situation, we say that the lock protects the data item. Although locks are an easy-to-understand concurrency control mechanism, **the downside of locks is that they can kill performance, because they serialize concurrent operations.**

The rest of this chapter explains why xv6 needs locks, how xv6 implements them, and how it uses them.

![image-20220605000625203](assets/Operating Systems.assets/image-20220605000625203.png)

### 6.1 Race conditions

> 2个CPU同时在进行子进程的`kfree`, 然而kernel维护的链表只有一个，此时无法并行

As an example of why we need locks, consider two processes calling wait on two different CPUs. wait frees the child’s memory. Thus on each CPU, the kernel will call `kfree` to free the children’s pages. The kernel allocator maintains a linked list: `kalloc()` (kernel/kalloc.c:69) pops a page of memory from a list of free pages, and `kfree()` (kernel/kalloc.c:47) pushes a page onto the free list. For best performance, we might hope that the `kfrees` of the two parent processes would execute in parallel without either having to wait for the other, but this would not be correct given xv6’s `kfree` implementation.

**Figure 6.1** illustrates the setting in more detail: **the linked list is in memory that is shared by the two CPUs**, which manipulate the linked list using load and store instructions. **(In reality, the processors have caches**, but conceptually multiprocessor systems behave as if there were a single, shared memory.) If there were no concurrent requests, you might implement a list push operation as follows:

```c
struct element {
 	int data;
	struct element *next;
};

struct element *list = 0;

void
push(int data)
{
	struct element *l;

	l = malloc(sizeof *l);
	l->data = data;
	l->next = list;
	list = l;
}
```

<img src="assets/Operating Systems.assets/image-20220605223756692.png" alt="image-20220605223756692" style="zoom: 80%;" />

This implementation is correct if executed in isolation. However, the code is not correct if more than one copy executes concurrently. If two CPUs execute push at the same time, both might execute line 15 as shown in Fig 6.1, before either executes line 16, which results in an incorrect outcome as illustrated by Figure 6.2. There would then be two list elements with next set to the former value of list. When the two assignments to list happen at line 16, **the second one will overwrite the first; the element involved in the first assignment will be lost.**

---

The lost update at line 16 is an example of a **race condition**.

A race condition is a situation in which **<u>a memory location is accessed concurrently, and at least one access is a write</u>**. A race is often a sign of a bug, either a lost update (if the accesses are writes) or a read of an incompletely-updated data structure. **The outcome of a race depends on the exact timing of the two CPUs involved and how their memory operations are ordered by the memory system, which can make race-induced errors difficult to reproduce and debug.** For example, adding print statements while debugging push might change the timing of the execution enough to make the race disappear.

---

The usual way to avoid races is to use a **lock**. Locks ensure **mutual exclusion**, so that <u>only one CPU at a time can execute the sensitive lines of push</u>; this makes the scenario above impossible. The correctly locked version of the above code adds just a few lines :

```c
struct element *list = 0;
struct lock listlock;

void
push(int data)
{
	struct element *l;
	l = malloc(sizeof *l);
	l->data = data;

	acquire(&listlock);
	l->next = list;
	list = l;
	release(&listlock);
}
```

The sequence of instructions between acquire and release is often called a **critical section**. The lock is typically said to be protecting list.

---

When we say that a lock protects data, we really mean that the lock protects some collection of **invariants** that apply to the data. I**nvariants are properties of data structures that are maintained across operations**. Typically, an operation’s correct behavior depends on the invariants being true when the operation begins. The operation may temporarily violate the invariants but must reestablish them before finishing. For example, in the linked list case, the invariant is that list points at the first element in the list and that each element’s next field points at the next element. The implementation of push violates this invariant temporarily: in line 17, l points to the next list element, but list does not point at l yet (reestablished at line 18). **The race condition we examined above happened because a second CPU executed code that depended on the list invariants while they were (temporarily) violated.** Proper use of a lock ensures that only one CPU at a time can operate on the data structure in the critical section, so that no CPU will execute a data structure operation when the data structure’s invariants do not hold.

You can think of a lock as

- **serializing concurrent critical sections so that they run one at a time**, and thus preserve invariants (assuming the critical sections are correct in isolation). You can also think of critical sections guarded by the same lock as
- **being atomic with respect to each other**, so that each sees only the complete set of changes from earlier critical sections, and never sees partially-completed updates.

---

Although correct use of locks can make incorrect code correct, **locks limit performance**.

For example, if two processes call `kfree` concurrently, the locks will serialize the two calls, and **we obtain no benefit from running them on different CPUs**.

We say that **multiple processes conflict if they want the same lock at the same time,** or that the lock experiences **`contention`**.

**A major challenge in kernel design is to avoid lock contention**. Xv6 does little of that, but sophisticated kernels organize data structures and algorithms specifically to avoid lock contention. In the list example, a kernel may maintain a free list per CPU and only touch another CPU’s free list if the CPU’s list is empty and it must steal memory from another CPU. Other use cases may require more complicated designs.

The placement of locks is also important for performance. For example, it would be correct to move acquire earlier in push: it is fine to move the call to acquire up to before line 13. This may reduce performance because then the calls to malloc are also serialized. The section “Using locks” below provides some guidelines for where to insert acquire and release invocations.

### 6.2 Code: Locks

Xv6 has two types of locks:

**`spinlocks`** and **`sleep-locks`**

---

#### `Spinlocks`

We’ll start with spinlocks. Xv6 represents a spinlock as a struct spinlock (kernel/spinlock.h:2). The important field in the structure is locked, a word that is zero when the lock is available and non-zero when it is held. Logically, xv6 should acquire a lock by executing code like

```c
// Mutual exclusion lock.
struct spinlock {
  uint locked;       // Is the lock held?

  // For debugging:
  char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
}

21 void
22 acquire(struct spinlock *lk) // does not work!
23 {
24 		for(;;) {
25 			if(lk->locked == 0) {
26 				lk->locked = 1;
27				 break;
28			 }
29 		}
30 }
```

Unfortunately, this implementation does not guarantee mutual exclusion on a multiprocessor. **It could happen that two CPUs simultaneously reach line 25, see that `lk->locked` is zero, and then both grab the lock by executing line 26**. At this point, two different CPUs hold the lock, which violates the mutual exclusion property. What we need is a way to make lines 25 and 26 execute as an atomic (i.e., indivisible) step.

---

Because locks are widely used, **multi-core processors usually provide instructions that implement an atomic version** of lines 25 and 26. On the RISC-V this instruction is `amoswap r, a`.

`amoswap` reads the value at the memory address a, writes the contents of register r to that address, and puts the value it read into r. That is, **it swaps the contents of the register and the memory address**. It performs this sequence **atomically**, using **special hardware** to prevent any other CPU from using the memory address between the read and the write.

#### Acquire

> 锁依靠的是硬件的技术，硬件使得指令可以原子的执行。上锁的过程就是用原子指令`amoswap`不断地用1和某个寄存器中的值进行交换，若交换后为0，则证明其他CPU已经开了锁，当前CPU也把1放进了该寄存器中；若交换后为1，说明有其他CPU还在占用，但我们是用1换了1，所以并没有对上锁本身造成影响。

Xv6’s acquire (kernel/spinlock.c:22) uses the portable C library call `__sync_lock_test_and_set`, which boils down to(归结为) the `amoswap` instruction; the return value is the old (swapped) contents of `lk->locked`. The acquire function wraps the swap in a loop, retrying (spinning) until it has acquired the lock. Each iteration swaps one into `lk->locked` and checks the previous value; if the previous value is zero, then we’ve acquired the lock, and the swap will have set `lk->locked` to one. If the previous value is one, then some other CPU holds the lock, and the fact that we atomically swapped one into `lk->locked` didn’t change its value.

```c
/ Acquire the lock.
// Loops (spins) until the lock is acquired.
void
acquire(struct spinlock *lk)
{
  push_off(); // disable interrupts to avoid deadlock.
  if(holding(lk))
    panic("acquire");

  // On RISC-V, sync_lock_test_and_set turns into an atomic swap:
  //   a5 = 1
  //   s1 = &lk->locked
  //   amoswap.w.aq a5, a5, (s1)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen strictly after the lock is acquired.
  // On RISC-V, this emits a fence instruction.
  __sync_synchronize();

  // Record info about lock acquisition for holding() and debugging.
  lk->cpu = mycpu();
}
```

Once the lock is acquired, acquire records, for debugging, the CPU that acquired the lock. The `lk->cpu` field is protected by the lock and must only be changed while holding the lock.

#### Release

> release就是acquire的反面了，她就是用0去换1。

The function release (kernel/spinlock.c:47) is the opposite of acquire: it clears the `lk->cpu` field and then releases the lock.

Conceptually, the release just requires assigning zero to `lk->locked`. The C standard allows compilers to implement an assignment with multiple store instructions, so a **C assignment might be non-atomic with respect to concurrent code**. Instead, release uses the C library function ` __sync_lock_release` that performs an atomic assignment. This function also boils down to a RISC-V `amoswap` instruction.

```c
// Release the lock.
void
release(struct spinlock *lk)
{
  if(!holding(lk))
    panic("release");

  lk->cpu = 0;

  // Tell the C compiler and the CPU to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other CPUs before the lock is released,
  // and that loads in the critical section occur strictly before
  // the lock is released.
  // On RISC-V, this emits a fence instruction.
  __sync_synchronize();

  // Release the lock, equivalent to lk->locked = 0.
  // This code doesn't use a C assignment, since the C standard
  // implies that an assignment might be implemented with
  // multiple store instructions.
  // On RISC-V, sync_lock_release turns into an atomic swap:
  //   s1 = &lk->locked
  //   amoswap.w zero, zero, (s1)
  __sync_lock_release(&lk->locked);

  pop_off();
}
```

### 6.3 Code: Using locks

Xv6 uses locks in many places to avoid race conditions. As described above, `kalloc` (kernel/kalloc.c:69) and `kfree` (kernel/kalloc.c:47) form a good example. Try Exercises 1 and 2 to see what happens if those functions omit the locks. You’ll likely find that it’s difficult to trigger incorrect behavior, suggesting that it’s hard to reliably test whether code is free from locking errors and races. It is not unlikely that xv6 has some races.

---

A hard part about using locks is deciding **how many locks to use** and **which data and invariants each lock should protect**.

There are a few basic principles.

- First, any time a variable can be written by one CPU at the same time that another CPU can read or write it, a lock should be used to keep the two operations from overlapping.
- Second, remember that locks protect invariants: if an invariant involves multiple memory locations, typically all of them need to be protected by a single lock to ensure the invariant is maintained.

The rules above say when locks are necessary but say nothing about when locks are unnecessary, and it is important for efficiency not to lock too much, because locks reduce parallelism. If parallelism isn’t important, then one could arrange to have only a single thread and not worry about locks. A simple kernel can do this on a multiprocessor by having a single lock that must be acquired on entering the kernel and released on exiting the kernel (though system calls such as pipe reads or wait would pose a problem). Many uniprocessor operating systems have been converted to run on multiprocessors using this approach, sometimes called a “big kernel lock,” but the approach sacrifices parallelism: only one CPU can execute in the kernel at a time. If the kernel does any heavy computation, it would be more efficient to use a larger set of more fine-grained locks, so that the kernel could execute on multiple CPUs simultaneously.

> Xv6在物理内存管理上用锁是很粗粒度的，也就是只有一个CPU可以去读写物理内存的链表。其他需要物理内存操作CPU就只能在锁的代码中一直循环。

As an example of **coarse-grained(粗粒度) locking**, xv6’s `kalloc.c` allocator has a single free list protected by a single lock. If multiple processes on different CPUs try to allocate pages at the same time, each will have to wait for its turn by spinning in acquire. Spinning reduces performance, since it’s not useful work. If contention for the lock wasted a significant fraction of CPU time, **perhaps performance could be improved by changing the allocator design to have multiple free lists, each with its own lock, to allow truly parallel allocation.**

As an example of **fine-grained locking**, **xv6 has a separate lock for each file**, so that processes that manipulate different files can often proceed without waiting for each other’s locks. The file locking scheme could be made even more fine-grained if one wanted to allow processes to simultaneously write different areas of the same file. Ultimately lock granularity decisions need to be driven by performance measurements as well as complexity considerations.

### 6.4 Deadlock and lock ordering

![image-20220605234049019](assets/Operating Systems.assets/image-20220605234049019.png)

If a code path through the kernel must hold several locks at the same time, it is important that all code paths acquire those locks in the same order. If they don’t, there is a risk of deadlock.

> 锁的顺序与死锁的例子
>
> 线程T1按顺序要两把锁A，B；线程T2按顺序要两把锁B，A。
>
> 某种情形下，T1拿到了A的锁，T2拿到了B的锁。那么接下来，T1就会等待锁B被release，T2就会等待锁A被release。这样的情况下，T1拿不到锁B所以也就不可能执行到释放A的代码。T2也是同理。
>
> 解决的方案就是让所有path使用锁的顺序一致

Let’s say two code paths in xv6 need locks A and B, but code path 1 acquires locks in the order A then B, and the other path acquires them in the order B then A. Suppose thread T1 executes code path 1 and acquires lock A, and thread T2 executes code path 2 and acquires lock B. Next T1 will try to acquire lock B, and T2 will try to acquire lock A. Both acquires will block indefinitely, because in both cases the other thread holds the needed lock, and won’t release it until its acquire returns. **To avoid such deadlocks, all code paths must acquire locks in the same order.** The need for a global lock acquisition order means that locks are effectively part of each function’s specification: **callers must invoke functions in a way that causes locks to be acquired in the agreed-on order.**

---

**Xv6 has many lock-order chains** of length two involving per-process locks (the lock in each struct proc) due to the way that sleep works (see Chapter 7).

> `con.lock` --> `p.lock`

For example, `consoleintr` (kernel/console.c:138) is the interrupt routine which handles typed characters. When a newline arrives, any process that is waiting for console input should be woken up. To do this,` consoleintr` holds `cons.lock` while calling wakeup, which acquires the waiting process’s lock in order to wake it up. In consequence, the global deadlock-avoiding lock order includes the rule that `cons.lock` must be acquired before any process lock.

> `ip.lock` --> `buf.lock` -->`vdisk_lock`-->`p->lock`

The file-system code contains xv6’s longest lock chains. For example, creating a file requires simultaneously holding a lock on the directory, a lock on the new file’s `inode`, a lock on a disk block buffer, the disk driver’s `vdisk_lock`, and the calling process’s `p->lock`. To avoid deadlock, file-system code always acquires locks in the order mentioned in the previous sentence.

---

Honoring a global deadlock-avoiding order can be surprisingly difficult.

Sometimes the **lock order conflicts with logical program structure**, e.g., perhaps code module M1 calls module M2, but the lock order requires that a lock in M2 be acquired before a lock in M1. Sometimes **the identities of locks aren’t known in advance**, perhaps because one lock must be held in order to discover the identity of the lock to be acquired next. This kind of situation arises in the file system as it looks up successive components in a path name, and in the code for wait and exit as they search the table of processes looking for child processes. Finally, the danger of deadlock is often a constraint on how fine-grained one can make a locking scheme, since **more locks often means more opportunity for deadlock**. The need to avoid deadlock is often a major factor in kernel implementation.

### 6.5 Locks and interrupt handlers

Some xv6 spinlocks protect data that is used by both threads and interrupt handlers. For example, the `clockintr` timer interrupt handler might increment ticks (kernel/trap.c:163) at about the same time that a kernel thread reads ticks in sys_sleep (kernel/sysproc.c:64). The lock `tickslock` serializes the two accesses.

```c
void
clockintr()
{
  acquire(&tickslock);
  ticks++;
  wakeup(&ticks);
  release(&tickslock);
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}
```

The **interaction of spinlocks and interrupts raises a potential danger**. Suppose sys_sleep holds `tickslock`, and its CPU is interrupted by a timer interrupt. `clockintr` would try to acquire `tickslock`, see it was held, and wait for it to be released. In this situation, `tickslock` will never be released: only sys_sleep can release it, but sys_sleep will not continue running until `clockintr` returns. So the CPU will deadlock, and any code that needs either lock will also freeze.

> 这里描述了中断可能带来的死锁问题，中断可能会导致预设的顺序被打乱。

To avoid this situation, **if a spinlock is used by an interrupt handler, a CPU must never hold that lock with interrupts enabled**. Xv6 is more conservative: when a CPU acquires any lock, xv6 always disables interrupts on that CPU. Interrupts may still occur on other CPUs, so an interrupt’s acquire can wait for a thread to release a spinlock; just not on the same CPU.

---

**xv6 re-enables interrupts when a CPU holds no spinlocks**;

it must do a little book-keeping to cope with nested critical sections. acquire calls `push_off` (kernel/spinlock.c:89) and release calls `pop_off` (kernel/spinlock.c:100) to **track the nesting level of locks on the current CPU**. When that count reaches zero, `pop_off` restores the interrupt enable state that existed at the start of the outermost critical section. The `intr_off`and `intr_on` functions execute RISC-V instructions to disable and enable interrupts, respectively.

```c
// push_off/pop_off are like intr_off()/intr_on() except that they are matched:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    mycpu()->intena = old;
  mycpu()->noff += 1;
}

void
pop_off(void)
{
  struct cpu *c = mycpu();
  if(intr_get())
    panic("pop_off - interruptible");
  if(c->noff < 1)
    panic("pop_off");
  c->noff -= 1;
  if(c->noff == 0 && c->intena)
    intr_on();
}
```

It is important that acquire call push_off strictly before setting `lk->locked` (kernel/spinlock.c:28). If the two were reversed, there would be a brief window when the lock was held with interrupts enabled, and an unfortunately timed interrupt would deadlock the system. Similarly, it is important that release call `pop_off` only after releasing the lock (kernel/spinlock.c:66).

### 6.6 Instruction and memory ordering

It is natural to think of programs executing in the order in which source code statements appear. **Many compilers and CPUs, however, execute code out of order to achieve higher performance.** If an instruction takes many cycles to complete, a CPU may issue the instruction early so that it can overlap with other instructions and avoid CPU stalls(停顿). For example, a CPU may notice that in a serial sequence of instructions A and B are not dependent on each other. The CPU may start instruction B first, either because its inputs are ready before A’s inputs, or in order to overlap execution of A and B. A compiler may perform a similar re-ordering by emitting instructions for one statement before the instructions for a statement that precedes it in the source.

> CPU和Compiler会为了程序的有更高的性能打乱执行的顺序，这对线性执行的代码功能没有影响，但对于并发的代码就带来了问题，

Compilers and CPUs follow rules when they re-order to ensure that they don’t change the results of correctly-written serial code. However, the rules do allow re-ordering that changes the results of concurrent code, and can easily lead to incorrect behavior on multiprocessors . <u>The CPU’s ordering rules are called the **`memory model`**.</u>

For example, in this code for push, it would be a disaster if the compiler or CPU moved the store corresponding to line 4 to a point after the release on line 6:

```c
1 l = malloc(sizeof *l);
2 l->data = data;
3 acquire(&listlock);
4 l->next = list;
5 list = l;
6 release(&listlock);
```

If such a re-ordering occurred, there would be a window during which another CPU could acquire the lock and observe the updated list, but see an uninitialized list->next.

**To tell the hardware and compiler not to perform such re-orderings**, xv6 uses **`__sync_synchronize()`** in both acquire (kernel/spinlock.c:22) and release (kernel/spinlock.c:47).` __sync_synchronize()` is a **memory barrier**: it tells the compiler and CPU to not reorder loads or stores across the barrier. The barriers in xv6’s acquire and release force order in almost all cases where it matters, since xv6 uses locks around accesses to shared data. Chapter 9 discusses a few exceptions.

### 6.7 Sleep locks

> 锁带来问题的情况之一：向磁盘读写文件时，因为锁的原因，其他的进程也无法使用CPU，只能等待CPU执行到磁盘返回消息并解开锁，但磁盘的读写是非常慢的。我们其实可以在当前进程等待I/O操作的空闲时间，把CPU让给其他的进程。
>
> 但是在拥有锁的时候切换进程是不合法的，
>
> 这里的不合法没有太明白。。。。。。。。。。。。。。之后补充
>
> 第七章会深入说明

Sometimes xv6 needs to hold a lock for a long time. For example, the file system (Chapter 8) keeps a file locked while reading and writing its content on the disk, and these disk operations can take tens of milliseconds. Holding a spinlock that long would lead to waste if another process wanted to acquire it, since the acquiring process would waste CPU for a long time while spinning. Another drawback of spinlocks is that **a process cannot yield the CPU while retaining a spinlock**; **we’d like to do this so that other processes can use the CPU while the process with the lock waits for the disk.** Yielding while holding a spinlock is illegal because it might lead to deadlock if a second thread then tried to acquire the spinlock; since acquire doesn’t yield the CPU, the second thread’s spinning might prevent the first thread from running and releasing the lock. Yielding while holding a lock would also violate the requirement that interrupts must be off while a spinlock is held. **Thus we’d like a type of lock that yields the CPU while waiting to acquire, and allows yields (and interrupts) while the lock is held.**

Xv6 provides such locks in the form of **sleep-locks**. `acquiresleep` (kernel/sleeplock.c:22) yields the CPU while waiting, using techniques that will be explained in Chapter 7. At a high level, a sleep-lock has a locked field that is protected by a spinlock, and `acquiresleep` ’s call to sleep atomically yields the CPU and releases the spinlock. The result is that other threads can execute while `acquiresleep` waits.

```c
void
acquiresleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  while (lk->locked) {
    sleep(lk, &lk->lk);
  }
  lk->locked = 1;
  lk->pid = myproc()->pid;
  release(&lk->lk);
}
```

Because sleep-locks leave interrupts enabled, they cannot be used in interrupt handlers. Because `acquiresleep` may yield the CPU, sleep-locks cannot be used inside spinlock critical sections (though spinlocks can be used inside sleep-lock critical sections). **Spin-locks are best suited to short critical sections, since waiting for them wastes CPU time; sleep-locks work well for lengthy operations.**

## Chapter 7 Scheduling

Any operating system is likely to run with more processes than the computer has CPUs, so a plan is needed to time-share the CPUs among the processes. Ideally the sharing would be transparent to user processes. A common approach is to provide each process with the illusion that it has its own virtual CPU by multiplexing the processes onto the hardware CPUs. This chapter explains how xv6 achieves this multiplexing.

### 7.1 Multiplexing

> xv6在两种情况下实现了对CPU的复用
>
> 1. sleep和wakeup机制
> 2. timer时间片机制
>
> 关于xv6的线程问题
>
> xv6并没有实现用户级别的多线程，xv6的每个process可以被看做有两个线程，一个是内核线程，另一个是用户线程。线程间的context切换也只是针对kernel thread。

Xv6 **multiplexes by switching each CPU** from one process to another in **two situations.**

- First, **xv6’s sleep and wakeup mechanism** switches when a process <u>waits for device or pipe I/O to complete</u>, or <u>waits for a child to exit</u>, or <u>waits in the sleep system call.</u>

- Second, **xv6 periodically forces a switch to cope with processes that compute for long periods without sleeping**. This multiplexing creates the illusion that each process has its own CPU, just as xv6 uses the memory allocator and hardware page tables to create the illusion that each process has its own memory.

---

Implementing **multiplexing** poses a few **challenges**.

- First, **how to switch** from one process to another? Although the idea of context switching is simple, the implementation is some of the most opaque code in xv6.
- Second, how to force switches in a way that is transparent to user processes? Xv6 uses the standard technique of driving context switches with timer interrupts.
- Third, many CPUs may be **switching** among processes **concurrently**, and **a locking plan** is necessary to avoid races.
- Fourth, a **process’s memory and other resources must be freed when the process exits**, **but it cannot do all of this itself because (for example) it can’t free its own kernel stack while still using it.**
- Fifth, **each core** of a multi-core machine **must remember which process it is executing** so that system calls affect the correct process’s kernel state.
- Finally, **sleep and wakeup** allow a process to give up the CPU and sleep waiting for an event, and allows another process to wake the first process up. Care is needed to **avoid races that result in the loss of wakeup notifications**. Xv6 tries to solve these problems as simply as possible, but nevertheless the resulting code is tricky.

![image-20220610234710788](assets/Operating Systems.assets/image-20220610234710788.png)

### 7.2 Code: Context switching

Figure 7.1 outlines the **steps involved in switching from one user process to another**:

> 这里以timer中断机制触发scheduling为例
>
> 1. `进程A`收到时间中断，从而进入该进程的kernel线程
> 2. `进程A的内核线程`保存当前的寄存器值到p->context
> 3. `进程A的内核线程`将寄存器恢复到CPU的scheduler线程切换前的状态
> 4. `CPU的scheduler线程`寻找到下一个`RUNNABLE`进程B，找到后将当前寄存器中的值保存到`cpu->context`， 将寄存器中的值恢复为进程B中保存的`p->context`
> 5. `进程B`一路return回到进程B的user space然后继续执行`进程B的用户线程`

- a user-kernel transition (system call or interrupt) to the old process’s kernel thread,

- a context switch to the current CPU’s scheduler thread,

- a context switch to a new process’s kernel thread, and

- a trap return to the user-level process.

> **每个CPU都有一个scheduler thread，他有着自己独立的栈和一些相应的寄存器值**。xv6的进程切换是通过CPU调度线程完成的，也就是说
>
> process A -> scheduler -> process B
>
> 每个scheduler thread是拥有自己的独立栈的，这些栈在`start.c`中被设置。这样设计的原因要通过代码理解。

The xv6 scheduler has a dedicated thread (saved registers and stack) per CPU because it is not safe for the scheduler execute on the old process’s kernel stack: some other core might wake the process up and run it, and it would be a disaster to use the same stack on two different cores. In this section we’ll examine the mechanics of switching between a kernel thread and a scheduler thread.

---

> `switch context（上下文切换）`这个术语一般用于内核发生的线程调度，这里这样说明是因为user trap进入内核前将主要的寄存器保存到`trapframe`中的行为也可以被看作是一种context的切换。
>
> 线程调度的核心函数就是`swtch()`了，他所做的事就是保存当前的寄存器中的值，然后把寄存器中的值设置为CPU调度器的上下文。之后将详细解释。
>
> context是什么？其实本质就是一些`callee saved`register和`ra, sp`寄存器。为什么是他们呢，之后会解释。

Switching from one thread to another involves saving the old thread’s CPU registers, and restoring the previously-saved registers of the new thread; the fact that the stack pointer and program counter are saved and restored means that the CPU will switch stacks and switch what code it is executing.

The function `swtch` performs the **saves and restores for a kernel thread switch**. `swtch` doesn’t directly know about threads; **it just saves and restores register sets, called `contexts`**.

When it is time for a process to give up the CPU, **the process’s kernel thread calls `swtch` to save its own context and return to the scheduler context.** Each context is contained in a `struct context` (kernel/proc.h:2), itself contained in a process’s struct proc or a CPU’s `struct cpu`. `Swtch` takes two arguments: `struct context *old` and `struct context *new`. It saves the current registers in old, loads registers from new, and returns.

```c
struct context {
  uint64 ra;
  uint64 sp;

  // callee-saved
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};

// Per-CPU state.
struct cpu {
  struct proc *proc;          // The process running on this cpu, or null.
  struct context context;     // swtch() here to enter scheduler().
  int noff;                   // Depth of push_off() nesting.
  int intena;                 // Were interrupts enabled before push_off()?
};
```

Let’s follow a process through `swtch` into the scheduler. We saw in Chapter 4 that one possibility at the end of an interrupt is that `usertrap` calls `yield`. `Yield` in turn calls `sched`, which calls `swtch` to save the current context in p->context and switch to the scheduler context previously saved in `cpu->scheduler` (kernel/proc.c:509).

> 这里以timer interrupt为例子，概述了整个函数调用的过程
>
> `process A kernel thread: usertrap() -> yield() -> sched() -> swtch() `
>
> `CPU scheduler thread(process A是通过它被调度执行的): swtch() return -> scheduler() for loop -> find process B -> swtch() `
>
> `process B kernel thread: swtch() return -> sched() return -> yield() return -> usertrap()`
>
> `sched()`函数主要用来对`yield()`进行二次检查

```c
// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}
```

`Swtch` (kernel/swtch.S:3) saves only `callee-saved` registers; **caller-saved registers are saved on the stack (if needed) by the calling C code**. `Swtch` knows the offset of each register’s field in struct context.

It does not save the program counter. **Instead, `swtch` saves the `ra` register, which holds the return address from which `swtch` was called.** Now `swtch` restores registers from the new context, which holds register values saved by a previous `swtch`. When `swtch` returns, it returns to the instructions pointed to by the restored `ra` register, that is, the instruction from which the new thread previously called `swtch`.

In addition, it returns on the **new thread’s stack.**

> `swtch()`的代码非常简单，就是简单的store和restore。
>
> 这里需要留意的是，我们在上下文切换时仅仅保存了`callee saved`寄存器，这些寄存器的特点就是他们会被被调用函数的栈帧保存，因为被调用函数会继续用他们执行自己的任务，这样当被调用函数返回时，这些寄存器就会恢复他们在调用者那时的状态。然而，`swtch()`函数不会再有`callee`来为它保存这些寄存器了，所以我们这里只保存`callee saved`。
>
> 另一点需要留意的就是我们只保存和恢复了`ra 和 sp`。`sp`很好理解，每个线程都有自己独立的栈；`ra`指的是return address，当下边的汇编代码执行到ret时，我们的pc就会指向`ra`中的地址, 所以在这里设置pc的值是没有必要的。

```assembly
## Context switch
##
##   void swtch(struct context *old, struct context *new);
##
## Save current registers in old. Load from new.


.globl swtch
swtch:
        sd ra, 0(a0)
        sd sp, 8(a0)
        sd s0, 16(a0)
        sd s1, 24(a0)
        sd s2, 32(a0)
        sd s3, 40(a0)
        sd s4, 48(a0)
        sd s5, 56(a0)
        sd s6, 64(a0)
        sd s7, 72(a0)
        sd s8, 80(a0)
        sd s9, 88(a0)
        sd s10, 96(a0)
        sd s11, 104(a0)

        ld ra, 0(a1)
        ld sp, 8(a1)
        ld s0, 16(a1)
        ld s1, 24(a1)
        ld s2, 32(a1)
        ld s3, 40(a1)
        ld s4, 48(a1)
        ld s5, 56(a1)
        ld s6, 64(a1)
        ld s7, 72(a1)
        ld s8, 80(a1)
        ld s9, 88(a1)
        ld s10, 96(a1)
        ld s11, 104(a1)

        ret
```

> 需要再强调一次，线程的切换是要经过CPU scheduler线程的。

In our example, `sched` called `swtch` to switch to `cpu->scheduler`, the per-CPU scheduler context. That context had been saved by scheduler’s call to `swtch` (kernel/proc.c:475). **When the `swtch` we have been tracing returns, it returns not to `sched` but to scheduler, and its stack pointer points at the current CPU’s scheduler stack.**

### 7.3 Code: Scheduling

The last section looked at the low-level details of `swtch`; now let’s take `swtch` as a given and examine switching from one process’s kernel thread through the scheduler to another process. **The scheduler exists in the form of a special thread per CPU, each running the scheduler function.** This function is in charge of choosing which process to run next.

```c
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}
```

**A process that wants to give up the CPU must acquire its own process lock p->lock, release any other locks it is holding, update its own state (p->state), and then call `sched`.** Yield (kernel/proc.c:515) follows this convention, as do sleep and exit, which we will examine later. Sched double-checks those conditions (kernel/proc.c:499-504) and then an implication of those conditions: since a lock is held, interrupts should be disabled. Finally, `sched` calls `swtch` to save the current context in p->context and switch to the scheduler context in `cpu->scheduler`. `Swtch` returns on the scheduler’s stack as though scheduler’s `swtch` had returned. The scheduler continues the for loop, finds a process to run, switches to it, and the cycle repeats.

```c
// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}
```

We just saw that xv6 holds p->lock across calls to `swtch`: the caller of `swtch` must already hold the lock, and control of the lock passes to the switched-to code. This convention is unusual with locks; usually the thread that acquires a lock is also responsible for releasing the lock, which makes it easier to reason about correctness.

For context switching it is necessary to break this convention because p->lock protects invariants on the process’s state and context fields that are not true while executing in `swtch`. <u>One example of a problem that could arise if p->lock were not held during `swtch`: a different CPU might decide to run the process after yield had set its state to RUNNABLE, but before `swtch` caused it to stop using its own kernel stack. The result would be two CPUs running on the same stack, which cannot be right.</u>

> 下图对整个调度的过程进行了汇总，这里对锁的使用是十分巧妙地，为了避免上述可能发生的情况。我们可以看到，process A在yield中获得锁，在进入scheduler线程中时释放了锁，这样保证了切换到调度进程的原子性。之后CPU线程就会继续for循环，直到找到了新的进程process B，scheduler线程给进程B上了锁，在yield中释放了锁，这样保证了切换到新线程的原子性。
>
> 通过下图，`p->context`和`c->context`之中保存了什么也就清晰了。process A在`swtch()`时将当前寄存器的相关值保存到了`p->context`, 这时`cpu->context`中存储的是scheduler线程进行找到process A后执行`swtch()`时寄存器的状态，`cpu->context`会被restore到寄存器中，从而我们就回到了scheduler线程。
>
> scheduler线程通过for循环找到的新的进程process B，又将`swtch()`时的context保存到`cpu->context`，然后将process B中之前保存的`p->context`restore到寄存器中，接着我们就切换到了process B的内核线程中。

![image-20220613001313654](assets/Operating Systems.assets/image-20220613001313654.png)

**A kernel thread always gives up its CPU in `sched` and always switches to the same location in the scheduler, which (almost) always switches to some kernel thread that previously called `sched`.** Thus, if one were to print out the line numbers where xv6 switches threads, one would observe the following simple pattern: (kernel/proc.c:475), (kernel/proc.c:509), (kernel/proc.c:475), (kernel/proc.c:509), and so on. **The procedures in which this stylized switching between two threads happens are sometimes referred to as `coroutines`**; in this example, **`sched` and `scheduler` are co-routines of each other**.

> 可以看出，内核线程间的切换的函数调用都是`sched` and `scheduler`交替着进行的，他们可以被称为`coroutines`
>
> 上图也相应的引出了一个问题，看上去进程之间都是在不停的交换context，那么一开始这些process中的context是哪里来的呢？下面的内容解答了这一问题。
>
> 可以看到`allocproc`在一开始初始化每一个`proc`的时候，就预先将他们的context中的返回地址设为了`forkret`, 这里有一个假的`usertrapret`让新的进程可以返回用户空间执行他的用户线程。

**There is one case when the scheduler’s call to `swtch` does not end up in `sched`.** When a new process is first scheduled, it begins at `forkret` (kernel/proc.c:527). `Forkret` exists to release the p->lock; otherwise, the new process could start at `usertrapret`.

```c
// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

 ...................

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
	................
  // An empty user page table.
	................
  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}
```

Scheduler (kernel/proc.c:457) runs a simple loop: find a process to run, run it until it yields, repeat. The scheduler loops over the process table looking for a runnable process, one that has p->state == RUNNABLE. Once it finds a process, it sets the per-CPU current process variable c->proc, marks the process as RUNNING, and then calls `swtch` to start running it (kernel/proc.c:470- 475).

```c
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}
```

---

#### Locks in scheduling code

One way to think about the structure of the scheduling code is that it enforces a set of invariants about each process, and holds p->lock whenever those invariants are not true. One invariant is that if a process is RUNNING, a timer interrupt’s yield must be able to safely switch away from the process; this means that the CPU registers must hold the process’s register values (i.e. `swtch` hasn’t moved them to a context), and c->proc must refer to the process. Another invariant is that if a process is RUNNABLE, it must be safe for an idle CPU’s scheduler to run it; this means that p->context must hold the process’s registers (i.e., they are not actually in the real registers), that no CPU is executing on the process’s kernel stack, and that no CPU’s c->proc refers to the process. Observe that these properties are often not true while p->lock is held.

Maintaining the above invariants is the reason why xv6 often acquires p->lock in one thread and releases it in other, for example acquiring in yield and releasing in scheduler. Once yield has started to modify a running process’s state to make it RUNNABLE, the lock must remain held until the invariants are restored: the earliest correct release point is after scheduler (running on its own stack) clears c->proc. Similarly, once scheduler starts to convert a RUNNABLE process to RUNNING, the lock cannot be released until the kernel thread is completely running (after the `swtch`, for example in yield).

p->lock protects other things as well: the interplay between exit and wait, the machinery to avoid lost wakeups (see Section 7.5), and avoidance of races between a process exiting and other processes reading or writing its state (e.g., the exit system call looking at `p->pid` and setting `p->killed` (kernel/proc.c:611)). It might be worth thinking about whether the different functions of p->lock could be split up, for clarity and perhaps for performance.

### 7.4 Code: `mycpu` and `myproc`

Xv6 often needs a pointer to the current process’s proc structure. On a uniprocessor one could have a global variable pointing to the current proc. This doesn’t work on a multi-core machine, since each core executes a different process. The way to solve this problem is to exploit the fact that each core has its own set of registers; we can use one of those registers to help find per-core information.

Xv6 maintains a struct `cpu` for each CPU (kernel/proc.h:22), which records the process currently running on that CPU (if any), saved registers for the CPU’s scheduler thread, and the count of nested spinlocks needed to manage interrupt disabling. The function `mycpu` (kernel/proc.c:60) returns a pointer to the current CPU’s struct `cpu`. RISC-V numbers its CPUs, giving each a `hartid`. Xv6 ensures that each CPU’s `hartid` is stored in that CPU’s **`tp` register while in the kernel**. This allows `mycpu` to use tp to index an array of `cpu` structures to find the right one.

```c
// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// read and write tp, the thread pointer, which holds
// this core's hartid (core number), the index into cpus[].
static inline uint64
r_tp()
{
  uint64 x;
  asm volatile("mv %0, tp" : "=r" (x) );
  return x;
}
```

Ensuring that a CPU’s tp always holds the CPU’s `hartid` is a little involved. `mstart` sets the tp register early in the CPU’s boot sequence, while still in machine mode (kernel/start.c:46). `usertrapret` saves tp in the trampoline page, because the user process might modify tp. Finally, `uservec` restores that saved tp when entering the kernel from user space (kernel/trampoline.S:70). **The compiler guarantees never to use the tp register**. It would be more convenient if RISC-V allowed xv6 to read the current `hartid` directly, but that is allowed only in machine mode, not in supervisor mode.

**The return values of `cpuid` and `mycpu` are fragile**: if the <u>timer were to interrupt</u> and cause the thread to <u>yield and then move to a different CPU, a previously returned value would no longer be correct</u>. To avoid this problem, xv6 requires that **callers disable interrupts**, and only enable them after they finish using the returned struct `cpu`.

```c
void
start()
{
  // set M Previous Privilege mode to Supervisor, for mret.

  // set M Exception Program Counter to main, for mret.
  // requires gcc -mcmodel=medany

  // disable paging for now.

  // delegate all interrupts and exceptions to supervisor mode.

  // configure Physical Memory Protection to give supervisor mode
  // access to all of physical memory.

  // ask for clock interrupts.
  timerinit();

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
}
```

The function `myproc` (kernel/proc.c:68) returns the struct proc pointer for the process that is running on the current CPU. `myproc` disables interrupts, invokes `mycpu`, fetches the current process pointer (c->proc) out of the struct `cpu`, and then enables interrupts. The return value of `myproc` is safe to use even if interrupts are enabled: if a timer interrupt moves the calling process to a different CPU, its struct proc pointer will stay the same.

```c
// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}
```

### 7.5 Sleep and wakeup

> 有了进程调度和锁，为什么还需要sleep和wakeup呢？

Scheduling and locks help conceal the existence of one process from another, but so far we have no abstractions that help processes intentionally interact. Many mechanisms have been invented to solve this problem. Xv6 uses one called sleep and wakeup, which allow one process to sleep waiting for an event and another process to wake it up once the event has happened. `Sleep` and `wakeup` are often called **sequence coordination** or **conditional synchronization mechanisms.**

> 下面是一个信号量的例子。生产者线程调用V来让让count增加，消费者线程调用P一直监控着count，一发现生产出东西就立刻消费。然而，如果生产者长时间不生产，那么消费者线程会一直占用CPU，我们应该想办法让消费者在等待的这段时间让出CPU。

To illustrate, let’s consider a synchronization mechanism called a **semaphore**(信号) that coordinates producers and consumers. A semaphore maintains a count and provides two operations. The “V” operation (for the producer) increments the count. The “P” operation (for the consumer) waits until the count is non-zero, and then decrements it and returns. If there were only one producer thread and one consumer thread, and they executed on different CPUs, and the compiler didn’t optimize too aggressively, this implementation would be correct:

```c
struct semaphore {
101 struct spinlock lock;
102 int count;
103 };
104
105 void
106 V(struct semaphore *s)
107 {
108 acquire(&s->lock);
109 s->count += 1;
110 release(&s->lock);
111 }
112
113 void
114 P(struct semaphore *s)
115 {
116 while(s->count == 0)
117 ;
118 acquire(&s->lock);
119 s->count -= 1;
120 release(&s->lock);
121 }
```

The implementation above is expensive. If the producer acts rarely, the consumer will spend most of its time spinning in the while loop hoping for a non-zero count. The consumer’s CPU could find more productive work than with busy waiting by repeatedly polling s->count. **Avoiding busy waiting requires a way for the consumer to yield the CPU and resume only after V increments the count.**

---

Here’s a step in that direction, though as we will see it is not enough. Let’s imagine a pair of calls, sleep and wakeup, that work as follows. Sleep(`chan`) sleeps on the arbitrary value `chan`, called the `wait channel`. `Sleep` puts the calling process to sleep, releasing the CPU for other work. `Wakeup(chan) `wakes all processes sleeping on`chan` (if any), causing their `sleep` calls to return. If no processes are waiting on `chan`, `wakeup` does nothing. We can change the semaphore implementation to use sleep and wakeup (changes highlighted in yellow):

```c
200 void
201 V(struct semaphore *s)
202 {
203 acquire(&s->lock);
204 s->count += 1;
205 wakeup(s);//change
206 release(&s->lock);
207 }
208
209 void
210 P(struct semaphore *s)
211 {
212 while(s->count == 0)
213 	sleep(s);//change
214 acquire(&s->lock);
215 s->count -= 1;
216 release(&s->lock);
217 }
```

P now gives up the CPU instead of spinning, which is nice. However, it turns out not to be straightforward to design sleep and wakeup with this interface without suffering from what is known as the **lost wake-up problem**.

> 这种设计并不完美，他会带来**lost wake-up problem**，具体的情景就是，消费者和生产者运行在两个CPU上，当消费者处在进入睡眠状态的过程中时，生产者完成了生产并将count变为1，然后通知睡眠中的进程苏醒，然而这时消费者还没有进入睡眠， 从而消费者面对count = 1时保持着睡眠的状态。最后造成的结果就是，若生产者之后不再调用消费者，那么消费者就会永远的沉睡。

Suppose that P finds that s->count == 0 on line 212. While P is between lines 212 and 213, V runs on another CPU: it changes s->count to be nonzero and calls wakeup, which finds no processes sleeping and thus does nothing. Now P continues executing at line 213: it calls sleep and goes to sleep. This causes a problem: P is asleep waiting for a V call that has already happened. Unless we get lucky and the producer calls V again, the consumer will wait forever even though the count is non-zero.

---

> 应对上面说的**lost wake-up problem**，下面的代码做了一些改变。看起来，生产者必须等到消费者进入睡眠状态后才能增加count。然而，当消费者进入睡眠之后，他会一直拥有锁，从而生产者永远无法拿到锁进行生产，这就造成了**死锁**。

The root of this problem is that the invariant that P only sleeps when s->count == 0 is violated by V running at just the wrong moment. An incorrect way to protect the invariant would be to move the lock acquisition (highlighted in yellow below) in P so that its check of the count and its call to sleep are atomic:

```c
300 void
301 V(struct semaphore *s)
302 {
303 acquire(&s->lock);
304 s->count += 1;
305 wakeup(s);
306 release(&s->lock);
307 }
308
309 void
310 P(struct semaphore *s)
311 {
312 acquire(&s->lock);//change
313 while(s->count == 0)
314 	sleep(s);
315 s->count -= 1;
316 release(&s->lock);// 这里永远执行不到
317 }
```

One might hope that this version of P would avoid the lost wakeup because the lock prevents V from executing between lines 313 and 314. It does that, but it also deadlocks: P holds the lock while it sleeps, so V will block forever waiting for the lock.

---

> 为了解决死锁的问题，sleep应该做到两件事
>
> 1. 接受消费者的锁为参数，当消费者完全进入sleep channel后，在sleep函数内部解锁，从而生产者就可以得到锁继续执行。
> 2. 当消费者wakeup时，sleep函数要重新获得锁，然后返回。

We’ll fix the preceding scheme by changing sleep’s interface: **the caller must pass the condition lock to sleep so it can release the lock after the calling process is marked as asleep and waiting on the sleep channel**. The lock will force a concurrent V to wait until P has finished putting itself to sleep, so that the wakeup will find the sleeping consumer and wake it up. **Once the consumer is awake again sleep reacquires the lock before returning**. Our new correct sleep/wakeup scheme is usable as follows (change highlighted in yellow):

```c
400 void
401 V(struct semaphore *s)
402 {
403 acquire(&s->lock);
404 s->count += 1;
405 wakeup(s);
406 release(&s->lock);
407 }
408
409 void
410 P(struct semaphore *s)
411 {
412 acquire(&s->lock);
413 while(s->count == 0)
414 sleep(s, &s->lock);//change
415 s->count -= 1;
416 release(&s->lock);
417 }
```

The fact that P holds s->lock prevents V from trying to wake it up between P’s check of c->count and its call to sleep. Note, however, that we need sleep to atomically release s->lock and put the consuming process to sleep.

### 7.6 Code: Sleep and wakeup

> 接下来就该看看sleep和wakeup究竟是怎么实现的了

Let’s look at the implementation of sleep (kernel/proc.c:548) and wakeup (kernel/proc.c:582). The basic idea is to have sleep mark the current process as SLEEPING and then call `sched` to release the CPU; wakeup looks for a process sleeping on the given wait channel and marks it as RUNNABLE. Callers of sleep and wakeup can use any mutually convenient number as the channel. Xv6 often uses the address of a kernel data structure involved in the waiting.

#### Sleep

```c
// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.
  if(lk != &p->lock){  //DOC: sleeplock0
    acquire(&p->lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  if(lk != &p->lock){
    release(&p->lock);
    acquire(lk);
  }
}
```

> `lk`是wakeup可以开始的条件，sleep在拿到`p->lock`后就立刻释放了`lk`，从而wakeup就可以开始工作了。
>
> 但这并不会导致missing wake up的问题，虽然我们释放了`lk`让wakeup得以进入for loop开始寻找需要被唤醒的进程，但是for loop中需要获取每个进程的锁。正在准备sleeping的进程正持有着这个锁，从而wakeup必须等待sleep进程彻底入睡后才能进行唤醒任务。
>
> 这里还有一个xv6的准则需要注意，我们**在进入`sched`之前，必须保证只有`p->lock`这一把锁**，因为这把锁会在调度进程那里被release。如果我们有其他锁的话，那么他们在`sched`之后将无法释放，从而当另外一些进程需要这些锁的时候，导致死锁。

Sleep acquires p->lock (kernel/proc.c:559). Now the process going to sleep holds both `p->lock` and `lk`. Holding `lk` was necessary in the caller (in the example, P): it ensured that no other process (in the example, one running V) could start a call to `wakeup(chan)`. <u>Now that sleep holds `p->lock`, it is safe to release `lk`: some other process may start a call to `wakeup(chan)`, but wakeup will wait to acquire `p->lock`, and thus will wait until sleep has finished putting the process to sleep, keeping the wakeup from missing the sleep.</u>

---

> sleep有一个特殊的情形，如果`lk`就是`p->lock`怎么办呢？
>
> 那么我们其实什么也不用做，等到sleeping进程切换到调度进程被释放后，对应的wakeup就可以进入for循环取唤醒它了。
>
> 这种情形出现在`wait()`系统调用这里，会在之后说明。

**There is a minor complication: if `lk` is the same lock as `p->lock`, then sleep would deadlock with itself if it tried to acquire p->lock**. But if the process calling sleep already holds `p->lock`, it doesn’t need to do anything more in order to avoiding missing a concurrent wakeup. This case arises when wait (kernel/proc.c:582) calls sleep with p->lock.

---

> 为什么`p->lock` is not released (by scheduler) until after the process is marked SLEEPING?

Now that sleep holds p->lock and no others, it can put the process to sleep by recording the sleep channel, changing the process state to SLEEPING, and calling `sched` (kernel/proc.c:564-567). In a moment it will be clear why it’s critical that `p->lock` is not released (by scheduler) until after the process is marked SLEEPING.

---

#### Wakeup

At some point, a process will acquire the condition lock, set the condition that the sleeper is waiting for, and call `wakeup(chan`). It’s important that wakeup is called while holding the condition lock . Wakeup loops over the process table (kernel/proc.c:582). It acquires the p->lock of each process it inspects, both because it may manipulate that process’s state and because p->lock ensures that sleep and wakeup do not miss each other. When wakeup finds a process in state SLEEPING with a matching `chan`, it changes that process’s state to RUNNABLE. The next time the scheduler runs, it will see that the process is ready to be run.

```c
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == SLEEPING && p->chan == chan) {
      p->state = RUNNABLE;
    }
    release(&p->lock);
  }
}
```

> 为何这种设计不会miss wakeup？
>
> 1. wakeup运行时一直拿着两把锁：进程锁和condition锁（condition锁是wakeup函数执行的前一步）
> 2. condition锁保证了在进入wakeup之前，已经原子性的完成了该做的业务逻辑（例如，给buffer中写入内容）
> 3. 进程锁保证了在sleeping进程完成睡眠过程之前，wakeup不可以忽略他（例如，buffer中已经有了一些内容，但`bufferReader`还没有进入睡眠，只有在`bufferReader`进入睡眠后，wakeup才会叫醒他）

**Why do the locking rules for sleep and wakeup ensure a sleeping process won’t miss a wakeup?** The sleeping process holds either the condition lock or its own p->lock or both from a point before it checks the condition to a point after it is marked SLEEPING. The process calling wakeup holds both of those locks in wakeup’s loop. Thus the `waker` either makes the condition true before the consuming thread checks the condition; or the `waker’s` wakeup examines the sleeping thread strictly after it has been marked SLEEPING. Then wakeup will see the sleeping process and wake it up (unless something else wakes it up first).

> **多个进程都在同一个channel中睡眠的情况**
>
> 然而，只有一个进程会在sleep中苏醒后抢到condition lock然后读取生产者生产的内容
>
> 当其他被唤醒的教程之后拿到condition lock，只会发现什么都没了，只能在while循环中再次进入睡眠
>
> 这也是为什么sleep为什么总是在while循环中被调用

It is sometimes the case that multiple processes are sleeping on the same channel; for example, more than one process reading from a pipe. A single call to wakeup will wake them all up. One of them will run first and acquire the lock that sleep was called with, and (in the case of pipes) read whatever data is waiting in the pipe. The other processes will find that, despite being woken up, there is no data to be read. From their point of view the wakeup was “**spurious(虚假的)**,” and they must sleep again. **For this reason sleep is always called inside a loop that checks the condition.**

No harm is done if two uses of sleep/wakeup accidentally choose the same channel: they will see spurious wakeups, but looping as described above will tolerate this problem. Much of the charm of sleep/wakeup is that it is both lightweight (no need to create special data structures to act as sleep channels) and provides a layer of indirection (callers need not know which specific process they are interacting with).

### 7.7 Code: Pipes

> 管道是使用sleep和wakeup来实现进程同步的

A more complex example that uses sleep and wakeup to synchronize producers and consumers is xv6’s implementation of pipes. We saw the interface for pipes in Chapter 1: bytes written to one end of a pipe are copied to an in-kernel buffer and then can be read from the other end of the pipe. Future chapters will examine the file descriptor support surrounding pipes, but let’s look now at the implementations of `pipewrite` and `piperead`.

Each pipe is represented by a struct pipe, which contains a lock and a data buffer. The fields `nread` and `nwrite` count the total number of bytes read from and written to the buffer. The buffer wraps around: the next byte written after `buf[PIPESIZE-1]` is `buf[0]`. The counts do not wrap. This convention lets the implementation distinguish a **full buffer (`nwrite == nread+PIPESIZE`)** from an **empty buffer (`nwrite == nread`),** but it means that indexing into the buffer must use `buf[nread % PIPESIZE]` instead of just `buf[nread]` (and similarly for `nwrite`).

```c
struct pipe {
  struct spinlock lock;
  char data[PIPESIZE];
  uint nread;     // number of bytes read
  uint nwrite;    // number of bytes written
  int readopen;   // read fd is still open
  int writeopen;  // write fd is still open
};
```

---

Let’s suppose that calls to `piperead` and `pipewrite` happen simultaneously on two different CPUs. `Pipewrite` (kernel/pipe.c:77) begins by acquiring the pipe’s lock, which protects the counts, the data, and their associated invariants. `Piperead` (kernel/pipe.c:103) then tries to acquire the lock too, but cannot. It spins in acquire (kernel/spinlock.c:22) waiting for the lock. While `piperead` waits, `pipewrite` loops over the bytes being written (`addr[0..n-1]`), adding each to the pipe in turn (kernel/pipe.c:95). During this loop, it could happen that the buffer fills (kernel/pipe.c:85). In this case, `pipewrite` calls wakeup to alert any sleeping readers to the fact that there is data waiting in the buffer and then sleeps on `&pi->nwrite` to wait for a reader to take some bytes out of the buffer. Sleep releases `pi->lock` as part of putting `pipewrite`’s process to sleep.

```c
int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
  int i = 0;
  struct proc *pr = myproc();

  acquire(&pi->lock);
  while(i < n){
    if(pi->readopen == 0 || pr->killed){
      release(&pi->lock);
      return -1;
    }
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
        break;
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
      i++;
    }
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
```

```c
int
piperead(struct pipe *pi, uint64 addr, int n)
{
  int i;
  struct proc *pr = myproc();
  char ch;

  acquire(&pi->lock);
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
  release(&pi->lock);
  return i;
}
```

Now that `pi->lock` is available, `piperead` manages to acquire it and enters its critical section: it finds that `pi->nread != pi->nwrite` (kernel/pipe.c:110) (`pipewrite` went to sleep because `pi->nwrite == pi->nread+PIPESIZE` (kernel/pipe.c:85)), so it falls through to the for loop, copies data out of the pipe (kernel/pipe.c:117), and increments `nread` by the number of bytes copied. That many bytes are now available for writing, so `piperead` calls wakeup (kernel/pipe.c:124) to wake any sleeping writers before it returns. Wakeup finds a process sleeping on `&pi->nwrite`, the process that was running `pipewrite` but stopped when the buffer filled. It marks that process as RUNNABLE.

> 下面这一部分听课补充 为什么两个channel更高效？没说:(

**The pipe code uses separate sleep channels for reader and writer** (`pi->nread` and `pi->nwrite`); this might make the system more efficient in the unlikely event that there are lots of readers and writers waiting for the same pipe. The pipe code sleeps inside a loop checking the sleep condition; if there are multiple readers or writers, all but the first process to wake up will see the condition is still false and sleep again.

### 7.8 Code: Wait, exit, and kill

`Sleep` and `wakeup` can be used for many kinds of waiting. An interesting example, introduced in Chapter 1, is the interaction between a child’s `exit` and its parent’s `wait`.

At the time of the child’s death, the parent may already be sleeping in `wait`, or may be doing something else; in the latter case, a subsequent call to wait must observe the child’s death, perhaps long after it calls `exit`.

- The way that xv6 records the child’s **demise(灭亡)** until wait observes it is for exit to put the caller into the ZOMBIE state, where it stays until the parent’s wait notices it, changes the child’s state to UNUSED, copies the child’s exit status, and returns the child’s process ID to the parent.
- If **the parent exits before the child**, the parent gives the child to the `init process`, which **perpetually(永远)** calls wait; <u>thus every child has a parent to clean up after it</u>. The main implementation challenge is the possibility of races and deadlock between parent and child wait and exit, as well as exit and exit.

---

#### Wait

**Wait** uses the calling process’s `p->lock` as the condition lock to **avoid lost wakeups**, and it acquires that lock at the start (kernel/proc.c:398).

Then it **scans the process table**.

- If it finds a child in ZOMBIE state, it frees that child’s resources and its proc structure, **copies the child’s exit status to the address supplied to wait** (if it is not 0), and returns the child’s process ID.

- If wait finds children but none have exited, it calls sleep to wait for one of them to exit (kernel/proc.c:445), then scans again.

> 这里就要解答直接提出的sleep的特殊情况了：sleep中传入的condition lock是进程锁本身怎么办
>
> // Wait for a child to exit.
> ` sleep(p, &p->lock);  //DOC: wait-sleep`
>
> 为了避免死锁，我们就要严格遵守上锁的顺序，先parent再child

Here, the condition lock being released in sleep is the waiting process’s p->lock, the special case mentioned above. Note that wait often holds two locks; that it acquires its own lock before trying to acquire any child’s lock; and that thus all of xv6 must obey the same locking order (parent, then child) in order to avoid deadlock.

```c
// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  // hold p->lock for the whole time to avoid lost
  // wakeups from a child's exit().
  acquire(&p->lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      // this code uses np->parent without holding np->lock.
      // acquiring the lock first would cause a deadlock,
      // since np might be an ancestor, and we already hold p->lock.
      if(np->parent == p){
        // np->parent can't change between the check and the acquire()
        // because only the parent changes it, and we're the parent.
        acquire(&np->lock);
        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&p->lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&p->lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&p->lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &p->lock);  //DOC: wait-sleep
  }
}
```

Wait looks at every process’s np->parent to find its children.

**It uses np->parent without holding np->lock, which is a violation of the usual rule that shared variables must be protected by locks.**

> 这又有一处违反规则的地方，我们在检查每个process的parent时并没有给这个process上锁。如果上锁的话，可能带来一个问题：也就是如果`np`是当前进程的祖先，这样的话我们如果给`np`上锁就会导致子进程p的锁在其父进程np之前被获得了，这就违反了获得锁应该遵守的顺序。
>
> ```c
> // 如果我们在if判断前加锁可能遇到的情况
> acquire(&p->lock);// child
> for(np = proc; np < &proc[NPROC]; np++){
>       acquire(&np->lock);//parent
>       if(np->parent == p){
> ```
>
> 这里没有问题的原因是：
>
> 1. 子进程的parent只能被父进程改变，然而我们已经拥有父进程的锁了

It is possible that np is an ancestor of the current process, in which case acquiring np->lock could cause a deadlock since that would violate the order mentioned above. Examining np->parent without a lock seems safe in this case; a process’s parent field is only changed by its parent, so if np->parent==p is true, the value can’t change unless the current process changes it.

---

#### Exit

**Exit** (kernel/proc.c:333)

1. records the exit status, frees some resources,

2. gives any children to the `init` process,

3. wakes up the parent in case it is in wait, marks the caller as a zombie, and permanently yields the CPU.

> 为什么子进程在最后设置ZOMBIE和wakeup其父进程时一直拿着它parent的锁
>
> 父进程的锁是condition lock，没有他父进程就无法进入for循环开始寻找子进程
>
> 子进程自己的锁用于保证父进程不会看到自己是ZOMBIE就开始`freeproc`，
>
> ```c
>   acquire(&original_parent->lock);
>   acquire(&p->lock);
>   // Give any children to init.
>   reparent(p);
>   // Parent might be sleeping in wait().
>   wakeup1(original_parent);
>   p->xstate = status;
>   p->state = ZOMBIE;
>   release(&original_parent->lock);
> ```
>
> **锁的获得顺序**对于**避免死锁**是非常重要的，wait和exit就是一对可能引发race condition的进程，他们就必须遵循同样的获得锁的顺序

The final sequence is a little tricky. **The exiting process must hold its parent’s lock while it sets its state to ZOMBIE and wakes the parent up, since the parent’s lock is the condition lock that guards against lost wakeups in wait.** The child must also hold its own `p->lock`, since otherwise the parent might see it in state ZOMBIE and free it while it is still running. **The lock <u>acquisition</u> order is important to avoid deadlock: since wait acquires the parent’s lock before the child’s lock, exit must use the same order.**

```c
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  // we might re-parent a child to init. we can't be precise about
  // waking up init, since we can't acquire its lock once we've
  // acquired any other proc lock. so wake up init whether that's
  // necessary or not. init may miss this wakeup, but that seems
  // harmless.
  acquire(&initproc->lock);
  wakeup1(initproc);
  release(&initproc->lock);

  // grab a copy of p->parent, to ensure that we unlock the same
  // parent we locked. in case our parent gives us away to init while
  // we're waiting for the parent lock. we may then race with an
  // exiting parent, but the result will be a harmless spurious wakeup
  // to a dead or wrong process; proc structs are never re-allocated
  // as anything else.
  acquire(&p->lock);
  struct proc *original_parent = p->parent;
  release(&p->lock);

  // we need the parent's lock in order to wake it up from wait().
  // the parent-then-child rule says we have to lock it first.
  acquire(&original_parent->lock);

  acquire(&p->lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup1(original_parent);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&original_parent->lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}
```

`Exit` calls a specialized wakeup function, `wakeup1`, that **wakes up only the parent**, and only if it is sleeping in wait (kernel/proc.c:598). It may look incorrect for the child to wake up the parent before setting its state to ZOMBIE, but that is safe: although `wakeup1` may cause the parent to run, the loop in wait cannot examine the child until the child’s p->lock is released by scheduler, so wait can’t look at the exiting process until well after exit has set its state to ZOMBIE (kernel/proc.c:386)

> 在我看来这里使用wakeup1这种设计有点像是为了克服sleep的condition lock是父进程锁的弊端，如果不使用wakeup1，那么父进程调用wait就要等到子进程在调度线程被解锁时才能执行。

```c
// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
  if(!holding(&p->lock))
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    p->state = RUNNABLE;
  }
}
```

---

#### Kill

While exit allows a process to terminate itself, **kill** (kernel/proc.c:611) lets one process request that another terminate. It would be too complex for kill to directly destroy the victim process, since the victim might be executing on another CPU, perhaps in the middle of a sensitive sequence of updates to kernel data structures.

```c
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}
```

Thus **kill does very little: it just sets the victim’s p->killed and, if it is sleeping, wakes it up**.

Eventually the victim will enter or leave the kernel, at which point **code in `usertrap` will call `exit` if p->killed is set**.

- If the victim is running in user space, it will soon enter the kernel by making a system call or because the timer (or some other device) interrupts.

- If the victim process is in sleep, `kill`’s call to `wakeup` will cause the victim to return from sleep.

> kill并不能直接让一个进程直接结束，他只能通过调度的方式让killed进程在下一次被调度时被杀死。杀死的方式就是让他自己调用`exit()`退出。
>
> 下一次的调度可以发生在两个地方
>
> 1. 用户空间，timer将该进程从用户空间带入`usertrap`，然后进行kill
> 2. 内核空间，从sleep中苏醒，被sleep所在的for循环杀死（sleep总是处在for循环中，用来预备这种情况）
>
> ```c
> for (....) {
>     if (p->state == KILLED)
>         exit();
>     sleep();
> }
> ```

**This is potentially dangerous because the condition being waiting for may not be true.** <u>However, xv6 calls to sleep are always wrapped in a while loop that re-tests the condition after sleep returns. Some calls to sleep also test p->killed in the loop, and abandon the current activity if it is set.</u> This is only done when such abandonment would be correct. For example, the pipe read and write code returns if the killed flag is set; eventually the code will return back to trap, which will again check the flag and exit.

> sleep不在for循环中的例外

Some xv6 sleep loops do not check `p->killed` **because the code is in the middle of a multistep system call that should be atomic**. The `virtio driver `(kernel/`virtio_disk.c`:242) is an example: it does not check `p->killed` because a disk operation may be one of a set of writes that are all needed in order for the file system to be left in a correct state.

**A process that is killed while waiting for disk I/O won’t exit until it completes the current system call and `usertrap` sees the killed flag.**

### 7.9 Real world

#### Different scheduling policy

The xv6 scheduler implements a simple scheduling policy, which runs each process in turn. This policy is called **round robin**.

Real operating systems implement more sophisticated policies that, for example, **allow processes to have priorities**. The idea is that a runnable high-priority process will be preferred by the scheduler over a runnable low-priority process.

---

These policies can become complex quickly because there are often competing goals:

for example, the operating might also want to <u>guarantee fairness and high **throughput（吞吐量）**</u>. In addition, complex policies may lead to unintended interactions such as **priority inversion and convoys**.

- **Priority inversion** can happen when a low-priority and high-priority process share a lock, which when acquired by the low-priority process can prevent the high-priority process from making progress.
- **A long convoy(护航队) of waiting processes** can form when many high-priority processes are waiting for a low-priority process that acquires a shared lock; once a convoy has formed it can persist for long time. To avoid these kinds of problems additional mechanisms are necessary in sophisticated schedulers.

---

#### Different synchronization method

`Sleep` and `wakeup` are a simple and effective **synchronization method**, but there are many others.

The first challenge in all of them is to avoid the **“lost wakeups” problem** we saw at the beginning of the chapter.

> sleep的不同实现

The original Unix kernel’s sleep simply disabled interrupts, which sufficed(足够) because Unix ran on a single-CPU system. Because xv6 runs on multiprocessors, it adds an explicit lock to sleep. FreeBSD’s `msleep` takes the same approach. Plan 9’s `sleep` uses a callback function that runs with the scheduling lock held just before going to sleep; the function serves as a last-minute check of the sleep condition, to avoid lost wakeups. <u>The Linux kernel’s sleep uses an explicit process queue, called a wait queue, instead of a wait channel; the queue has its own internal lock.</u>

> wakeup的不同实现
>
> 一种被叫做conditional variable的数据结构

**Scanning** the entire process list in wakeup for processes with a matching `chan` is **inefficient**.

**A better solution is to replace the `chan` in both sleep and wakeup with a <u>`data structure`</u> that holds a list of processes sleeping on that structure, such as Linux’s wait queue.** Plan 9’s sleep and wakeup call that structure a rendezvous point or `Rendez`. Many thread libraries refer to the same structure as a **condition variable**; in that context, the operations sleep and wakeup are called wait and signal. <u>All of these mechanisms share the same flavor: the sleep condition is protected by some kind of lock dropped atomically during sleep</u>.

> xv6 wakeup 唤醒全部等待进程的问题
>
> 解决方案：signal和broadcast

The implementation of `wakeup` wakes up all processes that are waiting on a particular channel, and it might be the case that many processes are waiting for that particular channel. The operating system will schedule all these processes and **they will race to check the sleep condition**. Processes that behave in this way are sometimes called a **thundering herd**, and it is best avoided.

**Most condition variables have two primitives for wakeup**: **`signal`**, which wakes up one process, and **`broadcast`**, which wakes up all waiting processes.

---

**Semaphores** are often used for synchronization. The count typically corresponds to something like the number of bytes available in a pipe buffer or the number of zombie children that a process has. Using an explicit count as part of the abstraction avoids the “lost wakeup” problem: there is an explicit count of the number of wakeups that have occurred. The count also avoids the spurious wakeup and thundering herd problems.

---

#### Terminating Process

Terminating processes and cleaning them up introduces much complexity in xv6. In most operating systems it is even more complex, because, for example, the victim process may be deep inside the kernel sleeping, and unwinding（展开） its stack requires much careful programming. Many operating systems unwind the stack using explicit mechanisms for exception handling, such as `longjmp`.

Furthermore, there are other events that can cause a sleeping process to be woken up, even though the event it is waiting for has not happened yet. For example, when a Unix process is sleeping, another process may send a signal to it. In this case, the process will return from the interrupted system call with the value -1 and with the error code set to EINTR. The application can check for these values and decide what to do. Xv6 doesn’t support signals and this complexity doesn’t arise.

#### Kill Problem

Xv6’s support for kill is not entirely satisfactory: there are sleep loops which probably should check for p->killed. A related problem is that, **even for sleep loops that check p->killed, there is a race between sleep and kill**; the latter may set p->killed and try to wake up the victim just after the victim’s loop checks p->killed but before it calls sleep. If this problem occurs, the victim won’t notice the p->killed until the condition it is waiting for occurs. This may be quite a bit later (e.g., when the `virtio` driver returns a disk block that the victim is waiting for) or never (e.g., if the victim is waiting from input from the console, but the user doesn’t type any input).

---

A real operating system would find free proc structures with an explicit free list in constant time instead of the linear-time search in `allocproc`; xv6 uses the linear scan for simplicity.

## Chapter 8 File system

The purpose of a file system is to organize and store data. File systems typically support sharing of data among users and applications, as well as persistence so that data is still available after a reboot.

The xv6 file system provides Unix-like files, directories, and pathnames (see Chapter 1), and stores its data on a `virtio` disk for persistence (see Chapter 4). The file system addresses several **challenges**:

- The file system needs **on-disk data structures** to represent the tree of named directories and files, to record the identities of the blocks that hold each file’s content, and to record which areas of the disk are free.

- The file system must support **crash recovery**. That is, if a crash (e.g., power failure) occurs, the file system must still work correctly after a restart. The risk is that a crash might interrupt a sequence of updates and leave inconsistent on-disk data structures (e.g., a block that is both used in a file and marked free).

- **Different processes** may **operate** on the file system at the **same time**, so the file-system code must coordinate to maintain invariants.

- Accessing a disk is orders of magnitude slower than accessing memory, so the file system must maintain an **in-memory cache of popular blocks**.

The rest of this chapter explains how xv6 addresses these challenges.

### 8.1 Overview

The xv6 file system implementation is organized in **seven layers**, shown in Figure 8.1.

![image-20220618234931008](assets/Operating Systems.assets/image-20220618234931008.png)

- The **disk layer** reads and writes blocks on an `virtio` <u>hard drive</u>.

- The **buffer cache layer** <u>caches disk blocks and synchronizes access to them</u>, making sure that only one kernel process at a time can modify the data stored in any particular block.

- The **logging layer** allows <u>higher layers to wrap updates to several blocks in a transaction</u>, and ensures that the blocks are updated atomically in the face of crashes (i.e., all of them are updated or none).

- The **`inode` layer** <u>provides individual files</u>, each represented as an `inode` with a unique`i-number` and some blocks holding the file’s data.

- The **directory layer** implements each <u>directory as a special kind of `inode` whose content is a sequence of directory entries</u>, each of which contains a file’s name and `i-number`.

- The **pathname layer** provides <u>hierarchical path names</u> like `/usr/rtm/xv6/fs.c`, and resolves them with recursive lookup.

- The **file descriptor layer** <u>abstracts many Unix resources</u> (e.g., pipes, devices, files, etc.) using the file system interface, simplifying the lives of application programmers.

---

The file system must have a plan for **where it stores `inodes` and content blocks on the disk**. To do so, xv6 divides the disk into several sections, as Figure 8.2 shows.

![image-20220618235633337](assets/Operating Systems.assets/image-20220618235633337.png)

- The file system does not use **block 0** (it holds the **boot sector**).

- **Block 1** is called the **superblock**; it contains **metadata about the file system** (the file system size in blocks, the number of data blocks, the number of `inodes`, and the number of blocks in the log).

- Blocks starting at 2 hold the **log**.

- After the log are the **`inodes`,** with multiple `inodes` per block.

- After those come **bitmap** blocks <u>tracking which data blocks are in use</u>.

- The remaining blocks are **data blocks**; each is either marked free in the bitmap block, or holds content for a file or directory.

The superblock is filled in by a separate program, called `mkfs`, which builds an initial file system.

> super block是对整个文件系统的描述。我们在之后进行定位`inode`等操作的时候，就需要super block来告诉我们具体的起始位置在哪里。
>
> ```c
> #define ROOTINO  1   // root i-number
> #define BSIZE 1024  // block size
> ```
>
> 所有的文件和文件夹都是由`inode`数据结构来表示的，我们定位`inode`主要是通过它的编号（例如x）作为偏移量，在上图所示的结构图中定位他所处的Block。具体的计算方式是：`sperblock.inodestart + x * inode_size / BSIZE`。在`xv6`中，一个`inode`的大小是64KB，一个Block的大小是1024KB。在磁盘上，通常用Sector作为磁盘的最小计量单位，1 sector = 512KB。

```c
// Disk layout:
// [ boot block | super block | log | inode blocks |
//                                          free bit map | data blocks]
//
// mkfs computes the super block and builds an initial file system. The
// super block describes the disk layout:
struct superblock {
  uint magic;        // Must be FSMAGIC
  uint size;         // Size of file system image (blocks)
  uint nblocks;      // Number of data blocks
  uint ninodes;      // Number of inodes.
  uint nlog;         // Number of log blocks
  uint logstart;     // Block number of first log block
  uint inodestart;   // Block number of first inode block
  uint bmapstart;    // Block number of first free map block
};
```

### 8.2 Buffer cache layer

> Buffer cache是对整个文件系统的缓存，在其之上的层可以通过它更快的和disk进行交互。

The buffer cache has two jobs:

- (1) **synchronize access to disk blocks** to ensure that

  - only one copy of a block is in memory and that

  - only one kernel thread at a time uses that copy;

- (2) **cache popular blocks** so that they don’t need to be re-read from the slow disk. The code is in `bio.c`.

---

The main interface exported by the buffer cache consists of `bread` and `bwrite`;

- the former**(`bread`)** <u>obtains a `buf` containing a copy of a block</u> which can be read or modified <u>in memory,</u> and

- the latter**(`bwriter`)** writes a <u>modified buffer to the appropriate block</u> on the disk.

- A kernel thread must <u>release a buffer by calling</u> **`brelse`** when it is done with it. The buffer cache uses a **per-buffer sleep-lock** to ensure that only one thread at a time uses each buffer (and thus each disk block); bread returns a locked buffer, and `brelse` releases the lock.

---

> 当上层要使用没有缓存在buffer上的disk内容时，使用LRU算法将最近最少使用的buffer中的内容替换为上层需要的内容。

Let’s return to the buffer cache. **The buffer cache has a <u>fixed number of buffers</u> to hold disk blocks**, which means that if the file system asks for a block that is not already in the cache, <u>the buffer cache must recycle a buffer currently holding some other block</u>. The buffer cache recycles the least recently used buffer for the new block. The assumption is that the least recently used buffer is the one least likely to be used again soon.

### 8.3 Code: Buffer cache

#### Buffer Cache Data Structure

The **buffer cache** is a **doubly-linked list of buffers**. The function `binit`, called by main (kernel/- main.c:27), initializes the list with the NBUF buffers in the static array `buf` (kernel/bio.c:43-52). **All other access to the buffer cache refer to the linked list via `bcache.head`, not the `buf` array.**

```c
struct {
  struct spinlock lock;
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head;
} bcache;
```

```c
void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
```

#### `Buf` Data Structure

> 一个buffer中只能存放一个block中的内容，也就是1024B大小的内容。

A buffer has two state fields associated with it. The field valid indicates that the buffer contains a copy of the block. The field disk indicates that the buffer content has been handed to the disk, which may change the buffer (e.g., write data from the disk into data).

```c
struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  uint dev;
  uint blockno;
  struct sleeplock lock;
  uint refcnt;
  struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE];
};
```

#### `Bread`

**`Bread`** (kernel/bio.c:93) calls `bget` to <u>get a buffer for the given sector</u> (kernel/bio.c:97). If the buffer needs to be read from disk, `bread` calls `virtio_disk_rw` to do that before returning the buffer.

```c
// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
```

#### `Sleep-Lock`

> 从下一小节的代码中可以知道，`Sleep-Lock`是用来保证一个buffer cache的唯一读写权限的。每个buffer cache都有一块自己的`Sleep-Lock`。
>
> <u>既然sleep lock是基于spinlock实现的，为什么对于block cache，我们使用的是sleep lock而不是spinlock？</u>
>
> 对于**spinlock**有很多限制，其中之一是**加锁时中断必须要关闭**。
>
> 所以如果使用spinlock的话，当我们对block cache做操作的时候需要持有锁，**那么我们就永远也不能从磁盘收到数据**。或许另一个CPU核可以收到中断并读到磁盘数据，但是如果我们只有一个CPU核的话，我们就永远也读不到数据了。
>
> **出于同样的原因，也不能在持有spinlock的时候进入sleep状态**。
>
> 所以这里我们使用sleep lock。**sleep lock的优势就是**，
>
> - **我们可以在持有锁的时候不关闭中断（持有的是sleep lock而不是他里边的spin lock）**。我们可以在磁盘操作的过程中持有锁，我们也可以长时间持有锁。
> - **当我们在等待sleep lock的时候，我们并没有让CPU一直空转**，我们通过sleep将CPU出让出去了。

> 仔细说说这一块的代码吧，sleep lock里边有一个spin lock，这个spinlock保证了一次只有一个process可以获得对这个buffer cache的访问权限。然而，如上文所说，spin lock导致中断被停止，所以读写就无法进行。于是就有了下边这个巧妙的设计。
>
> 对于第一个拿到spin lock的进程，他不会执行while loop，而是直接给sleep lock中的属性locked置为1（表示上锁），最后释放掉spin lock，从而使得读写操作可以进行。
>
> 对于其他想要读写这一块buffer cache的进程来说，他们能获得spin lock，然而，他们会进入while循环，因为sleep lock中的locked为1。此时，这一块buffer cache被其他进程占有，而且不能禁止中断，所以while循环中又调用了sleep函数将这个进程的spinlock释放，并且让出CPU供其他进程执行。

```c
// Long-term locks for processes
struct sleeplock {
  uint locked;       // Is the lock held?
  struct spinlock lk; // spinlock protecting this sleep lock

  // For debugging:
  char *name;        // Name of lock.
  int pid;           // Process holding lock
};

void
acquiresleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  while (lk->locked) {
    sleep(lk, &lk->lk);
  }
  lk->locked = 1;
  lk->pid = myproc()->pid;
  release(&lk->lk);
}

void
releasesleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  lk->locked = 0;
  lk->pid = 0;
  wakeup(lk);
  release(&lk->lk);
}
```

#### `Bget`

**`Bget`** (kernel/bio.c:59) scans the buffer list for a buffer with the given device and sector numbers (kernel/bio.c:65-73). If there is such a buffer, `bget` acquires the **sleep-lock** for the buffer. `Bget` then returns the locked buffer.

> 这里使用了睡眠锁，睡眠锁的本质是旋转锁，但是他并不会一直while循环占用CPU。
>
> 这里使用睡眠锁的目的其实就是为了在进行IO的过程中，把CPU让渡出去，而不是让当前进程在CPU上一直等待IO。

```c
// Long-term locks for processes
struct sleeplock {
  uint locked;       // Is the lock held?
  struct spinlock lk; // spinlock protecting this sleep lock

  // For debugging:
  char *name;        // Name of lock.
  int pid;           // Process holding lock
};

void
acquiresleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  while (lk->locked) {
    sleep(lk, &lk->lk);
  }
  lk->locked = 1;
  lk->pid = myproc()->pid;
  release(&lk->lk);
}
```

If there is no cached buffer for the given sector, `bget` must make one, possibly reusing a buffer that held a different sector. It scans the buffer list a second time, looking for a buffer that is not in use (`b->refcnt = 0`); any such buffer can be used.

`Bget` edits the buffer metadata to record the new device and sector number and acquires its sleep-lock. Note that the assignment `b->valid = 0` ensures that `bread` will read the block data from disk rather than incorrectly using the buffer’s previous contents.

```c
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  acquire(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}
```

It is important that

- there is at most one cached buffer per disk sector,

- to ensure that readers see writes,

- and because the file system uses locks on buffers for synchronization.

`Bget` ensures this invariant by holding the `bache.lock` continuously from the first loop’s check of whether the block is cached through the second loop’s declaration that the block is now cached (by setting dev, `blockno`, and `refcnt`). This causes the check for a block’s presence and (if not present) the designation of a buffer to hold the block to be atomic.

> `bache.lock`贯穿了对buffer的属性的修改，也就是说每次只有一个进程可以对整个buffer cache进行操作。从而，保证了上述的三点要求。

It is safe for `bget` to acquire the buffer’s sleep-lock outside of the `bcache.lock` critical section, since the non-zero `b->refcnt` prevents the buffer from being re-used for a different disk block. The sleep-lock protects reads and writes of the block’s buffered content, while the `bcache.lock` protects information about which blocks are cached.

> 可以看到sleep lock是在`bache.lock`被释放后才去获得的，这会不会导致当前的buffer被当作可替换的buffer而被使用，从而进一步导致当前进程的buffer里的内容不是进程一开始想要的内容呢？并不会这样，因为当前进程使得buffer的`refcnt++`，也就是当前buffer必然大于等于一，所以不存在被释放的风险。
>
> `bache.lock`保证了每个缓存属性的准确性（例如`refcnt, blockno....`），sleep lock被用来保证buffer中内容(`char[BSIZE] data`)不会被错误的修改。

If all the buffers are busy, then too many processes are simultaneously executing file system calls; `bget` panics. A more graceful response might be to sleep until a buffer became free, though there would then be a possibility of deadlock.

---

> 每个buffer被返回给上层时，他都拿着自己的sleep lock，只有上层所处的进程可以对buffer里的内容进行操作。若buffer中的内容被改变了，那么上层必须调用`bwrite`来将buffer中的内容写回disk。

Once `bread` has read the disk (if needed) and returned the buffer to its caller, the caller has exclusive use of the buffer and can read or write the data bytes. <u>If the caller does modify the buffer, it must call `bwrite` to write the changed data to disk before releasing the buffer</u>.

#### `Bwrite`

**`Bwrite`** (kernel/bio.c:107) calls `virtio_disk_rw` to talk to the disk hardware.

```c
// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}
```

---

#### `Brelse`

<u>When the caller is done with a buffer, it must call `brelse` to release it.</u> (The name `brelse`, a shortening of b-release, is cryptic but worth learning: it originated in Unix and is used in BSD, Linux, and Solaris too.)

> 在buffer被返回给上层之后，当前的进程始终拥有着对buffer中内容的唯一使用权，当使用完毕后，就要释放保证这一切的sleep lock。
>
> 接着，如果当前buffer的`refcnt==0`，那就证明当前的这个buffer是最近刚使用完的，我们把它放在链表的头部。由此推断，链表的尾部就是很久以前就使用完的buffer。

**`Brelse`** (kernel/bio.c:117) **releases the sleep-lock** and **moves the buffer to the front of the linked list** (kernel/bio.c:128-133). Moving the buffer causes the list to be ordered by how recently the buffers were used (meaning released): **the first buffer in the list is the most recently used, and the last is the least recently used**.

> 这时反观`bget`, 可以发现在寻找buffer中是否存有上层要的内容时，是从前往后扫描，这样遇到最近使用过的几率大。在寻找要被free并替代的buffer时，是从后向前扫描，这样遇到LRU的概率更大一些。

The two loops in `bget` take advantage of this: the scan for an existing buffer must process the entire list in the worst case, but checking the most recently used buffers first (starting at `bcache.head` and following next pointers) will reduce scan time when there is good locality of reference. The scan to pick a buffer to reuse picks the least recently used buffer by scanning backward (following `prev` pointers).

```c
// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  acquire(&bcache.lock);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }

  release(&bcache.lock);
}
```

### 8.7 Code: Block allocator

> 8.3讲的的都是Memory里存储的缓存，但我们在建立文件的时候，是要在磁盘上给每个文件分配一些地方的。操作系统将磁盘抽象成了许多的BLOCK, 并把其中一个BLOCK用作bitmap用来记录哪些BLOCK已经被分配了。
>
> bitmap是一个BLOCK SIZE大小的块，也就是1024B，他的每一位对应着一个块是否被使用。

File and directory content is stored in disk blocks, which must be allocated from a free pool. xv6’s block allocator maintains a free **bitmap** on disk, with one bit per block.

- A zero bit indicates that the corresponding block is free;

- a one bit indicates that it is in use.

The program **`mkfs` sets the bits corresponding to the boot sector, superblock, log blocks, `inode` blocks, and bitmap blocks.**

---

The block allocator provides two functions:

#### `Balloc`

**`balloc`** allocates a new disk block, and **`bfree`** frees a block.

> 先来看看代码中的一些名词的意思
>
> `sb.size`: super block中记载着系统的描述信息，size指的是总的block数量
>
> `BPB`: Bitmap bits per block (BSIZE\*8) = 1024 x 8bits
>
> `BBLOCK(b, sb) ((b)/BPB + sb.bmapstart)` : // Block of free map containing bit for block b

The loop in `balloc` at (kernel/fs.c:71) considers every block, starting at block 0 up to `sb.size`, the number of blocks in the file system. It looks for a block whose bitmap bit is zero, indicating that it is free. If `balloc` finds such a block, it updates the bitmap and returns the block. For efficiency, the loop is split into two pieces.

The outer loop reads each block of bitmap bits.

The inner loop checks all BPB bits in a single bitmap block.

**The race that might occur if two processes try to allocate a block at the same time is prevented by the fact that the buffer cache only lets one process use any one bitmap block at a time.**

![image-20220716230656087](assets/Operating Systems.assets/image-20220716230656087.png)

> `Balloc`在外层循环遍历每一个块，代码中b所代表的就是每个块的起始地址
>
> `bp`在这里应该指向的是bitmap的缓存，
>
> 内循环遍历bitmap中的每一个位，找到一个空位后，返回`b + bi`, 也就是BLOCK的序号（按照图中的设计所有的编号。例如46）
>
> 这里还存有许多不连贯的地方。我的解读对吗？为什么要设立两个for循环呢？内存里的数据是怎样被写回磁盘的呢？`bread`中的`blockno`究竟是以bit为单位还是以图中的序号为单位？`balloc`到底返回了什么？
>
> 这里目前无法理清，但**这段代码所做的事是很明确的，在bitmap中找到一个空闲的block，然后将这个block以某种形式返回**。
>
> 这里需要后续的补充！！！！！！！！！！！！！！

```c
// Allocate a zeroed disk block.`
static uint
balloc(uint dev)
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
      m = 1 << (bi % 8);
      if((bp->data[bi/8] & m) == 0){  // Is block free?
        bp->data[bi/8] |= m;  // Mark block in use.
        log_write(bp);
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
```

#### `Bfree`

`Bfree` (kernel/fs.c:90) finds the right bitmap block and clears the right bit. Again the exclusive use implied by `bread` and `brelse` avoids the need for explicit locking.

```c
// Free a disk block.
static void
bfree(int dev, uint b)
{
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
  bi = b % BPB;
  m = 1 << (bi % 8);
  if((bp->data[bi/8] & m) == 0)
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
  log_write(bp);
  brelse(bp);
}
```

### 8.8 `Inode` layer

> `Inode`是对BLOCK的再一次抽象，我们不可能仅仅把文件存储在一个BLOCK里边，`Inode`就是一个BLOCK的集合，让我们可以存储更大的文件。

The term `inode` can have one of **two related meanings**.

- It might refer to the **on-disk data structure** containing a file’s size and list of data block numbers. Or

- ` “inode”` might refer to an **`in-memory inode`,** which contains a copy of the on-disk `inode` as well as extra information needed within the kernel.

#### **on-disk `inodes`**

<img src="assets/Operating Systems.assets/image-20220716230656087.png" alt="image-20220716230656087" style="zoom:50%;" />

> **on-disk `inodes`** 存储在BLOCK32 --> BLOCK44之间，每个**on-disk `inodes`** 都有着固定的大小64B，从而，我们可以知道Xv6操作系统能有多少**on-disk `inodes`** ，换句话说就是能创建多少个文件。

The **on-disk `inodes`** are packed into a **contiguous area of disk called the `inode blocks`.** Every `inode` is the **same size**, so it is easy, given a number n, to find the `nth inode` on the disk. In fact, this number n, called the**` inode number` or `i-number`,** is how `inodes` are **identified** in the implementation.

---

The on-disk `inode` is defined by a struct `dinode` (kernel/fs.h:32).

- The **type** field distinguishes between **files, directories, and special files (devices)**. A **type of zero indicates that an on disk`inode` is free**.

- The **`nlink`** field counts the number of directory entries that refer to this `inode`, in order to recognize when the on-disk `inode` and its data blocks should be freed.

- The **size** field records the number of bytes of content in the file.

- The **`addrs`** array records the **block numbers of the disk blocks holding the file’s content**.

```c
// On-disk inode structure
struct dinode {
  short type;           // File type
  short major;          // Major device number (T_DEVICE only)
  short minor;          // Minor device number (T_DEVICE only)
  short nlink;          // Number of links to inode in file system
  uint size;            // Size of file (bytes)
  uint addrs[NDIRECT+1];   // Data block addresses
};
```

---

#### in-memory `inode`

> 内存中的`inodes`多了一些新特性，只有C指针指向的 `inodes`才有资格被加载到内存中。

The kernel keeps the set of active `inodes` in memory; **struct `inode` (kernel/file.h:17) is the in-memory copy of a struct `dinode` on disk**.

The kernel stores an `inode` in memory only if there are C pointers referring to that `inode`.

The **ref** field counts the **number of C pointers** referring to the in-memory `inode`, and the kernel discards the `inode` from memory if the reference count drops to zero.

```c
// in-memory copy of an inode
struct inode {
  uint dev;           // Device number
  uint inum;          // Inode number
  int ref;            // Reference count
  struct sleeplock lock; // protects everything below here
  int valid;          // inode has been read from disk?

  short type;         // copy of disk inode
  short major;
  short minor;
  short nlink;
  uint size;
  uint addrs[NDIRECT+1];
};
```

The **`iget` and `iput`** functions **acquire and release pointers** to an `inode`, modifying the reference count. Pointers to an `inode` can come from file descriptors, current working directories, and transient kernel code such as `exec`.

---

#### Lock in `Inode`

> 因为`inodes`在内核中也会被缓存，所以和buffer cache很相似，`inodes`也有一把大锁用来保证`inodes`的原子性（内存中不会有重复的`inodes`，内核对`inodes`的引用计数也是正确的）。每个`inodes`里边也有一把小锁（睡眠锁），用来保证该文件的独享访问权限。

There are **four lock or lock-like mechanisms** in xv6’s `inode` code.

**`icache.lock`** protects the invariant that an `inode` is present in the cache at most once, and the invariant that a cached `inode’s` ref field counts the number of in-memory pointers to the cached `inode`.

Each in-memory `inode` has a lock field containing a **sleep-lock**, which ensures exclusive access to the `inode’s` fields (such as file length) as well as to the `inode’s` file or directory content blocks.

> 一个在内存中的`inode`, 如果他的ref（指向`inode`的C指针的数量）大于0，那么内核就要在内存中维护这个`inode`并且不会重用这个`inode`的cache entry。
>
> `nlink`记录的是指向这个文件的文件夹的个数，只有`nlink`为0的时候，系统才会free这个`inode`。

An `inode’s` ref, if it is greater than zero, causes the system to maintain the `inode` in the cache, and not re-use the cache entry for a different `inode`. Finally, each `inode` contains a `nlink` field (on disk and copied in memory if it is cached) that counts the number of directory entries that refer to a file; xv6 won’t free an `inode` if its link count is greater than zero.

---

#### Life Cycle of `inode`

> 我们获取到的内存中的`inodes`如下特性。
>
> 每个进程都可以指向同一个`inodes`，这种设计有点读写锁的意思，我们在用文件系统的时候，会经常在相同的路径下找不同的文件，如果设置锁的话，那么如果我们打开了路径a/b/c，那么其他任何进程都无法再访问这个路径了。
>
> 当然，在对`inodes`进行写的操作时，例如：加载disk的内容到`inodes`以及写入`inodes`，只有一个进程可以独享这个资源。

A struct `inode` pointer returned by `iget()` is guaranteed to be valid until the corresponding call to `iput()`; the `inode` won’t be deleted, and the memory referred to by the pointer won’t be re-used for a different `inode`.

`iget()` provides **non-exclusive access to an `inode`**, so that **there can be many pointers to the same `inode`.** Many parts of the file-system code depend on this behavior of `iget()`, both to hold long-term references to `inodes` (as open files and current directories) and to prevent races while avoiding deadlock in code that manipulates multiple `inodes` (such as pathname lookup).

The struct `inode` that `iget` returns may not have any useful content. In order to ensure it holds a copy of the `on-disk inode`, code must call `ilock`. This locks the `inode` (so that no other process can `ilock` it) and reads the `inode` from the disk, if it has not already been read. `iunlock `releases the lock on the `inode`. Separating acquisition of `inode` pointers from locking helps avoid deadlock in some situations, for example during directory lookup. Multiple processes can hold a C pointer to an `inode` returned by `iget`, but **only one process can lock the `inode` at a time.**

---

> 内存中的`inodes`目的并不在于缓存，而在于同步不同进程对资源的请求。
>
> `inodes`缓存的另一大特点是写完就要同步到disk

The `inode` cache only caches `inodes` to which kernel code or data structures hold C pointers. **Its main job is really synchronizing access by multiple processes**; caching is secondary. If an `inode` is used frequently, the buffer cache will probably keep it in memory if it isn’t kept by the `inode` cache. The `inode` cache is **write-through**, which means that **code that modifies a cached `inode` must immediately write it to disk with `iupdate`.**

### 8.9 Code: `Inodes`

#### `ialloc`

> `ialloc` 就是创建文件实现，它的原理很简单，把disk上`inodes`那一段BLOCK加载到buffer cache中，然后在其中找到一个空闲的`inodes`
>
> 接着就改变`inodes`的属性type表明它已经被占用
>
> 最后用`iget()`方法返`inodes`在内存中的缓存

> 这里，并没有用到锁，因为buffer cache保证了每次只有一个process可以修改一个block

To allocate a new `inode` (for example, when creating a file), xv6 calls `ialloc` (kernel/fs.c:196). `Ialloc` is similar to `balloc`:

- it loops over the `inode` structures on the disk, one block at a time, **looking for one that is marked free.**

- When it finds one, it **claims it by writing the new type to the disk** and then

- **returns an entry from the `inode` cache** with the tail call to `iget` (kernel/fs.c:210).

The correct operation of `ialloc` depends on the fact that only one process at a time can be holding a reference to `bp`: `ialloc` can be sure that some other process does not simultaneously see that the `inode` is available and try to claim it.

```c
// Allocate an inode on device dev.
// Mark it as allocated by  giving it type type.
// Returns an unlocked but allocated and referenced inode.
struct inode*
ialloc(uint dev, short type)
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
    bp = bread(dev, IBLOCK(inum, sb));
    dip = (struct dinode*)bp->data + inum%IPB;
    if(dip->type == 0){  // a free inode
      memset(dip, 0, sizeof(*dip));
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
```

#### `Iget`

> 书接上文，上一步，我们在`inode` BLOCK中拿到了一个新的`inode`，我们下一步要做的就是把这个新的`inode`放进`inode` 缓存中。（Xv6维护了两个缓存，一个是BLOCK的缓存，另一个是`inode`的缓存，具体查看8.3，8.7)。
>
> 这里其实逻辑也很简单，如果有的话就返回，没有的话就找一个有空闲位置的缓存用于存放这个新的`inode`。

`Iget` (kernel/fs.c:243) looks through the `inode` cache for an active entry (`ip->ref > 0`) with the desired device and `inode` number. If it finds one, it returns a new reference to that `inode` (kernel/fs.c:252-256). **As `iget` scans, it records the position of the first empty slot (kernel/fs.c:257- 258), which it uses if it needs to allocate a cache entry.**

```c
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
  struct inode *ip, *empty;

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
      ip->ref++;
      release(&icache.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
  ip->inum = inum;
  ip->ref = 1;
  ip->valid = 0;
  release(&icache.lock);

  return ip;
}
```

#### `ilock`

> 在Buffer Cache中可以得知，遇到有缓存的问题，我们就要想办法解决多线程的问题。这一节的前一部分，我们知道，`inode` cache外边有把大锁，每个`inode`缓存中有把小锁。这个`ilock`就是那个小锁，他的本质是一个sleep lock。
>
> `ilock`的工作内容是把disk里`dinode`的内容读到缓存中的`inode`里边去。
>
> 目前还不是很明白他的应用场景在哪里
>
> 后续补充！！！！！！！！！！！！！！！！

Code must lock the `inode` using `ilock` before reading or writing its metadata or content.

`ilock` (kernel/fs.c:289) uses a `sleep-lock` for this purpose.

Once `ilock` has exclusive access to the `inode`, it reads the `inode` from disk (more likely, the buffer cache) if needed. The function `iunlock` (kernel/fs.c:317) releases the sleep-lock, which may cause any processes sleeping to be woken up.

```c
// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquiresleep(&ip->lock);

  if(ip->valid == 0){
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    ip->type = dip->type;
    ip->major = dip->major;
    ip->minor = dip->minor;
    ip->nlink = dip->nlink;
    ip->size = dip->size;
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    brelse(bp);
    ip->valid = 1;
    if(ip->type == 0)
      panic("ilock: no type");
  }
}
```

---

#### `Iput`

> `Iput`涉及的是`inode`缓存的释放，若是没有C指针指向它，那缓存就没有必要了；
>
> 若是links（文件里也没有这个`inode`了）也等于0，那么对应的BLOCK也就要被清理了。

`Iput` (kernel/fs.c:333) releases a C pointer to an `inode` by decrementing the reference count (kernel/fs.c:356). **If this is the last reference, the `inode’s `slot in the `inode` cache is now free and can be re-used for a different `inode`.**

If `iput` sees that there are no C pointer references to an `inode` and that **the `inode` has no links to it (occurs in no directory), then the `inode` and its data blocks must be freed**. `Iput` calls `itrunc` to truncate the file to zero bytes, freeing the data blocks; sets the `inode` type to 0 (unallocated); and writes the `inode` to disk (kernel/fs.c:338).

```c
// Drop a reference to an in-memory inode.
// If that was the last reference, the inode cache entry can
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
  acquire(&icache.lock);

  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    // inode has no links and no other references: truncate and free.

    // ip->ref == 1 means no other process can have ip locked,
    // so this acquiresleep() won't block (or deadlock).
    acquiresleep(&ip->lock);

    release(&icache.lock);

    itrunc(ip);
    ip->type = 0;
    iupdate(ip);
    ip->valid = 0;

    releasesleep(&ip->lock);

    acquire(&icache.lock);
  }

  ip->ref--;
  release(&icache.lock);
}
```

The locking protocol in `iput` in the case in which it frees the `inode` deserves a closer look.

> 需要理清这里的锁之间的关系，主要是第二段
>
> 这里涉及对sleep lock的理解
>
> 之后需要补充！！！！！！！！！！！！！！！！

One danger is that a concurrent thread might be waiting in `ilock` to use this `inode` (e.g., to read a file or list a directory), and won’t be prepared to find that the `inode` is not longer allocated. This can’t happen because there is no way for a system call to get a pointer to a cached `inode` if it has no links to it and` ip->ref` is one. That one reference is the reference owned by the thread calling `iput`. It’s true that `iput` checks that the reference count is one outside of its `icache.lock` critical section, but at that point the link count is known to be zero, so no thread will try to acquire a new reference.

The other main danger is that a concurrent call to `ialloc` might choose the same `inode` that `iput` is freeing. This can only happen after the `iupdate` writes the disk so that the `inode` has type zero. This race is benign; the allocating thread will politely wait to acquire the `inode’s` sleep-lock before reading or writing the `inode`, at which point `iput` is done with it.

---

> 这里引出一个有意思的点，文件系统的system call可能都会涉及到磁盘的写入，即使是一个读进程。
>
> 可以想象，一个进程完成了文件的写入，但这还停留在缓存的层面。因为此时还有一个进程在读这个文件，写入的代码还是无法触发，当我们关闭了读进程之后，`iput`进入了回收模式，这才把写进程写完的内存写入了disk上。

**`iput()` can write to the disk.** This means that any system call that uses the file system may write the disk, because the system call may be the last one having a reference to the file. **Even calls like `read()` that appear to be read-only, may end up calling `iput()`**. This, in turn, means that even read-only system calls must be wrapped in transactions if they use the file system.

#### `iput()` and `crashes`

> 这里引出了一个有趣的问题，`iput()`代码在`inode` link等于0时并没有选择去吧disk中的内容删除，而是选择继续让进程对缓存中的内容进行读写。
>
> 这样会引发一个问题，若文件系统在我们把这些内容彻底写入disk之前出现了crash，那么这个文件会被认为是存在于disk上的（`inode`内容没有被清零），但是事实上文件夹中已经没有这个文件了。
>
> Xv6并没有对这一问题作出处理，这也就意味着，会出现disk存储的泄露。

There is a challenging interaction between `iput()` and `crashes`. **`iput()` doesn’t truncate a file immediately when the link count for the file drops to zero**, because some process might still hold a reference to the `inode` in memory: a process might still be reading and writing to the file, because it successfully opened it.

But, if a crash happens before the last process closes the file descriptor for the file, then the file will be marked allocated on disk but no directory entry will point to it.

File systems handle this case in one of **two ways.**

- The simple solution is that on recovery, after reboot, the file system scans the whole file system for files that are marked allocated, but have no directory entry pointing to them. If any such file exists, then it can free those files.

- The second solution doesn’t require scanning the file system. In this solution, the file system records on disk (e.g., in the super block) the `inode inumber` of a file <u>whose link count drops to zero but whose reference count isn’t zero</u>. If the file system removes the file when its reference counts reaches 0, then it updates the on-disk list by removing that `inode` from the list. On recovery, the file system frees any file in the list.

Xv6 implements neither solution, which means that `inodes` may be marked allocated on disk, even though they are not in use anymore. This means that over time xv6 runs the risk that it may run out of disk space.

### 8.10 Code: `Inode` content

```c
// On-disk inode structure
struct dinode {
  short type;           // File type
  short major;          // Major device number (T_DEVICE only)
  short minor;          // Minor device number (T_DEVICE only)
  short nlink;          // Number of links to inode in file system
  uint size;            // Size of file (bytes)
  uint addrs[NDIRECT+1];   // Data block addresses
};
```

> 上一节讲了`inode`在哪里被存储着，如何使用和销毁，但在8.9节的开篇，我就提到了，`inode`的主要目的是把BLOCK打包起来，这块就是文件的核心了。
>
> 下边的图也说得很清晰了，前12个地址都对应着一个BLOCK
>
> 第13个地址设计了一个二级索引，也就是说这个BLOCK里又存储了许多的地址，BLOCK的大小是1024B， 一个地址的大小是4B，从而，这个二级索引让整个`inode`又多了256个BLOCK。

The on-disk `inode` structure, struct `dinode`, contains a size and an array of block numbers (see Figure 8.3). The `inode` data is found in the blocks listed in the `dinode` ’s `addrs` array.

- The first `NDIRECT` blocks of data are listed in the first `NDIRECT` entries in the array; these blocks are called **direct blocks**.

- The next `NINDIRECT` blocks of data are listed not in the `inode` but in a data block called the indirect block. The last entry in the `addrs` array gives the address of the indirect block.

Thus **the first 12 kB ( NDIRECT x BSIZE) bytes of a file can be loaded from blocks listed in the `inode`**, while **the next 256 kB ( NINDIRECT x BSIZE) bytes can only be loaded after consulting the indirect block.**

![image-20220621002733864](assets/Operating Systems.assets/image-20220621002733864.png)

This is a good on-disk representation but a complex one for clients. The function `bmap` manages the representation so that higher-level routines such as `readi` and`writei`, which we will see shortly. `Bmap` returns the disk block number of the `bn’th` data block for the `inode ip`. If `ip` does not have such a block yet, `bmap` allocates one.

> 这里就把文件存储的方式说明白了，但是不得不承认的是，让用户面对着这样的数据结构去操作文件，确实是很困难的。所以这就引出了下边的函数。

#### `Bmap`

> `Bmap`的会接受一个BLOCK的序号，当然这里的序号是`inode`给真实的BLOCK所编的序号。
>
> 然后，根据这个序号，`Bmap`会按照上述的数据结构去找到对应的BLOCK，如果没有就会调用`balloc`分配一个。
>
> 最后，`Bmap`会把找到的BLOCK序号返回(这里的序号是OS抽象出的磁盘的序号)。

The function `bmap` (kernel/fs.c:378) begins by picking off the easy case: the first NDIRECT blocks are listed in the `inode` itself (kernel/fs.c:383-387). The next NINDIRECT blocks are listed in the indirect block at `ip->addrs[NDIRECT]`. `Bmap` reads the indirect block (kernel/fs.c:394) and then reads a block number from the right position within the block (kernel/fs.c:395). If the block number exceeds `NDIRECT+NINDIRECT`, `bmap` panics; `writei` contains the check that prevents this from happening (kernel/fs.c:490).

```c
// Inode content
//
// The content (data) associated with each inode is stored
// in blocks on the disk. The first NDIRECT block numbers
// are listed in ip->addrs[].  The next NINDIRECT blocks are
// listed in block ip->addrs[NDIRECT].

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;

  if(bn < NINDIRECT){
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    a = (uint*)bp->data;
    if((addr = a[bn]) == 0){
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }

  panic("bmap: out of range");
}
```

**`Bmap` allocates blocks as needed**. An `ip->addrs[]` or indirect entry of zero indicates that no block is allocated. **As `bmap` encounters zeros, it replaces them with the numbers of fresh blocks**, allocated on demand (kernel/fs.c:384-385) (kernel/fs.c:392-393).

---

`Bmap` makes it easy for `readi` and `writei` to get at an `inode’s` data.

#### `readi`

> `readi`是在`bmap`上的又一层抽象。
>
> 简而言之，`readi`和我们常用的文件读写接口就比较类似了。
>
> `readi`会接受一个偏移量，我们通过这个 **偏移量/BLOCLK_SIZE** 就可以确定，这个偏移量对应的数据是在`inode`的哪一个BLOCK里，`bmap`会返回这个BLOCK在disk上的真实编号。接下来，我们把这块BLOCK加载到buffer cache中，然后就可以从指定位置开始读取数据了。

`Readi` (kernel/fs.c:456) starts by making sure that the offset and count are not beyond the end of the file. Reads that start beyond the end of the file return an error (kernel/fs.c:461-462) while reads that start at or cross the end of the file return fewer bytes than requested (kernel/fs.c:463-464). The main loop processes each block of the file, copying data from the buffer into `dst` (kernel/fs.c:466-474).

```c
// Read data from inode.
// Caller must hold ip->lock.
// If user_dst==1, then dst is a user virtual address;
// otherwise, dst is a kernel address.
int
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    return 0;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
  }
  return tot;
}
```

#### `writei`

> `writei`和`readi`是十分类似的，但是写操作多了三个异常
>
> - 写操作可以让增大文件大小，当然不能超过文件的最大限制
> - 数据从内存中被拷贝到了buffer cache之中
> - 以为写操作可能涉及到文件体积的增大，需要更新`inode`中对于文件大小的描述
>
> **我的疑问，如果我要在文件之中开始write，那么会不会出现BLOCK中的旧数据被新数据覆盖的问题呢？**

`writei` (kernel/fs.c:483) is identical to `readi`, with three exceptions:

writes that start at or cross the end of the file grow the file, up to the maximum file size (kernel/fs.c:490-491);

the loop copies data into the buffers instead of out (kernel/fs.c:36); and

if the write has extended the file, `writei` must update its size (kernel/fs.c:504-511).

```c
// Write data to inode.
// Caller must hold ip->lock.
// If user_src==1, then src is a user virtual address;
// otherwise, src is a kernel address.
int
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    brelse(bp);
  }

  if(n > 0){
    if(off > ip->size)
      ip->size = off;
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
  }

  return n;
}
```

Both `readi` and `writei` begin by checking for `ip->type == T_DEV`. This case handles special devices whose data does not live in the file system; we will return to this case in the file descriptor layer.

#### `stati`

The function `stati` (kernel/fs.c:442) copies `inode` metadata into the stat structure, which is exposed to user programs via the stat system call.

### 8.11 Code: directory layer

A directory is implemented internally much like a file. Its `inode` has type `T_DIR` and its data is a sequence of directory entries. Each entry is a struct `dirent` (kernel/fs.h:56), which contains a name and an `inode` number. The name is at most `DIRSIZ (14)` characters; if shorter, it is terminated by a NUL (0) byte. Directory entries with `inode` number zero are free.

> 文件夹和文件的实现其实是很相似的。文件里存储了许多BLOCK的地址，文件夹存储了许多其他文件夹的地址。这些地址指向下边所示的数据结构。

```c
// Directory is a file containing a sequence of dirent structures.
##define DIRSIZ 14

struct dirent {
  ushort inum;
  char name[DIRSIZ];
};
```

#### `dirlookup`

The function `dirlookup` (kernel/fs.c:527) searches a directory for an entry with the given name.

If it finds one, it returns a pointer to the corresponding `inode`, unlocked, and sets `*poff` to the byte offset of the entry within the directory, in case the caller wishes to edit it.

If `dirlookup` finds an entry with the right name, it updates `*poff` and returns an unlocked `inode` obtained via `iget`.

> 文件查找最后返回的是一个没有被锁住的`inode`缓存，这一点在8.9节`iget`中就有了论述，这里结合这个功能更深入的讨论了这一点。
>
> 要查询`dp`文件夹的人已经给`dp`加锁了，此时我们的name是当前文件夹，也就是通过`dp`找`dp`，如果我们的`iget`也要给`dp`加锁的话，那就造成死锁了。

**`Dirlookup`is the reason that`iget` returns unlocked `inodes`.** The caller has locked `dp`, so if the lookup was for `.`, an alias for the current directory, attempting to lock the `inode` before returning would try to re-lock `dp` and deadlock. (There are more complicated deadlock scenarios involving multiple processes and `..`, an alias for the parent directory; . is not the only problem.) **The caller can unlock `dp` and then lock `ip`, ensuring that it only holds one lock at a time.**

```c
// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlookup read");
    if(de.inum == 0)
      continue;
    if(namecmp(name, de.name) == 0){
      // entry matches path element
      if(poff)
        *poff = off;
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
}
```

#### `dirlink`

> 创建新文件夹

The function `dirlink` (kernel/fs.c:554) writes a new directory entry with the given name and `inode` number into the directory `dp`.

If the name already exists, `dirlink` returns an error (kernel/fs.c:560- 564).

The main loop reads directory entries looking for an unallocated entry. When it finds one, it stops the loop early (kernel/fs.c:538-539), with off set to the offset of the available entry. Otherwise, the loop ends with off set to `dp->size`. Either way, `dirlink` then adds a new entry to the directory by writing at offset off (kernel/fs.c:574-577).

```c
// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
  }

  strncpy(de.name, name, DIRSIZ);
  de.inum = inum;
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    panic("dirlink");

  return 0;
}
```

### 8.12 Code: Path names

Path name lookup involves a succession of calls to `dirlookup`, one for each path component.

> 两个通过名字找`inode`的函数

#### `Namei/nameiparent`

`Namei` (kernel/fs.c:661) evaluates path and returns the corresponding `inode`.

The function `nameiparent` is a variant: it stops before the last element, returning the `inode` of the parent directory and copying the final element into name. Both call the generalized function `namex` to do the real work.

```c
struct inode*
namei(char *path)
{
  char name[DIRSIZ];
  return namex(path, 0, name);
}

struct inode*
nameiparent(char *path, char *name)
{
  return namex(path, 1, name);
}
```

#### `Namex`

> 第一步，相对路径还是绝对路径？

`Namex` (kernel/fs.c:626) starts by deciding where the path evaluation begins. If the path begins with a slash, evaluation begins at the root; otherwise, the current directory (kernel/fs.c:630-633).

> 第二步，检查path中的每一个元素

Then it uses `skipelem` to consider each element of the path in turn (kernel/fs.c:635). Each iteration of the loop must look up name in the current `inode ip`.

> 第三步，确保path中的每一个元素的`inode`都是文件夹
>
> 注意，`ilock`在这里被使用了，path中的每个文件夹都是一个`inode`，在查看他们的Type之前需要通过`ilock`保证他们都被加载到了cache中，这里的lock的作用很特别！！！

The iteration begins by locking `ip` and checking that it is a directory. If not, the lookup fails (kernel/fs.c:636-640). (**Locking `ip` is necessary** not because `ip->type` can change underfoot—it can’t—but **because until `ilock` runs, `ip->type` is not guaranteed to have been loaded from disk**.)

> 第四步，根据相应的条件，找到文件或者文件的parent

If the call is `nameiparent` and this is the last path element, the loop stops early, as per the definition of `nameiparent`; the final path element has already been copied into name, so `namex` need only return the unlocked `ip` (kernel/fs.c:641-645).

Finally, the loop looks for the path element using `dirlookup` and prepares for the next iteration by setting `ip = next` (kernel/fs.c:646-651). When the loop runs out of path elements, it returns `ip`.

```c
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
      return 0;
    }
    if(nameiparent && *path == '\0'){
      // Stop one level early.
      iunlock(ip);
      return ip;
    }
    if((next = dirlookup(ip, name, 0)) == 0){
      iunlockput(ip);
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
```

> 这里的设计亮点就是，path中的每个文件夹都是用的时候锁住，用完了就释放。这使得并行得以实现。

The procedure `namex` may take a long time to complete: it could involve several disk operations to read `inodes` and directory blocks for the directories traversed in the pathname (if they are not in the buffer cache). **Xv6 is carefully designed so that if an invocation of `namex` by one kernel thread is blocked on a disk I/O, another kernel thread looking up a different pathname can proceed concurrently.** **`Namex` locks each directory in the path separately so that lookups in different directories can proceed in parallel.**

> 并发带来的挑战
>
> 挑战一：进程1正在查询一个pathname，进程二可能在同时把路径中的文件夹给删除了。这��会使得查���到的文件可��ｿ被删除了或者是被其他内容给覆盖了。
>
> Xv6解决了这个问题，首先`Iget`会增加`inode`的reference count，从而`inode`不会从缓存中被替换；其次，`namex`只有在获得`inode`之后才会释放对文件夹的锁。因此，如果`inode`已经被另一个进程删除了，但是他的pointer reference并没有归0，从而不会被立刻删除。

This concurrency introduces some challenges. For example, while one kernel thread is looking up a pathname another kernel thread may be changing the directory tree by unlinking a directory. A potential risk is that a lookup may be searching a directory that has been deleted by another kernel thread and its blocks have been re-used for another directory or file.

Xv6 avoids such races. For example, when executing `dirlookup` in `namex`, the lookup thread holds the lock on the directory and `dirlookup` returns an `inode` that was obtained using `iget`. `Iget` increases the reference count of the `inode`. Only after receiving the `inode` from `dirlookup` does `namex` release the lock on the directory. Now another thread may unlink the `inode` from the directory but xv6 will not delete the `inode` yet, because the reference count of the `inode` is still larger than zero.

> 挑战二：死锁。可以预想这样一种情况，`./a.txt`。也就是说，`namex`会先对这个`.`进行查询，也就是我查我自己。我们已经知道，`namex`会给被查询的当前节点上锁，那么，当前节点已经被锁了，下一个节点也是当前节点，这就造成了死锁。当然，代码中可以看出，在进入下一个节点之前，`namex`会释放当前节点的锁，从而这种死锁也就不会发生了。
>
> 这里也就体现出`inode cache` 和`buffer cache`上锁理念的不同了。`buffer cache`交给上层的都是一个上过锁的buffer，而`inode cache`会给上层一个不加锁的`inode`，对这个`inode`的上锁需要交给上层来处理。

Another risk is deadlock. For example, next points to the same `inode` as `ip` when looking up ".". Locking next before releasing the lock on `ip` would result in a deadlock. To avoid this deadlock, `namex` unlocks the directory before obtaining a lock on next. Here again we see why the separation between `iget` and `ilock` is important.

### 8.13 File descriptor layer

> File descriptor,句柄，是对硬盘或者其他硬件资源的进一步抽象。

A cool aspect of the Unix interface is that most resources in Unix are represented as files, including devices such as the console, pipes, and of course, real files. The file descriptor layer is the layer that achieves this uniformity.

> 每个进程都有一个file descriptor table。这个句柄表里存放的是file这个数据结构，他内部可能是一个`inode`或者是一个pipe。
>
> ```c
> // Per-process state
> struct proc {
>   struct spinlock lock;
>
>   // p->lock must be held when using these:
>   enum procstate state;        // Process state
>   struct proc *parent;         // Parent process
>   void *chan;                  // If non-zero, sleeping on chan
>   int killed;                  // If non-zero, have been killed
>   int xstate;                  // Exit status to be returned to parent's wait
>   int pid;                     // Process ID
>
>   // these are private to the process, so p->lock need not be held.
>   uint64 kstack;               // Virtual address of kernel stack
>   uint64 sz;                   // Size of process memory (bytes)
>   pagetable_t pagetable;       // User page table
>   struct trapframe *trapframe; // data page for trampoline.S
>   struct context context;      // swtch() here to run process
>   struct file *ofile[NOFILE];  // Open files
>   struct inode *cwd;           // Current directory
>   char name[16];               // Process name (debugging)
> };
> ```

#### Struct `file`

Xv6 gives each process its own table of open files, or file descriptors, as we saw in Chapter 1. **Each open file is represented by a struct file (kernel/file.h:1), which is a wrapper around either an `inode` or a `pipe`, plus an I/O offset**.

> 每当我们在一个进程中open一个文件时，一个file结构体就会被写入`proc`中的句柄表中。
>
> 多个进程可以打开同一个文件，也就是说，他们各自的句柄表中都会记录同一个`inode`,但是offset可能会各有不同。
>
> 一个进程也可以多次打开同一个文件，也就是说，一个进程的句柄表中可以多次存放同一个`inode`。

Each call to open creates a new open file (a new struct file): if multiple processes open the same file independently, the different instances will have different I/O offsets. On the other hand, a single open file (the same struct file) can appear multiple times in one process’s file table and also in the file tables of multiple processes. **This would happen if one process used open to open the file and then created aliases using dup or shared it with a child using fork.**

A **reference count** tracks the number of references to a particular open file. A file can be open for reading or writing or both. The readable and writable fields track this.

```c
struct file {
  enum { FD_NONE, FD_PIPE, FD_INODE, FD_DEVICE } type;

  int ref; // reference count
  char readable;
  char writable;
  struct pipe *pipe; // FD_PIPE
  struct inode *ip;  // FD_INODE and FD_DEVICE
  uint off;          // FD_INODE
  short major;       // FD_DEVICE
};

```

---

All the open files in the system are kept in a **global file table, the `ftable`.** The file table has functions to allocate a file (`filealloc`), create a duplicate reference (`filedup`), release a reference (`fileclose`), and read and write data (`fileread` and `filewrite`).

```c
struct {
  struct spinlock lock;
  struct file file[NFILE];
} ftable;
```

> 操作系统用了一个全局变量来存储所有的被打开的文件

The first three follow the now-familiar form. `Filealloc` (kernel/file.c:30) scans the file table for an unreferenced file (f->ref == 0) and returns a new reference; `filedup` (kernel/file.c:48) increments the reference count; and `fileclose` (kernel/file.c:60) decrements it. When a file’s reference count reaches zero, `fileclose` releases the underlying pipe or `inode`, according to the type.

#### `Filealloc`

从全局表中找出一个空闲的句柄，然后返回给上一级

```c
// Allocate a file structure.
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}
```

#### `Filedup`

增减句柄被引用的个数并返回句柄

```c
// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  f->ref++;
  release(&ftable.lock);
  return f;
}
```

#### `Fileclose`

当确认句柄没有引用之后，释放`inode`或者pipe

```c
// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  if(--f->ref > 0){
    release(&ftable.lock);
    return;
  }
  ff = *f;
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);

  if(ff.type == FD_PIPE){
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
```

---

The functions `filestat`, `fileread`, and `filewrite` implement the stat, read, and write operations on files.

`Filestat` (kernel/file.c:88) is only allowed on `inodes` and calls `stati`.

`Fileread` and `filewrite` check that the operation is allowed by the open mode and then pass the call through to either the pipe or `inode` implementation.

- If the file represents an `inode`, `fileread` and `filewrite` use the I/O offset as the offset for the operation and then advance it (kernel/file.c:122- 123) (kernel/file.c:153-154).

- Pipes have no concept of offset. Recall that the `inode` functions require the caller to handle locking (kernel/file.c:94-96) (kernel/file.c:121-124) (kernel/file.c:163-166).

> 通过句柄读写pipe没什么很特别的，都在`pipe.c`中。
>
> 通过句柄读写`inode`是很有意思的环节，它又**再次体现了Xv6把给`inode`的上锁解锁任务交给调用者的设计**，从下面的函数来看，`fileread`和`filewrite`保证了对`inode`的offset更新的原子性。从而，多个进程同时对文件写入并不会互相覆盖，一个进程必须在另一个进程更新完offset之后才能继续写入。

The `inode` locking has the convenient side effect that the read and write offsets are updated atomically, so that multiple writing to the same file simultaneously cannot overwrite each other’s data, though their writes may end up interlaced.

#### `fileread`

```c
// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
  int r = 0;

  if(f->readable == 0)
    return -1;

  if(f->type == FD_PIPE){
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    ilock(f->ip);
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
      f->off += r;
    iunlock(f->ip);
  } else {
    panic("fileread");
  }

  return r;
}
```

#### `filewrite`

> 结合8.6Logging章节，文件一次写入的大小是有限制的，因为LOG在DISK上的空间是有限的，遇到大文件只能把它按照LOG的最大空间多次写入。

```c
// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    return -1;

  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    ret = (i == n ? n : -1);
  } else {
    panic("filewrite");
  }

  return ret;
}
```

### 8.14 Code: System calls

With the functions that the lower layers provide the implementation of most system calls is trivial (see (`kernel/sysfile.c`)). There are a few calls that deserve a closer look.

---

The functions `sys_link` and `sys_unlink` edit directories, creating or removing references to `inodes`. They are another good example of the power of using transactions.

#### `sys_link`(硬链接)

> `sys_link`所做的是就是让new pathname和old pathname指向同一块`inode`。
>
> 1. 保证old pathname是存在的并且不是文件夹
> 2. 对old pathname对应的`inode`的引用++
> 3. new pathname的上层文件夹必须是存在的，并且new pathname和old pathname对应的是同一个硬件设备
> 4. **如果一切都没问题，就把old pathname所指向的`inode`存入new pathname对应的文件夹目录里边去（`dirlink(dp, name, ip->inum)`）**
> 5. 最后把共享的`inode`缓存同步到disk里边去

`Sys_link` (kernel/sysfile.c:120) begins by fetching its arguments, two strings old and new (kernel/sysfile.c:125). Assuming old exists and is not a directory (kernel/sysfile.c:129-132), sys_link increments its `ip->nlink` count. Then sys_link calls `nameiparent` to find the parent directory and final path element of new (kernel/sysfile.c:145) and creates a new directory entry pointing at old ’s `inode` (kernel/sysfile.c:148). The new parent directory must exist and be on the same device as the existing `inode`: **`inode` numbers only have a unique meaning on a single disk**. If an error like this occurs, `sys_link` must go back and decrement `ip->nlink`.

```c
// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    return -1;

  begin_op();
  if((ip = namei(old)) == 0){
    end_op();
    return -1;
  }

  ilock(ip);
  if(ip->type == T_DIR){
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
  ilock(dp);
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
  iput(ip);

  end_op();

  return 0;

bad:
  ilock(ip);
  ip->nlink--;
  iupdate(ip);
  iunlockput(ip);
  end_op();
  return -1;
}
```

> Logging部分的内容

Transactions simplify the implementation because it requires updating multiple disk blocks, but we don’t have to worry about the order in which we do them. They either will all succeed or none. For example, without transactions, updating `ip->nlink` before creating a link, would put the file system temporarily in an unsafe state, and a crash in between could result in havoc. With transactions we don’t have to worry about this.

`Sys_link` creates a new name for an existing `inode`.

#### `create`

The function `create` (kernel/sysfile.c:242) **creates a new name for a new `inode`.**

It is a generalization of the three file creation system calls: open with the O_CREATE flag makes a new ordinary file, `mkdir` makes a new directory, and `mkdev` makes a new device file.

- Like sys_link, create starts by calling `nameiparent` to get the `inode` of the parent directory.

- It then calls `dirlookup` to check whether the name already exists (kernel/sysfile.c:252).

- **If the name does exist**, `create`’s behavior depends on which system call it is being used for:

  - open has different semantics from `mkdir` and `mkdev`.

  - If create is being used on behalf of open (type == T_FILE) and the name that exists is itself a regular file, then open treats that as a success, so create does too (kernel/sysfile.c:256).

  - Otherwise, it is an error (kernel/sysfile.c:257-258).

- **If the name does not already exist**, create now allocates a new `inode` with `ialloc`(kernel/sysfile.c:261).

  I**f the new `inode` is a directory, create initializes it with . and .. entries.**

Finally, now that the data is initialized properly, create can link it into the parent directory (kernel/sysfile.c:274). Create, like sys_link, holds two `inode` locks simultaneously: `ip` and `dp`. **There is no possibility of deadlock because the `inode` `ip` is freshly allocated: no other process in the system will hold `ip` ’s lock and then try to lock `dp`.**

```c
static struct inode*
create(char *path, short type, short major, short minor)
{
  struct inode *ip, *dp;
  char name[DIRSIZ];
  // 获得文件夹对应的inode
  if((dp = nameiparent(path, name)) == 0)
    return 0;

  ilock(dp);
  // 查看文件夹中的每一个drient，保证没有重名的inode
  if((ip = dirlookup(dp, name, 0)) != 0){
    // 名字重复
    iunlockput(dp);
    ilock(ip);
    // 名字重复的inode是一个文件，直接返回已经存在的文件
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
      return ip;
    iunlockput(ip);
    // 否则返回错误
    return 0;
  }
  // 这里可以保证dp中没有叫name的文件
  // ialloc,给这个name分配一个inode
  if((ip = ialloc(dp->dev, type)) == 0)
    panic("create: ialloc");

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);
  // 如果这个inode代表的是一个文件夹
  if(type == T_DIR){  // Create . and .. entries.
    dp->nlink++;  // for ".."
    iupdate(dp);
    // No ip->nlink++ for ".": avoid cyclic ref count.
    // 给这个文件夹初始化两个基本的dirent . 和 ..
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      panic("create dots");
  }
  // 最后，把这个文件inode放到文件夹dp的其中一个dirent中
  if(dirlink(dp, name, ip->inum) < 0)
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
```

#### `sys_open`

Using create, it is easy to implement `sys_open`, `sys_mkdir`, and `sys_mknod`.

Sys_open (kernel/sysfile.c:287) is the most complex, because creating a new file is only a small part of what it can do.

- **If open is passed the O_CREATE flag, it calls create** (kernel/sysfile.c:301).

- **Otherwise, it calls `namei` (kernel/sysfile.c:307). Create returns a locked `inode`, but `namei` does not, so sys_open must lock the `inode` itself.** This provides a convenient place to check that directories are only opened for reading, not writing.

- Assuming the `inode` was obtained one way or the other, `sys_open` allocates a file and a file descriptor (kernel/sysfile.c:325) and then fills in the file (kernel/sysfile.c:337-342).

  Note that no other process can access the partially initialized file since it is only in the current process’s table.

```c
uint64
sys_open(void)
{
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    return -1;

  begin_op();

  if(omode & O_CREATE){
    ip = create(path, T_FILE, 0, 0);
    if(ip == 0){
      end_op();
      return -1;
    }
  } else {
    if((ip = namei(path)) == 0){
      end_op();
      return -1;
    }
    ilock(ip);
    if(ip->type == T_DIR && omode != O_RDONLY){
      iunlockput(ip);
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    iunlockput(ip);
    end_op();
    return -1;
  }
  // 这里一定拿到了一个inode
  // 接下来为inode分配一个句柄
  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    if(f)
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  // 初始化句柄fd中的细节
  if(ip->type == T_DEVICE){
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    f->off = 0;
  }
  f->ip = ip;
  f->readable = !(omode & O_WRONLY);
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

  if((omode & O_TRUNC) && ip->type == T_FILE){
    itrunc(ip);
  }

  iunlock(ip);
  end_op();

  return fd;
}
```

#### `sys_pipe`

Chapter 7 examined the implementation of pipes before we even had a file system. The function `sys_pipe` connects that implementation to the file system by providing a way to create a pipe pair. Its argument is a pointer to space for two integers, where it will record the two new file descriptors. Then it allocates the pipe and installs the file descriptors.

> `int pipe(int p[])`
>
> 这里论述一下，pipe是如何让进程间的沟通成为可能的。pipe 系统调用会创建两个句柄出来，这两个句柄会被存储在创建pipe的进程A的open file表中。如果我们使用fork，那么子进程B就会复制一份进程A内存空间，从而，子进程B也就能使用进程A中创造出的pipe了。
>
> 也就是说，进程A和进程B的句柄表中有着相同的两个个句柄，这两个句柄指向了同一块内核态开辟的内存空间，这块空间就是所谓的管道了。

```c
uint64
sys_pipe(void)
{
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
  // 拿到用户传入的p[]
  if(argaddr(0, &fdarray) < 0)
    return -1;
  // 通过pipealloc获得两个句柄
  // 一个用来读，一个用来写
  if(pipealloc(&rf, &wf) < 0)
    return -1;
  fd0 = -1;
  // 通过fdalloc把两个句柄写入进程的fd表中
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    if(fd0 >= 0)
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  // 把fd0和fd1写入用户空间的数组中
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    p->ofile[fd0] = 0;
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
}
```

```c
int
pipealloc(struct file **f0, struct file **f1)
{
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    goto bad;
  pi->readopen = 1;
  pi->writeopen = 1;
  pi->nwrite = 0;
  pi->nread = 0;
  initlock(&pi->lock, "pipe");
  (*f0)->type = FD_PIPE;
  (*f0)->readable = 1;
  (*f0)->writable = 0;
  (*f0)->pipe = pi;
  (*f1)->type = FD_PIPE;
  (*f1)->readable = 0;
  (*f1)->writable = 1;
  (*f1)->pipe = pi;
  return 0;

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    fileclose(*f0);
  if(*f1)
    fileclose(*f1);
  return -1;
}
```

### 8.4 Logging layer

One of the most interesting problems in file system design is **crash recovery**. The problem arises because many file-system operations involve multiple writes to the disk, and **a crash after a subset of the writes may leave the on-disk file system in an inconsistent state**. For example, suppose a crash occurs during file truncation (setting the length of a file to zero and freeing its content blocks). Depending on the order of the disk writes, the crash may either leave an `inode` with a reference to a content block that is marked free, or it may leave an allocated but unreferenced content block.

> crash带来的问题：
>
> 1. `inode`中依然指向着一块被标记为free的BLOCK（严重）
> 2. BLOCK被写入了数据但`inode`没有指向它

#### Crash Handling

The latter is relatively benign, but an `inode` that refers to a freed block is likely to cause serious problems after a reboot. **After reboot, the kernel might allocate that block to another file, and now we have two different files pointing unintentionally to the same block**. If xv6 supported multiple users, this situation could be a security problem, since the old file’s owner would be able to read and write blocks in the new file, owned by a different user.

> 解决方案
>
> 1. 将所有的disk写请求都写入disk上的log区域
> 2. 当log了所有的写请求后，写入一个commit record用来表示一个完整的操作可以进行
> 3. 开始真正向disk写入数据
> 4. 删除相关的log信息

Xv6 solves the problem of crashes during file-system operations with a simple form of logging. **An xv6 system call does not directly write the on-disk file system data structures. Instead, it places a description of all the disk writes it wishes to make in a log on the disk.**

Once the system call has logged all of its writes, it writes a special commit record to the disk indicating that the log contains a complete operation. At that point the system call copies the writes to the on-disk file system data structures. After those writes have completed, the system call erases the log on disk.

> file system的恢复过程（开始于运行任何程序之前）

If the system should crash and reboot, the file-system code recovers from the crash as follows, **before running any processes**.

- If the log is **marked** as containing a complete operation, then the recovery code **copies the writes to where they belong in the on-disk** file system.

- If the log is **not marked** as containing a complete operation, the recovery code ignores the log. The recovery code finishes by **erasing the log**.

Why does xv6’s log solve the problem of crashes during file system operations?

- If the crash occurs before the operation commits, then the log on disk will not be marked as complete, the recovery code will ignore it, and the state of the disk will be as if the operation had not even started.

- If the crash occurs after the operation commits, then recovery will replay all of the operation’s writes, perhaps repeating them if the operation had started to write them to the on-disk data structure.

In either case, **the log makes operations atomic with respect to crashes**: after recovery, **either all of the operation’s writes appear on the disk, or none of them appear.**

### 8.5 Log design

The log resides at a known fixed location, specified in the superblock.

![image-20220716230656087](assets/Operating Systems.assets/image-20220716230656087.png)

It consists of a header block followed by a sequence of updated block copies (“logged blocks”).

The **header block** contains <u>an array of sector numbers</u>, one for each of the logged blocks, <u>and the count of log blocks</u>.

The **count** in the header block on disk is **either zero**, indicating that there is **no transaction in the log**, or **nonzero**, indicating that the **log contains a complete committed transaction** with the indicated number of logged blocks.

```c
// Contents of the header block, used for both the on-disk header block
// and to keep track in memory of logged block# before commit.
struct logheader {
  int n;
  int block[LOGSIZE];
};

struct log {
  struct spinlock lock;
  int start;
  int size;
  int outstanding; // how many FS sys calls are executing.
  int committing;  // in commit(), please wait.
  int dev;
  struct logheader lh;
};
```

> 这里要对照着代码去看

Xv6 writes the header block when a transaction commits, but not before, and sets the count to zero after copying the logged blocks to the file system. Thus a crash midway through a transaction will result in a count of zero in the log’s header block; a crash after a commit will result in a non-zero count.

---

> 下面的这两点在8.6节的`end_op`中有详细的阐述，应该结合着代码理清逻辑再来看这里的结论

![image-20220723205203167](assets/Operating Systems.assets/image-20220723205203167.png)

#### Challenge: Concurrent FS `Syscalls`

Each system call’s code indicates the start and end of the sequence of writes that must be atomic with respect to crashes. To allow concurrent execution of file-system operations by different processes, **the logging system can accumulate the writes of multiple system calls into one transaction**. Thus a single commit may involve the writes of multiple complete system calls. To avoid splitting a system call across transactions, the logging system only commits when no file-system system calls are underway.

The idea of **committing several transactions together is known as `group commit`**.

- Group commit **reduces the number of disk operations** because it amortizes(分摊) the fixed cost of a commit over multiple operations.
- Group commit also hands the disk system more concurrent writes at the same time, perhaps allowing the disk to write them all during a single disk rotation. Xv6’s `virtio` driver doesn’t support this kind of batching, but xv6’s file system design allows for it.

#### Challenge: MAX log size

Xv6 dedicates a fixed amount of space on the disk to hold the log.

The total number of blocks written by the system calls in a transaction must fit in that space. This has **two consequences**.

> 第一个结论，详见`file write`

- **No single system call can be allowed to write more distinct blocks than there is space in the log**. This is not a problem for most system calls, but two of them can potentially write many blocks: write and unlink. A large file write may write many data blocks and many bitmap blocks as well as an `inode` block; unlinking a large file might write many bitmap blocks and an `inode`. Xv6’s write system call breaks up large writes into multiple smaller writes that fit in the log, and unlink doesn’t cause problems because in practice the xv6 file system uses only one bitmap block.
- The other consequence of limited log space is that **the logging system cannot allow a system call to start unless it is certain that the system call’s writes will fit in the space remaining in the log.**

### 8.6 Code: logging

A typical use of the log in a system call looks like this:

```c
begin_op();
...
bp = bread(...);
bp->data[...] = ...;
log_write(bp);
...
end_op();
```

#### `begin_op`

`begin_op` (kernel/log.c:126) waits until the logging system is not currently committing, and until there is enough unreserved log space to hold the writes from this call. **`log.outstanding` counts the number of system calls that have reserved log space;** the total reserved space is `log.outstanding` times MAXOPBLOCKS. Incrementing `log.outstanding` both reserves space and prevents a commit from occurring during this system call. The code conservatively assumes that each system call might write up to MAXOPBLOCKS distinct blocks.

> `begin_op`在log进行commit的时候是不可以再向log中写入的，这个很好理解。
>
> `begin_op`**在operation可能耗尽log空间的时候**，也会**进入sleep让出CPU**。这里和上一节提到的两个challenge有关。文件系统支持多个进程并发的向log写入自己的请求，当多个进程都写完了以后，log可以把多个进程的请求整合成为一个，当作一个commit提交。但这里会涉及到一个问题，如果一次有太多的进程向log中写入自己的请求，那么有可能导致**多个进程都没有完成自己的完整文件操作，但是log已经被填满了的问题**，这样的话，log是不能进行commit的，因为如果commit了，所有进程的文件操作都是不完整的。所以，这里加入了这样一个判断，来限制能使用log的进程数量。
>
> 总结一下，`begin_op`用来表示一个文件system call的开始，同时也是进程使用log前的一道关卡，保证log被并发的写入并且不会被过多进程耗尽log空间。

```c
// called at the start of each FS system call.
void
begin_op(void)
{
  acquire(&log.lock);
  while(1){
    if(log.committing){
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    } else {
      log.outstanding += 1;
      release(&log.lock);
      break;
    }
  }
}
```

---

#### `log_write`

`log_write` (kernel/log.c:214) acts as a proxy for `bwrite`.

- It records the block’s sector number in memory, reserving it a slot in the log on disk, and

- pins the buffer in the block cache to prevent the block cache from evicting it.

The block must stay in the cache until committed: until then, the cached copy is the only record of the modification; it cannot be written to its place on disk until after commit; and other reads in the same transaction must see the modifications.

`log_write` notices when a block is written multiple times during a single transaction, and allocates that block the same slot in the log. This optimization is often called **absorption**.

<u>It is common that, for example, the disk block containing `inodes` of several files is written several times within a transaction.</u> By absorbing several disk writes into one, the file system can save log space and can achieve better performance because only one copy of the disk block must be written to disk.

> `log_write`是对`bwrite`的一种代理，它主要干了两件事：
>
> 1. 把要进行磁盘写入的BLOCK No记录在log的header的数组中
> 2. 保证记录在数组中的BLOCK不会被驱逐出buffer cache
>
> 先来说说**防止驱逐的原因**，log要在一个system call全部完成之后才会进行真正的写入工作，也就是说，在加入log的数组中后，disk还不能同步buffer cache里修改的内容，所以，如果我们让这个buffer被evict了，那么直接写入的内容也就没有机会被同步到disk上了。所以使用`bpin()`给buffer的`refcnt++`，保证LRU不会夺走这个buffer cache。
>
> 这里还体现了`absorbtion`，简单的来说，就是我们在一个system call中可能会多次写入同一块block。举个例子，`inodes`就有可能处于同一块BLOCK，我们可能一次需要更新多个在同一块BLOCK中的`inodes`，所以我们没必要在数组中记录这个BLOCK编号两次，因为我们只用一次write disk就可以把对这块BLOCK的多次更新给同步到disk了。
>
> 总结一下，`log_write`并没有进行对磁盘的写入工作，他只是把所有的写请求放到了log之中（这个log指的是内存上的log）

```c
void
log_write(struct buf *b)
{
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
  }
  log.lh.block[i] = b->blockno;
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
}
```

---

#### `end_op`

> `end_op`主要干了两件事
>
> 1. 将对log进行写入的system call的数量减1
> 2. **commit()**
>
> `end_op`的核心是commit函数，除此之外，它所做的就是如果commit的条件没有达成，及还有system call没有完成整个事务，那么在`begin_op`进入阻塞的进程。

```c
// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
  int do_commit = 0;

  acquire(&log.lock);
  log.outstanding -= 1;
  if(log.committing)
    panic("log.committing");
  if(log.outstanding == 0){
    do_commit = 1;
    log.committing = 1;
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);

  if(do_commit){
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
    acquire(&log.lock);
    log.committing = 0;
    wakeup(&log);
    release(&log.lock);
  }
}
```

- `end_op` (kernel/log.c:146) first decrements the count of outstanding system calls.

- If the count is now zero, it commits the current transaction by calling `commit()`.

  > 下面就是`end_op`的核心，也是log这一节的核心，commit了。

  ```c
  static void
  commit()
  {
    if (log.lh.n > 0) {
      write_log();     // Write modified blocks from cache to log
      write_head();    // Write header to disk -- the real commit
      install_trans(0); // Now install writes to home locations
      log.lh.n = 0;
      write_head();    // Erase the transaction from the log
    }
  }
  ```

  - There are four stages in this process. `write_log()` (kernel/log.c:178) copies each block modified in the transaction from the buffer cache to its slot in the log on disk.

    > 第一步，把log header中记录的每一个被修改的BLOCK中从他们的buffer cache中，转移到log对应的buffer cache中。（修改还在内存之中）
    >
    > 然后，把log中的在buffer cache中的内容同步到disk的log之中。

    ```c
    // Copy modified blocks from cache to log.
    static void
    write_log(void)
    {
      int tail;

      for (tail = 0; tail < log.lh.n; tail++) {
        struct buf *to = bread(log.dev, log.start+tail+1); // log block
        struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
        memmove(to->data, from->data, BSIZE);
        bwrite(to);  // write the log
        brelse(from);
        brelse(to);
      }
    }
    ```

  - `write_head()` (kernel/log.c:102) writes the header block to disk: this is the commit point, and a crash after the write will result in recovery replaying the transaction’s writes from the log.

    > 第二步，修改内存中的log header，将这次事务涉及到的BLOCK数量写入到log header对应的disk部分
    >
    > 这里是**commit真的发生的地方**，重点在于`bwrite(buf)`
    >
    > `bwrite(buf)`之前断电，disk的log header中n == 0，所以之前的事务完全不作数，不会同步到disk上。
    >
    > `bwrite(buf)`之后断电，disk的log header中n ！= 0，所以OS会把log中存储的n个BLOCKS中的内容同步到disk上。

    ```c
    // Write in-memory log header to disk.
    // This is the true point at which the
    // current transaction commits.
    static void
    write_head(void)
    {
      struct buf *buf = bread(log.dev, log.start);
      struct logheader *hb = (struct logheader *) (buf->data);
      int i;
      hb->n = log.lh.n;
      for (i = 0; i < log.lh.n; i++) {
        hb->block[i] = log.lh.block[i];
      }
      bwrite(buf);
      brelse(buf);
    }
    ```

  - `install_trans` (kernel/log.c:69) reads each block from the log and writes it to the proper place in the file system.

    > `install_trans`所做的事，就是把log记录的BLOCKS全部同步到他们在disk上的对应位置上去。
    >
    > `install_trans`会在两种情况下被调用
    >
    > 1. 恢复的时候
    > 2. 正常的文件写操作执行的时候
    >
    >    可以看到代码也对这两种情况进行了区分，如果是恢复，那就不涉及释放buffer cache的问题；如果是正常执行，那就得把`begin_op`给buffer cache加的引用给消除。

    ```c
    // Copy committed blocks from log to their home location
    static void
    install_trans(int recovering)
    {
      int tail;

      for (tail = 0; tail < log.lh.n; tail++) {
        struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
        struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
        memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
        bwrite(dbuf);  // write dst to disk
        if(recovering == 0)
          bunpin(dbuf);
        brelse(lbuf);
        brelse(dbuf);
      }
    }
    ```

- Finally `end_op` writes the log header with a count of zero;

```c
static void
commit()
{
  if (log.lh.n > 0) {
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    install_trans(0); // Now install writes to home locations
    log.lh.n = 0;
    write_head();    // Erase the transaction from the log
  }
}
```

> 最后我们再次修改log header中的n值为0，并把它写入disk
>
> **最后的这次对header的写入必须发生在下一次事务开始之前**，`end_op`保证了这一点。如果不这样的话，如果发生了crash，log的disk中记录的是新Transaction保存在log中的修改内容，而n却还是上一个Transaction的计数。
>
> 这也就解释了，一个事务必须全部完成之后，才会允许新的事务开始。

this has to happen before the next transaction starts writing logged blocks, so that a crash doesn’t result in recovery using one transaction’s header with the subsequent transaction’s logged blocks.

---

`recover_from_log` (kernel/log.c:116) is called from `initlog` (kernel/log.c:55), which is called from `fsinit`(kernel/fs.c:42) during boot before the first user process runs (kernel/proc.c:539). It reads the log header, and mimics the actions of end_op if the header indicates that the log contains a committed transaction.

```c
static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
  log.lh.n = 0;
  write_head(); // clear the log
}
```

#### Summary Figure

![image-20220723210534296](assets/Operating Systems.assets/image-20220723210534296.png)

## Journaling the Linux ext2fs Filesystem

## Labs

### GDB

```shell
$ make CPUS=1 qemu-gdb
*** Now run 'gdb' in another window. qemu-system-riscv64 -machine virt -bios none -kernel kernel/kernel -m 128M -smp 3 -nographic -drive file=fs.img,if=none,format=raw,id=x0 -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 -S -gdb tcp::26000
```

```shell
echo "add-auto-load-safe-path $(pwd)/.gdbinit " >> ~/.gdbinit

$ gdb-multiarch
```

```shell
(gdb) layout split

(gdb) file user/_ls
(gdb) b main
(gdb) c
```

### Lab: Xv6 and Unix utilities

#### sleep

残留问题：while循环用于确保用户的输入只有数字，但在`xv6` 运行过程中会有运行失败的情况。未能定位原因。删去while可以完美运行但逻辑不完整。

```c
##include "kernel/types.h"
##include "kernel/stat.h"
##include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(2, "usage: sleep ticks....\n");
        exit(1);
    }

    char *s = argv[1];
    //Since the end of s points to 0x0000 0000 (NULL)
    //So while can be terminated
    while (*s)
    {
        if ('0' <= *s && *s <= '9')
            s++;
        else
        {
            fprintf(2, "only digits are allowed in inputs\n");
            exit(1);
        }
    }

    int ticks = atoi(argv[1]);

    sleep(ticks);

    exit(0);
}

```

#### pingpong

记得在使用完file descriptor后将其关闭，否则当多次运行ping pong后，`pipe()`就没有多余的file descriptor可供分配了。

<img src="assets/Operating Systems.assets/image-20220309231419282.png" alt="image-20220309231419282" style="zoom: 50%;" />

```c
##include "kernel/types.h"
##include "kernel/stat.h"
##include "user/user.h"

int main(int argc, char const *argv[])
{
    int p2c[2];
    int c2p[2];
    pipe(p2c);
    pipe(c2p);

    char ball;

    int pid = fork();
    if (pid < 0)
    {
        fprintf(2, "fork error");
        exit(1);
    }

    if (pid == 0)
    {
        close(p2c[1]);
        read(p2c[0], &ball, 1);
        close(p2c[0]);
        printf("%d: received ping\n", getpid());

        close(c2p[0]);
        write(c2p[1], &ball, 1);
        close(c2p[1]);
        exit(0);
    }
    else
    {
        close(p2c[0]);
        write(p2c[1], &ball, 1);
        close(p2c[1]);
        wait(0);

        close(c2p[1]);
        read(c2p[0], &ball, 1);
        close(c2p[0]);
        printf("%d: received pong\n", getpid());
    }

    exit(0);
}
```

#### primes(\*)

#### find

### Lab: system calls

本部分记录了系统调用的整个过程，所有的实现细节见`github`。

#### System call tracing

##### user mode

在user mode中的`user/trace.c`中，使用了system call ：`trace()`。

```c
##include "kernel/param.h"
##include "kernel/types.h"
##include "kernel/stat.h"
##include "user/user.h"

int
main(int argc, char *argv[])
{
  int i;
  char *nargv[MAXARG];

  if(argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9')){
    fprintf(2, "Usage: %s mask command\n", argv[0]);
    exit(1);
  }

  if (trace(atoi(argv[1])) < 0) {
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }

  for(i = 2; i < argc && i < MAXARG; i++){
    nargv[i-2] = argv[i];
  }
  exec(nargv[0], nargv);
  exit(0);
}
```

`trace()`被声明在`user/user.h`里，

```c
int trace(int);
```

`trace()`的定义在`usys.S`中，因为所有的system call都具有相同定义的形式，所以下边的代码`usys.pl`可以用来批量编写不同system call的汇编代码。

其中，`li a7, SYS_${name}\n` 这一句是将system call的编号放入`a7`寄存器当中。system call的编号记录在`kernel/syscall.h`文件中。

`ecall`通过硬件实现user mode进入kernel mode。

```perl
##!/usr/bin/perl -w
## Generate usys.S, the stubs for syscalls.
print "# generated by usys.pl - do not edit\n";
print "#include \"kernel/syscall.h\"\n";
sub entry {
    my $name = shift;
    print ".global $name\n";
    print "${name}:\n";
    print " li a7, SYS_${name}\n";
    print " ecall\n";
    print " ret\n";
}

entry("fork");
entry("exit");
entry("wait");
entry("pipe");
entry("read");
.
.
.
entry("trace");
```

`kernel/syscall.h`

```c
// System call numbers
##define SYS_fork    1
##define SYS_exit    2
##define SYS_wait    3
##define SYS_pipe    4
##define SYS_read    5
##define SYS_kill    6
##define SYS_exec    7
##define SYS_fstat   8
##define SYS_chdir   9
##define SYS_dup    10
##define SYS_getpid 11
##define SYS_sbrk   12
##define SYS_sleep  13
##define SYS_uptime 14
##define SYS_open   15
##define SYS_write  16
##define SYS_mknod  17
##define SYS_unlink 18
##define SYS_link   19
##define SYS_mkdir  20
##define SYS_close  21
##define SYS_trace  22
```

##### kernel mode

在内核态，执行system call的入口在`kernel/syscall.c`中。`uint64 (*syscalls[])(void)` 是一个函数指针数组，类似于java中的`Method[]`.

`void syscall(void)`是执行系统调用的核心代码，他从当前进程的页表中取出`a7`中保存的系统调用号码，然后从指针数组中取出对应的函数并执行，将返回值写入页表的`a0`寄存器中。

`kernel/syscall.c`

```c
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
[SYS_trace]   sys_trace,
};

void
syscall(void)
{
  int num;
  struct proc *p = myproc();
  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    p->trapframe->a0 = syscalls[num]();
    //print trace of syscall
    if (p->mask & (1 << num)) {
      printf("%d: systemcall %s -> %d\n",
              p->pid, syscallnames[num], p->trapframe->a0);
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
```

##### get `args` from user mode

`kernel/sysproc.c` 中记录了sys_trace的具体实现。

从`uint64 (*syscalls[])(void)`可以看出，所有的系统调用都没有参数传入，而且返回值类型都为uint64。那么，**系统调用是如何从用户态获得传入的参数的呢？**`kernel/syscall.c`中提供了许多函数用于从用户态拿到数据并赋值给内核态的变量。以`argint(0, &mask)`为例，该函数可以将用户态传入的第0个参数赋值给内核态变量mask。

```c
//trace system calls of a process and its child process
uint64
sys_trace(void)
{
  int mask;

  //get 0th arg from user mode sys call trace(int mask)
  if(argint(0, &mask) < 0)
    return -1;

  myproc()->mask = mask;

  return 0;
}
```

#### Sysinfo

系统调用的过程不再赘述，这一部分的实验涉及了process和page table的部分代码，这里不做详述。**这个实验的重点在于，内核态如何把内核态中的变量返回给用户态**。`copyout(p->pagetable, st, (char *)&xv6info, sizeof(xv6info))`做到了这一点，`copyout`是如何做到的不是这个lab的重点，会在之后的章节中讲明。

`kernel/sysproc.c`

```c
//return sysinfo to user space
uint64
sys_sysinfo(void)
{
  uint64 st; // user pointer to struct sysinfo
  struct sysinfo xv6info;

  //get syscall args[0]
  //in this case, the argument is a address
  //points to struct sysinfo
  //拿到用户态的参数->一个指向sysinfo的指针
  if(argaddr(0, &st) < 0)
    return -1;

  xv6info.freemem = free_memory();
  xv6info.nproc = num_process();

  struct proc *p = myproc();
  //将内核态获得的xv6info按字节复制到之前获得的用户地址指向的内存区域中
  if(copyout(p->pagetable, st, (char *)&xv6info, sizeof(xv6info)) < 0)
      return -1;

  return 0;
}
```

### Lab: Page Table

```she
test sbrkbugs: usertrap(): unexpected scause 0x000000000000000c pid=3234
            sepc=0x0000000000005406 stval=0x0000000000005406
usertrap(): unexpected scause 0x000000000000000c pid=3235
            sepc=0x0000000000005406 stval=0x0000000000005406
```

## Lab3 : Page Tables

### Lab 3.1 Print a page table

> Define a function called `vmprint()`. It should take a `pagetable_t` argument, and print that page table in the format described below. Insert `if(p->pid==1) vmprint(p->pagetable)` in `exec.c` just before the `return argc`, to print the first process's page table.
>
> ```
> page table 0x0000000087f6e000
> ..0: pte 0x0000000021fda801 pa 0x0000000087f6a000
> .. ..0: pte 0x0000000021fda401 pa 0x0000000087f69000
> .. .. ..0: pte 0x0000000021fdac1f pa 0x0000000087f6b000
> .. .. ..1: pte 0x0000000021fda00f pa 0x0000000087f68000
> .. .. ..2: pte 0x0000000021fd9c1f pa 0x0000000087f67000
> ..255: pte 0x0000000021fdb401 pa 0x0000000087f6d000
> .. ..511: pte 0x0000000021fdb001 pa 0x0000000087f6c000
> .. .. ..510: pte 0x0000000021fdd807 pa 0x0000000087f76000
> .. .. ..511: pte 0x0000000020001c0b pa 0x0000000080007000
> ```
>
> The first line displays the argument to `vmprint`. After that there is a line for each PTE, including PTEs that refer to page-table pages deeper in the tree. Each PTE line is indented by a number of `" .."` that indicates its depth in the tree. Each PTE line shows the PTE index in its page-table page, the `pte` bits, and the physical address extracted from the PTE. Don't print PTEs that are not valid. In the above example, the top-level page-table page has mappings for entries 0 and 255. The next level down for entry 0 has only index 0 mapped, and the bottom-level for that index 0 has entries 0, 1, and 2 mapped.

```c
// Print pagetable
// display its three level tree
void
vmprint(pagetable_t pagetable)
{
  printf("page table %p\n", pagetable);
  pteprint(pagetable, 1);
}

//A helper function to aid vmprint()
void
pteprint(pagetable_t pagetable, int level)
{
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    //pte是非叶子节点，其flags的后八位只有PTE_V = 1
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    	// this PTE points to a lower-level page table.
      	// print page table level
    	for (int j = 0; j < level; j++) {
      	if(j != 0)
        	printf(" ");
      	printf("..");
    	}

      	uint64 child = PTE2PA(pte);
      	printf("%d: pte %p pa %p\n", i, pte, child);
      	pteprint((pagetable_t) child, level + 1);
    } else if((pte & PTE_V)) {
      	//pte是叶子节点，其flags的后八位不只有PTE_V = 1
      	// print page table level
        for (int j = 0; j < level; j++) {
          if(j != 0)
            printf(" ");
          printf("..");
        }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    }
  }
}
```

### Lab 3.2 A kernel page table per process

> Xv6 has a single kernel page table that's used whenever it executes in the kernel. The kernel page table is a direct mapping to physical addresses, so that kernel virtual address _x_ maps to physical address _x_. Xv6 also has a separate page table for each process's user address space, containing only mappings for that process's user memory, starting at virtual address zero. Because the kernel page table doesn't contain these mappings, user addresses are not valid in the kernel. Thus, **when the kernel needs to use a user pointer passed in a system call (e.g., the buffer pointer passed to `write()`), the kernel must first translate the pointer to a physical address**. **The goal of this section and the next is to allow the kernel to directly dereference user pointers.**

## Lab4: Traps

### Lab 3.2 Alarm

`kernel/proc.h`

```c
// store the alarm interval and the pointer to the handler function
// for lab alarm
  int ticks;
  int passed_ticks;            // how many ticks have passed since the last call
  uint64 handler;              // the user space address of handler function
  struct trapframe *alarm_trapframe; // contains the state of the user process before calling sigalarm()
  int alarm_mode;
};
```

ticks表示多少个时钟周期运行一次handler

passed_ticks表示当前进程从上一次回调函数结束起经过了多少个时钟周期

handler存放的是用户态下handler函数的地址

`alarm_trapframe`用于保存调用handler时，用户进程的状态

alarm_mode表示当前进程是否处在一个alarm状态之中

---

`kernel/sysproc.c`

```c
uint64
sys_sigalarm(void)
{
  int ticks;
  uint64 handler;
  struct proc *p = myproc();

  // get ticks from user trapframe
  if(argint(0, &ticks) < 0)
    return -1;

  // get handler address from user trapframe
  if(argaddr(1, &handler))
    return -1;

  // check if the process has already
  // been in a sigalarm
  // sigalarm(2, 0) cannot be called again
  // but sigalarm(0, 0) can be called to terminate
  // the sigalarm
  // 若alarm_mode是开启的且用户并没有传来停止alarm的命令（ticks = 0）
  // 内核不会执行新的sigalarm()指令
  if(p->alarm_mode == 1 && ticks != 0)
    return -1;

  p->ticks = ticks;
  p->handler = handler;

  // sigalarm()合法，此时需要判断他是开启alarm命令
  // 还是结束alarm命令
  if(ticks != 0)
    p->alarm_mode = 1;
  else
    p->alarm_mode = 0;

  return 0;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();
  // 恢复调用handler之前用户进程的状态
  memmove(p->trapframe, p->alarm_trapframe, PGSIZE);
  return 0;
}
```

---

`kernel/trap.c`

```c
if(which_dev == 2) {
    p->passed_ticks += 1;
    if (p->ticks != 0 && p->ticks == p->passed_ticks) {
      // save the user trapframe, since we will modify it
      memmove(p->alarm_trapframe, p->trapframe, PGSIZE);
      p->passed_ticks = 0;
      p->trapframe->epc = p->handler;
    }
    yield();
  }

  usertrapret();
}
```

进程每进入一次timer trap，就对passed_ticks加一。当经过的时钟次数和预设的一致时，触发handler，这里并不需要我们主动去调用handler，将`trapframe`中记录返回地址的`epc`改为handler即可。同时，我们需要先将原来的`trapframe`保存下来，因为我们在调用完handler之后还需要返回用户进程timer中断时的运行位置。

---

注意：test 2 fork了一个新的进程同时并没有关闭test 1开启的alarm功能，所以我们需要修改fork()部分的代码，让新的进程和父进程的alarm状态一致。

## Lab5 Lazy Allocation

### Lab 5.1 Eliminate allocation from `sbrk()`

```c
uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  // if(growproc(n) < 0)
  //   return -1;
  // Only increase the size of the process
  // but allocate no memory for it
  myproc()->sz += n;
  return addr;
}
```

```tex
xv6 kernel is booting

init: starting sh
$ echo hi
usertrap(): unexpected scause 0x000000000000000f pid=3
            sepc=0x00000000000012ac stval=0x0000000000004008
panic: uvmunmap: not mapped
```

### Lab 5.2 Lazy Allocation

![image-20220601212451904](assets/Operating Systems.assets/image-20220601212451904.png)

```c
else if((which_dev = devintr()) != 0){
    // ok
  } else {
    // store/AMO page fault
    if(r_scause() == 15) {
      // 若发生了无法写入的page fault
      // 获取无法访问的虚拟地址
      // 这里访问不到的原因主要是我们加入了懒分配
      uint64 va = r_stval();
      uint64 va_downborder = PGROUNDDOWN(va);
      pagetable_t pagetable = p->pagetable;
      // 给该进程分配一页大小的物理内存
      uint64 pa = (uint64) kalloc();
      // 若物理内存已经满了，那么只能杀掉进程
      if(pa == 0) {
        p->killed = 1;
      }

      memset((void *)pa, 0, PGSIZE);
      // 使得用户无法访问的页表部分与新分配的物理内存建立映射
      // 给予她们可被读写的权限
      if(mappages(pagetable, va_downborder, PGSIZE, pa, PTE_W|PTE_R|PTE_U) != 0){
          kfree((void *) pa);
          p->killed = 1;
      }
      // 之后中断返回出现错误的程序地址，继续执行，这时之前无法读写的内存地址就可以读写了
    }
    else {
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
      p->killed = 1;
    }

  }
```

> trap有三种形式，这里是在exception的情况下添加代码。
>
> page fault一般有两种原因，如图中所示，13代表无法读，15代表无法写。这里的目的仅仅只为了能让`echo hi`正常运行，所以没有考虑过多细节。

### Lab 5.3 `Lazytests` and `Usertests`

> 实验5.2仅仅实现了一个基本的功能，但是他只支持为没有分配内存的虚拟地址空间增加内存，但没有考虑用户希望释放内存的请求
>
> 这一部分就是要解决这一类的边界问题，使得他具有完整的功能。

freewalk按照page的个数删除，然而现在我们的页表并不是连续的

![image-20220602222145739](assets/Operating Systems.assets/image-20220602222145739.png)

为什么会遇到这个问题，因为在我们缩小了sbrk以后

test02又尝试往没有映射的地方写数据，这时中断就又会给他分配空间，4就是这么被分配的

所以应该先判断va是否超出了size，若没有才能为它分配空间

`kernel trap问题`

user tests进不去，主要原因是`trap.c`逻辑太混乱了，需要改一改，错误原因在于当`kalloc`失败仅仅将killed设置成了1，但之后的正常逻辑依然会被执行。也就是说内核代码在修改pa==0地址的物理内存里的数据，所以kernel直接出发了device错误。

// remap 错误 我们虽然解决了用户直接去读写没有分配的va的情况，我们的解决方案是在walkaddr里判断va是不是在sz之中，是的话就分配。然而，这样一来，有些有pa��va也会被我们重新分批空间并remap，所以要在判断istouchable时再确定��������这个va是否���������映射过了。

![image-20220603144057553](assets/Operating Systems.assets/image-20220603144057553.png)
