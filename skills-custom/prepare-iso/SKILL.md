---
name: prepare-iso
description: "Prepare a SLES install ISO for VM testing in one go: download the latest build of a product version (16.0, 16.1, 16.2) and patch it (live password, grub timeout, register URL). Use when the user asks to prepare/get a ready-to-test SLES ISO. Records the result in ~/Downloads/isos/last-prepared.json for later skills."
---

# Prepare ISO

Orchestrates the `download-iso` and `modify-iso` skills. Do not call those separately for this workflow.

## Inputs

- **version** (required): `16.0`, `16.1` or `16.2`.
- **flavor** (required): `Online` or `Full`. If the user did not say, ask and wait. Never guess.
- Optional: `--password` (default `nots3cr3t`), `--grub-timeout` (default `3`), `--register-url` (override).

Ask for any missing required input in a single question.

## Running

Run this exact command and no other (no pipes, redirection or wrappers):

```bash
bash /root/.pi/agent/skills-custom/prepare-iso/prepare.sh <version> --flavor <Online|Full> [--password <pw>] [--grub-timeout <sec>] [--register-url <url>]
```

Behavior:
- Always x86_64. Downloads the highest build for the version (skipped if already present).
- Register URL is inferred: for the **latest** product version it is `http://all-<build>.proxy.scc.suse.de`; older versions have no proxy, so none is set. `--register-url` overrides this.
- Reuses an existing modified ISO if the source and parameters are unchanged.
- Keeps the newest 2 builds per version; older ISOs (original, modified, sidecar) are deleted.
- Stops at the failing step and reports it.

## Output contract

The last stdout line is the modified ISO path. The same details are written to `~/Downloads/isos/last-prepared.json` (keys: `iso`, `source_iso`, `version`, `flavor`, `arch`, `build`, `password`, `grub_timeout`, `register_url`, `params`). Later skills (VM spawn, Puppeteer tests) should read this file instead of asking again. Report the build number to the user so results are tied to a build.
