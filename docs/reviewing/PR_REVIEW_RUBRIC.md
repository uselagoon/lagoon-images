# Lagoon Images – PR Review Rubric for AI Agents

## Scope Guardrail (REQUIRED FIRST STEP)

**Before making any comments, determine:**

1. **Which image(s) are affected?** (Identify by directory: `images/php-fpm/`, `images/nginx/`, etc.)
2. **What type of change is this?**
   - Base image change (e.g., `commons`, `nginx`, `php-fpm`)
   - Variant image change (e.g., `nginx-drupal`, `php-cli-drupal`)
   - Helper script change (`helpers/` directory)
   - Build system change (`docker-bake.hcl`, `Makefile`)
   - Documentation-only

**Rule:** If multiple image families are affected, note cross-image impact in the summary section. Do NOT repeat the same inline comment on multiple files.

## 1. Base Image and Version Pinning (NON-NEGOTIABLE)

**Required Checks:**

FROM uses a fully qualified tag

✅ alpine:3.19

❌ alpine:latest

Major version bumps are intentional

Digest pinning is encouraged but not required unless:

Image is used as a shared base

Comment rules

If unpinned:

“Base image is not version-pinned. Pin to a specific version to ensure reproducible builds across Lagoon deployments.”

If major version bump:

“This bumps the base image major version. Confirm compatibility with downstream Lagoon services.”

Only one comment per Dockerfile. No pile-on.

## 2. Layer construction and determinism

**Explicit checks**

Copilot must check:

RUN steps:

No interactive commands

No time-dependent behavior

Package installs:

Use --no-cache (apk)

Clean up package lists

No redundant layers adding then removing files

Comment rules

If temp artifacts remain:

“Temporary build artifacts are left in the final image. Clean up in the same layer to reduce image size.”

If layering is inefficient:

“Multiple RUN layers perform related setup. Consider consolidating to reduce image layers.”

No style commentary. Size and determinism only.

## 3. Helper scripts (helpers/, shared scripts)

**Explicit checks**

If a helper script changes, Copilot must verify:

It is used by multiple images

It remains POSIX-compatible

It fails fast (set -e or equivalent)

Error output is meaningful

Comment rules

If helper script behavior changes:

“This helper script is shared across multiple images. Confirm downstream impact and update relevant images if required.”

If error handling weakens:

“Helper scripts should fail fast with clear error output to avoid silent image misbuilds.”

Copilot must not suggest refactors unless behavior is broken.

## 4. Security posture (image-specific, not generic)

**Explicit checks**

Copilot must flag:

curl | sh without checksum verification

Downloaded binaries without integrity checks

Build tools present in final runtime images

Root user usage in runtime images (when avoidable)

Comment rules

External downloads:

“External download lacks integrity verification. Add checksum validation to reduce supply-chain risk.”

Runtime as root:

“Image runs as root. If intended for runtime use, consider a non-root user unless explicitly required.”

Copilot must not recommend security theatre. Only concrete risks.

## 5. Image intent and audience clarity

**Explicit checks**

Copilot must verify:

Dockerfile header comment states:

Purpose

Intended use (build vs runtime)

Non-obvious steps are commented

Comment rules

Missing intent:

“Dockerfile lacks a clear statement of purpose. Add a short header comment describing intended use.”

Non-obvious logic:

“This step is non-obvious for an image build. Add a brief comment explaining why it’s required.”

One comment max per file.

## 6. Cross-Image Consistency

**Required Checks (compare against similar images in repo):**
- [ ] ENV variable naming follows established patterns
- [ ] Label usage matches conventions (especially `org.opencontainers.image.*` labels)
- [ ] Directory structure aligns with similar images
- [ ] Common utilities are copied from `commons` in the standard way

**Comment Template:**

If inconsistency detected:
```
This image diverges from conventions used in similar Lagoon images. Align ENV names and structure for consistency.
```

**Rule:** Reference existing patterns from the repo. Do NOT invent new conventions.

## 7. CI and Test Expectations

**Required Checks:**
- [ ] Image is built in CI (`docker-bake.hcl` target exists)
- [ ] New images have at minimum:
  - Build verification in CI
  - Docker Compose service definition in `helpers/`
  - Test commands in `helpers/TESTING_*_dockercompose.md`
- [ ] CI changes align with existing pipeline patterns

**Comment Template:**

If CI coverage is missing:
```
This image is not covered by CI build verification. Add CI coverage to ensure regressions are caught.
```

**Rule:** Do NOT speculate about test frameworks or suggest new testing approaches.

## 8. Documentation Impact

**Required Checks:**
- [ ] README is updated if:
  - Image behavior changes
  - Tags or variants are added/removed
  - Build instructions change
- [ ] Copilot instructions updated for new patterns or workflows

**Comment Template:**

If documentation is outdated:
```
Documentation does not reflect this image change. Update README to match new behavior or requirements.
```

## 9. Backward Compatibility and Tagging

**Required Checks:**
- [ ] No removed tags without EOL marking
- [ ] No changed defaults without documentation
- [ ] No behavior changes that could break existing consumers

**Comment Template:**

If breaking change detected:
```
This change alters existing image behavior. Confirm backward compatibility or document the breaking change.
```

**Rule:** Do NOT block minor internal refactors that don't affect external behavior.

## 10. Review Output Format (MANDATORY STRUCTURE)

**Every PR review MUST follow this exact format:**

```markdown
## Summary
- **Images affected:** [list affected image directories]
- **Risk level:** [low / medium / high]
- **Backward compatible:** [yes / no / n/a]

## Blocking Issues
[Only list issues that:]
- Break builds
- Introduce security risks
- Break backward compatibility

[If none, state: "No blocking issues."]

## Non-Blocking Suggestions
[Grouped, concise suggestions]
[If none, omit this section]
```

**Rules:**
- No praise or positive commentary
- No filler text or restating the obvious
- No repeating the diff contents
- Be concise and actionable
