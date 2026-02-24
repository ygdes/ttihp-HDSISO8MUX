![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout Project: HDSISO8_MUX

This is a prototype of a shift register that explores how to store data more densely than classic DFFs could, using the specific IHP CMOS PDK. This version uses sg13g2_mux2_1, another tile implements the exact same logic using the larger sg13g2_dlhq_1 for comparison.

SISO means Serial-In, Serial-Out, so it's not RAM since access is not random, but this non-randomness allows some clever tricks that optimise size, speed and power (static & dynamic) by eliminating the single general clock network. This implementation expects half the clock frequency and 4× clock load per cycle, for an effective 8× power reduction.

A complex synchronous-to-asynchronous-to-synchronous interface is needed to operate glitch-free, and apart from the small controller's overhead, this allows almost arbitrary depth at ~2× density. Expect P&R mayhem though because I can't do the manual layout.

The scalability comes from modularity: one IO block controls as many tranches as you like, which can be chained. Tranches come in sizes of 16, 64, 256 cells, each holding 12, 48 and 192 effective data bits. Here, 512 bits of depth requires 682 latches, assembling tranches of all sizes.

An extra LFSR is provided for extra testability, it can be used alone for something else but it allows frequency characterisation by using just a bench 'scope and a variable-frequency clock generator.

More info: see the /doc and reach me at https://hackaday.io/whygee
