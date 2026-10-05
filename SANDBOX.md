# pi-agent sandbox: egress allowlist

The agent runs in a rootless podman container on an `--internal` network (no route
to the internet). The only way out is a squid proxy (`pi-agent-proxy`) that forwards
a request only if its domain is in `~/.config/pi-agent/allow.txt`. The agent can
still read the project and the mounted gcloud credentials; the allowlist limits
where data can be sent, not what it can read.

## Commands

```bash
pi-agent allow <domain>...   # add (also matches subdomains); applies live
pi-agent deny  <domain>...   # remove
pi-agent list                # show current list
pi-agent secret set|ls|rm <NAME>   # env secrets (tokens), stored in podman secrets
```

Non-sensitive config (project ID, region) goes in `.env` (gitignored; see `.env.example`).

## Building your allowlist

Start empty and add only what is needed:

```bash
pi-agent allow googleapis.com      # Vertex AI + OAuth
pi-agent allow registry.npmjs.org  # npm install
```

Then run the agent and watch what it gets blocked on, in a second terminal:

```bash
podman exec pi-agent-proxy tail -n0 -f /var/log/squid/access.log | grep --line-buffered DENIED
```

`-n0` skips old entries. To wipe the log (e.g. before a fresh audit):

```bash
podman exec pi-agent-proxy truncate -s0 /var/log/squid/access.log
```

Each `DENIED` host is either something the agent shouldn't reach (leave it) or
something your task needs (`pi-agent allow <domain>`, then retry; no restart).

Audit after a run:

```bash
# hosts reached
podman exec pi-agent-proxy cat /var/log/squid/access.log | grep -v DENIED | awk '{print $7}' | sort -u
# hosts blocked
podman exec pi-agent-proxy cat /var/log/squid/access.log | grep DENIED | awk '{print $7}' | sort -u
```

Typical extras: browser/binary downloads (Playwright, Puppeteer, Cypress) use their own
domains; git hosts are blocked on purpose (commit from outside the container).

## Notes

- `pi.dev` is allowed (`/share`, model catalog refreshes, version check, telemetry).
- The proxy resolves DNS via `10.144.53.53` (`--dns` in the script, corporate resolver so internal hosts like download.suse.de work); change it there if needed.
- Services on the host (localhost, VMs) are unreachable from the container.
- Reset: `podman rm -f pi-agent-proxy` (recreated on next run); `podman network rm pi-agent-net`.
- The log in the proxy container resets when it is removed.
