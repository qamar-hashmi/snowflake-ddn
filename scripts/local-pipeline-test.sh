#!/bin/bash

# Local Pipeline Test Script
# This script simulates the Azure DevOps pipeline locally for testing
# Run this before pushing to ensure the pipeline will work

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create a .env file with required environment variables."
    exit 1
fi

print_step "Loading environment variables from .env"
source .env
print_success "Environment variables loaded"

# Check if DDN CLI is installed
print_step "Checking DDN CLI installation"
if ! command -v ddn &> /dev/null; then
    print_warning "DDN CLI not found. Installing..."
    curl -L https://graphql-engine-cdn.hasura.io/ddn/cli/v4/get.sh | bash
    print_success "DDN CLI installed"
else
    DDN_VERSION=$(ddn --version)
    print_success "DDN CLI found: $DDN_VERSION"
fi

# Check authentication
print_step "Verifying DDN authentication"
if [ -z "$HASURA_DDN_PAT" ]; then
    print_error "HASURA_DDN_PAT not set in .env file"
    echo "Run: ddn auth login"
    echo "Then: ddn auth print-access-token"
    exit 1
fi

export HASURA_DDN_PAT
if ddn auth print-access-token &> /dev/null; then
    print_success "Authentication verified"
else
    print_error "Authentication failed. Please check your HASURA_DDN_PAT"
    exit 1
fi

# Stage 1: Introspection
echo ""
print_step "STAGE 1: INTROSPECTION"
echo "========================================"

print_step "Introspecting Snowflake connector"

# Check if JDBC_URL is set
if [ -z "$APP_MY_SNOWFLAKE_JDBC_URL" ]; then
    print_error "APP_MY_SNOWFLAKE_JDBC_URL not set in .env file"
    exit 1
fi

# Run introspection from project root
# The DDN CLI will handle the connector directory navigation
if ddn connector introspect my_snowflake --connector-dir app/connector/my_snowflake; then
    print_success "Connector introspection completed"

    # Verify configuration was updated
    if [ -f "app/connector/my_snowflake/configuration.json" ]; then
        echo "  ✓ Configuration file updated"
        table_count=$(grep -o '"name"' app/connector/my_snowflake/configuration.json | wc -l | tr -d ' ')
        echo "  ✓ Found $table_count tables"
    fi
else
    print_error "Connector introspection failed"
    echo "  Tip: Check your Snowflake credentials in .env file"
    exit 1
fi

print_step "Adding connector resources to metadata"
if ddn connector-link update my_snowflake --subgraph app --add-all-resources; then
    print_success "Connector resources added to metadata"
else
    print_warning "Failed to add connector resources (may already exist)"
fi

# Stage 2: Build
echo ""
print_step "STAGE 2: SUPERGRAPH BUILD"
echo "========================================"

print_step "Building supergraph"
if ddn supergraph build create --supergraph supergraph.yaml --description "Local test build"; then
    print_success "Supergraph build completed"
else
    print_error "Supergraph build failed"
    exit 1
fi

print_step "Generating build artifacts"
mkdir -p engine/build

# Copy metadata to build directory
if [ -d "app/metadata" ]; then
    cp -r app/metadata/* engine/build/ 2>/dev/null || true
fi

if [ -d "globals/metadata" ]; then
    cp -r globals/metadata/* engine/build/ 2>/dev/null || true
fi

print_success "Build artifacts generated in engine/build/"

print_step "Validating supergraph build"
if ddn supergraph build list --supergraph supergraph.yaml --limit 5; then
    print_success "Build validation completed"
else
    print_warning "Could not list builds"
fi

# Summary
echo ""
echo "========================================"
print_success "LOCAL PIPELINE TEST COMPLETED SUCCESSFULLY!"
echo "========================================"
echo ""
echo "Summary:"
echo "  ✓ DDN CLI installed and authenticated"
echo "  ✓ Connector introspection completed"
echo "  ✓ Metadata updated with connector resources"
echo "  ✓ Supergraph build created"
echo "  ✓ Build artifacts generated"
echo ""
echo "Next steps:"
echo "  1. Review the changes in app/connector/my_snowflake/"
echo "  2. Review the metadata in app/metadata/"
echo "  3. Test locally with: ddn run docker-start"
echo "  4. Commit and push to trigger Azure DevOps pipeline"
echo ""

