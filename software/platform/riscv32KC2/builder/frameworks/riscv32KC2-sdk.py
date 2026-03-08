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

from os import listdir
from os.path import isdir, join
import sys

from SCons.Script import DefaultEnvironment

env = DefaultEnvironment()
board = env.BoardConfig()
build_board = board.id

FRAMEWORK_DIR = env.PioPlatform().get_package_dir("framework-riscv32KC2-sdk")
assert FRAMEWORK_DIR and isdir(FRAMEWORK_DIR)

build_mabi = board.get("build.mabi", "ilp32").lower().strip()
build_march = board.get("build.march", "rv32imac").lower().strip()
build_mcmodel = board.get("build.mcmodel", "medany").lower().strip()
build_download_mode = board.get("build.download", "iram").lower().strip()

if not board.get("build.ldscript", ""):
    ld_script = "linker.lds"
    build_ldscript = join(FRAMEWORK_DIR, "bsp", "env", build_board, ld_script)
    if not isdir(join(FRAMEWORK_DIR, "bsp", "env", build_board)):
        # Fallback to project directory linker script
        build_ldscript = join("$PROJECT_DIR", "linker.lds")
    env.Replace(LDSCRIPT_PATH=build_ldscript)
else:
    print("Use user defined ldscript %s" % board.get("build.ldscript"))

env.SConscript("_bare.py", exports="env")

env.Append(
    CCFLAGS=[
        "-march=%s" % build_march,
        "-mabi=%s" % build_mabi,
        "-mcmodel=%s" % build_mcmodel,
        "-ffunction-sections",
        "-fdata-sections",
        "-fno-builtin-printf",
        "-fno-builtin-malloc"     
    ],

    ASFLAGS=[
        "-march=%s" % build_march,
        "-mabi=%s" % build_mabi,
        "-mcmodel=%s" % build_mcmodel,
        "-ffunction-sections",
        "-fdata-sections",
        "-fno-builtin-printf",
        "-fno-builtin-malloc"                               
    ],

    LINKFLAGS=[
        "-march=%s" % build_march,
        "-mabi=%s" % build_mabi,
        "-mcmodel=%s" % build_mcmodel,
        "-ffunction-sections",
        "-fdata-sections",
        "-fno-builtin-printf",
        "-fno-builtin-malloc",        
        "-nostartfiles",
        "--specs=nano.specs",
        "--specs=nosys.specs",
        "-Wl,--gc-sections",
        "-Wl,--wrap=scanf",
        "-Wl,--wrap=malloc",
        "-Wl,--wrap=printf",
        "-Wl,--check-sections",
        "-u", "_isatty",
        "-u", "_write",
        "-u", "_init"    
    ],

    CPPPATH=[
        "$PROJECT_SRC_DIR",
        "$PROJECT_INCLUDE_DIR",   
        join(FRAMEWORK_DIR, "bsp", "env"),
        join(FRAMEWORK_DIR, "bsp", "include")
    ]
)

print("Building with framework-riscv32KC2-sdk")
print("  Framework DIR: %s" % FRAMEWORK_DIR)
print("  Linker Script: %s" % env.get("LDSCRIPT_PATH", "Not set"))
print("  Architecture: %s" % build_march)
print("  ABI: %s" % build_mabi)

#
# Target: Build SDK Libraries
#

libs = []

# Build environment/startup code
if isdir(join(FRAMEWORK_DIR, "bsp", "env")):
    libs.append(
        env.BuildLibrary(
            join("$BUILD_DIR", "bsp", "env"),
            join(FRAMEWORK_DIR, "bsp", "env")
        ) 
    )

# Build BSP source code
if isdir(join(FRAMEWORK_DIR, "bsp", "src")):
    libs.append(
        env.BuildLibrary(
            join("$BUILD_DIR", "bsp", "src"),
            join(FRAMEWORK_DIR, "bsp", "src")
        ) 
    )

# Build libwrap drivers
if isdir(join(FRAMEWORK_DIR, "bsp", "libwrap")):
    for driver in listdir(join(FRAMEWORK_DIR, "bsp", "libwrap")):
        driver_path = join(FRAMEWORK_DIR, "bsp", "libwrap", driver)
        if isdir(driver_path):
            libs.append(
                env.BuildLibrary(
                    join("$BUILD_DIR", "bsp", "libwrap", driver),
                    driver_path
                )
            )

env.Prepend(LIBS=libs)


