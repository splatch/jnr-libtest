#!/usr/bin/env bash

set -euo pipefail

java_home="${1?no java home given}"
libname="${2?no lib name given}"
version="${3?no version given}"
dockcross_image="${4?no arch given}"
classifier="${5?no classifier given}"
link_mode="${6?no link mode}"
build_os="${7:-linux}"

# c99 doesn't fly very well..
#cc_opts=('-shared' '-std=c99' '-fPIC' '-D' "MVN_VERSION=$version")
cc_opts=('-shared' '-fPIC' '-D' "MVN_VERSION=$version")

if grep -Pq -- '-SNAPSHOT$' <<<"$version"; then
    cc_opts+=('-g3' '-Og')
else
    cc_opts+=('-O2' '-flto')
fi

relative_output_dir="target"

src="src/main/c"

compiler_dir="${relative_output_dir}/cross-compile"

export DOCKCROSS_IMAGE=${dockcross_image}

echo "Compiling for: ${classifier} (dockcross: ${dockcross_image})"
compiler_output_dir="${compiler_dir}/${classifier}"
mkdir -p "$compiler_output_dir" 2>/dev/null
proxy="${compiler_output_dir}/proxy"
#docker pull "$dockcross_image"
docker run --rm "$dockcross_image" >"$proxy"
chmod +x "$proxy"

cp -r $src/* $compiler_output_dir

output_dir="${relative_output_dir}/native/${classifier}"
CC="$("$proxy" bash -c 'echo "$CC"' | tr -d '\r')"

"$proxy" make -f src/main/c/GNUmakefile \
  JAVA_HOME=${java_home} \
  BUILD_DIR=${output_dir} \
  BUILD_CC=$CC \
  BUILD_OS=${build_os} \
  TARGET_CPU=${classifier} debug all || exit 1 && unset DOCKCROSS_IMAGE

unset DOCKCROSS_IMAGE