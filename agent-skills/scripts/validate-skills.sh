#!/usr/bin/env bash
# Validate every skill under .agents/skills:
#   - SKILL.md exists
#   - YAML frontmatter block is present and closed
#   - frontmatter declares `name:` and `description:`
#   - `name:` matches the containing directory
#
# Exit 0 when all skills pass, 1 otherwise.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${root}/.agents/skills"

if [ ! -d "${skills_dir}" ]; then
	printf 'validate-skills: %s not found\n' "${skills_dir}" >&2
	exit 1
fi

failures=0
count=0

for dir in "${skills_dir}"/*/; do
	[ -d "${dir}" ] || continue
	name="$(basename "${dir}")"
	file="${dir}SKILL.md"
	count=$((count + 1))

	if [ ! -f "${file}" ]; then
		printf 'FAIL  %-32s missing SKILL.md\n' "${name}" >&2
		failures=$((failures + 1))
		continue
	fi

	if [ "$(head -n 1 "${file}")" != "---" ]; then
		printf 'FAIL  %-32s frontmatter must start on line 1\n' "${name}" >&2
		failures=$((failures + 1))
		continue
	fi

	frontmatter="$(sed -n '2,/^---$/p' "${file}")"
	if [ -z "${frontmatter}" ]; then
		printf 'FAIL  %-32s unterminated frontmatter\n' "${name}" >&2
		failures=$((failures + 1))
		continue
	fi

	declared="$(printf '%s\n' "${frontmatter}" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
	described="$(printf '%s\n' "${frontmatter}" | grep -c '^description:')"

	if [ -z "${declared}" ]; then
		printf 'FAIL  %-32s frontmatter missing name\n' "${name}" >&2
		failures=$((failures + 1))
		continue
	fi

	if [ "${declared}" != "${name}" ]; then
		printf 'FAIL  %-32s name "%s" does not match directory\n' "${name}" "${declared}" >&2
		failures=$((failures + 1))
		continue
	fi

	if [ "${described}" -eq 0 ]; then
		printf 'FAIL  %-32s frontmatter missing description\n' "${name}" >&2
		failures=$((failures + 1))
		continue
	fi

	printf 'ok    %s\n' "${name}"
done

printf '\n%d skill(s) checked, %d failure(s)\n' "${count}" "${failures}"
[ "${failures}" -eq 0 ]
