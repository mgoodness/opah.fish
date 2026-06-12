# opah.fish

A Fish shell plugin that loads 1Password secrets into environment variables on shell startup, using a local cache to avoid calling the 1Password CLI on every prompt.

## Language

**Account**:
A distinct 1Password subscription, identified by its shorthand or sign-in address (e.g., `work`, `personal`, `my.1password.com`). One user may have multiple accounts.
_Avoid_: Vault, tenant, profile

**Secret reference**:
An `op://` URI stored in the config file that points to a specific field in a 1Password item. opah never stores or logs the resolved value — only the reference.
_Avoid_: Secret path, op URL, credential reference

**Account block**:
A named section under `accounts:` in the config file, keyed by a 1Password sign-in address (e.g., `work.1password.com`). All secret references inside it are fetched using that account via `op read --account`.
_Avoid_: Account group, account section, profile

**Default block**:
The `secrets:` section in the config file. Secret references here are fetched without an explicit `--account` flag, using whichever account the 1Password CLI considers active. Compatible with all existing single-account configs.
_Avoid_: Unqualified block, legacy block, global block

**Cache**:
The local tab-separated file (`~/.cache/fish/opah/secrets.fish`) that stores resolved secret values between shell sessions. Populated by `opah refresh`; invalidated by `opah clear`.
_Avoid_: Secret store, local store, dotfile
