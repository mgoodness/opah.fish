function _opah_extract_accounts -d "Extract unique account identifiers from account-qualified op:// URIs"
    set -l seen
    for uri in $argv
        set -l parts (string split / "$uri")
        if test (count $parts) -eq 6
            set -l account $parts[3]
            if not contains -- "$account" $seen
                set -a seen "$account"
                echo "$account"
            end
        end
    end
end
