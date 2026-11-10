import spidev
import time

# Letter mappings: J=9, O=14, I=8, N=13
def encode_word(c0, c1, c2, c3):
    return (c3 << 15) | (c2 << 10) | (c1 << 5) | c0

spi = spidev.SpiDev()
spi.open(0, 0)
spi.max_speed_hz = 1000000 # 1 MHz SPI clock

# Send word "JOIN" to RAM slot 2
word_val = encode_word(9, 14, 8, 13) # J, O, I, N
cmd_byte = 0x3 # Command 3 = Write to RAM

# Package 24-bit frame: [Cmd (4 bits) | Reserved (4 bits)] + [Data (16 bits)]
packet = [ (cmd_byte << 4) | ((word_val >> 16) & 0x0F),
           (word_val >> 8) & 0xFF,
           word_val & 0xFF ]

spi.xfer2(packet)
print("Successfully wrote 'JOIN' to FPGA memory over SPI!")