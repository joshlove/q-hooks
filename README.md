# Amazon Q Context Hooks

## How Context Hooks Work

Amazon Q context hooks are scripts that run automatically before each chat message to gather information about your current environment. They execute silently in the background, providing Amazon Q with real-time context about your git status, project type, AWS configuration, and more.

When you send a message in `q chat`, these hooks run first (within a 5-second timeout) and their output gets included with your message. This allows Amazon Q to give more relevant, targeted responses without you having to manually explain your current situation each time.

## Setup

Run the setup script to install shared context hooks for your team:

```bash
./setup-q-hooks.sh
```

This creates hooks in `~/.config/q/hooks/` and configures them to run automatically.

## Installed Hooks

### git-context.sh
**Purpose**: Provides git repository information and conflict detection

**What it reports to the model**:
- Current branch name
- Number of modified files
- Potential merge conflicts with main branch
- Files that overlap between your branch and main

**Example output sent to the model**:
```
GIT_BRANCH: feature/login-fix
GIT_STATUS: 3 files changed
POTENTIAL_CONFLICTS: src/auth.py config/settings.json
```

### project-context.sh
**Purpose**: Detects project type and runtime versions, making Q aware of the type of project you're working on

**What it reports**:
- Project type based on configuration files
- Runtime version information

**Supported project types**:
- Node.js (detects `package.json`)
- Python (detects `requirements.txt`)
- Rust (detects `Cargo.toml`)
- Java (detects `pom.xml`)
- Go (detects `go.mod`)

**Example output to the model**:
```
PROJECT_TYPE: nodejs
NODE_VERSION: v18.17.0
```

### aws-context.sh
**Purpose**: Shows current AWS configuration

**What it reports**:
- Active AWS profile
- Configured AWS region

**Example output to the model**:
```
AWS_PROFILE: development
AWS_REGION: us-west-2
```

## Benefits

- **Automatic Context**: No need to repeatedly explain your environment
- **Conflict Prevention**: Early warning about potential git merge conflicts
- **Environment Awareness**: Amazon Q knows your project type and AWS setup
- **Team Consistency**: Everyone gets the same helpful context automatically

## Configuration

Hooks are configured in `~/.config/q/config.yaml`:

```yaml
context_hooks:
  global:
    - git-context.sh
    - project-context.sh
    - aws-context.sh
  enabled: true
  timeout: 5
```

New git repositories automatically get these hooks via the git template system configured by the setup script.
