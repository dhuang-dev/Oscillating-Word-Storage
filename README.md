# Oscillating-Word-Storage
Word storage that oscillates 4-letter words on a singular SSD under a 555 timer clock, with complete ALU and RAM8 word storage.

# Asynchronous Multi-Clock Word Display System (JOIN v2)

An FPGA-targeted digital system written in SystemVerilog that stores multi-character word payloads into RAM and cycles their display across an asynchronous clock-domain boundary on a single 7-segment display (SSD).

## 📌 Architecture Overview

The system processes **20-bit words**, where each word stores four concatenated **5-bit character indices** ($4 \text{ letters} \times 5 \text{ bits/letter} = 20 \text{ bits}$). This provides a full 32-character alphabet capability (A–Z plus custom symbols).

## 🔑 Key Engineering Concepts

### 1. Clock Domain Crossing (CDC) & Metastability Protection
The display counter runs on an independent slow clock (`slow_clk`), simulating an external 555-timer relaxation oscillator. To pass this counter value into the main clock domain (`clk`) safely:
* **Gray Code Encoding:** The counter increments using Gray code (`00` -> `01` -> `11` -> `10`), ensuring **only one bit changes per clock cycle**.
* **2-Flop Synchronizer:** A 2-stage flip-flop synchronizer (`cdc_sync2`) synchronizes the Gray code across domains, eliminating multi-bit bus skew hazards and metastability.

### 2. Concatenated Datapath Multiplexing
Instead of storing multi-character words in separate memory locations, four 5-bit character codes are packed into a single 20-bit vector. A 4-to-1 chunk multiplexer selects slices (`word_in[pos*5 +: 5]`) to feed the active-low character decoder.

+------------------+     +------------+     +---------+     +----------+
| 20-bit Switches  |---->| Reg A / D  |---->| ALU 20  |---->| RAM8     |
+------------------+     +------------+     +---------+     |(20-bit)  |
                                                            +----------+
| (display_word)
v

+------------------+     +------------+     +---------+  +------------+  +---------+
| slow_clk (555)   |---->| Gray Pos   |---->| 2FF CDC |--| Chunk Mux  |->| 7-Seg   |
| Asynchronous Domain|   | Counter    |     | Sync    |  | (5-bit)    |  | Decoder |
+------------------+     +------------+     +---------+  +------------+  +---------+

## 📁 Repository Structure

text
├── rtl/
│   ├── alu20.sv                 # 20-bit Hack-style ALU
│   ├── register20.sv            # 20-bit general-purpose registers
│   ├── ram8_20bit.sv            # 8-word x 20-bit RAM memory
│   ├── debounce_pulse.sv        # Button debouncer & edge detector
│   ├── gray_position_counter.sv # Asynchronous Gray code counter
│   ├── cdc_sync2.sv             # 2FF CDC Synchronizer
│   ├── chunk_mux.sv             # 5-bit slice selector
│   ├── char_decoder.sv          # 5-bit to 7-segment display decoder
│   └── join_ssd_top.sv          # Top-level system wrapper
├── tb/
│   └── join_ssd_tb.sv           # Self-checking simulation testbench
└── README.md

### **3. Two Ways to Run the Device**
There are two ways we can view this project. First, on a physical FPGA, we have to manually adjust data switches and load pushbuttons to manually drive inputs with fingers to change the word we want on the SSD. Second, we can use a computer system to program new 4 letter words into the 20-bit RAM8 memory through Python, Arduino/Raspberry Pi, or other microcontrollers with software instructions.

+--------------------------+
 | Physical Switches/Btns   |-------\
 +--------------------------+        \     +------------------+     +------------------+
                                      ====>| Input Select Mux |====>| Processor /      |
 +--------------------------+        /     +------------------+     | Datapath         |
 | SPI Slave Subsystem      |-------/               ^               | (A, D, RAM8)     |
 | (sclk, cs_n, mosi, miso) |                       |               +------------------+
 +--------------------------+                 Mode Switch
                                          (0 = Manual, 1 = SPI)

🚀 How to Run Simulation
Using Icarus Verilog & GTKWave
Bash
iverilog -g2012 -o sim_out rtl/*.sv tb/join_ssd_tb.sv
vvp sim_out
gtkwave wave.vcd
