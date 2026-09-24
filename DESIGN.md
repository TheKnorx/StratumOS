# Design choices for StratumOS
(More specifications will be added in the future...)

## Minimum Requirements
- 16 GiB of RAM
- CPU capable of protected mode and long mode

## Hardware / Drivers
This projects goal is to provide as many Prove-of-Concepts for hardware devices as possible, but nothing else further.

## Paging:
Paging is implemented by using Physical Address Extension (PAE) through a Page Map Level 4 Table (PML4T), effectively
producing an identity-mapping over addresses in the range of 0 up to 16 GiB (standard RAM size).<br>
That leaves 5.3 GiB for the kernel, and 5.3 GiB each for two processes.
---
## Kernel functionality
Planed is the implementation of the most used Linux syscalls, 

## Threads, Contexts, 
Planed is the implementation of threading, context switching and the use of multiple (virtual) CPU cores, allowing for 
processes to run simultaneously.