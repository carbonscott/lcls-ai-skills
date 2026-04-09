# lcls-ai-skills

Registry and installer for LCLS AI agent skills. Install skills individually for Claude Code or OpenCode.

## Quick start

```bash
git clone https://github.com/carbonscott/lcls-ai-skills.git
cd lcls-ai-skills

# List available skills
bash install.sh --list

# Install a specific skill (--target is required)
bash install.sh --target ~/.claude/skills ask-slurm-s3df

# Install multiple skills
bash install.sh --target ~/.claude/skills ask-s3df ask-olcf

# Install all skills
bash install.sh --target ~/.claude/skills --all
```

## Available skills

| Skill | Description | Data setup |
|-------|-------------|-----------|
| [ask-slurm-s3df](https://github.com/carbonscott/skill-ask-slurm-s3df) | S3DF Slurm cluster assistant | None (live commands) |
| [docs-search](https://github.com/carbonscott/skill-docs-search) | Documentation indexing tool (docs-index) | None |
| [ask-s3df](https://github.com/carbonscott/skill-ask-s3df) | S3DF documentation assistant | Clones sdf-docs repo |
| [ask-olcf](https://github.com/carbonscott/skill-ask-olcf) | OLCF documentation assistant | Clones olcf-user-docs repo |
| [ask-epics](https://github.com/carbonscott/skill-ask-epics) | EPICS documentation assistant | Clones 26 epics-base repos |
| [askcode](https://github.com/carbonscott/skill-askcode) | Code indexing with tree-sitter | On-demand |

## Prerequisites

- **jq** (for the installer): `brew install jq` or `apt install jq`
- **uv** (for docs-index skills): https://docs.astral.sh/uv/
- **Git** (for cloning skills and data repos)

## How it works

Each skill is an independent GitHub repo. The installer:
1. Clones the skill repo to the directory you specify with `--target`
2. Auto-installs dependencies (e.g., ask-s3df pulls in docs-search)
3. Offers to run `setup.sh` for data-backed skills (clones upstream docs, builds search index)

You can also install any skill manually without the registry:
```bash
git clone https://github.com/carbonscott/skill-ask-s3df.git ~/.claude/skills/ask-s3df
cd ~/.claude/skills/ask-s3df && bash setup.sh
```

## Customization

Each skill supports path customization via `env.local` (gitignored):
```bash
# Point to a shared data location instead of skill-local
echo 'export SDF_DOCS_ROOT="/shared/data/sdf-docs"' > ~/.claude/skills/ask-s3df/env.local
```

## License

Apache-2.0
