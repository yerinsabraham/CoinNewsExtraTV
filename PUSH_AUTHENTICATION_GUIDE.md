# Authentication Setup for Pushing to Your Repositories

## ✅ Credentials Cleared

The old Lykluk-main credentials have been removed. Your repositories are correctly configured:

- **GitHub:** https://github.com/yerinsabraham/CoinNewsExtraTV
- **GitLab:** https://gitlab.com/cnesmartcontract/coinnewsextratvMain

---

## 📝 What You Need Before Pushing

### For GitHub:
You'll need a **Personal Access Token** (not your password):

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Give it a name: "CoinNewsExtraTV Push"
4. Select scopes: **✅ repo** (all repo permissions)
5. Click **"Generate token"**
6. **COPY THE TOKEN** (you won't see it again!)

### For GitLab:
You'll need a **Personal Access Token**:

1. Go to: https://gitlab.com/-/profile/personal_access_tokens
2. Create new token
3. Name: "CoinNewsExtraTV"
4. Select scopes: **✅ write_repository**, **✅ read_repository**
5. Click **"Create personal access token"**
6. **COPY THE TOKEN**

---

## 🚀 Ready to Push

Now run these commands in order:

### 1. Push to GitHub
```powershell
git push github cleaned-main
```

**When prompted:**
- Username: `yerinsabraham`
- Password: **[Paste your GitHub Personal Access Token]**

### 2. Push to GitLab
```powershell
git push origin cleaned-main
```

**When prompted:**
- Username: `yerinsabraham` (or your GitLab username)
- Password: **[Paste your GitLab Personal Access Token]**

---

## 💡 Alternative: Use Tokens in Remote URLs (No Prompts)

If you don't want to be prompted each time:

### GitHub:
```powershell
git remote set-url github https://YOUR_GITHUB_TOKEN@github.com/yerinsabraham/CoinNewsExtraTV.git
git push github cleaned-main
```

### GitLab:
```powershell
git remote set-url origin https://YOUR_GITLAB_TOKEN@gitlab.com/cnesmartcontract/coinnewsextratvMain.git
git push origin cleaned-main
```

Replace `YOUR_GITHUB_TOKEN` and `YOUR_GITLAB_TOKEN` with your actual tokens.

---

## 🔒 Security Note

- **Never share your tokens**
- Tokens work like passwords
- Store them securely
- You can revoke them anytime from GitHub/GitLab settings

---

## ✅ After Successful Push

You'll see output like:
```
Enumerating objects: 50, done.
Counting objects: 100% (50/50), done.
Writing objects: 100% (36/36), done.
To https://github.com/yerinsabraham/CoinNewsExtraTV.git
   abc1234..a08b4b5  cleaned-main -> cleaned-main
```

---

## 📊 What Will Be Pushed

**Commit:** a08b4b5  
**Branch:** cleaned-main  
**Message:** "feat: Implement multi-level admin access system with role-based permissions"

**Changes:**
- 33 files changed
- 4,705 insertions
- 115 deletions

**New Features:**
- Multi-level admin system (Super, Finance, Updates)
- Role-based permissions
- Admin dashboards
- sendTokensToUser function
- Complete documentation

---

## ❓ Need Help?

If you get errors, check:
1. Token has correct permissions
2. Token is not expired
3. Username is correct
4. You're using the token as password (not your actual password)
