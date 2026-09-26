# StratumOS
Experimental x86-64 operating system and ELF runtime


<br><br>
## Milestones 🗿:
### Commit `14cb9b5`
Implemented PML4T paging with PAE for mapping 16 GiB into the virtual address space.

### Commit `098d42d`
The OS in the this state is capable of: 
1) being loaded by any multiboot compliant bootloader,
2) setting up paging for 64-Bit
3) and switching from 32-Bit protected mode to 64-Bit long mode.

