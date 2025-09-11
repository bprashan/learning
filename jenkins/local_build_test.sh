#!/bin/bash

# BKC Kernel Build - Local Testing Script
# This script simulates the Jenkins pipeline for local testing

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔵 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration (modify these as needed for local testing)
WORKSPACE="${PWD}"
BUILD_DIR="${WORKSPACE}/buildtop"
CLONE_DIR="${WORKSPACE}/applications.security.tdx.solutions-and-tools.linux-bkc"
ARTIFACTS_DIR="${WORKSPACE}/artifacts"

# Repository configuration
REPO_URL="https://github.com/intel-innersource/applications.security.tdx.solutions-and-tools.linux-bkc.git"
REPO_BRANCH="6.2.0-emr"

# Build configuration
KERNEL_CONFIG_SOURCE="${CLONE_DIR}/rpmtools/emr-config"
MAKE_JOBS="$(nproc)"  # Use all available cores for local testing
PACKAGE_NAME="kernel-emr-bkc"

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v rpmbuild >/dev/null 2>&1 || missing_tools+=("rpm-build")
    command -v make >/dev/null 2>&1 || missing_tools+=("make")
    command -v tar >/dev/null 2>&1 || missing_tools+=("tar")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_warning "Please install missing tools before continuing"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Stage 1: Initialize Build Environment
initialize_build_environment() {
    print_status "🚀 Starting BKC Kernel Build Pipeline (Local)"
    echo "Repository: ${REPO_URL}"
    echo "Branch: ${REPO_BRANCH}"
    echo "Config Source: ${KERNEL_CONFIG_SOURCE}"
    echo "Make Jobs: ${MAKE_JOBS}"
    
    print_status "Cleaning workspace..."
    rm -rf "${BUILD_DIR}" "${ARTIFACTS_DIR}"
    
    print_status "Creating RPM build directory structure..."
    mkdir -p "${BUILD_DIR}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    
    # Configure RPM build for parallel compilation
    echo "%__make /usr/bin/make -j ${MAKE_JOBS}" > ~/.rpmmacros
    
    print_success "Build environment initialized"
}

# Stage 2: Clone Source Code
clone_source_code() {
    print_status "📥 Cloning BKC source repository..."
    
    if [ -d "${CLONE_DIR}" ]; then
        print_warning "Repository directory exists, removing..."
        rm -rf "${CLONE_DIR}"
    fi
    
    # Check if we have access to the repository
    if ! git ls-remote "${REPO_URL}" >/dev/null 2>&1; then
        print_error "Cannot access repository: ${REPO_URL}"
        print_warning "Please ensure you have proper credentials configured"
        exit 1
    fi
    
    git clone -b "${REPO_BRANCH}" "${REPO_URL}" "${CLONE_DIR}"
    
    print_success "Repository cloned successfully"
    echo "📁 Repository contents:"
    ls -la "${CLONE_DIR}"
}

# Stage 3: Prepare Build Files
prepare_build_files() {
    print_status "📦 Preparing RPM build files..."
    
    cd "${CLONE_DIR}/rpmtools"
    
    # Check if spec file exists
    if [ ! -f "${PACKAGE_NAME}.spec" ]; then
        print_error "Spec file ${PACKAGE_NAME}.spec not found in rpmtools directory"
        exit 1
    fi
    
    # Move spec file and sources to appropriate directories
    cp "${PACKAGE_NAME}.spec" "${BUILD_DIR}/SPECS/"
    cp -r * "${BUILD_DIR}/SOURCES/" 2>/dev/null || true
    
    # Create source tarball
    cd "${WORKSPACE}"
    tar -czf applications.security.tdx.solutions-and-tools.linux-bkc.tar.gz \
        applications.security.tdx.solutions-and-tools.linux-bkc
    cp applications.security.tdx.solutions-and-tools.linux-bkc.tar.gz "${BUILD_DIR}/SOURCES/"
    
    print_success "Build files prepared"
    echo "📄 SPECS contents: $(ls "${BUILD_DIR}/SPECS/")"
    echo "📁 SOURCES count: $(ls "${BUILD_DIR}/SOURCES/" | wc -l) files"
}

# Stage 4: RPM Build Preparation
rpm_build_preparation() {
    print_status "🔧 Preparing RPM build environment..."
    
    cd "${BUILD_DIR}/SPECS"
    
    rpmbuild --define "_topdir ${BUILD_DIR}" \
             -bp \
             --target="$(uname -m)" \
             "${PACKAGE_NAME}.spec"
    
    print_success "RPM preparation completed"
    echo "📁 Build directory contents:"
    ls -la "${BUILD_DIR}/BUILD/"
}

