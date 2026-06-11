# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `mgoodness/opah.fish`. Use the `gh` CLI with `--repo mgoodness/opah.fish` for all operations.

## Conventions

- **Create an issue**: `gh issue create --repo mgoodness/opah.fish --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --repo mgoodness/opah.fish --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --repo mgoodness/opah.fish --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --repo mgoodness/opah.fish --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --repo mgoodness/opah.fish --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --repo mgoodness/opah.fish --comment "..."`

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --repo mgoodness/opah.fish --comments`.
