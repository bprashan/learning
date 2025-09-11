#!/bin/bash
# interactive-learner.sh - Guided Interactive Bash Learning Experience

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
LEARNING_DIR="./learning-sessions"
PROGRESS_FILE="$LEARNING_DIR/progress.json"
SESSION_LOG="$LEARNING_DIR/session-$(date +%Y%m%d-%H%M%S).log"

# Learning modules
declare -A LEARNING_MODULES=(
    ["intro"]="Introduction to Bash Scripting"
    ["variables"]="Variables and Environment"
    ["substitution"]="Command Substitution"
    ["expansions"]="Parameter Expansion"
    ["redirection"]="Input/Output Redirection"
    ["conditionals"]="Conditional Logic"
    ["loops"]="Loops and Iteration"
    ["functions"]="Functions and Scope"
    ["arrays"]="Arrays and Data Structures"
    ["text-processing"]="Text Processing Tools"
    ["error-handling"]="Error Handling"
    ["devops-basics"]="DevOps Automation Basics"
)

# Initialize learning environment
init_learning_environment() {
    mkdir -p "$LEARNING_DIR"
    
    echo -e "${BLUE}${BOLD}🎓 Interactive Bash Learning Experience${NC}"
    echo -e "${CYAN}=======================================${NC}"
    echo ""
    
    if [ ! -f "$PROGRESS_FILE" ]; then
        create_progress_file
    fi
    
    # Start session logging
    exec 19> "$SESSION_LOG"
    echo "Session started: $(date)" >&19
}

# Create progress tracking file
create_progress_file() {
    cat > "$PROGRESS_FILE" << 'EOF'
{
    "created": "",
    "last_session": "",
    "completed_modules": [],
    "current_module": "intro",
    "total_time_minutes": 0,
    "exercises_completed": 0,
    "skill_level": "beginner"
}
EOF
    
    # Set creation date
    local created_date=$(date -Iseconds)
    if command -v jq >/dev/null; then
        jq --arg date "$created_date" '.created = $date' "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
    else
        echo "Note: Install 'jq' for better progress tracking"
    fi
}

# Load progress
load_progress() {
    if [ -f "$PROGRESS_FILE" ] && command -v jq >/dev/null; then
        CURRENT_MODULE=$(jq -r '.current_module' "$PROGRESS_FILE" 2>/dev/null || echo "intro")
        COMPLETED_MODULES=($(jq -r '.completed_modules[]' "$PROGRESS_FILE" 2>/dev/null))
        SKILL_LEVEL=$(jq -r '.skill_level' "$PROGRESS_FILE" 2>/dev/null || echo "beginner")
    else
        CURRENT_MODULE="intro"
        COMPLETED_MODULES=()
        SKILL_LEVEL="beginner"
    fi
}

# Save progress
save_progress() {
    local module="$1"
    local completed="${2:-false}"
    
    if command -v jq >/dev/null && [ -f "$PROGRESS_FILE" ]; then
        local session_date=$(date -Iseconds)
        
        if [ "$completed" = "true" ]; then
            jq --arg module "$module" --arg date "$session_date" \
               '.completed_modules += [$module] | .last_session = $date | .exercises_completed += 1' \
               "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
        else
            jq --arg module "$module" --arg date "$session_date" \
               '.current_module = $module | .last_session = $date' \
               "$PROGRESS_FILE" > "$PROGRESS_FILE.tmp" && mv "$PROGRESS_FILE.tmp" "$PROGRESS_FILE"
        fi
    fi
    
    echo "Progress saved: $module" >&19
}

