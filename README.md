This program uses [GBlinkDX](https://github.com/tzlion/gblinkdx) to backup your battery saves (SRAM). It is a demonstration project and cannot currently restore.


## Supported MBCs

It is supposed to support:

- 1
- 2
- 3
- 30
- 5

With any RAM size. However, I'm not sure if there is a standard way of saving MBC2 because it is too odd. MBC2 does not work with bytes but uses the low nibbles of 512 bytes. These 512 bytes are then repeated 15 more times. This tool saves all these 16 copies.

I only had MBC5 with 32 KiB of SRAM to test.


## Installation

Put this and [GBlinkDX](https://github.com/tzlion/gblinkdx) in the same folder. Tested with v0.4, because v0.5 doesn't work with my computer.


## Usage

- Run `gblinkdl.gb` from your flashcart (see GBlinkDX docs where to find it)
- Make a hotswap to your game of choice
- Plug in cable
- Run tool

You can pass the filename as an argument. If you don't, it becomes `output.sav`.


## To Do

- Restore
- Pass custom arguments
- Understand how to not pass useless arguments to GBlinkDX but still have it work...


## Comparison with [GB Save Manager](https://github.com/Gronis/gb-save-manager)

You need one Game Boy less. But instead you need:
- One more motherboard with parallel port
- If you don't have a compatible cable yet:
  - One Game Link cable you are willing to destroy (you can make two of these cables with just one destroyed link cable)
  - Depending on your motherboard:
    - If it has a parallel port: A parallel cable you are willing to destroy, plus some clips to fix the cables together.
    - If it has a parallel header: 4 to 7 DuPont wires, some hot glue, and your motherboard's manual to look up the pins.
 
When you make a cable, do note that the schematic on Brian's archived page shows the parallel _cable's plug_ but the Game Boy's Link _jack_.

|                                     | GB Save Manager | GBsavelink
| ----------------------------------- | --------------- | ----------
| **Needed Game Boys**                | 2               | 1
| **Need Flash Carts**                | 1               | 1
| **Needed Link Cables**              | 1               | 0
| **Needed MoBos with Parallel Port** | 0               | 1
| **Needed Parallel-to-Link Cables**  | 0               | 1
