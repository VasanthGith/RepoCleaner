#!/bin/bash

# Get PAT Token from user
read -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

# Repolist
REPO_LIST_FILE="masterRepoList.txt"

STALE_DAYS=365

# current date in Unix format
CURRENT_DATE=$(date +%s)

# looping thru the repo from i/p file
while read -r REPO; do
    [[ -z "$REPO" ]] && continue
    echo "Processing repository: $REPO"

    BRANCHES=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO/branches" | jq -r '.[].name')

    TOTAL_BRANCHES=$(echo "$BRANCHES" | wc -l)
    echo "Total branches in $REPO: $TOTAL_BRANCHES"

    STALE_BRANCHES=()

    # checking last commit date in branches
    for BRANCH in $BRANCHES; do
        [[ -z "$BRANCH" ]] && continue

        COMMIT_DATE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$REPO/commits?sha=$BRANCH&per_page=1" | jq -r '.[0].commit.author.date' | cut -d 'T' -f1)

        if [[ "$COMMIT_DATE" == "null" || -z "$COMMIT_DATE" ]]; then
            echo "Branch: $BRANCH | Last Commit Date: No commits found"
            continue
        fi

        # Convert commit date to Unix time
        COMMIT_TIMESTAMP=$(date -d "$COMMIT_DATE" +%s)
        AGE_DAYS=$(( (CURRENT_DATE - COMMIT_TIMESTAMP) / 86400 ))

        echo "Branch: $BRANCH | Last Commit Date: $COMMIT_DATE | Age: $AGE_DAYS days"

        if [[ $AGE_DAYS -ge $STALE_DAYS ]]; then
            STALE_BRANCHES+=("$BRANCH")
        fi
    done

    echo "Branch check completed for $REPO!"

    # get user i/p for deletion or not
    if [[ ${#STALE_BRANCHES[@]} -gt 0 ]]; then
        echo "Stale branches (older than $STALE_DAYS days) in $REPO:"
        printf "  - %s\n" "${STALE_BRANCHES[@]}"
        
        echo "Do you want to delete all stale branches in $REPO? (yes/no/selective)"
        read -r choice

        if [[ "$choice" == "yes" ]]; then
            for BRANCH in "${STALE_BRANCHES[@]}"; do
                curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                    "https://api.github.com/repos/$REPO/git/refs/heads/$BRANCH"
                echo "Deleted branch: $BRANCH"
            done
        elif [[ "$choice" == "selective" ]]; then
            for BRANCH in "${STALE_BRANCHES[@]}"; do
                echo "Delete branch: $BRANCH? (yes/no)"
                read -r branch_choice
                if [[ "$branch_choice" == "yes" ]]; then
                    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                        "https://api.github.com/repos/$REPO/git/refs/heads/$BRANCH"
                    echo "Deleted branch: $BRANCH"
                fi
            done
        else
            echo "Skipping deletion of stale branches for $REPO."
        fi
    else
        echo "No stale branches found in $REPO!"
    fi
done < "$REPO_LIST_FILE"

echo "All repositories processed!"