# agent-custom

Personal setup for running the [Pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
in a rootless podman container, with custom skills, prompts and a TUI header extension.
The agent can read the project (`$PWD` mounted at `/workspace`) and the mounted gcloud credentials.

## Layout

| Path | What |
|---|---|
| `pi-agent` | Launcher script (install as `~/.local/bin/pi-agent`) |
| `Dockerfile.pi` | Image `pi-sandbox`: openSUSE Tumbleweed + Node, ripgrep, jq, mkmedia, xorriso, SUSE CA |
| `pi-settings.json`, `pi-models.json` | Pi config, mounted read-only (default model, Vertex/Ollama providers, packages) |
| `APPEND_SYSTEM.md` | Extra system prompt |
| `prompts/` | Prompt templates (`refactor`) |
| `skills-custom/` | Own skills: `download-iso`, `modify-iso`, `prepare-iso` (SLES 16.x test ISOs) |
| `skills/` | Downloaded third-party skills (`find-skills`, `herdr`), always read-only |
| `pi-extensions-custom/` | Extensions (`goku-header.ts`) |
| `.env` | Non-sensitive config, gitignored; copy from `.env.example` |

## Usage

```bash
pi-agent [--dev] [args]             # run the agent in a fresh --rm container
pi-agent secret set|ls|rm <NAME>    # env secrets (tokens), stored in podman secrets
```

`--dev` mounts `skills-custom`, `pi-extensions-custom` and `APPEND_SYSTEM.md` read-write
(default is read-only). Secrets are injected as env vars of the same name.

Non-sensitive config (project ID, region) goes in `.env` (see `.env.example`).

## Rebuilding the agent image

```bash
cd ~/.agent-custom
podman build -f Dockerfile.pi -t pi-sandbox .
# fresh Pi version / base image (the npm layer is otherwise cached):
podman build --no-cache --pull=newer -f Dockerfile.pi -t pi-sandbox .
```

No restart needed: each `pi-agent` run starts a new container from the image.
State lives in the `pi-agent-home` volume and survives rebuilds.

## Sandbox

- Rootless podman, `--cap-drop=ALL`, `no-new-privileges`.
- gcloud credentials mounted read-only; Pi's own `~/.pi/agent` is not mounted from the host.
