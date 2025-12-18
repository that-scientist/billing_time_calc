# Git Workflow Guide

This repository uses Git for version control to allow safe experimentation with new features.

## Branching Strategy

### Main Branch
- `main` - The stable, production-ready version
- Always keep this branch in a working state
- Only merge tested, working features into main

### Feature Branches
Create feature branches for new functionality:

```bash
# Create and switch to a new feature branch
git checkout -b feature/new-feature-name

# Make your changes, test them
# ...

# Commit your changes
git add .
git commit -m "Description of changes"

# Switch back to main when done experimenting
git checkout main
```

## Common Git Commands

### Creating a Branch
```bash
# Create and switch to a new branch
git checkout -b feature/experiment-name

# Or create branch without switching
git branch feature/experiment-name
```

### Switching Branches
```bash
# Switch to main branch
git checkout main

# Switch to a feature branch
git checkout feature/experiment-name
```

### Viewing Branches
```bash
# List all branches
git branch

# List all branches (including remote)
git branch -a
```

### Merging Changes
```bash
# Switch to main first
git checkout main

# Merge feature branch into main
git merge feature/experiment-name

# Delete feature branch after merging (optional)
git branch -d feature/experiment-name
```

### Discarding Changes
```bash
# Discard all uncommitted changes
git checkout .

# Discard changes to a specific file
git checkout -- filename.swift

# Reset to last commit (destructive!)
git reset --hard HEAD
```

### Viewing History
```bash
# View commit history
git log

# View commit history (one line per commit)
git log --oneline

# View changes in a file
git log -p filename.swift
```

## Workflow Example

1. **Start a new feature:**
   ```bash
   git checkout main
   git checkout -b feature/add-new-warning
   ```

2. **Make changes and test:**
   - Edit files
   - Test the application
   - Build and verify

3. **Commit changes:**
   ```bash
   git add .
   git commit -m "Add new warning type for consult notes"
   ```

4. **Continue working or merge:**
   - If feature is complete and tested:
     ```bash
     git checkout main
     git merge feature/add-new-warning
     ```
   - If you want to experiment more, stay on the branch

5. **Discard experiment (if needed):**
   ```bash
   git checkout main
   git branch -D feature/add-new-warning  # Force delete
   ```

## Best Practices

- **Always commit working code** - Don't commit broken builds
- **Use descriptive commit messages** - Explain what and why
- **Test before merging** - Ensure features work before merging to main
- **Keep main stable** - Main should always be in a deployable state
- **Use feature branches** - Never experiment directly on main

## Current Status

```bash
# Check current branch
git branch

# Check status
git status

# View recent commits
git log --oneline -5
```

