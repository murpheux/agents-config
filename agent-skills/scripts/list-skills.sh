#!/usr/bin/env bash
# Print each skill's name and one-line description.
# Handles both inline descriptions and folded/literal block scalars (>-, |, ...)
# plus quoted values, so output stays a single line per skill.

set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${root}/.agents/skills"

for dir in "${skills_dir}"/*/; do
	[ -d "${dir}" ] || continue
	file="${dir}SKILL.md"
	[ -f "${file}" ] || continue

	awk '
		BEGIN { dq = sprintf("%c", 34); sq = sprintf("%c", 39) }
		NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
		fm == 1 && /^---[[:space:]]*$/ { exit }
		fm == 1 {
			if (block) {
				if ($0 ~ /^[[:space:]]+/) {
					s = $0
					sub(/^[[:space:]]+/, "", s)
					buf = (buf == "" ? s : buf " " s)
					next
				}
				block = 0
			}
			if ($0 ~ /^name:[[:space:]]*/) {
				n = $0
				sub(/^name:[[:space:]]*/, "", n)
				name = n
			} else if ($0 ~ /^description:[[:space:]]*/) {
				d = $0
				sub(/^description:[[:space:]]*/, "", d)
				if (d == "" || d == ">" || d == ">-" || d == "|" || d == "|-") {
					block = 1
					buf = ""
				} else {
					desc = d
				}
			}
		}
		END {
			if (buf != "") desc = buf
			gsub("^" dq, "", desc)
			gsub(dq "$", "", desc)
			gsub("^" sq, "", desc)
			gsub(sq "$", "", desc)
			printf "%-28s %s\n", name, desc
		}
	' "${file}"
done
