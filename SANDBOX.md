# pi-agent sandbox

The agent runs in a rootless podman container. It can read the project and the
mounted gcloud credentials.

## Commands

```bash
pi-agent secret set|ls|rm <NAME>   # env secrets (tokens), stored in podman secrets
```

Non-sensitive config (project ID, region) goes in `.env` (gitignored; see `.env.example`).

## Rebuilding the agent image

```bash
cd ~/.agent-custom
podman build -f Dockerfile.pi -t pi-sandbox .
# fresh Pi version / base image (the npm layer is otherwise cached):
podman build --no-cache --pull=newer -f Dockerfile.pi -t pi-sandbox .
```

No restart needed: each `pi-agent` run starts a new `--rm` container from the image.
State lives in the `pi-agent-home` volume and survives rebuilds.

## Notes

- Services on the host (localhost, VMs) are unreachable from the container.
