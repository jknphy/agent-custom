---
name: modify-iso
description: "Patch a downloaded install ISO for testing by injecting bootloader/kernel parameters, e.g. to set the live password or point at a registration server. Use only when the user asks to modify/patch/customize an already-downloaded .iso for testing."
---

# Modify ISO

## Choosing the ISO

Unless the user gave an explicit ISO path, first list the candidates:

```bash
ls -1 ~/Downloads/isos/*.iso
```

Then ask the user which one to use (numbered list of filenames) and wait for their answer. If only one ISO exists, still confirm it with the user. If none exist, tell the user and stop. Use the full expanded path `~/Downloads/isos/<chosen>` as `<iso-path>` below.

## Running

Run this exact command and no other, with the ISO path and optional flags — do not add pipes, redirection, `timeout`, or any other wrapper around it:

```bash
bash /root/.pi/agent/skills-custom/modify-iso/modify.sh "<iso-path>" [--password "<password>"] [--grub-timeout <seconds>] [<boot-param> ...]
```

`live.password=<password>` is always injected as a boot parameter (password defaults to `nots3cr3t`). The grub menu timeout is set to `3` seconds by default; use `--grub-timeout <seconds>` to change it (e.g. `0` to boot immediately).

Any additional arguments are passed through verbatim as extra kernel boot parameters, e.g. `inst.register_url=http://example.com`. On success it prints the path to the new, modified ISO; the source ISO is never changed.
