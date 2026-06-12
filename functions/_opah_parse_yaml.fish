#
# Parse secrets from YAML configuration file and output as tab-separated stream
#
# Parses a YAML configuration file looking for `secrets:` and `accounts:` sections.
# Outputs each secret as a tab-separated line: KEY<tab>VALUE<tab>ACCOUNT
# ACCOUNT is empty for entries in the `secrets:` block; it is the sign-in address
# (e.g. work.1password.com) for entries under `accounts: <address>:` blocks.
#
# @param config_file The path to the YAML configuration file
# @return 0 if at least one secrets or accounts section found, 1 otherwise
#
function _opah_parse_yaml -d "Parse secrets from YAML configuration file and output as tab-separated stream"
    set -l config_file $argv[1]

    if test -z "$config_file"
        echo "Usage: _opah_parse_yaml CONFIG_FILE" >&2
        return 1
    end

    if not test -f "$config_file"
        echo "Config file not found: $config_file" >&2
        return 1
    end

    set -l in_section none
    set -l base_indent ""
    set -l current_account ""
    set -l found_secrets false

    while read -l line
        # Skip empty lines and comments
        if string match -qr '^\s*(#|$)' "$line"
            continue
        end

        # Detect section headers (must come before the exit check)
        if string match -qr '^\s*secrets:\s*($|#.*$)' "$line"
            set in_section secrets
            set found_secrets true
            set base_indent (string replace -r '^(\s*).*$' '$1' "$line")
            set current_account ""
            continue
        end

        if string match -qr '^\s*accounts:\s*($|#.*$)' "$line"
            set in_section accounts
            set found_secrets true
            set base_indent (string replace -r '^(\s*).*$' '$1' "$line")
            set current_account ""
            continue
        end

        # If not in a section, skip
        if test "$in_section" = none
            continue
        end

        set -l current_indent (string replace -r '^(\s*).*$' '$1' "$line")

        # Exit section when indent returns to base level
        if test (string length "$current_indent") -le (string length "$base_indent"); and string match -q "*:*" "$line"
            set in_section none
            continue
        end

        if test "$in_section" = secrets
            if string match -q "*:*" "$line"
                set -l parts (string split -m 1 ":" "$line")
                set -l key (string trim $parts[1])
                set -l value (string trim $parts[2])
                set value (string replace -ra '^["\']|["\']$' '' "$value")
                if string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' "$key"
                    if test -n "$key"; and test -n "$value"
                        printf '%s\t%s\t\n' "$key" "$value"
                    end
                else if test -n "$key"
                    echo "Warning: Skipping invalid key '$key' (must match ^[A-Za-z_][A-Za-z0-9_]*\$)" >&2
                end
            end
        else if test "$in_section" = accounts
            if string match -q "*:*" "$line"
                set -l parts (string split -m 1 ":" "$line")
                set -l key (string trim $parts[1])
                set -l raw_value (string replace -r '\s*#.*$' '' (string trim $parts[2]))
                set -l value (string replace -ra '^["\']|["\']$' '' "$raw_value")

                if test -z "$value"
                    # Account header: work.1password.com:
                    set current_account $key
                else
                    # Secret key-value pair under an account
                    if string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' "$key"
                        if test -n "$key"; and test -n "$value"; and test -n "$current_account"
                            printf '%s\t%s\t%s\n' "$key" "$value" "$current_account"
                        end
                    else if test -n "$key"
                        echo "Warning: Skipping invalid key '$key' (must match ^[A-Za-z_][A-Za-z0-9_]*\$)" >&2
                    end
                end
            end
        end
    end <"$config_file"

    if test "$found_secrets" = true
        return 0
    else
        return 1
    end
end
