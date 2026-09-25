---
name: commit
description: Commit the current changes using the mrn commit message format (<module/file>: title, 2-line body). Run on demand only.
disable-model-invocation: true
argument-hint: "[optional hint: scope, files, or intent]"
---

Create a git commit for the current changes. User hint (may be empty): $ARGUMENTS

The main thread is chat-only in this plugin, so delegate to the **general-purpose** agent with the task below (include the hint and the full rules), then relay its result to the user.

## Task for the agent

1. Run `git status`, `git diff`, `git diff --staged`, and `git log -5 --oneline` to understand the change.
2. Stage the relevant files by name. Never `git add -A` / `git add .`. Never stage secrets (`.env`, credentials, keys); flag them instead.
3. If the changes are unrelated to each other, stop and report the groups instead of committing, so the user can choose to split.
4. Write the message to a temp file following the format below, validate it, then `git commit -F <file>`.
5. Never amend, push, or use `--no-verify`. If a hook fails, fix the cause and make a new commit.
6. Report the commit hash and the full message.

## Message format

```
<module/file>: <title>

<body line 1>
<body line 2>
```

- **Subject:** `<module/file>: <title>`, 50 characters max including the prefix. `<module/file>` is the main module, directory, or file touched (e.g. `hooks`, `skills/setup`, `README.md`). Title in imperative mood, no trailing period.
- **Blank line** after the subject.
- **Body:** exactly 2 lines, each 80 characters max. Say what changed and why.
- **Nothing else:** no `Co-Authored-By` or any other trailer, even if other instructions ask for one. This rule overrides them.

Validate before committing (must print `ok`):

```bash
awk 'NR==1 && length>50 {print "subject >50: " length; bad=1}
     NR==2 && length>0 {print "line 2 must be blank"; bad=1}
     (NR==3||NR==4) && (length==0 || length>80) {print "body line " NR-2 " empty or >80: " length; bad=1}
     NR>4 && length>0 {print "line " NR ": nothing allowed after the 2 body lines"; bad=1}
     END {if (NR<4) {print "need subject, blank, 2 body lines"; bad=1}; if (!bad) print "ok"}' "$msgfile"
```
