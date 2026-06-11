# Tests for _opah_doctor per-account authentication checks
#
# Run with: fishtape tests/test_doctor.fish
# Install fishtape: fisher install jorgebucaran/fishtape

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
source (status dirname)/../functions/_opah_find_config.fish
source (status dirname)/../functions/_opah_parse_yaml.fish
source (status dirname)/../functions/_opah_extract_accounts.fish
source (status dirname)/../functions/_opah_cache_count.fish
source (status dirname)/../functions/_opah_mtime.fish
source (status dirname)/../functions/_opah_perms.fish
source (status dirname)/../functions/_opah_doctor.fish

# ── Fixtures ──────────────────────────────────────────────────────────────────

set tmp (mktemp -d)
set config_qualified "$tmp/secrets_qualified.yaml"
set config_unqualified "$tmp/secrets_unqualified.yaml"
set cache_file "$tmp/cache/opah/secrets.fish"

printf "secrets:\n  WORK_KEY: op://work/Vault/Item/field\n" >"$config_qualified"
printf "secrets:\n  API_KEY: op://Vault/Item/field\n" >"$config_unqualified"

# ── Per-account auth rows ─────────────────────────────────────────────────────

@test "doctor: names account identifier in auth output when account is signed in" \
    (begin
        function _opah_get_config_paths; echo "$config_qualified"; end
        function _opah_get_cache_dir; echo "$tmp/cache/opah"; end
        function _opah_get_cache_file; echo "$tmp/cache/opah/secrets.fish"; end
        function op
            switch "$argv[1]"
                case --version; echo "2.0.0-mock"; return 0
                case account; printf '[{"url":"work.1password.com","shorthand":"work"}]\n'; return 0
            end
            return 1
        end
        _opah_doctor 2>/dev/null | string match -q "*work*"
        echo $status
    end) -eq 0

@test "doctor: not-signed-in account is counted as an issue" \
    (begin
        function _opah_get_config_paths; echo "$config_qualified"; end
        function _opah_get_cache_dir; echo "$tmp/cache/opah"; end
        function _opah_get_cache_file; echo "$tmp/cache/opah/secrets.fish"; end
        function op
            switch "$argv[1]"
                case --version; echo "2.0.0-mock"; return 0
                case account; printf '[{"url":"personal.1password.com","shorthand":"personal"}]\n'; return 0
            end
            return 1
        end
        _opah_doctor 2>/dev/null | string match -q "*issue*"
        echo $status
    end) -eq 0

@test "doctor: unqualified-only config shows single auth row without account identifier" \
    (begin
        function _opah_get_config_paths; echo "$config_unqualified"; end
        function _opah_get_cache_dir; echo "$tmp/cache/opah"; end
        function _opah_get_cache_file; echo "$tmp/cache/opah/secrets.fish"; end
        function op
            switch "$argv[1]"
                case --version; echo "2.0.0-mock"; return 0
                case account; printf '[{"email":"me@example.com","url":"my.1password.com","shorthand":"my"}]\n'; return 0
            end
            return 1
        end
        set -l output (_opah_doctor 2>/dev/null)
        # Must contain the generic signed-in message, not a per-account row
        if string match -q "*Signed in to 1Password*" -- $output
            and not string match -q "*(my)*" -- $output
            echo ok
        end
    end) = ok

@test "doctor: names account identifier in auth output when account is not signed in" \
    (begin
        function _opah_get_config_paths; echo "$config_qualified"; end
        function _opah_get_cache_dir; echo "$tmp/cache/opah"; end
        function _opah_get_cache_file; echo "$tmp/cache/opah/secrets.fish"; end
        function op
            switch "$argv[1]"
                case --version; echo "2.0.0-mock"; return 0
                case account; printf '[{"url":"personal.1password.com","shorthand":"personal"}]\n'; return 0
            end
            return 1
        end
        _opah_doctor 2>/dev/null | string match -q "*work*"
        echo $status
    end) -eq 0

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf $tmp
