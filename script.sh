# Step 1: Stash any uncommitted changes first
git stash

# Step 2: Now run filter-branch (it'll work since index is clean)
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch \
    pico_aes_soc/src/our_runs/run1/picosoc_final.odb \
    pico_aes_soc/src/our_runs/run2/9_final.odb \
    pico_aes_soc/src/our_runs/run1/picosoc_aes_final.gds \
    pico_aes_soc/src/our_runs/run2/picosoc_aes_3.gds' \
  --prune-empty --tag-name-filter cat -- --all

# Step 3: Clean up git's local object cache
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Step 4: Add to .gitignore
echo "*.odb" >> .gitignore
echo "*.gds" >> .gitignore
git add .gitignore
git commit -m "Ignore large EDA binary outputs"

# Step 5: Force push
git push origin rohit --force

# Step 6: Restore your stashed work
git stash pop