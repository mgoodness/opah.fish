# opah.fish

A Fish shell plugin that loads 1Password secrets into environment variables on shell startup, using a local cache to avoid calling the 1Password CLI on every prompt.

## Language

**Account**:
A distinct 1Password subscription, identified by its shorthand or sign-in address (e.g., `work`, `personal`, `my.1password.com`). One user may have multiple accounts.
_Avoid_: Vault, tenant, profile

**Secret reference**:
An `op://` URI stored in the config file that points to a specific field in a 1Password item. opah never stores or logs the resolved value — only the reference.
_Avoid_: Secret path, op URL, credential reference

**Account-qualified reference**:
A 4-part secret reference — `op://account/vault/item/field` — that names the account explicitly. Required when secrets span multiple accounts.
_Avoid_: Full reference, long reference

**Unqualified reference**:
A 3-part secret reference — `op://vault/item/field` — that resolves against whichever account the 1Password CLI considers default. Sufficient when all secrets belong to one account.
_Avoid_: Short reference, legacy reference

**Cache**:
The local tab-separated file (`~/.cache/fish/opah/secrets.fish`) that stores resolved secret values between shell sessions. Populated by `opah refresh`; invalidated by `opah clear`.
_Avoid_: Secret store, local store, dotfile
