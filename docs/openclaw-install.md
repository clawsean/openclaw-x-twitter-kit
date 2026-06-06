# OpenClaw install notes

OpenClaw loads AgentSkills-compatible folders containing `SKILL.md`. The most direct install path is to copy or symlink this repo's skill folder into your OpenClaw workspace.

## Option A: copy into a workspace

```bash
git clone https://github.com/clawSean/openclaw-x-twitter-kit.git
cp -R openclaw-x-twitter-kit/skills/x-twitter-kit ~/.openclaw/workspace/skills/
```

Start a new OpenClaw turn/session so the skills snapshot refreshes, then ask the agent to use the `x-twitter-kit` skill.

If your workspace already has a host-specific Twitter/search skill, keep that
skill as the user-facing routing policy and use this kit for setup,
diagnostics, and proof. Do not copy host-specific account names, secret refs, or
standing action policies into this public skill.

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
