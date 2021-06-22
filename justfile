TARGET := "riscv64imac-unknown-none-elf"
BINARY := "<Your Binary Here>"
PAYLOAD := "target/"+TARGET+"/debug/"+BINARY

build:
	cargo build

copy-debug:
	for sec in 'abbrev' 'addr' 'aranges' 'info' 'line' 'line_str' 'ranges' 'rnglists' 'str' 'str_offsets'; do \
		rust-objcopy {{PAYLOAD}} --dump-section .debug_$sec=tmp_$sec; \
		riscv64-unknown-elf-objcopy {{PAYLOAD}} --update-section .rvbt_$sec=tmp_$sec; \
	done
	rm tmp*; 
