# ⚙️ OsSetupHelper Configuration

This repository contains your personal configuration for the OsSetupHelper. You can fork this repository to customize your OS installation process.

## 📂 Structure

- `config.yaml`: The primary configuration file where you enable/disable apps, cli tools, and settings.
- `preinstall/`: Place `.sh` scripts here to run before any Ansible tasks.
- `postinstall/`: Place `.sh` scripts here to run after all Ansible tasks are finished.
- `ansible_tasks/`:
    - `pre.yml`: Custom Ansible tasks to run before role execution.
    - `post.yml`: Custom Ansible tasks to run after all roles are finished.
- `user_env/`: Files here are automatically copied to `~/.config/env/`.
- `content/apps/`, `content/cli/`, `content/settings/`: Mirrors the engine repo's own `content/` layout (`<category>/<common|mac|linux|win>/<role_name>/`), and is checked **before** it — so anything you put here takes priority. Two things you can do here:
    - **Override an existing role.** Create `content/<category>/<os>/<role_name>/` with the same name as a role that already exists in the engine repo, and your version is used instead (works for `tasks/`, `defaults/`, everything — a full role replacement).
    - **Add a brand-new role.** Same as above, but with a name the engine repo doesn't have — it's discovered and usable in `config.yaml` just like a built-in one.
    - Scaffold either with `./new_role.sh <apps|cli|settings> <common|mac|linux|win> <role_name> --config` from the engine repo.
- `content/apps/<role_name>/`, `content/cli/<role_name>/`, `content/settings/<role_name>/` (**no** `common`/`mac`/`linux`/`win` in the path — just the role name directly): a lighter-weight hook mechanism for a role that already exists, without replacing it — create `pre.yml` and/or `post.yml` here to run custom tasks before/after that role, or `tasks.yml` to fully replace just its task logic while keeping its `defaults`/`meta`.

## 🚀 Usage

Run the orchestrator with your fork's URL:

```bash
python3 orchestrator.py --config https://github.com/your-username/OsSetupHelperConfig.git
```
