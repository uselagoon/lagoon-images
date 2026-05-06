# Lagoon Images - Copilot PR Review Instructions

This is the canonical, machine-consumed policy for automated Copilot PR
reviews in this repository.

If this file conflicts with prose guidance elsewhere, this file wins for
automation behavior.

## Before You Start (Required)

1. Identify affected image(s) by directory (`images/php-fpm/`, `images/nginx/`, etc.)
2. Classify the change type:
   - Base image change (`commons`, `nginx`, `php-fpm`)
   - Variant image change (`nginx-drupal`, `php-cli-drupal`)
   - Helper script change (`helpers/`)
   - Build system change (`docker-bake.hcl`, `Makefile`)
   - Documentation-only
3. If multiple image families are affected, note cross-image impact in the summary.
4. Do not repeat the same comment across multiple files.

## 1. Base Image Version Pinning

Checks:

- `FROM` uses a fully-qualified tag (e.g. `alpine:3.19`, not `alpine:latest`)
- Existing version Dockerfiles only receive minor/patch updates (as applicable)
- Major version updates are introduced as new image/version Dockerfiles, not by mutating existing version Dockerfiles

Comment templates:

- Unpinned tag: `Base image is not version-pinned. Pin to a specific version to ensure reproducible builds.`
- Major version bump in existing Dockerfile: `Major version bumps should be introduced via a new image/version Dockerfile. Keep existing version Dockerfiles on minor/patch updates only.`

One comment per Dockerfile maximum.

## 2. Layer Construction and Determinism

Checks:

- No interactive commands in `RUN` steps
- No time-dependent behavior
- Package installs use `--no-cache` (apk)
- Package lists are cleaned up
- No redundant add/remove layering patterns

Comment templates:

- Temp artifacts remain: `Temporary build artifacts are left in the final image. Clean up in the same layer to reduce image size.`
- Inefficient layering: `Multiple RUN layers perform related setup. Consider consolidating to reduce image layers.`

No style commentary. Focus on determinism and image size.

## 3. Helper Scripts

If a helper script changes, verify:

- It is used by multiple images
- It remains POSIX-compatible
- It fails fast (`set -e` or equivalent)
- Error output is meaningful

Comment templates:

- Shared behavior change: `This helper script is shared across multiple images. Confirm downstream impact and update relevant images if required.`
- Error handling weakens: `Helper scripts should fail fast with clear error output to avoid silent image misbuilds.`

Do not suggest refactors unless behavior is broken.

## 4. Security Posture

Flag concrete risks:

- `curl | sh` without checksum verification
- Downloaded binaries without integrity checks
- Build tools present in final runtime images
- Runtime images using root when avoidable

Comment templates:

- External download risk: `External download lacks integrity verification. Add checksum validation to reduce supply-chain risk.`
- Runtime root user: `Image runs as root. If intended for runtime use, consider a non-root user unless explicitly required.`

No generic security theater.

## 5. Image Intent and Audience Clarity

Verify OCI labels include:

- `org.opencontainers.image.source`
- `org.opencontainers.image.description`
- `org.opencontainers.image.title`
- `org.opencontainers.image.base.name`

Non-obvious `RUN` steps must carry a brief inline comment.

Comment templates:

- Missing/vague description: `OCI description label does not state image purpose or audience. Update to clarify intended use.`
- Non-obvious logic: `This step is non-obvious. Add a brief comment explaining why it is required.`

One comment max per file.

## 6. Cross-Image Consistency

Checks:

- `ENV` naming follows established patterns
- All four OCI labels from section 5 are present
- Directory structure matches established image families
- Utilities from `commons` are copied using established pattern
- Target name uses dashes; published tag keeps dots
- First-tier images use `ARG LOCAL_REPO` + `FROM ${LOCAL_REPO:-lagoon}/commons AS commons`
- Variants use `FROM ${LOCAL_REPO:-lagoon}/<parent>`

Comment template:

`This image diverges from conventions used in similar Lagoon images. See architecture.md section 7 for the expected pattern.`

Reference existing repository conventions only.

## 7. Build Wiring and Test Coverage

For any new image, version, or variant, verify all of:

- `docker-bake.hcl` has a target block
- Target is in the service-specific group
- Target is in `group "default"`
- `contexts` map is correct for first-tier vs variant
- Combined specializations layer on the first specialization
- Compose service entry exists in `helpers/images-docker-compose.yml` or `helpers/services-docker-compose.yml`
- Matching commands exist in corresponding `helpers/TESTING_*_dockercompose.md`

Comment templates:

- Missing group wiring: `Target is defined but not added to group "default" (and/or its service group). CI will silently skip it.`
- Variant incorrectly includes commons in contexts: `Variant images should reference only their direct parent in contexts. Remove the commons entry unless this Dockerfile has an explicit FROM commons AS commons stage.`
- First-tier missing commons context: `First-tier image is missing ${LOCAL_REPO}/commons: target:commons in its bake contexts.`
- Missing compose/testing coverage: `New image has no compose entry or TESTING_*.md commands. Add coverage in helpers/.`

## 8. Documentation

Check for needed updates to:

- `README.md` for consumer-visible behavior/tag changes
- `.github/copilot-instructions.md` for workflow/recipe changes
- `architecture.md` for structural convention changes

Comment template:

`Documentation does not reflect this change. Update README / copilot-instructions / architecture as appropriate.`

## 9. Lifecycle and Backward Compatibility

Checks:

- No image removed without prior EOL labeling and deprecation window
- No published tag removed without EOL marker first
- No default behavior or `ENV` changed without PR note
- No breaking changes without clear upgrade path

Comment template:

`This change alters existing image behaviour. Confirm backward compatibility or document the breaking change and upgrade path.`

Do not block internal refactors that do not affect external behavior.

## 10. End-of-Life Labeling

For EOL changes, verify:

- Both labels are present exactly as expected
- Suggested replacement exists in this repository build graph
- Replacement is latest stable / longest-supported equivalent
- Image still builds and publishes during deprecation window

Comment templates:

- Missing/nonexistent replacement: `Suggested replacement image is not built by this repo. Point to an image that exists in docker-bake.hcl.`
- Image gutted instead of labeled: `EOL marking should only add the two deprecation labels. Image must keep building and publishing for the deprecation window.`

## Review Output Format (Required)

Always use this exact structure:

```markdown
## Summary
- **Images affected:** [list affected image directories]
- **Risk level:** low | medium | high
- **Backward compatible:** yes | no | n/a

## Blocking Issues
[Issues that break builds, introduce security risks, or break backward compatibility.]
[If none: "No blocking issues."]

## Non-Blocking Suggestions
[Grouped, concise suggestions. Omit section if none.]
```

Rules:

- No praise or positive commentary
- No filler text or restatement of the diff
- No duplicate comments across files

## References

Use these as supporting references when available:

- `docs/reviewing/PR_REVIEW_RUBRIC.md`
- `architecture.md`
- `.github/copilot-instructions.md`

If references are unavailable at runtime, continue with this file's rules.