# Display main menu
show_main_menu() {
    clear
    echo -e "${BLUE}${BOLD}🎓 Interactive Bash Learning${NC}"
    echo -e "${CYAN}=============================${NC}"
    echo ""
    echo -e "${YELLOW}Current Level: $SKILL_LEVEL${NC}"
    echo -e "${YELLOW}Completed Modules: ${#COMPLETED_MODULES[@]}/${#LEARNING_MODULES[@]}${NC}"
    echo ""
    
    echo -e "${PURPLE}Available Learning Modules:${NC}"
    echo ""
    
    local counter=1
    for module in "${!LEARNING_MODULES[@]}"; do
        local status=""
        if [[ " ${COMPLETED_MODULES[@]} " =~ " ${module} " ]]; then
            status="${GREEN}✅${NC}"
        elif [ "$module" = "$CURRENT_MODULE" ]; then
            status="${YELLOW}🔄${NC}"
        else
            status="${BLUE}📚${NC}"
        fi
        
        printf "%2d. %s %-20s - %s\n" "$counter" "$status" "$module" "${LEARNING_MODULES[$module]}"
        ((counter++))
    done
    
    echo ""
    echo "Options:"
    echo "  📊 progress  - View detailed progress"
    echo "  🎯 quick     - Quick skill check"
    echo "  🔄 continue  - Continue from last session"
    echo "  ❌ exit      - Exit learning"
    echo ""
    read -p "Enter module name or option: " choice
    
    case "$choice" in
        "progress") show_progress ;;
        "quick") quick_skill_check ;;
        "continue") learn_module "$CURRENT_MODULE" ;;
        "exit") exit_learning ;;
        *) 
            if [ -n "${LEARNING_MODULES[$choice]}" ]; then
                learn_module "$choice"
            else
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                read -p "Press Enter to continue..."
                show_main_menu
            fi
            ;;
    esac
}

# Learn specific module
learn_module() {
    local module="$1"
    
    if [ -z "${LEARNING_MODULES[$module]}" ]; then
        echo -e "${RED}Unknown module: $module${NC}"
        return 1
    fi
    
    save_progress "$module"
    
    case "$module" in
        "intro") learn_introduction ;;
        "variables") learn_variables ;;
        "substitution") learn_command_substitution ;;
        "expansions") learn_expansions ;;
        "redirection") learn_redirection ;;
        "conditionals") learn_conditionals ;;
        "loops") learn_loops ;;
        "functions") learn_functions ;;
        "arrays") learn_arrays ;;
        "text-processing") learn_text_processing ;;
        "error-handling") learn_error_handling ;;
        "devops-basics") learn_devops_basics ;;
        *) 
            echo -e "${RED}Module not yet implemented: $module${NC}"
            read -p "Press Enter to return to menu..."
            show_main_menu
            ;;
    esac
}

# Introduction module
learn_introduction() {
    clear
    echo -e "${PURPLE}${BOLD}📚 Introduction to Bash Scripting${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Welcome to Interactive Bash Learning!${NC}"
    echo ""
    echo "Bash is the most widely used shell in Linux systems and is essential"
    echo "for DevOps engineers, system administrators, and developers."
    echo ""
    echo -e "${BLUE}What you'll learn:${NC}"
    echo "• Writing robust and maintainable bash scripts"
    echo "• Automating system administration tasks"
    echo "• Building DevOps pipelines and deployment scripts"
    echo "• Best practices for production environments"
    echo ""
    
    echo -e "${GREEN}Let's start with your first command!${NC}"
    echo ""
    echo "Type the following command to see your current shell:"
    echo -e "${CYAN}echo \$SHELL${NC}"
    echo ""
    read -p "Your command: " user_input
    
    if [ "$user_input" = "echo \$SHELL" ] || [ "$user_input" = "echo \"\$SHELL\"" ]; then
        echo -e "${GREEN}✅ Perfect!${NC}"
        echo "Output: $SHELL"
        echo ""
        echo "The \$SHELL variable contains the path to your current shell."
    else
        echo -e "${YELLOW}💡 Try: echo \$SHELL${NC}"
        echo "This shows your current shell path."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    
    # Interactive exercise
    echo ""
    echo -e "${CYAN}Interactive Exercise:${NC}"
    echo "Now let's check your username and home directory."
    echo "Try typing: echo \"Hello \$USER, your home is \$HOME\""
    echo ""
    read -p "Your command: " user_input
    
    # Execute the command if it's safe
    if [[ "$user_input" =~ ^echo.*USER.*HOME ]]; then
        echo -e "${GREEN}✅ Excellent!${NC}"
        echo "Let's see the output:"
        eval "$user_input"
    else
        echo -e "${YELLOW}💡 The correct command uses variables \$USER and \$HOME${NC}"
        echo "Output would be: Hello $USER, your home is $HOME"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Module completed! You learned about:${NC}"
    echo "• The \$SHELL variable"
    echo "• Basic variable substitution with \$USER and \$HOME"
    echo "• Using echo to display information"
    echo ""
    
    save_progress "intro" "true"
    
    read -p "Continue to next module (variables)? [y/N]: " continue_choice
    if [[ "$continue_choice" =~ ^[Yy] ]]; then
        learn_module "variables"
    else
        show_main_menu
    fi
}

