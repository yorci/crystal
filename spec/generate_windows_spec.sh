#! /usr/bin/env bash
set +x

# This script iterates through each spec file and tries to build and run it.
#
# * `failed codegen` annotates specs that error in the compiler.
#   This is mostly caused by some API not being ported to win32 (either the spec
#   target itself or some tools used by the spec).
# * `failed linking` annotates specs that compile but don't link (at least not on
#   basis of the libraries from *Porting to Windows* guide).
#   Most failers are caused by missing libraries (libxml2, libyaml, libgmp,
#   libllvm, libz, libssl), but there also seem to be some incompatibilities
#   with the existing libraries.
# * `failed to run` annotates specs that compile and link but don't properly
#   execute.
#
# PREREQUISITES:
#
# This script requires a working win32 build environment as described in
# the [*Porting to Windows* guide](https://github.com/crystal-lang/crystal/wiki/Porting-to-Windows)
#
# USAGE:
#
# For std spec:
# $ spec/generate_windows_spec.cr > spec/win32_std_spec.cr
# For compiler spec:
# $ spec/generate_windows_spec.cr compiler > spec/win32_compiler_spec.cr

SPEC_SUITE=${1:-std}
CRYSTAL_BIN=${CRYSTAL_BIN:-./crystal.exe}

command="$0 $*"
echo "# This file is autogenerated by \`${command% }\`"
echo "# $(date --rfc-3339 seconds)"
echo

for spec in $(find "spec/$SPEC_SUITE" -type f -iname "*_spec.cr" | LC_ALL=C sort); do
  require="require \"./${spec##spec/}\""

  if ! output=$($CRYSTAL_BIN build "$spec" -Di_know_what_im_doing -Dwithout_openssl 2>&1); then
    if [[ "$output" =~ "execution of command failed" ]]; then
      echo "# $require (failed linking)"
    else
      echo "# $require (failed codegen)"
    fi
    continue
  fi

  binary_path="./$(basename $spec .cr).exe"

  "$binary_path" > /dev/null; exit=$?

  if [ $exit -eq 0 ] || [ $exit -eq 1 ]; then
    echo "$require"
  else
    echo "# $require (failed to run)"
  fi
done
