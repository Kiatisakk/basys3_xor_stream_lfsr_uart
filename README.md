# FPGA Stream Cipher via UART 🔐

Implementation of a Stream Cipher (XOR with LFSR Key) on **Basys3 FPGA**, controlled via a custom **Python Terminal**.

## 🚀 Features
- **Hardware Acceleration:** Encryption/Decryption happens on FPGA logic.
- **LFSR Key Generator:** 16-bit Linear Feedback Shift Register with customizable Seed.
- **Dual Mode Terminal:** Python script supporting both TEXT and HEX visualization.
- **FIFO Buffering:** Supports burst typing without data loss.

## 🛠 Hardware Used
- **Board:** Digilent Basys3 (Artix-7 FPGA)
- **Interface:** USB-UART (Baud rate 115200)

## 📂 Project Structure
- `rtl/`: SystemVerilog source codes (`Top_System`, `UART`, `LFSR`, etc.)
- `constraints/`: XDC file for Basys3 pin mapping.
- `python/`: `terminal.py` for PC communication.
- `ip/`: Xilinx IP Core configuration for FIFO Generator.

## 🎮 How to Use
1. **Flash:** Program the `.bit` file to Basys3.
2. **Setup:**
   - Set Seed switches (SW0-SW15).
   - Press **btnL** to Load Seed.
3. **Run Terminal:**
   ```bash
   python python/terminal.py
   
pip install -r python/requirements.txt
