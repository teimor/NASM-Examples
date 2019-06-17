![](https://img.shields.io/badge/OS-GNU%2FLinux-green.svg) ![](https://img.shields.io/badge/arch-x86__64-orange.svg) ![](https://img.shields.io/badge/Assembler-NASM-blue.svg) ![](https://img.shields.io/badge/license-MIT-green.svg)

# NASM Examples

Examples of using NASM language on Linux based system, some of the examples are calling c standard library functions using NASM.

## Getting Started

### Requerments

- Linux machine, Ubuntu is recommended (Use only 64-bit version).
- Run `gcc -v` command, if version is under 7 do "gcc Upgrade process"
- Install NASM by `sudo apt-get install nasm
- Check NASM installed correctly by useing : `nasm -v

### gcc Upgrade process

1. Add gcc repository : `sudo add-apt-repository ppa:jonathonf/gcc`
2. Update apt-get : `sudo apt-get update`
3. Install gcc7 : `sudo apt-get install gcc-7 g++-7`
4. Set gcc as default : `sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7`
5. Test gcc version : `gcc -v` and see the version is 7 or above

## Examples

### 1st Example - "Hello World"

Simple code example that using c standard library `printf` function to print Hello World.

#### How to complie and run

**Compile command**

Compiling the code with NASM.

```shell
nasm -f elf64 -o hello_world.o hello_world.asm
```

**Linker proccess**

gcc is our linker.

```shell
gcc -no-pie -m64 -o hello_world hello_world.o
```

**Run the program**

```shell
./hello_world
```

#### One line command

Using the command, we will compile, link and run the code:

```shell
nasm -f elf64 -o hello_world.o hello_world.asm && gcc -no-pie -m64 -o hello_world hello_world.o && ./hello_world
```

#### Makefile

You can also just use the makefile in the folder and then use the `make` command.

### 2nd Example - Square

When three numbers are given: X, Y, Z. The program calculates the distance function - sqrt(x^2+y^2+z^2). In this example, you can see the use of `XMM0` - `XMM15` registers. Those can be used for floating point numbers and for more complex calculation such as `mulsd` (Multiply Scalar Double-Precision Floating-Point).

### 3rd Example - Find Integers and Floating point numbers

In this example, the program is reading an external file and searching for integers & floating point numbers. In this example, you can see how to read an external file and also how to use  `atoll` & `atof` functions for converting chars and strings to a numeric value.

### 4th and 5th Examples - Threads Calcualtion

In those examples, you can see how to use threads in NASM. In both examples, the program at first gets from the user the number of lines and threads to use. Then the program will fill up the memory with random numbers and calculate the average of the random number and the deviation.

In the 4th example, the memory filling & calculation is done by multiple threads but it contains a bottleneck in the calculation process due that only one thread can access the memory every time. In order to fix the bottleneck, In the 5th Example at first, the program is filling the memory with random numbers and only the calculation is done by parallel threads. Each thread gets a specific range of memory it can access and in this way, the program uses threads in a more efficient way.



### License

This project is licensed under the MIT License.



### Additional Information and links

- [Assembly Programming Tutorial by Tutorialspoint](https://www.tutorialspoint.com/assembly_programming/index.htm)
- [NASM Online Compiler by Tutorialspoint](https://www.tutorialspoint.com/compile_asm_online.php)
- [NASM Tutorial by Ray Toal from Loyola Marymount University](https://cs.lmu.edu/~ray/notes/nasmtutorial/)
- [Sample 64-bit nasm programs by Maryland University](https://web.archive.org/web/20161008080537/http://www.csee.umbc.edu/portal/help/nasm/sample_64.shtml)

### Github Projects with good Examples

- [Assembly-step-by-step by Poonam Mishra](https://github.com/mish24/Assembly-step-by-step)
- [Assembly-Language-Lab by Amit Roy](https://github.com/AmitRoy7/Assembly-Language-Lab)
- [Assembly-Collection by Angelo Moura](https://github.com/m4n3dw0lf/Assembly-x64)
- [S4-NASM by Arjun Lal](https://github.com/theSleepDeprivedCoder/S4-NASM)
- [Doing Things with Assembly Language and NASM by Ken Mathieu Sternberg](https://github.com/elfsternberg/asmtutorials)