# Variables module
learn_variables() {
    clear
    echo -e "${PURPLE}${BOLD}🔧 Variables and Environment${NC}"
    echo -e "${CYAN}============================${NC}"
    echo ""
    
    echo -e "${YELLOW}Understanding Bash Variables${NC}"
    echo ""
    echo "Variables are fundamental to bash scripting. They store data that"
    echo "can be used throughout your script."
    echo ""
    
    # Interactive demonstration
    echo -e "${BLUE}Let's practice variable assignment:${NC}"
    echo ""
    echo "Try creating a variable called 'name' with your name:"
    echo "Example: name=\"YourName\""
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ ^name= ]]; then
        echo -e "${GREEN}✅ Good!${NC}"
        # Safely execute the assignment
        if [[ "$user_input" =~ ^name=\"?[a-zA-Z0-9\ ]+\"?$ ]]; then
            eval "$user_input"
            echo "Variable created: name = $name"
        fi
    else
        echo -e "${YELLOW}💡 Try: name=\"YourName\"${NC}"
        name="Student"
        echo "I'll set name=\"Student\" for this example"
    fi
    
    echo ""
    echo "Now let's use the variable. Type: echo \"Hello \$name\""
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ echo.*name ]]; then
        echo -e "${GREEN}✅ Perfect!${NC}"
        eval "$user_input"
    else
        echo -e "${YELLOW}💡 Try: echo \"Hello \$name\"${NC}"
        echo "Output: Hello $name"
    fi
    
    echo ""
    echo -e "${CYAN}Advanced Variable Features:${NC}"
    echo ""
    echo "1. Default values: \${var:-default}"
    echo "2. Required variables: \${var:?error message}"
    echo "3. Export to environment: export var=\"value\""
    echo ""
    
    # Practical exercise
    echo -e "${BLUE}Practical Exercise:${NC}"
    echo "Create a variable 'database_host' with a default value of 'localhost'"
    echo "Use the syntax: \${variable_name:-default_value}"
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ database_host.*:- ]]; then
        echo -e "${GREEN}✅ Excellent! You understand default values.${NC}"
        eval "$user_input"
        echo "Result: database_host = $database_host"
    else
        echo -e "${YELLOW}💡 Try: database_host=\"\${database_host:-localhost}\"${NC}"
        database_host="localhost"
        echo "This sets database_host to 'localhost' if it's not already set."
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Variables module completed!${NC}"
    echo "You learned:"
    echo "• Basic variable assignment and usage"
    echo "• Variable substitution with \$var"
    echo "• Default values with \${var:-default}"
    echo ""
    
    save_progress "variables" "true"
    
    read -p "Continue to next module (substitution)? [y/N]: " continue_choice
    if [[ "$continue_choice" =~ ^[Yy] ]]; then
        learn_module "substitution"
    else
        show_main_menu
    fi
}

