#!/usr/bin/env python3
# Convert binary to hex format suitable for Verilog readmemh

import sys
import os

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input_bin> <output_hex>")
        sys.exit(1)
    
    input_bin = sys.argv[1]
    output_hex = sys.argv[2]
    
    with open(input_bin, 'rb') as infile:
        bin_data = infile.read()
    
    # Pad to 4-byte alignment if necessary
    if len(bin_data) % 4 != 0:
        bin_data += b'\x00' * (4 - (len(bin_data) % 4))
    
    with open(output_hex, 'w') as outfile:
        for i in range(0, len(bin_data), 4):
            # Read 4 bytes (little-endian word)
            word = bin_data[i:i+4]
            # Convert to hex in memory order (little-endian to big-endian for readmemh)
            hex_str = '{:02x}{:02x}{:02x}{:02x}'.format(word[3], word[2], word[1], word[0])
            outfile.write(hex_str + '\n')

if __name__ == "__main__":
    main()
