# pi-sandbox

Personal setup for running the [Pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)
in a rootless podman container, with custom skills, prompts and a TUI header extension.
The agent can read the project (`$PWD` mounted at `/workspace`) and the mounted gcloud ADC file.

## Layout

| Path | What |
|---|---|
| `pi-sandbox` | Launcher script (install as `~/.local/bin/pi-sandbox`) |
| `Dockerfile.pi` | Image `pi-sandbox`: openSUSE Tumbleweed + Node, ripgrep, jq, mkmedia, xorriso, SUSE CA |
| `pi-settings.json`, `pi-models.json`, `web-search.json` | Pi config, mounted read-only (default model, Vertex/Ollama providers, packages, web-search) |
| `APPEND_SYSTEM.md` | Extra system prompt |
| `prompts/` | Prompt templates (`refactor`) |
| `skills-custom/` | Own skills: `download-iso`, `modify-iso`, `prepare-iso` (SLES 16.x test ISOs) |
| `skills/` | Downloaded third-party skills (`find-skills`, `herdr`), read-only except in `dev` |
| `extensions-custom/` | Extensions (`goku-header.ts`) |
| `.env` | Non-sensitive config, gitignored; copy from `.env.example` |

## Usage

```bash
pi-sandbox [--profile restricted|dev] [args]  # run the agent in a fresh --rm container
```

Profiles select the pi-permission-system config (`extensions/pi-permission-system/`) and mount mode:

| Profile | Config | Mounts |
|---|---|---|
| `restricted` (default) | `config.json`: deny-by-default, for unattended tasks | all read-only |
| `dev` | `config.dev.json`: allow-by-default, `ask` for destructive bash/external dirs | `skills-custom`, `skills`, `prompts`, `extensions-custom`, `APPEND_SYSTEM.md`, `pi-settings.json`, `pi-models.json`, `web-search.json` read-write |

Non-sensitive config (project ID, region) goes in `.env` (see `.env.example`).

## Rebuilding the agent image

```bash
cd ~/Code/pi-sandbox
podman build -f Dockerfile.pi -t pi-sandbox .
# fresh Pi version / base image (the npm layer is otherwise cached):
podman build --no-cache --pull=newer -f Dockerfile.pi -t pi-sandbox .
```

No restart needed: each `pi-sandbox` run starts a new container from the image.
State lives in the `pi-agent-home` volume and survives rebuilds.

## Sandbox

- Rootless podman, `--cap-drop=ALL`, `no-new-privileges`.
- Only `application_default_credentials.json` is mounted (read-only), not the whole `~/.config/gcloud`; Pi's own `~/.pi/agent` is not mounted from the host.
