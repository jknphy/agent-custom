---
name: download-iso
description: "Download an ISO file from a URL for development use (no checksum verification). Use only when the user gives a direct http(s) URL ending in .iso and asks to download it."
---

# Download ISO

Run this exact command and no other to download the ISO, with the URL as the only argument:

```bash
bash /root/.pi/agent/skills-custom/download-iso/download.sh "<URL>"
```

The script aborts and downloads nothing if the URL is not `http(s)` or does not end in `.iso`. On success it prints the final path. The file lands at `~/Downloads/isos/<name>.iso`.