# Stage 5: Configure Kernel
configure_kernel() {
    print_status "⚙️ Configuring kernel build..."
    
    # Navigate to kernel source directory
    cd "${BUILD_DIR}/BUILD/${PACKAGE_NAME}"/linux-6.2.0-emr.bkc.*
    
    # Validate and copy kernel configuration
    if [ -f "${KERNEL_CONFIG_SOURCE}" ]; then
        print_success "Using kernel config: ${KERNEL_CONFIG_SOURCE}"
        cp "${KERNEL_CONFIG_SOURCE}" .config
    else
        print_error "Kernel config not found at ${KERNEL_CONFIG_SOURCE}"
        print_error "Build cannot proceed without proper kernel configuration"
        exit 1
    fi
    
    # Update configuration for current environment
    make oldconfig
    
    # Add architecture marker
    sed -i '1i# x86_64' .config
    
    # Prepare config files for packaging
    mkdir -p configs
    cp .config configs/kernel-*-"$(uname -m)".config
    cp configs/* "${BUILD_DIR}/SOURCES/"
    
    print_success "Kernel configuration completed"
    echo "📄 Config files: $(ls configs/)"
}

# Stage 6: Build Kernel RPM
build_kernel_rpm() {
    print_status "🔨 Building kernel RPM package..."
    
    cd "${BUILD_DIR}/SPECS"
    
    # Build RPM package with comprehensive logging
    echo "Starting RPM build at $(date)"
    
    if rpmbuild --define "_topdir ${BUILD_DIR}" \
                -bb \
                --target="$(uname -m)" \
                "${PACKAGE_NAME}.spec" \
                2> build-err.log | tee build-out.log; then
        print_success "RPM build completed successfully at $(date)"
        echo "📦 Built packages:"
        find "${BUILD_DIR}/RPMS" -name "*.rpm" -type f -exec basename {} \;
    else
        print_error "RPM build failed!"
        echo "📄 Error log:"
        cat build-err.log
        exit 1
    fi
}

# Stage 7: Archive Build Artifacts
archive_build_artifacts() {
    print_status "📚 Archiving build artifacts..."
    
    # Create artifacts directory
    mkdir -p "${ARTIFACTS_DIR}"
    
    # Copy specific RPM packages only
    print_status "🔍 Searching for specific RPM packages..."
    
    # Copy kernel-emr-bkc-core package
    find "${BUILD_DIR}/RPMS" -name "kernel-emr-bkc-core-*.rpm" -type f -exec cp {} "${ARTIFACTS_DIR}/" \;
    
    # Copy kernel-emr-bkc-modules packages
    find "${BUILD_DIR}/RPMS" -name "kernel-emr-bkc-modules-*.rpm" -type f -exec cp {} "${ARTIFACTS_DIR}/" \;
    
    # Copy main kernel-emr-bkc package
    find "${BUILD_DIR}/RPMS" -name "kernel-emr-bkc-*.rpm" -type f ! -name "kernel-emr-bkc-core-*.rpm" ! -name "kernel-emr-bkc-modules-*.rpm" -exec cp {} "${ARTIFACTS_DIR}/" \;
    
    # Copy kernel-headers package
    find "${BUILD_DIR}/RPMS" -name "kernel-headers-*.rpm" -type f -exec cp {} "${ARTIFACTS_DIR}/" \;
    
    # Copy build logs
    cp "${BUILD_DIR}/SPECS/build-"*.log "${ARTIFACTS_DIR}/"
    
    print_success "Specific artifacts archived successfully"
    echo "📁 Archived artifacts:"
    ls -la "${ARTIFACTS_DIR}/"
    
    echo "📦 RPM packages archived:"
    ls -1 "${ARTIFACTS_DIR}/"*.rpm 2>/dev/null || echo "No RPM packages found"
}

# Build summary function
build_summary() {
    print_status "🏁 Build pipeline completed"
    echo "📊 Build executed on: $(hostname)"
    
    echo ""
    echo "======================================"
    echo "         BUILD SUMMARY"
    echo "======================================"
    echo "📦 Built RPM Packages:"
    echo "--------------------------------------"
    
    find "${BUILD_DIR}/RPMS" -name "*.rpm" -type f | while read -r rpm; do
        echo "  📄 $(basename "$rpm")"
        echo "     Size: $(du -h "$rpm" | cut -f1)"
        echo "     Path: $rpm"
        echo ""
    done
    
    echo "======================================"
    echo "🚀 Artifacts are available in: ${ARTIFACTS_DIR}"
}

# Error handling function
handle_error() {
    print_error "Build failed at stage: $1"
    echo ""
    echo "======================================"
    echo "         FAILURE ANALYSIS"
    echo "======================================"
    
    if [ -f "${BUILD_DIR}/SPECS/build-err.log" ]; then
        echo "📄 Last 50 lines of error log:"
        echo "--------------------------------------"
        tail -50 "${BUILD_DIR}/SPECS/build-err.log"
    else
        print_warning "No error log found"
    fi
    
    echo ""
    echo "💡 Check the build logs for detailed error information"
    echo "======================================"
    exit 1
}

# Main execution
main() {
    echo "========================================"
    echo "    BKC Kernel Build - Local Testing"
    echo "========================================"
    echo ""
    
    # Check prerequisites first
    check_prerequisites || handle_error "Prerequisites Check"
    
    # Execute pipeline stages
    initialize_build_environment || handle_error "Initialize Build Environment"
    clone_source_code || handle_error "Clone Source Code"
    prepare_build_files || handle_error "Prepare Build Files"
    rpm_build_preparation || handle_error "RPM Build Preparation"
    configure_kernel || handle_error "Configure Kernel"
    build_kernel_rpm || handle_error "Build Kernel RPM"
    archive_build_artifacts || handle_error "Archive Build Artifacts"
    
    # Show build summary
    build_summary
    
    print_success "🎉 BKC kernel build completed successfully!"
}

# Execute main function
main "$@"
