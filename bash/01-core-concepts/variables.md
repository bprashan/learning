# 🔧 Shell Variables & Environment Management

## 📖 Core Concepts

Shell variables are fundamental to bash scripting and essential for DevOps automation. Understanding variable scope, types, and best practices is crucial for writing maintainable scripts.

---

## 🎯 Variable Types & Scope

### **1. Local Variables**
```bash
#!/bin/bash
# Local variables - only available in current script

# Standard variable assignment
NAME="DevOps Engineer"
AGE=30
DEPARTMENT="Infrastructure"

# Using variables
echo "Hello, I'm a $NAME"
echo "I'm $AGE years old"
echo "I work in $DEPARTMENT"
```

### **2. Environment Variables**
```bash
#!/bin/bash
# Environment variables - available to child processes

# Export makes variables available to child processes
export DATABASE_URL="postgresql://localhost:5432/app"
export API_KEY="sk-1234567890abcdef"
export LOG_LEVEL="INFO"

# Check if environment variable exists
if [ -n "$DATABASE_URL" ]; then
    echo "Database URL is set: $DATABASE_URL"
else
    echo "DATABASE_URL not configured!"
    exit 1
fi
```

### **3. Special Variables**
```bash
#!/bin/bash
# Special variables provided by the shell

echo "Script name: $0"
echo "First argument: $1"
echo "Second argument: $2"
echo "All arguments: $@"
echo "Number of arguments: $#"
echo "Process ID: $$"
echo "Exit status of last command: $?"
echo "Current user: $USER"
echo "Home directory: $HOME"
echo "Current working directory: $PWD"
```

---

## 🛠️ DevOps Variable Patterns

### **Configuration Management Pattern**
```bash
#!/bin/bash
# config-manager.sh - Centralized configuration management

# Default configurations
DEFAULT_APP_PORT=8080
DEFAULT_DB_HOST="localhost"
DEFAULT_LOG_LEVEL="INFO"

# Environment-specific overrides
APP_PORT="${APP_PORT:-$DEFAULT_APP_PORT}"
DB_HOST="${DB_HOST:-$DEFAULT_DB_HOST}"
LOG_LEVEL="${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"

# Validation function
validate_config() {
    local errors=0
    
    # Validate port number
    if ! [[ "$APP_PORT" =~ ^[0-9]+$ ]] || [ "$APP_PORT" -lt 1 ] || [ "$APP_PORT" -gt 65535 ]; then
        echo "ERROR: Invalid port number: $APP_PORT" >&2
        ((errors++))
    fi
    
    # Validate log level
    case "$LOG_LEVEL" in
        DEBUG|INFO|WARN|ERROR) ;;
        *) echo "ERROR: Invalid log level: $LOG_LEVEL" >&2; ((errors++)) ;;
    esac
    
    return $errors
}

# Display configuration
show_config() {
    echo "=== Application Configuration ==="
    echo "Port: $APP_PORT"
    echo "Database Host: $DB_HOST"
    echo "Log Level: $LOG_LEVEL"
    echo "================================="
}

# Main execution
if validate_config; then
    show_config
    echo "Configuration is valid!"
else
    echo "Configuration validation failed!" >&2
    exit 1
fi
```

### **Environment Detection Pattern**
```bash
#!/bin/bash
# env-detector.sh - Automatic environment detection

# Detect environment based on various factors
detect_environment() {
    local env="unknown"
    
    # Check by hostname pattern
    case "$HOSTNAME" in
        *prod*|*production*) env="production" ;;
        *stage*|*staging*) env="staging" ;;
        *dev*|*development*) env="development" ;;
        *test*) env="testing" ;;
    esac
    
    # Override with explicit environment variable
    env="${ENVIRONMENT:-$env}"
    
    # Validate environment
    case "$env" in
        production|staging|development|testing) ;;
        *) env="development" ;; # Default fallback
    esac
    
    echo "$env"
}

# Set environment-specific configurations
setup_environment() {
    local env=$(detect_environment)
    
    case "$env" in
        production)
            export LOG_LEVEL="WARN"
            export DEBUG_MODE="false"
            export DB_POOL_SIZE="20"
            export CACHE_TTL="3600"
            ;;
        staging)
            export LOG_LEVEL="INFO"
            export DEBUG_MODE="true"
            export DB_POOL_SIZE="10"
            export CACHE_TTL="1800"
            ;;
        development|testing)
            export LOG_LEVEL="DEBUG"
            export DEBUG_MODE="true"
            export DB_POOL_SIZE="5"
            export CACHE_TTL="300"
            ;;
    esac
    
    echo "Environment: $env"
    echo "Log Level: $LOG_LEVEL"
    echo "Debug Mode: $DEBUG_MODE"
}

setup_environment
```

