# OpenClaw install notes

OpenClaw loads AgentSkills-compatible folders containing `SKILL.md`. The most direct install path is to copy or symlink this repo's skill folder into your OpenClaw workspace.

## Option A: copy into a workspace

```bash
git clone https://github.com/clawSean/openclaw-x-twitter-kit.git
cp -R openclaw-x-twitter-kit/skills/x-twitter-kit ~/.openclaw/workspace/skills/
```

Start a new OpenClaw turn/session so the skills snapshot refreshes, then ask the agent to use the `x-twitter-kit` skill.

Do not keep a separate host-specific Twitter/search skill active for the same
workspace. `x-twitter-kit` should be the one agent-facing Twitter/X skill.

For local account expectations and standing policies, create an untracked local
defaults file:

```bash
cp ~/.openclaw/workspace/skills/x-twitter-kit/templates/LOCAL_DEFAULTS.example.md \
  ~/.openclaw/workspace/skills/x-twitter-kit/LOCAL_DEFAULTS.md
```

Edit the local copy with profile names, expected usernames, secret refs, and
standing policies. Do not store token values, OAuth callback codes, access
tokens, refresh tokens, or bearer token values in that file.

## Option B: load from this repo as an extra skill directory

If you keep helper repos outside the workspace, configure OpenClaw `skills.load.extraDirs` to include the repo's `skills` directory.

Example shape:

```json5
{
  skills: {
    load: {
      extraDirs: ["/path/to/openclaw-x-twitter-kit/skills"]
    }
  }
}
```

OpenClaw docs note that workspace skills take highest precedence, while `skills.load.extraDirs` has lower precedence. Keep extra dirs narrow and trusted.

## Smoke test after install

```bash
cd /path/to/openclaw-x-twitter-kit
XTK_EXPECTED_X_USERNAME=your_x_handle \
XTK_BOOKMARK_APP=default \
skills/x-twitter-kit/scripts/twitter-doctor.sh
```

Set `XTK_BOOKMARK_APP` if OAuth2-only endpoints such as bookmarks are attached to a separate xurl app name.
