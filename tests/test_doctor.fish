# Tests for _opah_doctor — Authentication section
#
# Uses mock `op` and path functions — no real 1Password connection required.
#
# Run with: fishtape tests/test_doctor.fish

source (status dirname)/../functions/_opah_ui.fish
source (status dirname)/../functions/_opah_success.fish
source (status dirname)/../functions/_opah_error.fish
source (status dirname)/../functions/_opah_warning.fish
source (status dirname)/../functions/_opah_info.fish
source (status dirname)/../functions/_opah_section.fish
source (status dirname)/../functions/_opah_hint.fish
source (status dirname)/../functions/_opah_header.fish
source (status dirname)/../functions/_opah_get_config_paths.fish
source (status dirname)/../functions/_opah_get_cache_dir.fish
source (status dirname)/../functions/_opah_get_cache_file.fish
source (status dirname)/../functions/_opah_cache_count.fish
source (status dirname)/../functions/_opah_parse_yaml.fish
source (status dirname)/../functions/_opah_find_config.fish
source (status dirname)/../functions/_opah_doctor.fish

# ── Fixtures ──────────────────────────────────────────────────────────────────

set tmp (mktemp -d)

set secrets_config "$tmp/secrets.yaml"
printf "secrets:\n  API_KEY: op://Vault/Item/key\n" >"$secrets_config"

set accounts_config "$tmp/accounts.yaml"
printf "accounts:\n  work.1password.com:\n    WORK_KEY: op://Work/Item/key\n" >"$accounts_config"

set mixed_config "$tmp/mixed.yaml"
printf "secrets:\n  API_KEY: op://Vault/Item/key\naccounts:\n  work.1password.com:\n    WORK_KEY: op://Work/Item/key\n  personal.1password.com:\n    HOME_KEY: op://Personal/Item/key\n" >"$mixed_config"

# Shared mock for path functions; each test overrides _opah_find_config as needed
function mock_doctor_paths
    function _opah_get_cache_dir; echo "$tmp/cache/opah"; end
    function _opah_get_cache_file; echo "$tmp/cache/opah/secrets.fish"; end
    function _opah_get_config_paths; echo "$tmp/secrets.yaml"; end
end

# Helper: run doctor with given config and op mock, strip ANSI, return lines
# Usage: run_doctor <config_file> <account_list_json>
# Uses globals _rd_config and _rd_json to pass values into inner mock functions
# (Fish inner functions do not close over outer locals)
function run_doctor -a config_file account_list_json
    set -g _rd_config $config_file
    set -g _rd_json $account_list_json
    mock_doctor_paths
    function _opah_find_config; echo $_rd_config; end
    function op
        switch $argv[1]
            case version; echo "2.0.0"; return 0
            case account
                switch $argv[2]
                    case list; echo $_rd_json; return 0
                end
            case read; echo "secret_value"; return 0
        end
        return 1
    end
    mkdir -p "$tmp/cache/opah"
    printf 'CACHED_KEY\tcached_value\n' >"$tmp/cache/opah/secrets.fish"
    chmod 600 "$tmp/cache/opah/secrets.fish"
    _opah_doctor 2>/dev/null | string replace -ra '\e\[[0-9;]*m' ''
end

# ── Authentication: accounts block ────────────────────────────────────────────

@test "doctor: accounts-block config shows sign-in address in auth section" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"work.1password.com"}]')
        string match -q "*work.1password.com*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: signed-in account shows success row" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"work.1password.com"}]')
        string match -q "* ● *work.1password.com*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: missing account shows error row with address" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"personal.1password.com"}]')
        string match -q "* ✕ *work.1password.com*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: missing account row includes op signin --account hint" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"personal.1password.com"}]')
        string match -q "*op signin --account work.1password.com*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: missing account increments issues counter" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"personal.1password.com"}]')
        string match -q "*issue(s) detected*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: secrets-only config shows single signed-in row" \
    (begin
        set -l out (run_doctor "$secrets_config" '[{"url":"my.1password.com","email":"me@example.com"}]')
        string match -q "*Signed in to 1Password*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: secrets-only config does not show per-address rows" \
    (begin
        set -l out (run_doctor "$secrets_config" '[{"url":"my.1password.com"}]')
        string match -q "*my.1password.com*" $out
        and echo found; or echo not-found
    end) = not-found

@test "doctor: signed-in account with pretty-printed JSON (space after colon) shows success row" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url": "work.1password.com"}]')
        string match -q "* ● *work.1password.com*" $out
        and echo found; or echo not-found
    end) = found

@test "doctor: accounts-only config with all op:// values shows no non-op warning" \
    (begin
        set -l out (run_doctor "$accounts_config" '[{"url":"work.1password.com"}]')
        string match -q "*value(s) are not 1Password references*" $out
        and echo found; or echo not-found
    end) = not-found

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