---

## 🔒 Security Best Practices

### **Secret Management**
```bash
#!/bin/bash
# secure-vars.sh - Secure handling of sensitive variables

# Read secrets from secure file
load_secrets() {
    local secrets_file="/etc/myapp/secrets"
    
    if [ -f "$secrets_file" ]; then
        # Source file in subshell to avoid polluting current environment
        set -o allexport
        source "$secrets_file"
        set +o allexport
        echo "Secrets loaded from $secrets_file"
    else
        echo "Warning: Secrets file not found at $secrets_file" >&2
    fi
}

# Mask sensitive output
mask_sensitive() {
    local value="$1"
    local visible_chars=4
    
    if [ ${#value} -gt $visible_chars ]; then
        echo "${value:0:$visible_chars}$(printf '*%.0s' $(seq 1 $((${#value} - $visible_chars))))"
    else
        printf '*%.0s' $(seq 1 ${#value})
    fi
}

# Example usage
API_KEY="sk-1234567890abcdef"
echo "API Key: $(mask_sensitive "$API_KEY")"

# Unset sensitive variables when done
cleanup_secrets() {
    unset API_KEY
    unset DATABASE_PASSWORD
    unset PRIVATE_KEY
}

# Register cleanup on script exit
trap cleanup_secrets EXIT
```

### **Input Validation**
```bash
#!/bin/bash
# input-validator.sh - Comprehensive input validation

# Validate variable types and formats
validate_variable() {
    local var_name="$1"
    local var_value="$2"
    local var_type="$3"
    
    case "$var_type" in
        "port")
            if ! [[ "$var_value" =~ ^[0-9]+$ ]] || [ "$var_value" -lt 1 ] || [ "$var_value" -gt 65535 ]; then
                echo "ERROR: $var_name must be a valid port number (1-65535)" >&2
                return 1
            fi
            ;;
        "url")
            if ! [[ "$var_value" =~ ^https?:// ]]; then
                echo "ERROR: $var_name must be a valid HTTP/HTTPS URL" >&2
                return 1
            fi
            ;;
        "email")
            if ! [[ "$var_value" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                echo "ERROR: $var_name must be a valid email address" >&2
                return 1
            fi
            ;;
        "path")
            if [ ! -e "$var_value" ]; then
                echo "ERROR: $var_name path does not exist: $var_value" >&2
                return 1
            fi
            ;;
        "non-empty")
            if [ -z "$var_value" ]; then
                echo "ERROR: $var_name cannot be empty" >&2
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Example validation usage
CONFIG_PORT="${PORT:-8080}"
CONFIG_URL="${API_URL:-}"
CONFIG_EMAIL="${ADMIN_EMAIL:-}"

validate_variable "PORT" "$CONFIG_PORT" "port" || exit 1
validate_variable "API_URL" "$CONFIG_URL" "url" || exit 1
validate_variable "ADMIN_EMAIL" "$CONFIG_EMAIL" "email" || exit 1

echo "All variables validated successfully!"
```

---

## 📊 Advanced Variable Techniques

### **Dynamic Variable Names**
```bash
#!/bin/bash
# dynamic-vars.sh - Dynamic variable manipulation

# Create variables dynamically
create_service_vars() {
    local services=("web" "api" "db" "cache")
    
    for service in "${services[@]}"; do
        # Create dynamic variable names
        local port_var="${service}_port"
        local host_var="${service}_host"
        local status_var="${service}_status"
        
        # Set default values
        declare -g "$port_var"=8080
        declare -g "$host_var"="localhost"
        declare -g "$status_var"="stopped"
    done
}

# Access variables dynamically
get_service_config() {
    local service="$1"
    local port_var="${service}_port"
    local host_var="${service}_host"
    
    # Use indirect reference
    echo "Service: $service"
    echo "Port: ${!port_var}"
    echo "Host: ${!host_var}"
}

# Example usage
create_service_vars
get_service_config "web"
get_service_config "api"
```

