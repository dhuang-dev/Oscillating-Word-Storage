import spidev
import time

#Example of using JOIN to the SSD
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

#for words in general
def encode_word(word: str) -> int:
    # 1. Force uppercase, pad with spaces if <4 chars, and slice to exactly 4 chars
    word = word.upper().ljust(4)[:4]
    packed = 0

    # 2. Loop through each character with its index (i = 0, 1, 2, 3)
    for i, char in enumerate(word):
        # 3. Convert letter to 0-25 index ('A'=0, 'B'=1, ..., 'J'=9, 'N'=13, 'O'=14, 'I'=8)
        code = ord(char) - ord('A')

        # 4. Mask to 5 bits (& 0x1F) and shift left into its 5-bit slot (0, 5, 10, 15)
        packed |= (code & 0x1F) << (i * 5)

    return packed