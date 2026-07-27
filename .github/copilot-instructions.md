# Commit message generation rules

Generate commit messages from the actual staged diff, not merely from file
names, directory names, or the number of changed files.

The commit title must precisely describe the primary intentional change.

## Output format

Use Conventional Commits:

```text
type(scope): subject
```

The first line must be a complete and accurate title that can stand alone.

Generate a body only when the staged changes contain multiple inseparable
details or require important rationale. Never rely on the body to correct a
vague or inaccurate title.

## Required analysis before generating the title

Before writing the commit message, silently perform these steps:

1. Inspect every staged file and its actual diff.
2. Identify the primary intentional change.
3. Distinguish:

   * behavior changes from documentation changes;
   * source files from generated files;
   * manual changes from automated refreshes;
   * implementation changes from accompanying tests and documentation;
   * functional workflow changes from routine dependency updates.
4. Determine what the repository will do differently after the commit.
5. Select the type and scope from the semantic effect of the change.
6. Write a subject that names the concrete resource, behavior, or defect.
7. Verify the complete title length before returning it.

Do not infer functionality from a filename alone.

Do not claim an effect that is not demonstrated by the diff.

## Hard title requirements

* Use English only.
* Use exactly the format `type(scope): subject`.
* Keep the complete title, including type and scope, at 72 characters or fewer.
* Prefer 50–65 characters when accuracy is not reduced.
* Use a lowercase type and lowercase scope.
* Begin the subject with a lowercase imperative verb unless it starts with a
  proper name or established acronym.
* Do not end the subject with a period.
* Do not include Markdown, quotation marks, issue numbers, or a trailing colon.
* Do not repeat the type or scope in the subject.
* Preserve established names and capitalization:

  * OpenClash
  * Mihomo
  * GeoIP
  * GeoSite
  * DNS
  * IPv4
  * IPv6
  * YAML
  * MRS
  * CDN
  * COCR
  * Sub-Store
  * GitHub Actions
  * jsDelivr
* Return one best title, not several alternatives.

Before returning the title, count every character. If it exceeds 72
characters, shorten the subject without removing the concrete object or effect.

## Allowed types

Use only:

```text
feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
```

Choose the type according to the actual semantic effect.

### `feat`

Use `feat` for a new user-visible capability, usable resource, routing
behavior, configuration option, script feature, or automation capability.

Examples include:

* adding a new manually maintained direct or proxy rule;
* adding a new OpenClash override;
* adding a new Subconverter policy or configuration capability;
* adding a new Shell-script operation;
* adding a new validation or publishing capability.

Creating a new file does not automatically make the change a feature.

### `fix`

Use `fix` only when the diff corrects incorrect behavior, incorrect data, a
broken path, an invalid rule, a failed workflow, or another identifiable
defect.

The subject must state what was corrected.

Do not use `fix` for:

* clearer wording;
* additional comments;
* metadata changes;
* formatting;
* general cleanup;
* speculative hardening without an identifiable defect.

### `docs`

Use `docs` when all meaningful changes affect documentation, comments,
instructions, examples, descriptions, or metadata intended for humans.

This rule applies even when comments are inside:

* `.conf`;
* `.ini`;
* `.yaml`;
* `.yml`;
* `.sh`;
* `.py`;
* `.js`.

Comment-only changes are `docs`, not `fix`, `style`, or `chore`.

### `style`

Use `style` only for formatting changes with no behavior, data, documentation,
or semantic effect.

Examples include whitespace, indentation, line wrapping, or ordering that does
not alter meaning.

Do not use `style` for rewritten documentation.

### `refactor`

Use `refactor` for internal restructuring that preserves intended behavior.

Examples include:

* renaming internal identifiers;
* reorganizing implementation code;
* deduplicating shared logic;
* changing internal structure without adding a feature or fixing a defect.

A rename that changes only provider identifiers should use `refactor`, while
its scope must still identify the owning repository component.

### `perf`

Use `perf` only when the primary purpose is a measurable or clearly
demonstrated performance improvement.

Do not infer a performance improvement merely because code became shorter.

### `test`

Use `test` when the primary change adds, removes, or corrects tests without
changing production behavior.

Tests added together with an implementation change normally inherit the
implementation commit's type and scope.

### `build`

