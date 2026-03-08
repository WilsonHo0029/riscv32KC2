# Copyright 2024-present AI RISC-V KC32
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
from platform import system
from os import makedirs
from os.path import isdir, join

from SCons.Script import (ARGUMENTS, COMMAND_LINE_TARGETS, AlwaysBuild,
                          Builder, Default, DefaultEnvironment)

env = DefaultEnvironment()
platform = env.PioPlatform()
board_config = env.BoardConfig()

env.Replace(
    AR="riscv-none-elf-ar",
    AS="riscv-none-elf-as",
    CC="riscv-none-elf-gcc",
    GDB="riscv-none-elf-gdb",
    CXX="riscv-none-elf-g++",
    OBJCOPY="riscv-none-elf-objcopy",
    RANLIB="riscv-none-elf-gcc-ranlib",
    SIZETOOL="riscv-none-elf-size",

    ARFLAGS=["rc"],

    SIZEPRINTCMD='$SIZETOOL -d $SOURCES',

    PROGSUFFIX=".elf"
)

# Allow user to override via pre:script
if env.get("PROGNAME", "program") == "program":
    env.Replace(PROGNAME="firmware")

env.Append(
    BUILDERS=dict(
        ElfToHex=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJCOPY",
                "-O",
                "ihex",
                "$SOURCES",
                "$TARGET"
            ]), "Building $TARGET"),
            suffix=".hex"
        ),
        ElfToBin=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJCOPY",
                "-O",
                "binary",
                "$SOURCES",
                "$TARGET"
            ]), "Building $TARGET"),
            suffix=".bin"
        ),
        ElfToVerilog=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJCOPY",
                "-O",
                "verilog",
                "$SOURCES",
                "$TARGET"
            ]), "Building $TARGET"),
            suffix=".verilog"
        )
    )
)

if not env.get("PIOFRAMEWORK"):
    env.SConscript("frameworks/_bare.py", exports="env")

#
# Target: Build executable and linkable firmware
#

target_elf = None
if "nobuild" in COMMAND_LINE_TARGETS:
    target_elf = join("$BUILD_DIR", "${PROGNAME}.elf")
    target_hex = join("$BUILD_DIR", "${PROGNAME}.hex")
    target_bin = join("$BUILD_DIR", "${PROGNAME}.bin")
else:
    target_elf = env.BuildProgram()
    target_hex = env.ElfToHex(join("$BUILD_DIR", "${PROGNAME}"), target_elf)
    target_bin = env.ElfToBin(join("$BUILD_DIR", "${PROGNAME}"), target_elf)

AlwaysBuild(env.Alias("nobuild", target_elf))
target_buildprog = env.Alias("buildprog", target_elf, target_elf)

#
# Target: Print binary size
#

target_size = env.Alias(
    "size", target_elf,
    env.VerboseAction("$SIZEPRINTCMD", "Calculating size $SOURCE"))
AlwaysBuild(target_size)

#
# Target: Upload by default .elf file
#

upload_protocol = env.subst("$UPLOAD_PROTOCOL")
debug_tools = board_config.get("debug.tools", {})
download_mode = board_config.get("build.download", "iram").lower().strip()
upload_actions = []
upload_target = target_elf

FRAMEWORK_DIR = env.PioPlatform().get_package_dir("framework-riscv32KC2-sdk")
board_id = board_config.id

# Determine OpenOCD config directory
openocd_config_dir = join(FRAMEWORK_DIR, "bsp", "env", board_id)
if not isdir(openocd_config_dir):
    # Fallback to project directory
    openocd_config_dir = "$PROJECT_DIR"

openocd_args = [
    "-s", openocd_config_dir
]

print("Download mode: %s" % download_mode)

if download_mode in ("iram"):
    # Load to Instruction RAM at 0x80000000
    openocd_args.extend([ 
        debug_tools.get(upload_protocol).get("server").get("arguments", []),
        "-c", "reset halt; load_image {$SOURCE}; resume 0x80000000; shutdown;"
    ])
else:
    # Default: load to Instruction RAM
    openocd_args.extend([ 
        debug_tools.get(upload_protocol).get("server").get("arguments", []),
        "-c", "reset halt; load_image {$SOURCE}; resume 0x80000000; shutdown;"
    ])   

env.Replace(
    UPLOADER="openocd",
    UPLOADERFLAGS=openocd_args,
    UPLOADCMD="$UPLOADER $UPLOADERFLAGS")

upload_actions = [env.VerboseAction("$UPLOADCMD", "Uploading $SOURCE")]

AlwaysBuild(env.Alias("upload", upload_target, upload_actions))

#
# Setup default targets
#

Default([target_buildprog, target_size])



