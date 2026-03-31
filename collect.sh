#!/bin/bash
# Embodied AGI daily paper collection

WORKDIR="/root/.openclaw/workspace/embodied_agi"
DATE=$(date +%Y-%m-%d)
LOGFILE="$WORKDIR/cron.log"

echo "=== Embodied AGI collection started at $(date) ===" >> "$LOGFILE"

cd "$WORKDIR"

# Retry up to 3 times with backoff
for i in 1 2 3; do
    echo "Attempt $i..." >> "$LOGFILE"
    curl -s --max-time 30 --retry 3 --retry-delay 10 \
        "https://export.arxiv.org/api/query?search_query=cat:cs.AI+AND+(all:embodied+OR+all:robot+OR+all:manipulation+OR+all:grasping+OR+all:VR+OR+all:sim2real)&max_results=5&sortBy=submittedDate&sortOrder=descending" \
        > /tmp/arxiv_embodied.xml 2>&1
    
    if grep -q "<entry>" /tmp/arxiv_embodied.xml; then
        break
    fi
    echo "Attempt $i failed, retrying..." >> "$LOGFILE"
    sleep 10
done

# Generate daily thinking file
{
    echo "# Embodied AGI Daily Thinking - $DATE"
    echo ""
    echo "## Papers Found"
    echo ""
    
    if grep -q "<entry>" /tmp/arxiv_embodied.xml; then
        grep -oP '(?<=<id>)[^<]+(?=</id>)' /tmp/arxiv_embodied.xml | head -5 | while read -r url; do
            # Skip internal API URLs - only keep public arxiv.org/abs URLs
            if [[ "$url" == *"arxiv.org/api/"* ]]; then
                continue
            fi
            echo "- $url"
        done
    else
        echo "(API rate limited - no papers fetched)"
    fi
    
    echo ""
    echo "---"
    echo "*Generated at $(date)*"
} > "$WORKDIR/daily_thinking/$DATE.md"

echo "=== Collection completed: $(date) ===" >> "$LOGFILE"