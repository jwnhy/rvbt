# `rvbt` Baremetal Backtrace on RISC-V

[中文介绍](https://jwnhy.github.io/riscv/rvbt.html)

## What is it and why?

It provides a simple but useful backtrace in baremetal machine,
basically it links DWARF info into the binary and print them when backtrace the
program. Currently it only supports RISC-V architecture,
but I did not see any barrier to make it available in other architectures like x86.

When I am doing research, there is not a very good way to debug on a baremetal machine.
The only way my mentor tell me is to put log and use `objdump` to look for error.
It is fairly inefficient, now with **rvbt**,
you can directly know the exact file and line of exception.

## DEMO

![DEMO](https://i.loli.net/2021/06/22/KzNJrG2D5RS38po.png)

## How to use it?

Currently, it is pretty complex to use, but I will try to make it easy to use.
If you want to use it in your project, you need the following steps.

### 1. Compiler configuration

First you will need to force the compiler to use `fp` the frame pointer,
because `rvbt` reiles on it to backtrace. You also need to specify the link script.
So that the compiler know to leave room for DWARF info in the final binary.

```toml
[target.riscv64imac-unknown-none-elf]
rustflags = [
  "-C", "force-frame-pointers=yes", "-C", "link-arg=-Tlink-qemu-64.ld",
  
]
[build]
target = "riscv64imac-unknown-none-elf"
```

### 2. Copy DWARF info

As linkscript does not support **copy** sections around
and there is a 2M limit of `pc` relative addressing. So you need to use a script to
copy DWARF info into the final binary.

```bash
for sec in 'abbrev' 'addr' 'aranges' 'info' 'line' 'line_str' 'ranges' 'rnglists' 'str' 'str_offsets'; do \
    rust-objcopy {{PAYLOAD}} --dump-section .debug_$sec=tmp_$sec; \
    riscv64-unknown-elf-objcopy {{PAYLOAD}} --update-section .rvbt_$sec=tmp_$sec; \
done
rm tmp*; 
```

Now the program can use `extern "C"` keywords 
to access these link symbol to get the DWARF info.

### 3. Runtime parsing

In `src/init.rs`, a bunch of symbols are defined.

```rust
extern "C" {
    /*...*/
    fn _rvbt_abbrev_start();
    fn _rvbt_abbrev_end();
    /*...*/
}
```

You just need to call `debug_init` to initialize the DWARF context and
use the following code to perform backtrace.

```rust
    debug_init();
    trace(&mut |frame| {
        resolve_frame(frame, &|symbol| println!("{}", symbol));
        true
    });
```

## How it may be used?

With `rvbt`, you now can print out a more human readable information when
an exception/interrupt happends. You can put it in exception handler to help
you debug your baremetal program. Or you can use it to debug supervisor mode kernel.
As long as you can put the debugee program's DWARF info into `rvbt`.

## Future Work

- [x] Meaningful backtrace
- [ ] Cross-platform support
- [ ] More debug functionality, memory probing, breakpoint
- [ ] Space efficient DWARF storage
- [ ] Easy-to-use script/package
- [ ] crate.io publish

## Limitation

It will put a bunch of information into the binary,
so maybe it can only be used when you have sufficient memory.
But the DWARF info may be put in other places,
as long as the program can access it, this scheme can work.
