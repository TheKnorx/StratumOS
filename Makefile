x86_64_src_path		:= src/x86_64
x86_64_build_path 	:= build/x86_64
x86_64_dist_path 	:= dist/x86_64
x86_64_target_path 	:= targets/x86_64

x86_64_asm_source_files := $(shell find $(x86_64_src_path) -name *.asm)
x86_64_asm_cpp_files 	:= $(patsubst $(x86_64_src_path)/%.asm, $(x86_64_build_path)/%.s, $(x86_64_asm_source_files))
x86_64_asm_object_files := $(patsubst $(x86_64_build_path)/%.s, $(x86_64_build_path)/%.o, $(x86_64_asm_cpp_files))

x86_64_c_source_files 	:= $(shell find $(x86_64_src_path) -name *.c)
x86_64_c_object_files 	:= $(patsubst $(x86_64_src_path)/%.c, $(x86_64_build_path)/%.o, $(x86_64_c_source_files))

# create the preprocessor assembly files ==> .asm -> .s
$(x86_64_build_path)/%.s: $(x86_64_src_path)/%.asm
	mkdir -p $(dir $@)
	cpp -x assembler-with-cpp  $< -o $@

# make object files from preprocessor assembly files ==> .s -> .o
$(x86_64_build_path)/%.o: $(x86_64_build_path)/%.s
	mkdir -p $(dir $@)
	nasm -f elf64 $< -o $@

# make object files from C files ==> .c -> .o
$(x86_64_build_path)/%.o: $(x86_64_src_path)/%.c
	mkdir -p $(dir $@)
	gcc -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -c $< -o $@

# throw everything together and we have a kernel
.PHONY: build-x86_64
build-x86_64: $(x86_64_asm_object_files) $(x86_64_c_object_files)
	mkdir -p $(x86_64_dist_path)
	ld -n -o $(x86_64_dist_path)/kernel.bin \
		-T $(x86_64_target_path)/linker.ld \
		$(x86_64_asm_object_files) $(x86_64_c_object_files)
	cp $(x86_64_dist_path)/kernel.bin \
		$(x86_64_target_path)/iso/boot/kernel.bin
	grub-mkrescue /usr/lib/grub/i386-pc \
		-o $(x86_64_dist_path)/kernel.iso \
		$(x86_64_target_path)/iso

.PHONY: run
run: build-x86_64
	qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso

debug: build-x86_64
	qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso -monitor stdio -s -S -d cpu_reset

.PHONY: clean
clean:
	rm -R ./build/ ./dist targets/x86_64/iso/boot/kernel.bin