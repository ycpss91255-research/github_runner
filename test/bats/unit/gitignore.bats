#!/usr/bin/env bats
# Executable spec for the per-user tooling ignores (#119). `.claude/` and
# `.agents/` stay untracked by decision, and a worktree gets the main
# checkout's hooks by symlinking `<worktree>/.claude -> <main>/.claude`. A
# trailing-slash pattern matches only a real directory, so the ignore must be
# slash-less or the symlink surfaces as untracked.

setup() {
  # The kcov image carries no git; the test-tools image (just test) does.
  command -v git >/dev/null 2>&1 || skip "git not available in this image"
  ROOT="${BATS_TEST_DIRNAME}/../../.."
  SCRATCH="$(mktemp -d)"
  git -C "${SCRATCH}" init -q
  cp "${ROOT}/.gitignore" "${SCRATCH}/.gitignore"
}

teardown() {
  if [ -n "${SCRATCH:-}" ]; then rm -rf "${SCRATCH}"; fi
}

@test "a real .claude/ directory is ignored (#119)" {
  mkdir -p "${SCRATCH}/.claude/hooks"
  touch "${SCRATCH}/.claude/hooks/x.sh"
  run git -C "${SCRATCH}" check-ignore -q .claude/hooks/x.sh
  [ "${status}" -eq 0 ]
}

@test "a .claude symlink (hooked worktree) is ignored (#119)" {
  mkdir -p "${SCRATCH}/target"
  ln -s "${SCRATCH}/target" "${SCRATCH}/.claude"
  run git -C "${SCRATCH}" check-ignore -q .claude
  [ "${status}" -eq 0 ]
}

@test "a .agents symlink is ignored (#119)" {
  mkdir -p "${SCRATCH}/target"
  ln -s "${SCRATCH}/target" "${SCRATCH}/.agents"
  run git -C "${SCRATCH}" check-ignore -q .agents
  [ "${status}" -eq 0 ]
}

@test "the untracked set stays empty with both symlinks present (#119)" {
  mkdir -p "${SCRATCH}/target"
  ln -s "${SCRATCH}/target" "${SCRATCH}/.claude"
  ln -s "${SCRATCH}/target" "${SCRATCH}/.agents"
  run git -C "${SCRATCH}" status --porcelain --untracked-files=all
  [ "${status}" -eq 0 ]
  [ "${output}" = "?? .gitignore" ]
}
