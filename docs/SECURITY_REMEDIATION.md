# Security Remediation Plan

## 1. Secrets Exposed

The file `kubernetes/secrets.yaml` contains credentials in **plaintext** (not just Base64-encoded, but literal connection strings with passwords visible).

| Field | Risk | Location |
|-------|------|----------|
| `database-url` | PostgreSQL connection string with username and password in cleartext | `kubernetes/secrets.yaml:8` |
| `redis-url` | Redis connection string with password in cleartext | `kubernetes/secrets.yaml:9` |

Both credentials are committed to the Git repository and visible in the public GitHub repository at `https://github.com/mzet97/benchmark`.

## 2. Credentials That Must Be Rotated

| Service | Credential | Action Required |
|---------|-----------|-----------------|
| **PostgreSQL** (`spsql.home.arpa:5432`) | Password for user `app` | Change password immediately |
| **Redis** (`redis.home.arpa:30379`) | AUTH password | Change password immediately |

### Rotation Steps (PostgreSQL)

```bash
# Connect to PostgreSQL as admin
psql -h spsql.home.arpa -U postgres -d postgres

# Change the app user password
ALTER USER app WITH PASSWORD '<NEW_SECURE_PASSWORD>';

# Verify connectivity with new password
psql -h spsql.home.arpa -U app -d benchmark_api
```

### Rotation Steps (Redis)

```bash
# Connect to Redis
redis-cli -h redis.home.arpa -p 30379

# Change the password
CONFIG SET requirepass <NEW_SECURE_PASSWORD>

# Verify
redis-cli -h redis.home.arpa -p 30379 -a <NEW_SECURE_PASSWORD> ping
```

## 3. How to Remove Credential Values from Current Code

Replace `kubernetes/secrets.yaml` with the example file `kubernetes/secrets.example.yaml` which contains placeholder values only.

**Do NOT commit real credentials to any file tracked by Git.**

## 4. How to Use Secrets Created Outside Git

### Option A: Manual kubectl (recommended for homelab)

```bash
# Create the secret directly in the cluster (never stored in Git)
kubectl create secret generic benchmark-secrets \
  --namespace benchmark \
  --from-literal=database-url="postgresql://app:<NEW_PASSWORD>@spsql.home.arpa:5432/benchmark_api" \
  --from-literal=redis-url="redis://:<NEW_PASSWORD>@redis.home.arpa:30379"

# Verify
kubectl get secret benchmark-secrets -n benchmark -o yaml
```

### Option B: Local .env file (for development)

Create a `.env` file (already in `.gitignore`):

```bash
# .env (DO NOT COMMIT)
DATABASE_URL=postgresql://app:<NEW_PASSWORD>@spsql.home.arpa:5432/benchmark_api
REDIS_URL=redis://:<NEW_PASSWORD>@redis.home.arpa:30379
```

### Option C: External Secrets Operator (if available in cluster)

If the K3s cluster has External Secrets Operator installed:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: benchmark-secrets
  namespace: benchmark
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: <secret-store-name>
    kind: ClusterSecretStore
  target:
    name: benchmark-secrets
  data:
    - secretKey: database-url
      remoteRef:
        key: benchmark/database-url
    - secretKey: redis-url
      remoteRef:
        key: benchmark/redis-url
```

### Option D: Sealed Secrets (if available in cluster)

```bash
# Install kubeseal if not present
# Create a SealedSecret from the regular secret
echo "
apiVersion: v1
kind: Secret
metadata:
  name: benchmark-secrets
  namespace: benchmark
type: Opaque
stringData:
  database-url: \"postgresql://app:<NEW_PASSWORD>@spsql.home.arpa:5432/benchmark_api\"
  redis-url: \"redis://:<NEW_PASSWORD>@redis.home.arpa:30379\"
" | kubeseal -o yaml > kubernetes/sealed-secrets.yaml

# Apply the SealedSecret (safe to commit)
kubectl apply -f kubernetes/sealed-secrets.yaml
```

## 5. How to Remove Secrets from Git History

The credentials exist in the Git history and must be purged.

### Option A: BFG Repo-Cleaner (recommended)

```bash
# Install BFG
# https://rtyley.github.io/bfg-repo-cleaner/

# Create a file with the passwords to remove
echo "Admin@123" > passwords.txt

# Run BFG to remove the passwords from all history
java -jar bfg.jar --replace-text passwords.txt

# Clean up and force push
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force --all
git push --force --tags
```

### Option B: git filter-repo

```bash
pip install git-filter-repo

# Replace the password string in all files
git-filter-repo --replace-text <(echo "Admin@123==>REDACTED")

git push --force --all
```

### Important Notes

- **All collaborators must re-clone** after history rewriting
- **GitHub caches may retain old data** — contact GitHub support if needed
- **Rotate credentials BEFORE or simultaneously** with history cleanup

## 6. How to Verify Credentials Are No Longer Accessible

### Check current HEAD

```bash
git show HEAD:kubernetes/secrets.yaml
# Should show example/placeholder values, NOT real credentials
```

### Check all branches

```bash
for branch in $(git branch -r); do
  echo "=== $branch ==="
  git show "$branch:kubernetes/secrets.yaml" 2>/dev/null || echo "File not found"
done
```

### Check Git log for password strings

```bash
git log --all -p -S "Admin@123" -- '*.yaml' '*.yml' '*.env' '*.sh'
# Should return no results after cleanup
```

### Check GitHub

Even after force-push, GitHub may cache old commits. Verify by:
1. Browsing old commit URLs on GitHub
2. Using the GitHub API to check raw file content at old SHAs
3. Contacting GitHub support to purge caches if needed

## 7. Prevention

### Pre-commit hook (recommended)

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for common credential patterns
if git diff --cached --diff-filter=ACM | grep -iE '(password|secret|token|key)\s*[:=]\s*["\x27][^"\x27]{8,}'; then
  echo "ERROR: Possible credentials detected in staged files."
  echo "Please review and remove sensitive data before committing."
  exit 1
fi
```

### git-secrets (AWS tool, works generically)

```bash
# Install
git secrets --install
git secrets --register-aws  # Also catches generic patterns

# Add custom patterns
git secrets --add 'Admin@123'
git secrets --add 'postgresql://[^:]+:[^@]+@'
```

## 8. Action Checklist

- [ ] **Rotate PostgreSQL password** for user `app`
- [ ] **Rotate Redis AUTH password**
- [ ] **Create secret manually in K3s** (not via Git)
- [ ] **Replace `kubernetes/secrets.yaml`** with `secrets.example.yaml`
- [ ] **Add `kubernetes/secrets.yaml` to `.gitignore`**
- [ ] **Purge credentials from Git history** (BFG or git-filter-repo)
- [ ] **Force push and notify all collaborators**
- [ ] **Verify no credentials remain** in any branch or tag
- [ ] **Set up pre-commit hook** or `git-secrets`
- [ ] **Document the new secret management process**

---

**Last Updated**: 2026-07-28
**Status**: REMEDIATION PLAN — NOT YET EXECUTED
