#!/usr/bin/env python3
"""
Binary to Hex Converter for RISC-V Memory Images
=================================================

Converts binary files to various hex formats suitable for Verilog memory
initialization and other uses.
"""

import argparse
import sys
from pathlib import Path
from typing import Optional


class BinaryToHexConverter:
    """Convert binary files to hex format suitable for Verilog $readmemh."""
    
    def __init__(self, word_size: int = 4, endianness: str = "little"):
        """
        Initialize the converter.
        
        Args:
            word_size: Size of each word in bytes (default: 4 for 32-bit)
            endianness: Byte order - "little" or "big" (default: "little")
        """
        self.word_size = word_size
        self.endianness = endianness
    
    def convert(self, input_file: Path, output_file: Path, min_words: int = 0) -> None:
        """
        Convert binary file to hex format.
        
        Args:
            input_file: Path to input binary file
            output_file: Path to output hex file
            min_words: Minimum number of words to output (pad with zeros if needed)
        """
        with open(input_file, 'rb') as f:
            data = f.read()
        
        # Pad to word alignment
        while len(data) % self.word_size != 0:
            data += b'\x00'
        
        # Calculate how many words we'll write
        words_to_write = max(len(data) // self.word_size, min_words)
        
        print(f"Converting binary: {len(data)} bytes, padding to {words_to_write} words")
        
        with open(output_file, 'w') as f:
            # Write data from binary file
            for i in range(0, len(data), self.word_size):
                word = data[i:i+self.word_size]
                if len(word) < self.word_size:
                    # Pad last word if needed
                    word = word + b'\x00' * (self.word_size - len(word))
                
                if self.endianness == "little":
                    # Little endian: least significant byte first
                    val = int.from_bytes(word, byteorder="little")
                else:
                    # Big endian: most significant byte first
                    val = int.from_bytes(word, byteorder="big")
                
                f.write(f"{val:0{self.word_size*2}x}\n")
            
            # Fill remaining words with zeros if min_words > actual words
            remaining_words = words_to_write - (len(data) // self.word_size)
            if remaining_words > 0:
                for _ in range(remaining_words):
                    f.write("00000000\n")
    
    def get_info(self, input_file: Path) -> dict:
        """Get information about the binary file."""
        with open(input_file, 'rb') as f:
            data = f.read()
        
        return {
            "size_bytes": len(data),
            "size_words": (len(data) + self.word_size - 1) // self.word_size,
            "word_size": self.word_size,
            "endianness": self.endianness
        }


def main():
    """Command-line interface for the converter."""
    parser = argparse.ArgumentParser(
        description="Convert binary files to hex format for Verilog memory initialization"
    )
    parser.add_argument("input", type=Path, help="Input binary file")
    parser.add_argument("output", type=Path, help="Output hex file")
    parser.add_argument(
        "--word-size", type=int, default=4,
        help="Word size in bytes (default: 4)"
    )
    parser.add_argument(
        "--endianness", choices=["little", "big"], default="little",
        help="Byte order (default: little)"
    )
    parser.add_argument(
        "--info", action="store_true",
        help="Show information about the input file"
    )
    
    args = parser.parse_args()
    
    if not args.input.exists():
        print(f"Error: Input file {args.input} not found", file=sys.stderr)
        sys.exit(1)
    
    converter = BinaryToHexConverter(args.word_size, args.endianness)
    
    if args.info:
        info = converter.get_info(args.input)
        print(f"File: {args.input}")
        print(f"Size: {info['size_bytes']} bytes ({info['size_words']} words)")
        print(f"Word size: {info['word_size']} bytes")
        print(f"Endianness: {info['endianness']}")
    
    try:
        converter.convert(args.input, args.output)
        print(f"Converted {args.input} to {args.output}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
