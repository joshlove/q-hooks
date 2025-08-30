#!/bin/bash
# Team Q Context Hooks Setup Script
# Run this to install shared context hooks for Amazon Q
# These run silently before each message you send to Q. This adds to the execution time for each prompt
# They'll time out after 5 seconds by our default config, so be concise with your hooks 

set -e

HOOKS_DIR="$HOME/.config/q/hooks"
CONFIG_FILE="$HOME/.config/q/config.yaml"

echo "Setting up shared Q context hooks..."

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Git context hook
cat > "$HOOKS_DIR/git-context.sh" << 'EOF'
#!/bin/bash
current_branch=$(git branch --show-current 2>/dev/null || echo "not-a-repo")
if [ "$current_branch" != "not-a-repo" ]; then
    echo "GIT_BRANCH: $current_branch"
    echo "GIT_STATUS: $(git status --porcelain | wc -l) files changed"
    
    # Check for potential conflicts with main
    if git show-ref --verify --quiet refs/heads/main; then
        modified_files=$(git diff --name-only main..HEAD 2>/dev/null || echo "")
        branch_point=$(git merge-base HEAD main 2>/dev/null || echo "")
        if [ -n "$branch_point" ]; then
            target_modified=$(git diff --name-only $branch_point..main 2>/dev/null || echo "")
            conflicts=$(comm -12 <(echo "$modified_files" | sort) <(echo "$target_modified" | sort) 2>/dev/null || echo "")
            if [ -n "$conflicts" ]; then
                echo "POTENTIAL_CONFLICTS: $conflicts"
            fi
        fi
    fi
fi
EOF

# Project type detector hook
cat > "$HOOKS_DIR/project-context.sh" << 'EOF'
#!/bin/bash
if [ -f package.json ]; then
    echo "PROJECT_TYPE: nodejs"
    node --version 2>/dev/null || echo "NODE_VERSION: not installed"
elif [ -f requirements.txt ]; then
    echo "PROJECT_TYPE: python"
    python --version 2>/dev/null || python3 --version 2>/dev/null || echo "PYTHON_VERSION: not installed"
elif [ -f Cargo.toml ]; then
    echo "PROJECT_TYPE: rust"
    cargo --version 2>/dev/null || echo "CARGO_VERSION: not installed"
elif [ -f pom.xml ]; then
    echo "PROJECT_TYPE: java"
    java --version 2>/dev/null || echo "JAVA_VERSION: not installed"
elif [ -f go.mod ]; then
    echo "PROJECT_TYPE: go"
    go version 2>/dev/null || echo "GO_VERSION: not installed"
else
    echo "PROJECT_TYPE: unknown"
fi
EOF

# AWS context hook
cat > "$HOOKS_DIR/aws-context.sh" << 'EOF'
#!/bin/bash
if command -v aws >/dev/null 2>&1; then
    profile=$(aws configure list | grep profile | awk '{print $2}' 2>/dev/null || echo "default")
    region=$(aws configure get region 2>/dev/null || echo "not-set")
    echo "AWS_PROFILE: $profile"
    echo "AWS_REGION: $region"
fi
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR"/*.sh

# Create Q config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << 'EOF'
context_hooks:
  global:
    - git-context.sh
    - project-context.sh
    - aws-context.sh
  enabled: true
  timeout: 5
EOF
else
    echo "Config file exists at $CONFIG_FILE - you may need to manually add hooks configuration"
fi

# Set up git template for new repos
git config --global init.templateDir ~/.git-template
mkdir -p ~/.git-template/q-hooks
cp "$HOOKS_DIR"/*.sh ~/.git-template/q-hooks/

echo "✅ Q context hooks installed successfully!"
echo ""
echo "Hooks installed:"
echo "  - Git context (branch, conflicts, status)"
echo "  - Project type detection"
echo "  - AWS profile/region info"
echo ""
echo "New git repositories will automatically include these hooks."
echo "Run 'q chat' to test the setup."
