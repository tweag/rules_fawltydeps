#!/usr/bin/env bash

# This script is the default integration test runner. In addition to the 
# --bazel and --workspace flags, it also expects one or more --bazel_cmd
# flag-value pairs.

# NOTE: Do not introduce any external dependencies to this script!

exit_with_msg() {
  echo >&2 "${@}"
  exit 1
}

bazel_cmds=(
  "build //... --announce_rc --config=fawltydeps --keep_going --verbose_failures"
)
bazel="${BIT_BAZEL_BINARY:-}"
workspace_dir="${BIT_WORKSPACE_DIR:-}"
bit_cache="${BIT_CACHE:-${BASH_SOURCE[0]%%/sandbox/*}/bit_cache}"

[[ -n "${bazel:-}" ]] || exit_with_msg "Must specify the location of the Bazel binary."
[[ -n "${workspace_dir:-}" ]] || exit_with_msg "Must specify the path of the workspace directory."
[[ ${#bazel_cmds[@]} > 0 ]] || exit_with_msg "No Bazel commands were specified."


# Configure caching
#
args=()
# BAZELISK_HOME
bazelisk_home="${bit_cache}/bazelisk"
mkdir -p "$bazelisk_home"
export BAZELISK_HOME="$bazelisk_home"
# --repository_cache
repository_cache="${bit_cache}/repository_cache"
mkdir -p "$repository_cache"
args+=("--repository_cache" "$repository_cache")
# --disk_cache
disk_cache="${bit_cache}/disk_cache"
mkdir -p "$disk_cache"
args+=("--disk_cache" "$disk_cache")
# -- repo_contents_cache
bazel_version=$("${bazel}" --version | cut -d ' ' -f 2)
if [[ -n "${bazel_version}" ]] && "${bazel}" info --repo_contents_cache= &>/dev/null ; then
  repo_contents_cache="${bit_cache}/repo_contents_cache/$bazel_version"
  mkdir -p "$repo_contents_cache"
  args+=("--repo_contents_cache" "$repo_contents_cache")
fi

for var_name in ${ENV_VARS_TO_ABSOLUTIFY:-}; do
  export "${var_name}=$(pwd)/$(printenv "${var_name}")"
done

cd "${workspace_dir}"

for cmd in "${bazel_cmds[@]}" ; do
  # Break the cmd string into parts
  read -a cmd_parts <<< ${cmd}
  # Execute the Bazel command
  echo Running "${bazel}" "${cmd_parts[@]}" "${args[@]}"
  "${bazel}" "${cmd_parts[@]}" "${args[@]}"
done
