# StratumOS
Experimental x86-64 operating system and ELF runtime

---

### System V ABI 32 Bit:
- Integer/General Purpose: `ebx`, `esi`, `edi`, `ebp`, `esp`
- Floating-Point: The `x87` control word is preserved, but most `x87` data registers are caller-saved.
### System V ABI 64 Bit:
- Integer/General Purpose: `rbx`, `rbp`, `r12`, `r13`, `r14`, `r15`
- Stack Pointer: `rsp` (must be maintained/restored)
- Floating-Point: `xmm6` through `xmm15` 