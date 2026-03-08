# Remove the conflicting untracked junk files
rm -f .DS_Store pico_aes_soc/.DS_Store pico_aes_soc/src/.DS_Store \
      pico_aes_soc/src/our_runs/.DS_Store pico_aes_soc/src/our_runs/run2/.DS_Store

# Now pop the stash
git stash pop

# Add all your files back and push
git add .
git commit -m "Restore project files"
git push origin rohit