#!/bin/bash

newVersion=$2

# Get the last branch
lastGitBranch=$1

#  Checkout it
git checkout $lastGitBranch

# Get the version of React (and strip the version qualifier)
reactVersion=`npm view react-native@$newVersion peerDependencies.react | sed -e 's/[\~\^]//'`

cd RnDiffApp

# Save package.json for later use (for not being taken into account when computing stats)
cp package.json ../package.json.temp

# Replace versions in package.json
sed -i "" "s/\"react\": \"[0-9]*\.[0-9]*\.[0-9]*\",/\"react\": \"${reactVersion}\",/" ./package.json
sed -i "" "s/\"react-native\": \"[0-9]*\.[0-9]*\.[0-9]*\"/\"react-native\": \"${newVersion}\"/" ./package.json

# Install dependencies
npm install

# Remove lock file, it is irrelevant for computing the diff
rm package-lock.json

# Launch RN upgrade and automatically overwrite all files
react-native upgrade

cd ..

# Create the new branch
git branch rn-$newVersion

# Checkout it
git checkout rn-$newVersion

# Add modified files to commit
git add RnDiffApp

# Commit
git commit -m "Output version ${newVersion}"

# Compute diff stats pour README.md
## Restore the old package.json (we don't want to take it into account for stats)
cp package.json.temp RnDiffApp/package.json
## Save the stats
diffStat=`git --no-pager diff HEAD~1 --shortstat`
## Clean old package.json
rm package.json.temp
## Restore the new package.json
git checkout -- RnDiffApp/package.json

# Print diff
git --no-pager diff HEAD~1

# Print all branches (inspired from the oh-my-zsh shortcut: "glola")
git --no-pager log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all

# Ask for confirmation before pushing
echo -e "\nIs that OK ? (Yn)"
read confirmation

if [ -z $confirmation ] || [ $confirmation = "y" ] || [ $confirmation = "Y" ]
then
  echo -e "Push branch..."

  # Push the branch
  git push origin rn-$newVersion
fi

# Come back to master branch
git checkout master

# Update README.md
diffUrl="[${lastGitBranch}...rn-${newVersion}](https://github.com/ncuillery/rn-diff/compare/${lastGitBranch}...rn-${newVersion})"
patchUrl="[${lastGitBranch}...rn-${newVersion}](https://github.com/ncuillery/rn-diff/compare/${lastGitBranch}...rn-${newVersion}.diff)"

# Insert a row in the version table
## Insert a new line (a bit tricky but compatible with either OSX sed and GNU sed)
sed -i '' 's/----|----|----|----/----|----|----|----\
NEWLINE/g' README.md
## Edit the new line with the version info
sed -i "" "s@NEWLINE@${newVersion}|${diffUrl}|${patchUrl}|${diffStat}@" README.md
