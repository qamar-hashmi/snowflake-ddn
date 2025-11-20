#!/bin/bash

# Pipeline Configuration Validator
# This script validates that all required configuration is in place
# before running the Azure DevOps pipeline

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Azure DevOps Pipeline Configuration Validator${NC}       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "\n${BLUE}▶${NC} ${GREEN}$1${NC}"
    echo "────────────────────────────────────────────────────────"
}

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Start validation
print_header

# Check 1: Required files
print_section "Checking Required Files"

if [ -f "azure-pipelines.yml" ]; then
    check_pass "azure-pipelines.yml exists"
else
    check_fail "azure-pipelines.yml not found"
fi

if [ -f "supergraph.yaml" ]; then
    check_pass "supergraph.yaml exists"
else
    check_fail "supergraph.yaml not found"
fi

if [ -f "app/subgraph.yaml" ]; then
    check_pass "app/subgraph.yaml exists"
else
    check_fail "app/subgraph.yaml not found"
fi

if [ -f "app/connector/my_snowflake/connector.yaml" ]; then
    check_pass "Snowflake connector configuration exists"
else
    check_fail "Snowflake connector configuration not found"
fi

# Check 2: Environment variables
print_section "Checking Environment Variables"

if [ -f ".env" ]; then
    check_pass ".env file exists"
    source .env
    
    # Check required variables
    required_vars=(
        "APP_MY_SNOWFLAKE_JDBC_URL"
        "APP_MY_SNOWFLAKE_AUTHORIZATION_HEADER"
        "APP_MY_SNOWFLAKE_HASURA_SERVICE_TOKEN_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -n "${!var}" ]; then
            check_pass "$var is set"
        else
            check_fail "$var is not set in .env"
        fi
    done
    
    # Check optional but recommended variables
    if [ -n "$HASURA_DDN_PAT" ]; then
        check_pass "HASURA_DDN_PAT is set"
    else
        check_warn "HASURA_DDN_PAT not set (required for pipeline)"
    fi
    
    if [ -n "$JDBC_SCHEMAS" ]; then
        check_pass "JDBC_SCHEMAS is set: $JDBC_SCHEMAS"
    else
        check_warn "JDBC_SCHEMAS not set (will use default)"
    fi
else
    check_fail ".env file not found"
fi

# Check 3: DDN CLI
print_section "Checking DDN CLI"

if command -v ddn &> /dev/null; then
    DDN_VERSION=$(ddn --version 2>&1 || echo "unknown")
    check_pass "DDN CLI installed: $DDN_VERSION"
    
    # Test authentication
    if [ -n "$HASURA_DDN_PAT" ]; then
        export HASURA_DDN_PAT
        if ddn auth print-access-token &> /dev/null; then
            check_pass "DDN authentication successful"
        else
            check_fail "DDN authentication failed"
        fi
    fi
else
    check_warn "DDN CLI not installed (will be installed in pipeline)"
fi

# Check 4: Connector configuration
print_section "Checking Connector Configuration"

if [ -f "app/connector/my_snowflake/configuration.json" ]; then
    check_pass "Connector configuration.json exists"
    
    # Validate JSON
    if command -v jq &> /dev/null; then
        if jq empty app/connector/my_snowflake/configuration.json 2>/dev/null; then
            check_pass "configuration.json is valid JSON"
            
            # Check for tables
            table_count=$(jq '.tables | length' app/connector/my_snowflake/configuration.json)
            if [ "$table_count" -gt 0 ]; then
                check_pass "Found $table_count tables in configuration"
            else
                check_warn "No tables found in configuration (run introspection)"
            fi
        else
            check_fail "configuration.json is invalid JSON"
        fi
    else
        check_warn "jq not installed, skipping JSON validation"
    fi
else
    check_warn "configuration.json not found (will be created during introspection)"
fi

# Check 5: Metadata
print_section "Checking Metadata"

if [ -d "app/metadata" ]; then
    hml_count=$(find app/metadata -name "*.hml" | wc -l)
    if [ "$hml_count" -gt 0 ]; then
        check_pass "Found $hml_count metadata files in app/metadata"
    else
        check_warn "No .hml files found in app/metadata"
    fi
else
    check_warn "app/metadata directory not found"
fi

if [ -d "globals/metadata" ]; then
    check_pass "globals/metadata directory exists"
else
    check_fail "globals/metadata directory not found"
fi

# Check 6: Git configuration
print_section "Checking Git Configuration"

if git rev-parse --git-dir > /dev/null 2>&1; then
    check_pass "Git repository initialized"
    
    # Check for remote
    if git remote -v | grep -q "origin\|azure"; then
        check_pass "Git remote configured"
        git remote -v | while read line; do
            echo "    $line"
        done
    else
        check_warn "No git remote configured"
    fi
    
    # Check current branch
    current_branch=$(git branch --show-current)
    check_pass "Current branch: $current_branch"
    
    # Check for uncommitted changes
    if git diff-index --quiet HEAD --; then
        check_pass "No uncommitted changes"
    else
        check_warn "You have uncommitted changes"
    fi
else
    check_fail "Not a git repository"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo -e "${BLUE}Validation Summary${NC}"
echo "════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your configuration is ready for Azure DevOps pipeline."
    echo ""
    echo "Next steps:"
    echo "  1. Commit your changes: git add . && git commit -m 'Add Azure pipeline'"
    echo "  2. Push to Azure DevOps: git push"
    echo "  3. Create variable group in Azure DevOps (see PIPELINE_QUICK_START.md)"
    echo "  4. Create pipeline in Azure DevOps"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "You can proceed, but review the warnings above."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before proceeding."
    exit 1
fi