# Command substitution module
learn_command_substitution() {
    clear
    echo -e "${PURPLE}${BOLD}🔄 Command Substitution${NC}"
    echo -e "${CYAN}========================${NC}"
    echo ""
    
    echo -e "${YELLOW}Capturing Command Output${NC}"
    echo ""
    echo "Command substitution allows you to capture the output of commands"
    echo "and use them as values in your scripts."
    echo ""
    
    echo -e "${BLUE}Two syntaxes available:${NC}"
    echo "• Modern: \$(command)  [Recommended]"
    echo "• Legacy: \`command\`   [Avoid in new scripts]"
    echo ""
    
    echo "Let's try capturing the current date:"
    echo "Type: current_date=\$(date)"
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ \$\(date\) ]]; then
        echo -e "${GREEN}✅ Perfect modern syntax!${NC}"
        eval "$user_input"
        echo "Result: current_date = $current_date"
    elif [[ "$user_input" =~ \`date\` ]]; then
        echo -e "${YELLOW}⚠️  This works but use \$(date) instead of backticks${NC}"
        eval "$user_input"
        echo "Result: current_date = $current_date"
    else
        echo -e "${YELLOW}💡 Try: current_date=\$(date)${NC}"
        current_date=$(date)
        echo "Result: current_date = $current_date"
    fi
    
    echo ""
    echo -e "${CYAN}Practical Example:${NC}"
    echo "Let's capture system information"
    echo ""
    echo "Try getting the number of CPU cores:"
    echo "Hint: use the 'nproc' command with command substitution"
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ \$\(nproc\) ]]; then
        echo -e "${GREEN}✅ Excellent!${NC}"
        eval "$user_input"
        echo "Your system has $(nproc) CPU cores"
    else
        echo -e "${YELLOW}💡 Try: cpu_cores=\$(nproc)${NC}"
        cpu_cores=$(nproc)
        echo "Your system has $cpu_cores CPU cores"
    fi
    
    echo ""
    echo -e "${BLUE}Advanced Exercise:${NC}"
    echo "Combine command substitution with text processing"
    echo "Get the disk usage percentage of your root filesystem:"
    echo "Hint: df / | tail -1 | awk '{print \$5}'"
    echo ""
    read -p "Your command: " user_input
    
    if [[ "$user_input" =~ \$\(.*df.*tail.*awk ]]; then
        echo -e "${GREEN}✅ Advanced technique mastered!${NC}"
        eval "$user_input"
    else
        echo -e "${YELLOW}💡 Try: disk_usage=\$(df / | tail -1 | awk '{print \$5}')${NC}"
        disk_usage=$(df / | tail -1 | awk '{print $5}')
        echo "Root filesystem is $disk_usage full"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Command substitution completed!${NC}"
    echo "Key concepts learned:"
    echo "• Modern \$(command) syntax"
    echo "• Capturing command output in variables"
    echo "• Combining commands with pipes in substitution"
    echo ""
    
    save_progress "substitution" "true"
    
    read -p "Continue to next module? [y/N]: " continue_choice
    if [[ "$continue_choice" =~ ^[Yy] ]]; then
        show_main_menu
    else
        show_main_menu
    fi
}

# Show progress
show_progress() {
    clear
    echo -e "${PURPLE}${BOLD}📊 Your Learning Progress${NC}"
    echo -e "${CYAN}=========================${NC}"
    echo ""
    
    if [ -f "$PROGRESS_FILE" ] && command -v jq >/dev/null; then
        local created=$(jq -r '.created' "$PROGRESS_FILE" 2>/dev/null)
        local last_session=$(jq -r '.last_session' "$PROGRESS_FILE" 2>/dev/null)
        local exercises=$(jq -r '.exercises_completed' "$PROGRESS_FILE" 2>/dev/null)
        
        echo -e "${YELLOW}Profile Information:${NC}"
        echo "Created: $created"
        echo "Last session: $last_session"
        echo "Exercises completed: $exercises"
        echo "Current skill level: $SKILL_LEVEL"
        echo ""
    fi
    
    echo -e "${YELLOW}Module Progress:${NC}"
    echo ""
    
    for module in "${!LEARNING_MODULES[@]}"; do
        if [[ " ${COMPLETED_MODULES[@]} " =~ " ${module} " ]]; then
            echo -e "${GREEN}✅${NC} $module - ${LEARNING_MODULES[$module]}"
        elif [ "$module" = "$CURRENT_MODULE" ]; then
            echo -e "${YELLOW}🔄${NC} $module - ${LEARNING_MODULES[$module]} (In Progress)"
        else
            echo -e "${BLUE}📚${NC} $module - ${LEARNING_MODULES[$module]}"
        fi
    done
    
    echo ""
    local completion_rate=$(( ${#COMPLETED_MODULES[@]} * 100 / ${#LEARNING_MODULES[@]} ))
    echo -e "${CYAN}Overall Completion: $completion_rate%${NC}"
    
    # Progress bar
    local filled=$(( completion_rate / 5 ))
    local empty=$(( 20 - filled ))
    echo -n "["
    printf "${GREEN}%*s${NC}" "$filled" | tr ' ' '='
    printf "%*s" "$empty" | tr ' ' '-'
    echo "]"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# Quick skill check
quick_skill_check() {
    clear
    echo -e "${PURPLE}${BOLD}🎯 Quick Skill Check${NC}"
    echo -e "${CYAN}===================${NC}"
    echo ""
    
    local score=0
    local total=3
    
    echo "Question 1/3: What does this command do?"
    echo "echo \"\$USER is logged in\""
    echo ""
    echo "a) Prints the literal text \$USER is logged in"
    echo "b) Prints the username followed by 'is logged in'"
    echo "c) Causes an error"
    echo ""
    read -p "Your answer (a/b/c): " answer1
    
    if [[ "$answer1" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ The correct answer is b${NC}"
        echo "Variables inside double quotes are expanded."
    fi
    
    echo ""
    echo "Question 2/3: Which syntax is preferred for command substitution?"
    echo ""
    echo "a) \`command\`"
    echo "b) \$(command)"
    echo "c) Both are equally good"
    echo ""
    read -p "Your answer (a/b/c): " answer2
    
    if [[ "$answer2" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ The correct answer is b${NC}"
        echo "\$(command) is the modern, preferred syntax."
    fi
    
    echo ""
    echo "Question 3/3: How do you set a variable with a default value?"
    echo ""
    echo "a) var=default"
    echo "b) var=\${var:-default}"
    echo "c) var=\${default}"
    echo ""
    read -p "Your answer (a/b/c): " answer3
    
    if [[ "$answer3" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ The correct answer is b${NC}"
        echo "\${var:-default} uses default if var is unset."
    fi
    
    echo ""
    echo -e "${CYAN}Quick Check Results: $score/$total${NC}"
    
    if [ $score -eq $total ]; then
        echo -e "${GREEN}🎉 Perfect score! You're doing great!${NC}"
    elif [ $score -ge 2 ]; then
        echo -e "${YELLOW}👍 Good job! Review the areas you missed.${NC}"
    else
        echo -e "${RED}📚 Keep learning! Focus on the basics.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# Exit learning
exit_learning() {
    echo ""
    echo -e "${GREEN}Thanks for learning with us!${NC}"
    echo "Your progress has been saved."
    echo ""
    echo "Next steps:"
    echo "• Practice with real scripts"
    echo "• Take the skill assessment"
    echo "• Work on DevOps automation projects"
    echo ""
    echo "Session log saved to: $SESSION_LOG"
    echo "Continue learning anytime by running this script again!"
    echo ""
    
    # Close session log
    echo "Session ended: $(date)" >&19
    exec 19>&-
    
    exit 0
}

# Main execution
main() {
    init_learning_environment
    load_progress
    
    case "$1" in
        "--module")
            learn_module "$2"
            ;;
        "--progress")
            show_progress
            ;;
        "--quick")
            quick_skill_check
            ;;
        *)
            show_main_menu
            ;;
    esac
}

# Cleanup on exit
trap 'echo "Session ended: $(date)" >&19; exec 19>&-' EXIT

# Run main with all arguments
main "$@"
