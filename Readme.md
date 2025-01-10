# Zig Language Installer GitHub Action

This GitHub Action simplifies the installation of the [Zig programming language](https://ziglang.org) by downloading the specified version and flavor, verifying its integrity, and configuring the Zig binary for use in your workflows.

## Features

- Installs Zig from the official [Zig Downloads](https://ziglang.org/download/) page.
- Supports specifying Zig version (e.g., `master`, `0.13.0`) and build flavor (e.g., `x86_64-linux`, `aarch64-macos`).
- Verifies the SHA256 checksum for download integrity.
- Automatically installs missing dependencies (`curl`, `jq`, etc.) if required.
- Adds the Zig binary to the system's `PATH`.

## Usage

Add the following to your workflow YAML file:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Install Zig
        uses: iambnlvn/zig-action
        with:
          version: "master" # Specify the Zig version (e.g., master, 0.11.0)
          flavor: "x86_64-linux" # Specify the build flavor
```

### Inputs

| **Name**  | **Description**                                                            | **Required** | **Default** |
| --------- | -------------------------------------------------------------------------- | ------------ | ----------- |
| `version` | The version of Zig to install (e.g., `master`, `0.13.0`).                  | Yes          | `master`    |
| `flavor`  | The build flavor to install (e.g., `x86_64-linux`, `aarch64-macos`, etc.). | Yes          | None        |

### Outputs

| **Name**  | **Description**                       |
| --------- | ------------------------------------- |
| `zig-bin` | The path to the installed Zig binary. |

### Supported Flavors

The following build flavors are supported:

| **Flavor**          | **Description**              |
| ------------------- | ---------------------------- |
| `x86_64-linux`      | 64-bit Linux                 |
| `x86_64-windows`    | 64-bit Windows               |
| `aarch64-linux`     | ARM 64-bit Linux             |
| `x86-linux`         | 32-bit Linux                 |
| `aarch64-windows`   | ARM 64-bit Windows           |
| `x86-windows`       | 32-bit Windows               |
| `x86_64-macos`      | 64-bit macOS                 |
| `aarch64-macos`     | ARM 64-bit macOS             |
| `riscv64-linux`     | RISC-V 64-bit Linux          |
| `powerpc64le-linux` | PowerPC 64-bit Little Endian |
| `powerpc-linux`     | PowerPC                      |
| `bootstrap`         | Bootstrap build              |
| `src`               | Source code                  |

### Dependencies

Ensure the following dependencies are installed on the system:

| **Dependency** | **Description**                                                |
| -------------- | -------------------------------------------------------------- |
| `curl`         | Used for downloading files.                                    |
| `jq`           | Used for parsing JSON data.                                    |
| `coreutils`    | Provides utilities like `sha256sum` for checksum verification. |
| `tar`          | Used for extracting tarball files.                             |

The script will attempt to install missing dependencies automatically if `sudo` access is available.

### Development and Testing

#### Run Locally

To test the script locally:

1. Clone the repository.
2. Execute the `install.sh` script with the desired arguments:

   ```bash
   chmod +x install.sh
   ./install.sh [version] [flavor]
   ```

### Example

```bash
./install.sh 0.13.0 x86_64-linux
```

### Troubleshooting

If the action fails:

1. Verify the `version` and `flavor` inputs are correct.
2. Check the `fetch_errors.log` file for detailed error messages.
3. Ensure that `sudo` privileges are available for installing dependencies.
4. Confirm that your system meets the dependency requirements.
