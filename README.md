# Simple Shell
A simple Unix-like shell implementation with advanced features and comprehensive testing framework.


## Features
- **Built-in Commands**: help, cd, echo, exit, record, replay, mypid
- **External Command Execution**: Support for single and multi-process pipelines
- **I/O Redirection**: Support for `<` and `>` redirection
- **Background Execution**: Support for `&` background execution
- **Command History**: Record and replay last 16 commands
- **Comprehensive Testing Framework**: Automated test suite ensures functionality correctness

## Quick Start
### Build and Run

```bash
# Build the project
make

# Run the shell
./my_shell
```

### Run Tests

```bash
# Run specific test using the quick test runner
./simple_tests/run_test.sh 01_single_command

# List all available tests
./simple_tests/run_test.sh
```

## Project Structure

```
.
├── include/             # Header files directory
│   ├── builtin.h        # Built-in command function definitions
│   ├── command.h        # Command parsing function definitions
│   └── shell.h          # Main shell process function definitions
├── src/                 # Source code directory
│   ├── builtin.c        # Built-in command implementations
│   ├── command.c        # Command parsing and data structure management
│   └── shell.c          # Main shell loop and process control
├── simple_tests/        # Simple testing framework directory
│   ├── 01_single_command/  # Single command tests
│   ├── 02_pipelines/       # Pipeline tests
│   ├── 03_redirection/     # Redirection tests
│   ├── 04_background/      # Background execution tests
│   ├── 05_multi_pipelines/ # Multi-pipeline tests
│   ├── 06_comprehensive/   # Comprehensive tests
│   ├── README.md          # Testing framework documentation
│   └── run_test.sh        # Quick test runner
├── obj/                 # Compiled object files directory (auto-generated)
├── my_shell.c           # Main program entry point
├── my_shell             # Executable file (auto-generated)
├── Makefile             # Build and clean commands
└── README.md            # This file
```

## Usage Examples

```bash
# Basic commands
$ ls -la
$ cd /tmp
$ echo "Hello World"

# Pipeline operations
$ ls | grep .txt
$ cat text.txt | head -4 | tail -2

# Redirection
$ echo "test" > output.txt
$ cat < input.txt

# Background execution
$ sleep 10 &

# Command history
$ record
$ replay 3
```

## Testing Framework

This project includes a simple and focused testing framework:

```bash
# List all available tests
./simple_tests/run_test.sh

# Run specific tests
./simple_tests/run_test.sh 01_single_command  # Single command execution
./simple_tests/run_test.sh 02_pipelines       # Pipeline functionality
./simple_tests/run_test.sh 03_redirection     # I/O redirection
./simple_tests/run_test.sh 04_background      # Background execution
./simple_tests/run_test.sh 05_multi_pipelines # Multi-pipeline tests
./simple_tests/run_test.sh 06_comprehensive   # Comprehensive tests
```

**Test Categories**:
- **01_single_command**: Basic single process command execution
- **02_pipelines**: Pipeline functionality tests
- **03_redirection**: I/O redirection tests
- **04_background**: Background execution tests
- **05_multi_pipelines**: Multi-pipeline tests
- **06_comprehensive**: Complex scenario tests

For detailed testing information:
- [simple_tests/README.md](simple_tests/README.md) - Testing framework documentation
- [simple_tests/01_single_command/README.md](simple_tests/01_single_command/README.md) - Single command test guide
- [simple_tests/02_pipelines/README.md](simple_tests/02_pipelines/README.md) - Pipeline test guide
- [simple_tests/03_redirection/README.md](simple_tests/03_redirection/README.md) - Redirection test guide
- [simple_tests/04_background/README.md](simple_tests/04_background/README.md) - Background execution test guide
- [simple_tests/05_multi_pipelines/README.md](simple_tests/05_multi_pipelines/README.md) - Multi-pipeline test guide
- [simple_tests/06_comprehensive/README.md](simple_tests/06_comprehensive/README.md) - Comprehensive test guide


## Build Options
```bash
make            # Standard build
make clean      # Clean build files
make rebuild    # Clean and rebuild
make debug      # Debug build
make release    # Optimized build
make run        # Build and run
make help       # Show all targets
```

## Built-in Commands

| Command | Description |
|---------|-------------|
| `help` | Show help information |
| `cd [dir]` | Change directory |
| `echo [-n] [text]` | Output text |
| `record` | Show command history |
| `replay N` | Re-execute command #N |
| `mypid [-i\|-p\|-c] [pid]` | Show process information |
| `exit` | Exit the shell |

## Requirements

- GCC compiler
- GNU/Linux system
- Standard C library

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License.
