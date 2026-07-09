# Commit message rules

When generating commit messages, strictly follow Conventional Commits.

Format:

type(scope): subject

Allowed types:

feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Rules:

- Use English only.
- Use lowercase type and scope.
- Keep the commit title under 72 characters.
- Do not end the subject with a period.
- Use imperative mood.
- Choose a meaningful scope from the changed module, directory, or file.
- Do not generate vague messages like "update files", "fix bug", "misc changes", or "change config".
- Prefer a single-line title unless the change genuinely needs a body.

Recommended scopes for this repository:

- rules
- workflow
- docs
- shell
- config
- geoip
- geosite
- openclash
- subconverter
- sync
- ci

Good examples:

- feat(rules): add Alibaba mainland IP ranges
- fix(workflow): avoid duplicate branch sync runs
- docs(readme): clarify GitHub Actions abuse warning
- chore(config): update OpenClash rule sources
- ci(sync): adjust dev to master synchronization