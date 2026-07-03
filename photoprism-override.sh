#!/bin/sh

# Fail immediately if any command exits with a non-zero status
set -e

if [ -n "$CUSTOM_MAP_URL" ]; then
    echo "Executing Pure sed Safe Codemod..."
    echo "Override Target URL: $CUSTOM_MAP_URL"

    # Find the compiled production bundle asset dealing with the target map path strings
    TARGET_FILE=$(grep -l "cdn.photoprism.app/maps" -r /opt/photoprism/assets/static/build/ | head -n 1)

    if [ -z "$TARGET_FILE" ]; then
        echo "ERROR: Target map template asset string not found! Aborting container spin up." >&2
        exit 1
    fi

    echo "Processing target production build asset: $TARGET_FILE"

    # 1. Match the exact backtick string interpolation boundaries: `https://photoprism.app{...}.json`
    # and swap it globally with your hardcoded environment string wrapped in double quotes
    OLD_PATTERN='`https://cdn\.photoprism\.app/maps/\$\{[^}]+\}\.json`'
    NEW_PATTERN="\"$CUSTOM_MAP_URL\""

    # Execute the replacement inside the single-line minified file space using extended regex (-E)
    sed -i -E "s|$OLD_PATTERN|$NEW_PATTERN|g" "$TARGET_FILE"

    # 2. Prepend your custom signature comment block safely using printf
    # This guarantees no literal "-e" flags get injected into your production JS file
    TEMP_CONTENT=$(cat "$TARGET_FILE")
    printf "// modified \n%s" "$TEMP_CONTENT" > "$TARGET_FILE"

    echo "Successfully updated map configuration occurrences and injected file signature header."
else
    echo "ERROR: CUSTOM_MAP_URL environment variable is empty. Aborting container spin up." >&2
    exit 1
fi

# Resume standard PhotoPrism startup execution sequence
echo "Handing control over to PhotoPrism..."
exec photoprism start