Use `build` for build systems, packaging, documentation build dependencies, or
artifact construction tooling when the change is not primarily a CI workflow
change.

### `ci`

Use `ci` for GitHub Actions workflows and their supporting scripts when the
primary change affects repository automation, validation, publishing,
scheduling, permissions, concurrency, or automated commits.

For workflow commits, choose the scope from the workflow's purpose, not merely
`workflow`.

### `chore`

Use `chore` for routine maintenance that does not introduce user-visible
behavior or fix a defect.

Typical examples include:

* regenerating derived rule files;
* refreshing automatically collected upstream data;
* synchronizing a submodule;
* bumping dependencies;
* updating pinned action versions;
* repository housekeeping.

A manually selected new routing rule is normally `feat(rules)`, not
`chore(rules)`. An automated upstream refresh of an existing rule list is
normally `chore(rules)`.

### `revert`

Use `revert` only when the commit reverts an earlier commit.

Describe the reverted change precisely. Do not copy a malformed original title
without correcting its format.

## Allowed scopes

Prefer one of these repository scopes:

```text
rules
overwrite
config
subconverter
shell
substore
readme
wiki
docs
validation
pages
sync
deps
security
cdn
workflow
repo
```

Use these spellings consistently.

Do not invent singular, plural, or synonymous variants such as:

```text
rule
module
modules
script
scripts
workflows
configs
configuration
```

Use `rules`, not `rule`.

Use `overwrite`, not `module` or `modules`, for OpenClash override resources.

Use `shell`, not `script`, for files under `shell/`.

Use `workflow` only for genuinely cross-cutting workflow infrastructure. Prefer
the workflow's functional scope whenever one is available.

Use `repo` only as a last resort for genuinely repository-wide maintenance.
Never use `repo` to hide unrelated staged changes.

## Repository path and scope mapping

### Root documentation

For:

```text
README.md
DO_NOT_README.md
```

use:

```text
docs(readme)
```

For a README inside a component directory, use `docs` with that component's
scope:

```text
docs(rules)
docs(overwrite)
docs(config)
docs(shell)
docs(substore)
```

### Wiki and documentation site

For content under:

```text
wiki/**
```

use:

```text
docs(wiki)
```

For documentation-site configuration or build dependencies such as:

```text
mkdocs.yml
requirements-docs.txt
```

use `docs`, `build(docs)`, or `ci(pages)` according to the actual change.

### Subconverter templates

For maintained INI templates under:

```text
cfg/*.ini
```

prefer:

```text
subconverter
```

Examples:

```text
feat(subconverter): add gaming download policy
fix(subconverter): correct rule provider ordering
```

For automatically copied or derived INI templates, use `chore(subconverter)`
when only generated output changes.

### Complete YAML configurations

For maintained configuration files under:

```text
cfg/yaml/**
```

prefer:

```text
config
```

Use the actual configuration behavior in the subject, not a generic phrase
such as “update config”.

### Rule source files

The maintained rule sources include files such as:

```text
rule/Custom_Direct.list
rule/Custom_Proxy.list
rule/Steam_CDN.list
rule/Encrypted_DNS.list
rule/Game_Download_CDN.list
```

Use:

```text
rules
```

Examples:

```text
feat(rules): add hbymfswz.com to direct rules
fix(rules): move example.com from proxy to direct
chore(rules): refresh encrypted DNS sources
```

State the affected domain, service, platform, source set, or routing behavior
whenever it fits within the title limit.

### Generated rule files

Files under `rule/` with derived formats such as:

```text
*_Classical.yaml
*_Classical_IP.yaml
*_Classical_Port.yaml
*_Domain.yaml
*_IP.yaml
*.mrs
```

are generated artifacts when produced from the maintained `.list` sources.

When only generated files change, use:

```text
chore(rules): regenerate derived rule files
```

When a source `.list` and its generated files change together, describe the
source-rule change. Do not make regeneration the primary title.

Correct:

```text
feat(rules): add Steam CDN IP ranges
```

Incorrect:

```text
chore(rules): update YAML and MRS files
```

### OpenClash override resources

For files under:

```text
overwrite/**
```

use:

```text
overwrite
```

Examples:

```text
feat(overwrite): add encrypted DNS blocking override
feat(overwrite): set GeoIP database sources
feat(overwrite): set mainland IP whitelist sources
fix(overwrite): correct rule provider paths
docs(overwrite): standardize encrypted DNS metadata
refactor(overwrite): rename providers with COCR prefix
chore(overwrite): sync upstream overwrite submodules
```

