#!/usr/bin/env python3
import sys

def bin_to_hex(input_file, output_file):
    """Convert binary file to hex format suitable for Verilog $readmemh"""
    with open(input_file, 'rb') as f:
        data = f.read()
    
    # Pad to 4-byte alignment
    while len(data) % 4 != 0:
        data += b'\x00'
    
    with open(output_file, 'w') as f:
        for i in range(0, len(data), 4):
            # Read 4 bytes and convert to little-endian 32-bit word
            word = data[i:i+4]
            if len(word) == 4:
                # Convert to little-endian 32-bit value
                val = (word[3] << 24) | (word[2] << 16) | (word[1] << 8) | word[0]
                f.write(f"{val:08x}\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python bin_to_hex.py input.bin output.hex")
        sys.exit(1)
    
    bin_to_hex(sys.argv[1], sys.argv[2])
    print(f"Converted {sys.argv[1]} to {sys.argv[2]}")
