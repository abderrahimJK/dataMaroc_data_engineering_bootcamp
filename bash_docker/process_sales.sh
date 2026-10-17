#!/bin/bash
TODAY=$(date +%F)
LOG="logs/run_$TODAY.log"
ID=1
colName='reason'
REPORT="result/report_$TODAY.csv"

mkdir -p result archive errors trash logs

# Initialize CSV with header only if it does not already exist
[ -s "$REPORT" ] || echo "id,city,reason,count" > "$REPORT"

log() {
    local level="${1:-INFO}"
    local msg="$2"
    printf "[%s] [%-5s] %s\n" "$(date '+%H:%M:%S')" "$level" "$msg" | tee -a "$LOG"
}

# Clean temp files
for f in incoming/*.tmp; do
    [ -e "$f" ] || continue
    mv "$f" trash/
    log "INFO" "Moved $(basename "$f") to trash/"
done

process_file() {
    local file="$1"
    local name
    name=$(basename "$file")

    log "INFO" "Reading incoming/$name"

    # Verify column existence
    if head -n 1 "$file" | grep -q "$colName"; then
        local city
        city=$(basename "$file" .csv)
        city="${city##*_}"

        # Count reasons using awk, keeping sequential IDs
        awk -F',' -v id="$ID" -v city="$city" '
            NR > 1 && $3 != "" { c[$3]++ }
            END {
                for (item in c) {
                    print id "," city "," item "," c[item]
                    id++
                }
            }
        ' "$file" >> "$REPORT"

        # Update the Bash ID counter based on total lines in report
        ID=$(wc -l < "$REPORT")

        # Move to archive (NOT cp) so it will not be processed again
        mv "$file" "archive/${name%.csv}_$TODAY.csv"
        log "INFO" "Successfully processed and archived as ${name%.csv}_$TODAY.csv"
    else
        mv "$file" errors/
        log "ERROR" "Missing column '$colName' in $name — moved to errors/"
    fi
}

# Process each incoming CSV file
for f in incoming/*.csv; do
    [ -e "$f" ] || continue
    process_file "$f"
done