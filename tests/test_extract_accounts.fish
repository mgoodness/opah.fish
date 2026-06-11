# Tests for _opah_extract_accounts
#
# Run with: fishtape tests/test_extract_accounts.fish
# Install fishtape: fisher install jorgebucaran/fishtape

source (status dirname)/../functions/_opah_extract_accounts.fish

@test "extract_accounts: returns account from 4-part URI" \
    (_opah_extract_accounts op://work/Vault/Item/field) = work

@test "extract_accounts: 3-part URI returns nothing" \
    (count (_opah_extract_accounts op://Vault/Item/field)) -eq 0

@test "extract_accounts: deduplicates repeated account identifiers" \
    (count (_opah_extract_accounts op://work/V/I/f op://work/V/I/g)) -eq 1

@test "extract_accounts: mixed input returns only accounts from 4-part URIs" \
    (count (_opah_extract_accounts op://work/V/I/f op://Vault/Item/field op://personal/V/I/f)) -eq 2

@test "extract_accounts: no arguments returns no output" \
    (count (_opah_extract_accounts)) -eq 0

@test "extract_accounts: no arguments exits 0" \
    (_opah_extract_accounts >/dev/null 2>&1; echo $status) -eq 0
