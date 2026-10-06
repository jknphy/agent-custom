---
name: download-iso
description: "Download an ISO file for development use (no checksum verification), either from a direct http(s) .iso URL or the latest SLES build for a product version (16.0, 16.1, 16.2) from download.suse.de. Use only when the user asks to download an ISO."
---

# Download ISO

Run this exact command and no other, with either a URL or a product version:

```bash
bash /root/.pi/agent/skills-custom/download-iso/download.sh "<URL>"
bash /root/.pi/agent/skills-custom/download-iso/download.sh <16.0|16.1|16.2> --flavor <Online|Full>
```

- **URL**: must be `http(s)` and end in `.iso`, otherwise nothing is downloaded.
- **Version**: picks the highest build of `SLES-<version>-<flavor>-x86_64-Build*.install.iso` from `https://download.suse.de/ibs/SUSE:/SLFO:/Products:/SLES:/<version>:/TEST/product/iso/`. Architecture is always x86_64 (development use).
- **Flavor**: if the user gave a version but no flavor, ask which one (Online or Full) and wait for the answer before running. Never guess.

On success it prints the final path. The file lands at `~/Downloads/isos/<name>.iso`; an existing file is not downloaded again.