An override that references rules is still scoped to `overwrite` when the
changed artifact is the override itself.

Do not use `rules`, `module`, `modules`, or `openclash` merely because an
override contains `rules` or `rule-providers`.

### Shell utilities

For files under:

```text
shell/**
```

use:

```text
shell
```

Examples:

```text
feat(shell): verify OpenClash startup after updates
fix(shell): restore package sources after failure
perf(shell): reduce repeated release metadata requests
docs(shell): clarify full update behavior
test(shell): cover installer rollback paths
```

### Sub-Store scripts

For files under:

```text
script/sub-store/**
```

use:

```text
substore
```

Examples:

```text
feat(substore): filter nodes without IPv6 egress
fix(substore): preserve nodes with valid IPv6 routes
test(substore): cover mixed IPv4 and IPv6 nodes
```

### Python maintenance tools

Choose the scope from the tool's target rather than from the `py/` directory.

Examples:

```text
py/generate_rules.py           -> rules
py/generate_game_cdn.py        -> rules
py/update_encrypted_dns.py     -> rules
py/sync_installer_common.py    -> shell
```

Tests inherit the target scope:

```text
test(rules): cover empty provider generation
test(shell): verify shared installer synchronization
```

Do not use `python`, `py`, or `script` as a scope unless the Python tooling
itself becomes an independent repository component.

### GitHub Actions and supporting scripts

For:

```text
.github/workflows/**
.github/scripts/**
```

use `ci` when the primary change affects automation.

Select the scope from the automation's responsibility:

```text
rule generation or rule refresh          -> rules
repository validation                    -> validation
wiki publishing or backup                -> wiki
GitHub Pages deployment                   -> pages
Dependabot automation                     -> deps
CodeQL or security scanning               -> security
jsDelivr cache purging                    -> cdn
OpenClash overwrite submodule syncing     -> overwrite
cross-workflow concurrency or permissions -> workflow
```

Examples:

```text
ci(rules): serialize generated rule commits
ci(validation): validate Sub-Store filter syntax
ci(wiki): back up wiki before publishing
ci(pages): pin documentation build dependencies
ci(overwrite): prevent stale submodule sync pushes
ci(workflow): share the main branch writer queue
```

Do not automatically use `ci(workflow)` for every file under
`.github/workflows/`.

### Dependencies

For routine dependency or pinned action updates, use:

```text
chore(deps): bump actions checkout to v7.0.1
chore(deps): update CodeQL actions
```

Use `fix(deps)` only when a dependency change corrects an actual compatibility
or security defect demonstrated by the change.

### Archived files

Use the scope of the owning component.

Mention `archived` in the subject only when moving, restoring, documenting, or
removing archived resources is the primary purpose.

Changes that affect only archived resources are normally `docs`, `chore`, or
`refactor`, not `feat`.

## Multiple-file commits

Determine whether all staged files serve one coherent objective.

Apply these rules:

1. Implementation plus tests:

   * describe the implementation;
   * do not title the commit as a test change.

2. Implementation plus documentation:

   * describe the implementation;
   * mention documentation only in the body when needed.

3. Source rule plus generated providers:

   * describe the source-rule change;
   * do not title the commit as regeneration.

4. Workflow plus supporting script:

   * use `ci`;
   * scope it to the automation's actual purpose.

5. Renames across several files:

   * describe the shared renamed concept;
   * use the owning component as scope.

6. Several files with one corrected defect:

   * use `fix`;
   * name the defect or corrected behavior.

7. Truly unrelated changes:

   * describe the highest-impact intentional change in the title;
   * summarize secondary changes in the body;
   * never invent a vague umbrella statement;
   * do not use `chore(repo)` merely to avoid identifying the primary change.

Do not join unrelated changes with a generic subject such as:

```text
update rules and workflows
improve repository files
make various fixes
update configuration and docs
```

## Subject-writing rules

The subject must answer:

```text
What concrete behavior, resource, data set, or defect changed?
```

Prefer specific verbs such as:

```text
add
remove
block
allow
route
direct
reject
set
correct
restore
prevent
validate
generate
regenerate
refresh
sync
rename
document
clarify
pin
bump
```

