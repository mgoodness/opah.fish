# Multi-account secrets grouped under `accounts:` blocks keyed by sign-in address

When a user has secrets across multiple 1Password accounts, those secrets are grouped in the config under an `accounts:` top-level key, with each sub-key being the account's sign-in address (e.g., `work.1password.com`). opah passes that address via `op read --account <sign-in-address>` when fetching secrets in that block. The existing `secrets:` block is preserved as the default (no `--account` flag), keeping all single-account configs unchanged.

A flat per-secret annotation approach was considered but rejected: it would require changing the value schema (from a plain `op://` string to a map) and offers no benefit for the common case where all secrets in a block share one account. A user-defined alias approach was also rejected: it would require opah to maintain a separate alias-to-address mapping with no payoff, since sign-in addresses are already short and stable identifiers.
