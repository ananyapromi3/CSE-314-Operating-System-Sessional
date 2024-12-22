# CSE-314-Operating-System-Sessional

## Cloning codebase:
git clone https://github.com/shuaibw/xv6-riscv --depth=1
## Compile and run (from inside xv6-riscv directory):
make clean; make qemu
## Generating patch (from inside xv6-riscv directory):
git add --all; git diff HEAD > <patch file name>
e.g.: git add --all; git diff HEAD > ../test.patch
## Applying patch:
git apply --whitespace=fix <patch file name>
e.g.: git apply --whitespace=fix ../test.patch
## Cleanup git directory:
git clean -fdx; git reset --hard