### **Array-like Variable Groups**
```bash
#!/bin/bash
# variable-groups.sh - Managing related variables as groups

# Server configuration groups
setup_server_groups() {
    # Production servers
    prod_servers=("prod-web-01" "prod-web-02" "prod-api-01" "prod-db-01")
    prod_ips=("10.0.1.10" "10.0.1.11" "10.0.2.10" "10.0.3.10")
    
    # Staging servers
    stage_servers=("stage-web-01" "stage-api-01" "stage-db-01")
    stage_ips=("10.1.1.10" "10.1.2.10" "10.1.3.10")
    
    # Development servers
    dev_servers=("dev-all-in-one")
    dev_ips=("10.2.1.10")
}

# Function to process server groups
process_servers() {
    local env="$1"
    local servers_var="${env}_servers[@]"
    local ips_var="${env}_ips[@]"
    
    local servers=("${!servers_var}")
    local ips=("${!ips_var}")
    
    echo "=== $env Environment ==="
    for i in "${!servers[@]}"; do
        echo "Server: ${servers[$i]} -> IP: ${ips[$i]}"
    done
    echo
}

setup_server_groups
process_servers "prod"
process_servers "stage"
process_servers "dev"
```

---

## 🎯 Common DevOps Use Cases

### **1. Docker Environment Variables**
```bash
#!/bin/bash
# docker-env.sh - Docker container environment management

# Build environment variables for Docker
build_docker_env() {
    local env_file=".env"
    local docker_env_file="docker.env"
    
    # Read from .env file and create Docker-compatible format
    if [ -f "$env_file" ]; then
        # Remove comments and empty lines, format for Docker
        grep -v '^#' "$env_file" | grep -v '^$' > "$docker_env_file"
        echo "Docker environment file created: $docker_env_file"
    else
        echo "Environment file not found: $env_file" >&2
        return 1
    fi
}

# Generate environment variables for different services
generate_service_env() {
    local service="$1"
    
    case "$service" in
        "web")
            cat > "web.env" << EOF
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
SESSION_SECRET=your-secret-here
EOF
            ;;
        "api")
            cat > "api.env" << EOF
FLASK_ENV=production
FLASK_APP=app.py
DATABASE_URL=postgresql://user:pass@db:5432/app
REDIS_URL=redis://cache:6379
EOF
            ;;
        "worker")
            cat > "worker.env" << EOF
CELERY_BROKER_URL=redis://cache:6379
CELERY_RESULT_BACKEND=redis://cache:6379
WORKER_CONCURRENCY=4
EOF
            ;;
    esac
    
    echo "Environment file generated for $service"
}

# Usage examples
build_docker_env
generate_service_env "web"
generate_service_env "api"
generate_service_env "worker"
```

### **2. CI/CD Variable Management**
```bash
#!/bin/bash
# cicd-vars.sh - CI/CD pipeline variable management

# Load CI/CD environment variables
load_cicd_vars() {
    # Common CI/CD variables
    export CI_COMMIT_SHA="${GITHUB_SHA:-${GITLAB_COMMIT_SHA:-unknown}}"
    export CI_BRANCH="${GITHUB_REF_NAME:-${CI_COMMIT_REF_NAME:-main}}"
    export CI_BUILD_NUMBER="${GITHUB_RUN_NUMBER:-${CI_PIPELINE_ID:-0}}"
    export CI_BUILD_URL="${GITHUB_SERVER_URL:-${CI_PIPELINE_URL:-}}"
    
    # Generate build metadata
    export BUILD_TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
    export BUILD_TAG="${CI_BRANCH}-${BUILD_TIMESTAMP}-${CI_COMMIT_SHA:0:8}"
    
    echo "=== CI/CD Environment ==="
    echo "Commit SHA: $CI_COMMIT_SHA"
    echo "Branch: $CI_BRANCH"
    echo "Build Number: $CI_BUILD_NUMBER"
    echo "Build Tag: $BUILD_TAG"
    echo "========================"
}

# Validate required CI/CD variables
validate_cicd_env() {
    local required_vars=("CI_COMMIT_SHA" "CI_BRANCH" "BUILD_TAG")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "ERROR: Missing required CI/CD variables: ${missing_vars[*]}" >&2
        return 1
    fi
    
    return 0
}

load_cicd_vars
validate_cicd_env || exit 1
```

