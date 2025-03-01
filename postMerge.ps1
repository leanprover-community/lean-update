# Steps to perform after merging develop into main
git checkout main
git pull origin main

git checkout develop
git rebase main
git push origin develop