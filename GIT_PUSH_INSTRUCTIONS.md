# Git Push Instructions

## Issue
The current Git credentials are for user "Lykluk-main" but you need to push to repositories owned by "yerinsabraham".

## Solution Options

### Option 1: Use Git Credential Manager (Recommended)

```powershell
# Clear stored credentials
git credential-manager erase https://github.com

# Try pushing again - it will prompt for new credentials
git push github cleaned-main
# When prompted, enter your GitHub username and Personal Access Token

# For GitLab
git credential-manager erase https://gitlab.com
git push origin cleaned-main
# When prompted, enter your GitLab username and Personal Access Token
```

### Option 2: Use Personal Access Tokens in URL

**GitHub:**
```powershell
# Update remote URL with your Personal Access Token
git remote set-url github https://YOUR_GITHUB_TOKEN@github.com/yerinsabraham/CoinNewsExtraTV.git

# Push
git push github cleaned-main
```

**GitLab:**
```powershell
# Update remote URL with your GitLab Personal Access Token
git remote add gitlab https://YOUR_GITLAB_TOKEN@gitlab.com/cnesmartcontract/coinnewsextratvMain.git

# Push
git push gitlab cleaned-main
```

### Option 3: Use SSH Keys (Most Secure)

**Setup SSH keys:**
```powershell
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start SSH agent
Start-Service ssh-agent

# Add your SSH key
ssh-add ~/.ssh/id_ed25519
```

**Add public key to GitHub:**
1. Copy your public key: `cat ~/.ssh/id_ed25519.pub`
2. Go to GitHub: Settings > SSH and GPG keys > New SSH key
3. Paste and save

**Add public key to GitLab:**
1. Copy your public key: `cat ~/.ssh/id_ed25519.pub`
2. Go to GitLab: Preferences > SSH Keys
3. Paste and save

**Update remotes to use SSH:**
```powershell
git remote set-url github git@github.com:yerinsabraham/CoinNewsExtraTV.git
git remote set-url origin git@gitlab.com:cnesmartcontract/coinnewsextratvMain.git

# Push
git push github cleaned-main
git push origin cleaned-main
```

### Option 4: Quick Manual Commands

If you have your credentials ready:

```powershell
# 1. Clear cached credentials
git config --global --unset credential.helper
cmdkey /delete:git:https://github.com
cmdkey /delete:git:https://gitlab.com

# 2. Push (will prompt for credentials)
git push github cleaned-main
git push origin cleaned-main
```

---

## Creating Personal Access Tokens

### GitHub Personal Access Token:
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (all repo permissions)
4. Generate and copy the token
5. Use it as your password when prompted

### GitLab Personal Access Token:
1. Go to: https://gitlab.com/-/profile/personal_access_tokens
2. Create new token
3. Select scopes: `write_repository`, `read_repository`
4. Create and copy the token
5. Use it as your password when prompted

---

## After Successful Push

Once you've successfully authenticated and pushed, verify:

```powershell
# Check GitHub
git ls-remote github

# Check GitLab  
git ls-remote origin
```

---

## Current Commit Ready to Push

**Commit Hash:** a08b4b5  
**Branch:** cleaned-main  
**Message:** "feat: Implement multi-level admin access system with role-based permissions"

**Files Changed:** 33 files  
**Insertions:** 4,705 lines  
**Deletions:** 115 lines

**New Features:**
- Multi-level admin system (Super, Finance, Updates admins)
- Role-based permissions (16 granular permissions)
- Admin authentication service
- Role-specific dashboards
- sendTokensToUser Cloud Function
- Security rules updates
- Complete documentation

---

## Quick Reference

**GitHub Repository:** https://github.com/yerinsabraham/CoinNewsExtraTV  
**GitLab Repository:** https://gitlab.com/cnesmartcontract/coinnewsextratvMain

**Current Remotes:**
```
github → https://github.com/yerinsabraham/CoinNewsExtraTV.git
origin → https://gitlab.com/cnesmartcontract/coinnewsextratvMain.git
```
