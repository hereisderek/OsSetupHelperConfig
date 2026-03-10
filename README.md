# ⚙️ OsSetupHelper Configuration

This repository contains your personal configuration for the OsSetupHelper. You can fork this repository to customize your OS installation process.

## 📂 Structure

- `config.yaml`: The primary configuration file where you enable/disable apps and settings.
- `preinstall/`: Place `.sh` scripts here to run before any Ansible tasks.
- `postinstall/`: Place `.sh` scripts here to run after all Ansible tasks are finished.
- `ansible_tasks/`:
    - `pre.yml`: Custom Ansible tasks to run before role execution.
    - `post.yml`: Custom Ansible tasks to run after all roles are finished.
- `user_env/`: Files here are automatically copied to `~/.config/env/app/`.
- `apps/`, `commandline_tools/`, `settings/`:
    - You can create a folder with the same name as a role (e.g., `apps/chrome/`).
    - Inside that folder, create `pre.yml` and/or `post.yml` to run custom tasks before or after that specific role is executed.

## 🚀 Usage

Run the orchestrator with your fork's URL:

```bash
python3 orchestrator.py --config https://github.com/your-username/OsSetupHelperConfig.git
```
