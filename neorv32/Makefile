.PHONY: all build clean

all: build

build:
	cd rust-hello-world && cargo build --release
	cd rust-hello-world && cargo objcopy --release -- -O binary ../hello_world.bin

clean:
	cd rust-hello-world && cargo clean
	rm -f hello_world.bin