---

## 🔍 Debugging & Troubleshooting

### **Variable Debugging Utilities**
```bash
#!/bin/bash
# debug-vars.sh - Variable debugging and inspection tools

# Debug variable function
debug_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    
    echo "DEBUG: Variable Analysis"
    echo "  Name: $var_name"
    echo "  Value: '$var_value'"
    echo "  Length: ${#var_value}"
    echo "  Type: $(declare -p "$var_name" 2>/dev/null | cut -d' ' -f2 || echo "undefined")"
    echo "  Empty: $([ -z "$var_value" ] && echo "true" || echo "false")"
    echo "  Set: $([ -n "$var_value" ] && echo "true" || echo "false")"
}

# Show all environment variables
show_env_vars() {
    echo "=== Environment Variables ==="
    env | sort | while IFS='=' read -r name value; do
        echo "$name=$(mask_sensitive "$value")"
    done
}

# Show variable differences between environments
compare_environments() {
    local env1_file="$1"
    local env2_file="$2"
    
    echo "=== Environment Comparison ==="
    echo "File 1: $env1_file"
    echo "File 2: $env2_file"
    
    # Show variables only in env1
    comm -23 <(cut -d'=' -f1 "$env1_file" | sort) <(cut -d'=' -f1 "$env2_file" | sort) | \
        while read var; do
            echo "Only in $env1_file: $var"
        done
    
    # Show variables only in env2
    comm -13 <(cut -d'=' -f1 "$env1_file" | sort) <(cut -d'=' -f1 "$env2_file" | sort) | \
        while read var; do
            echo "Only in $env2_file: $var"
        done
}

# Example usage
TEST_VAR="Hello World"
debug_var "TEST_VAR"
```

---

## 🏆 Best Practices Summary

### **✅ Do's**
- Use meaningful variable names (`DATABASE_URL` not `DB_URL`)
- Quote variables to prevent word splitting: `"$var"`
- Use `${var:-default}` for default values
- Validate input variables early in scripts
- Use `readonly` for constants: `readonly CONFIG_FILE="/etc/app.conf"`
- Export only necessary variables to child processes

### **❌ Don'ts**
- Don't use variables without validation
- Don't store secrets in plain text files
- Avoid global variables when local ones suffice
- Don't use cryptic variable names
- Don't forget to unset sensitive variables

### **🔧 Production Patterns**
- Always validate configuration variables
- Use environment-specific configuration files
- Implement proper secret management
- Log variable changes for audit purposes
- Use consistent naming conventions across teams

---

## 🎯 Interview Questions

### **Q1: Scope & Environment**
```bash
# What's the difference between these variable assignments?
var1="value"           # Local variable
export var2="value"    # Environment variable
readonly var3="value"  # Read-only variable
local var4="value"     # Function-local variable
```

### **Q2: Parameter Expansion**
```bash
# Explain each expansion:
echo "${var}"          # Basic expansion
echo "${var:-default}" # Default if unset
echo "${var:=default}" # Assign default if unset
echo "${var:+alt}"     # Alternative if set
echo "${var:?error}"   # Error if unset
echo "${#var}"         # Length
echo "${var##*/}"      # Remove longest prefix
echo "${var%%/*}"      # Remove longest suffix
```

### **Q3: Security & Best Practices**
*"How would you securely handle database passwords in a deployment script?"*

**Answer**: Use external secret management, environment variables, or encrypted files. Never hardcode secrets in scripts.

---

**🎯 Next Section: [Command Substitution & Tokens](../01-core-concepts/command-substitution.md)**