Avoid weak verbs unless followed by a precise object and effect:

```text
update
change
improve
modify
adjust
enhance
optimize
clean up
```

Avoid subjects that merely restate a filename.

Incorrect:

```text
feat(overwrite): add Set_GeoIP_Database_URL.conf
```

Correct:

```text
feat(overwrite): set GeoIP database sources
```

Do not include implementation details when the observable effect is clearer.

Incorrect:

```text
feat(overwrite): add CHNR_CUSTOM_URL variables
```

Correct:

```text
feat(overwrite): set mainland IP whitelist sources
```

Use file or resource names only when they are established public names and
provide the clearest description.

## Prohibited vague messages

Never generate titles such as:

```text
update files
update rules
update config
change configuration
fix bug
misc changes
various improvements
improve metadata
enhance workflow
refactor code
clean up files
sync changes
adjust settings
```

Never claim:

```text
improve performance
increase stability
fix compatibility
enhance security
```

unless the diff specifically demonstrates that effect.

## Repository-specific examples

Good:

```text
feat(rules): add Alibaba mainland IP ranges
feat(rules): add hbymfswz.com to direct rules
fix(rules): remove an invalid Steam CDN prefix
chore(rules): refresh encrypted DNS sources
chore(rules): regenerate derived rule files

feat(overwrite): add encrypted DNS blocking override
feat(overwrite): add direct game download rules
feat(overwrite): set GeoIP database sources
feat(overwrite): set mainland IP whitelist sources
fix(overwrite): correct rule provider paths
docs(overwrite): standardize encrypted DNS metadata
refactor(overwrite): rename providers with COCR prefix
chore(overwrite): sync upstream overwrite submodules

feat(subconverter): add gaming download policy
fix(subconverter): preserve fallback rule ordering
chore(subconverter): regenerate mainland template

feat(config): add IPv6 DNS routing example
fix(config): correct GeoSite rule ordering

feat(shell): verify OpenClash service startup
fix(shell): restore package feeds on failed installation
perf(shell): reuse fetched release metadata
docs(shell): clarify lightweight update exclusions
test(shell): cover missing package manager handling

feat(substore): filter nodes without IPv6 egress
fix(substore): retain dual-stack nodes
test(substore): cover empty node collections

ci(rules): serialize generated rule commits
ci(validation): validate complete Mihomo templates
ci(wiki): prevent empty wiki backup commits
ci(overwrite): reset stale submodule sync state
ci(cdn): purge changed rule resources
ci(workflow): serialize main branch writers

docs(readme): expand configuration resource guide
docs(wiki): clarify Fake-IP DNS routing
build(docs): pin MkDocs dependencies
chore(deps): bump CodeQL actions
```

Incorrect:

```text
feat(module): add GeoIP config
feat(rules): add Direct Game Download overwrite
fix(overwrite): improve metadata
chore(rule): update Encrypted_DNS.list
ci(workflows): improve automation
docs(script): update README
chore(config): update OpenClash rule sources
```

Corrected versions:

```text
feat(overwrite): set GeoIP database sources
feat(overwrite): add direct game download rules
docs(overwrite): standardize encrypted DNS metadata
chore(rules): refresh encrypted DNS sources
ci(rules): prevent stale generated rule commits
docs(shell): clarify installer usage
chore(subconverter): refresh rule source references
```

## Optional body rules

Generate a body only when it adds information that cannot fit in the title.

When a body is needed:

* leave one blank line after the title;
* explain what changed and why;
* mention important secondary changes;
* do not repeat the title;
* do not invent validation results;
* mention tests only when the diff or available context shows they were run;
* wrap body lines at approximately 72 characters where practical.

## Final validation checklist

Before returning a commit message, verify all of the following:

1. The title reflects the actual diff.
2. The type matches the semantic effect.
3. The scope uses the repository's canonical vocabulary.
4. The scope identifies the owning component, not an incidental keyword.
5. Source files and generated files are correctly distinguished.
6. Comment-only changes use `docs`.
7. Automated refreshes use `chore` unless automation behavior itself changed.
8. Workflow changes use a functional scope.
9. The subject names a concrete object or behavior.
10. No effect or test result was invented.
11. The complete title is no longer than 72 characters.
12. The title contains no trailing period.
13. The output contains one best commit title.
