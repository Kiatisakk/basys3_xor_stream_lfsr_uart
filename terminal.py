import serial
import serial.tools.list_ports
import threading
import sys
import time
from colorama import init, Fore, Style

# Initialize colorama
init(autoreset=True)

# ==========================================
# CONFIGURATION
# ==========================================
BAUD_RATE = 115200

# Input Mode (Text is default)
tx_mode = 'TEXT'

def print_header():
    print(Fore.CYAN + "="*60)
    print(Fore.CYAN + "      FPGA SMART TERMINAL (Auto-Port & Dual View)      ")
    print(Fore.CYAN + "="*60)

def list_and_select_port():

    print(Fore.YELLOW + "Scanning ports...", end='')
    ports = list(serial.tools.list_ports.comports())
    
    if not ports:
        print(Fore.RED + "\n[!] No serial ports found! Please check connection.")
        return None
    
    print(Fore.GREEN + " Done!\n")
    print("Available Ports:")
    for index, p in enumerate(ports):
        # p.device = COM3, p.description = USB Serial Port...
        print(f"  {Fore.MAGENTA}[{index + 1}]{Style.RESET_ALL} {p.device} - {p.description}")
        
    while True:
        try:
            choice = input(f"\n{Fore.YELLOW}Select Port (1-{len(ports)}): {Style.RESET_ALL}")
            selection = int(choice)
            if 1 <= selection <= len(ports):
                selected_port = ports[selection - 1].device
                print(f"Selected: {Fore.GREEN}{selected_port}{Style.RESET_ALL}")
                return selected_port
            else:
                print(Fore.RED + "Invalid number. Try again.")
        except ValueError:
            print(Fore.RED + "Please enter a number.")

def print_help():
    print("\nCommands:")
    print(f"  {Fore.YELLOW}/hex      {Style.RESET_ALL} : Switch Input to HEX mode")
    print(f"  {Fore.YELLOW}/text     {Style.RESET_ALL} : Switch Input to TEXT mode")
    print(f"  {Fore.YELLOW}/exit     {Style.RESET_ALL} : Quit")
    print("-" * 60)

def read_from_port(ser):
    while True:
        try:
            if ser.in_waiting > 0:
                time.sleep(0.05) 
                data = ser.read(ser.in_waiting)
                
                hex_str = ' '.join(f'{b:02X}' for b in data)
                text_str = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data)
                
                print(f"\n{Fore.GREEN}[RX] >> HEX : {hex_str}")
                print(f"{Fore.GREEN}       TXT : {text_str}{Style.RESET_ALL}")
                
                print(f"{Fore.YELLOW}>> {Style.RESET_ALL}", end='', flush=True)
        except:
            break

def main():
    global tx_mode
    print_header()
    
    selected_port = list_and_select_port()
    if not selected_port:
        input("Press Enter to exit...")
        return

    try:
        ser = serial.Serial(selected_port, BAUD_RATE, timeout=0.1)
        print(f"\n{Fore.CYAN}✅ Successfully connected to {selected_port} at {BAUD_RATE}{Style.RESET_ALL}")
    except serial.SerialException as e:
        print(Fore.RED + f"\n❌ Error: Could not open port {selected_port}")
        print(e)
        return

    print_help()
    print(f"Current Input Mode: {Fore.GREEN}{tx_mode}{Style.RESET_ALL}")

    t = threading.Thread(target=read_from_port, args=(ser,), daemon=True)
    t.start()

    while True:
        try:
            mode_str = "[HEX]" if tx_mode == 'HEX' else "[TXT]"
            user_input = input(f"{Fore.YELLOW}{mode_str} >> {Style.RESET_ALL}")
            
            # --- Commands ---
            if user_input.lower() in ['/exit', 'exit']:
                break
            elif user_input.lower() == '/hex':
                tx_mode = 'HEX'
                print(Fore.MAGENTA + "Input mode set to HEX (Format: 41 42 FF)")
                continue
            elif user_input.lower() == '/text':
                tx_mode = 'TEXT'
                print(Fore.MAGENTA + "Input mode set to TEXT")
                continue

            # --- Sending Logic ---
            data_to_send = b''
            
            if tx_mode == 'TEXT':
                data_to_send = user_input.encode('utf-8')
            
            elif tx_mode == 'HEX':
                clean = user_input.replace(" ", "").replace("0x", "").replace(",", "")
                try:
                    data_to_send = bytes.fromhex(clean)
                except ValueError:
                    print(Fore.RED + "Invalid HEX! Use format: 41 42 FF")
                    continue

            if len(data_to_send) > 0:
                ser.write(data_to_send)
                # Feedback
                print(Fore.BLUE + f"Sent ({len(data_to_send)} bytes)")
            
        except KeyboardInterrupt:
            break
        except serial.SerialException:
            print(Fore.RED + "\nDevice disconnected!")
            break

    ser.close()
    print("\nBye!")

if __name__ == "__main__":
    main()