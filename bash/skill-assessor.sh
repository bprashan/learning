#!/bin/bash
# skill-assessor.sh - Interactive Bash Skills Assessment Tool

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Assessment configuration
ASSESSMENT_DIR="./assessments"
RESULTS_FILE="$ASSESSMENT_DIR/results-$(date +%Y%m%d-%H%M%S).json"
USER_PROFILE="$ASSESSMENT_DIR/user-profile.json"

# Skills categories
declare -A SKILL_CATEGORIES=(
    ["variables"]="Shell Variables & Environment"
    ["substitution"]="Command Substitution & Tokens"
    ["expansions"]="Expansions & Quote Removal"
    ["redirection"]="Redirection & I/O Management"
    ["conditionals"]="Conditional Statements"
    ["arrays"]="Arrays & Data Structures"
    ["loops"]="Loops & Iteration"
    ["functions"]="Functions & Scope"
    ["error-handling"]="Error Handling & Logging"
    ["text-processing"]="Text Processing & Parsing"
    ["devops-automation"]="DevOps Automation"
)

# Initialize assessment environment
init_assessment() {
    mkdir -p "$ASSESSMENT_DIR"
    
    if [ ! -f "$USER_PROFILE" ]; then
        create_user_profile
    fi
    
    echo -e "${BLUE}Bash Skills Assessment Tool${NC}"
    echo -e "${CYAN}===========================${NC}"
    echo ""
}

# Create user profile
create_user_profile() {
    echo -e "${YELLOW}First time setup - Creating your profile${NC}"
    echo ""
    
    read -p "Enter your name: " user_name
    read -p "Enter your experience level (beginner/intermediate/advanced): " experience_level
    read -p "Enter your role (developer/devops/sysadmin/student): " role
    
    cat > "$USER_PROFILE" << EOF
{
    "name": "$user_name",
    "experience_level": "$experience_level",
    "role": "$role",
    "created": "$(date -Iseconds)",
    "assessments_taken": 0,
    "skill_scores": {}
}
EOF
    
    echo -e "${GREEN}Profile created successfully!${NC}"
    echo ""
}

# Load user profile
load_user_profile() {
    if [ -f "$USER_PROFILE" ]; then
        USER_NAME=$(jq -r '.name' "$USER_PROFILE" 2>/dev/null || echo "User")
        EXPERIENCE_LEVEL=$(jq -r '.experience_level' "$USER_PROFILE" 2>/dev/null || echo "unknown")
        ROLE=$(jq -r '.role' "$USER_PROFILE" 2>/dev/null || echo "unknown")
    else
        USER_NAME="User"
        EXPERIENCE_LEVEL="unknown"
        ROLE="unknown"
    fi
}

# Quick skill test
quick_test() {
    echo -e "${PURPLE}Quick Skill Assessment${NC}"
    echo -e "${CYAN}======================${NC}"
    echo ""
    
    local score=0
    local total=5
    
    # Question 1: Variables
    echo -e "${YELLOW}Question 1/5: Variables${NC}"
    echo "What does this command output?"
    echo '  name="John"; echo "Hello ${name:-Anonymous}"'
    echo ""
    echo "a) Hello John"
    echo "b) Hello Anonymous"
    echo "c) Hello \${name:-Anonymous}"
    echo "d) Error"
    echo ""
    read -p "Your answer (a/b/c/d): " answer1
    
    if [[ "$answer1" =~ ^[Aa]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ Incorrect. Answer: a) Hello John${NC}"
        echo "Explanation: \${var:-default} uses the variable value if set, default if unset."
    fi
    echo ""
    
    # Question 2: Command Substitution
    echo -e "${YELLOW}Question 2/5: Command Substitution${NC}"
    echo "Which is the preferred modern syntax for command substitution?"
    echo ""
    echo "a) \`command\`"
    echo "b) \$(command)"
    echo "c) \${command}"
    echo "d) \\command"
    echo ""
    read -p "Your answer (a/b/c/d): " answer2
    
    if [[ "$answer2" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ Incorrect. Answer: b) \$(command)${NC}"
        echo "Explanation: \$(command) is the modern, nestable syntax preferred over backticks."
    fi
    echo ""
    
    # Question 3: Redirection
    echo -e "${YELLOW}Question 3/5: Redirection${NC}"
    echo "What does this command do?"
    echo '  command > output.txt 2>&1'
    echo ""
    echo "a) Redirects stdout to output.txt, stderr to stdout"
    echo "b) Redirects both stdout and stderr to output.txt"
    echo "c) Redirects stderr to output.txt, stdout to stderr"
    echo "d) Creates an error"
    echo ""
    read -p "Your answer (a/b/c/d): " answer3
    
    if [[ "$answer3" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ Incorrect. Answer: b) Redirects both stdout and stderr to output.txt${NC}"
        echo "Explanation: > redirects stdout, 2>&1 redirects stderr to stdout (which goes to the file)."
    fi
    echo ""
    
    # Question 4: Conditionals
    echo -e "${YELLOW}Question 4/5: Conditionals${NC}"
    echo "Which test checks if a file exists and is readable?"
    echo ""
    echo "a) [ -f file ]"
    echo "b) [ -r file ]"
    echo "c) [ -e file ]"
    echo "d) [ -x file ]"
    echo ""
    read -p "Your answer (a/b/c/d): " answer4
    
    if [[ "$answer4" =~ ^[Bb]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ Incorrect. Answer: b) [ -r file ]${NC}"
        echo "Explanation: -r tests for read permission, -f tests if it's a regular file, -e tests existence, -x tests execute permission."
    fi
    echo ""
    
    # Question 5: Best Practices
    echo -e "${YELLOW}Question 5/5: Best Practices${NC}"
    echo "Which is the safest way to iterate over filenames that might contain spaces?"
    echo ""
    echo 'a) for file in $(ls *.txt); do'
    echo 'b) for file in *.txt; do'
    echo 'c) ls *.txt | while read file; do'
    echo 'd) find . -name "*.txt" -print0 | while IFS= read -r -d "" file; do'
    echo ""
    read -p "Your answer (a/b/c/d): " answer5
    
    if [[ "$answer5" =~ ^[Dd]$ ]]; then
        echo -e "${GREEN}✅ Correct!${NC}"
        ((score++))
    else
        echo -e "${RED}❌ Incorrect. Answer: d) find with -print0 and read -d \"\"${NC}"
        echo "Explanation: This properly handles filenames with spaces, newlines, and special characters."
    fi
    echo ""
    
    # Show results
    local percentage=$((score * 100 / total))
    echo -e "${CYAN}=== Quick Test Results ===${NC}"
    echo "Score: $score out of $total ($percentage%)"
    
    if [ $percentage -ge 80 ]; then
        echo -e "${GREEN}🎉 Excellent! You have strong bash fundamentals.${NC}"
        echo -e "Recommended: Take advanced assessments or work on DevOps automation."
    elif [ $percentage -ge 60 ]; then
        echo -e "${YELLOW}👍 Good job! You understand the basics well.${NC}"
        echo -e "Recommended: Practice more with advanced topics like error handling and text processing."
    else
        echo -e "${RED}📚 Keep studying! Focus on the fundamentals first.${NC}"
        echo -e "Recommended: Start with core concepts: variables, command substitution, and redirection."
    fi
    
    # Save results
    save_quick_test_results $score $total
}

# Detailed skill assessment
detailed_assessment() {
    local skill="$1"
    
    if [ -z "$skill" ]; then
        echo -e "${PURPLE}Available Skills for Assessment:${NC}"
        echo ""
        for key in "${!SKILL_CATEGORIES[@]}"; do
            echo -e "${CYAN}$key${NC}: ${SKILL_CATEGORIES[$key]}"
        done
        echo ""
        read -p "Enter skill to assess: " skill
    fi
    
    if [ -z "${SKILL_CATEGORIES[$skill]}" ]; then
        echo -e "${RED}Unknown skill: $skill${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}Detailed Assessment: ${SKILL_CATEGORIES[$skill]}${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..50})${NC}"
    echo ""
    
    case "$skill" in
        "variables")
            assess_variables
            ;;
        "substitution")
            assess_command_substitution
            ;;
        "expansions")
            assess_expansions
            ;;
        "redirection")
            assess_redirection
            ;;
        "conditionals")
            assess_conditionals
            ;;
        "arrays")
            assess_arrays
            ;;
        "loops")
            assess_loops
            ;;
        "error-handling")
            assess_error_handling
            ;;
        "text-processing")
            assess_text_processing
            ;;
        "devops-automation")
            assess_devops_automation
            ;;
        *)
            echo -e "${RED}Assessment not yet implemented for: $skill${NC}"
            ;;
    esac
}

# Variables assessment
assess_variables() {
    local score=0
    local total=8
    
    echo -e "${YELLOW}Variables and Environment Management Assessment${NC}"
    echo ""
    
    # Question 1
    echo "1. What's the difference between these assignments?"
    echo "   var1=\"value\""
    echo "   export var2=\"value\""
    echo ""
    echo "a) No difference"
    echo "b) var2 is available to child processes, var1 is not"
    echo "c) var1 is global, var2 is local"
    echo "d) var2 is read-only"
    echo ""
    read -p "Answer: " q1
    [ "$q1" = "b" ] && ((score++))
    
    # Question 2
    echo ""
    echo "2. What does this output if VAR is unset?"
    echo "   echo \"\${VAR:=default}\""
    echo ""
    echo "a) Nothing"
    echo "b) default"
    echo "c) \${VAR:=default}"
    echo "d) Error"
    echo ""
    read -p "Answer: " q2
    [ "$q2" = "b" ] && ((score++))
    
    # Question 3
    echo ""
    echo "3. How do you make a variable read-only?"
    echo ""
    echo "a) const VAR=\"value\""
    echo "b) readonly VAR=\"value\""
    echo "c) final VAR=\"value\""
    echo "d) static VAR=\"value\""
    echo ""
    read -p "Answer: " q3
    [ "$q3" = "b" ] && ((score++))
    
    # Practical exercise
    echo ""
    echo -e "${CYAN}Practical Exercise:${NC}"
    echo "Write a command to check if the environment variable API_KEY is set,"
    echo "and if not, display an error message and exit."
    echo ""
    read -p "Your command: " practical1
    
    if [[ "$practical1" =~ (\[|\[\[).*API_KEY.*(\]|\]\]) ]] || [[ "$practical1" =~ \$\{API_KEY.*\?\} ]]; then
        echo -e "${GREEN}✅ Good approach!${NC}"
        ((score++))
    else
        echo -e "${YELLOW}Consider: [ -z \"\$API_KEY\" ] && echo \"Error\" && exit 1${NC}"
        echo -e "${YELLOW}Or: : \"\${API_KEY:?API_KEY must be set}\"${NC}"
    fi
    
    # Show detailed results
    show_assessment_results "Variables" $score $total
}

# Command substitution assessment
assess_command_substitution() {
    local score=0
    local total=6
    
    echo -e "${YELLOW}Command Substitution Assessment${NC}"
    echo ""
    
    # Question 1
    echo "1. Which command substitution syntax allows nesting?"
    echo ""
    echo "a) \`command\`"
    echo "b) \$(command)"
    echo "c) Both"
    echo "d) Neither"
    echo ""
    read -p "Answer: " q1
    [ "$q1" = "b" ] && ((score++))
    
    # Question 2
    echo ""
    echo "2. What's wrong with this code?"
    echo "   for file in \$(find /large/dir -name \"*.log\"); do"
    echo "       process \"\$file\""
    echo "   done"
    echo ""
    echo "a) Nothing wrong"
    echo "b) Word splitting on filenames with spaces"
    echo "c) Performance issues with large directories"
    echo "d) Both b and c"
    echo ""
    read -p "Answer: " q2
    [ "$q2" = "d" ] && ((score++))
    
    # Practical exercise
    echo ""
    echo -e "${CYAN}Practical Exercise:${NC}"
    echo "Write a command to get the PID of the process using the most memory"
    echo "(without using top/htop commands)"
    echo ""
    read -p "Your command: " practical1
    
    if [[ "$practical1" =~ ps.*sort.*awk ]] || [[ "$practical1" =~ ps.*head ]]; then
        echo -e "${GREEN}✅ Good approach!${NC}"
        ((score++))
    else
        echo -e "${YELLOW}Consider: ps aux --sort=-%mem | head -2 | tail -1 | awk '{print \$2}'${NC}"
    fi
    
    show_assessment_results "Command Substitution" $score $total
}

# Assessment results display
show_assessment_results() {
    local topic="$1"
    local score="$2"
    local total="$3"
    local percentage=$((score * 100 / total))
    
    echo ""
    echo -e "${CYAN}=== $topic Assessment Results ===${NC}"
    echo "Score: $score out of $total ($percentage%)"
    
    if [ $percentage -ge 90 ]; then
        echo -e "${GREEN}🏆 Expert level! You've mastered this topic.${NC}"
        echo -e "Next: Consider teaching others or contributing to documentation."
    elif [ $percentage -ge 75 ]; then
        echo -e "${GREEN}🎯 Advanced level! Very good understanding.${NC}"
        echo -e "Next: Practice real-world scenarios and edge cases."
    elif [ $percentage -ge 60 ]; then
        echo -e "${YELLOW}📈 Intermediate level! Solid foundation.${NC}"
        echo -e "Next: Study advanced patterns and best practices."
    elif [ $percentage -ge 40 ]; then
        echo -e "${YELLOW}📚 Beginner level! Basic understanding present.${NC}"
        echo -e "Next: Practice more examples and hands-on exercises."
    else
        echo -e "${RED}🎓 Study needed! Review the fundamentals.${NC}"
        echo -e "Next: Go through the tutorial materials for this topic."
    fi
    
    # Save results
    save_assessment_results "$topic" $score $total
}

# Save assessment results
save_assessment_results() {
    local topic="$1"
    local score="$2"
    local total="$3"
    local percentage=$((score * 100 / total))
    
    # Create results JSON
    cat > "$RESULTS_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "user": "$USER_NAME",
    "topic": "$topic",
    "score": $score,
    "total": $total,
    "percentage": $percentage,
    "level": "$(get_skill_level $percentage)"
}
EOF
    
    echo -e "${BLUE}Results saved to: $RESULTS_FILE${NC}"
}

# Save quick test results
save_quick_test_results() {
    local score="$1"
    local total="$2"
    local percentage=$((score * 100 / total))
    
    cat > "$RESULTS_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "user": "$USER_NAME",
    "topic": "Quick Test",
    "score": $score,
    "total": $total,
    "percentage": $percentage,
    "level": "$(get_skill_level $percentage)"
}
EOF
}

# Get skill level based on percentage
get_skill_level() {
    local percentage="$1"
    
    if [ $percentage -ge 90 ]; then
        echo "expert"
    elif [ $percentage -ge 75 ]; then
        echo "advanced"
    elif [ $percentage -ge 60 ]; then
        echo "intermediate"
    elif [ $percentage -ge 40 ]; then
        echo "beginner"
    else
        echo "novice"
    fi
}

# Generate learning path
generate_learning_path() {
    load_user_profile
    
    echo -e "${PURPLE}Personalized Learning Path${NC}"
    echo -e "${CYAN}=========================${NC}"
    echo ""
    echo "Based on your profile:"
    echo "  Name: $USER_NAME"
    echo "  Experience: $EXPERIENCE_LEVEL"
    echo "  Role: $ROLE"
    echo ""
    
    case "$EXPERIENCE_LEVEL" in
        "beginner")
            echo -e "${YELLOW}Beginner Learning Path:${NC}"
            echo "1. 📚 Core Concepts (4-6 weeks)"
            echo "   • Shell Variables & Environment"
            echo "   • Command Substitution & Tokens"
            echo "   • Expansions & Quote Removal"
            echo "   • Redirection & I/O Management"
            echo ""
            echo "2. 🧠 Control Structures (3-4 weeks)"
            echo "   • Conditional Statements"
            echo "   • Arrays & Data Structures"
            echo "   • Loops & Iteration"
            echo ""
            echo "3. 🎯 Practice Projects"
            echo "   • Simple backup scripts"
            echo "   • Log processing tools"
            echo "   • System monitoring scripts"
            ;;
        "intermediate")
            echo -e "${YELLOW}Intermediate Learning Path:${NC}"
            echo "1. 🔧 Advanced Techniques (3-4 weeks)"
            echo "   • Error Handling & Logging"
            echo "   • Text Processing & Parsing"
            echo "   • Process Management"
            echo ""
            echo "2. 🚀 DevOps Automation (4-5 weeks)"
            echo "   • Deployment Scripts"
            echo "   • Infrastructure Automation"
            echo "   • Monitoring & Alerting"
            echo ""
            echo "3. 🎯 Real-world Projects"
            echo "   • CI/CD pipeline scripts"
            echo "   • Infrastructure management"
            echo "   • Performance monitoring"
            ;;
        "advanced")
            echo -e "${YELLOW}Advanced Learning Path:${NC}"
            echo "1. 🏗️ Architecture & Design (2-3 weeks)"
            echo "   • Script architecture patterns"
            echo "   • Security best practices"
            echo "   • Performance optimization"
            echo ""
            echo "2. 🎓 Mastery Topics (3-4 weeks)"
            echo "   • Complex automation frameworks"
            echo "   • Integration with modern tools"
            echo "   • Debugging and troubleshooting"
            echo ""
            echo "3. 🎯 Leadership Projects"
            echo "   • Team automation standards"
            echo "   • Tool development"
            echo "   • Knowledge sharing"
            ;;
    esac
    
    echo ""
    echo -e "${BLUE}Recommended next step: Run './skill-assessor.sh --practice [topic]'${NC}"
}

# Practice mode
practice_mode() {
    local topic="$1"
    
    echo -e "${PURPLE}Practice Mode: $topic${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..30})${NC}"
    echo ""
    
    case "$topic" in
        "variables")
            practice_variables
            ;;
        "substitution")
            practice_substitution
            ;;
        "arrays")
            practice_arrays
            ;;
        *)
            echo -e "${RED}Practice mode not yet available for: $topic${NC}"
            echo "Available practice topics: variables, substitution, arrays"
            ;;
    esac
}

# Variables practice
practice_variables() {
    echo -e "${YELLOW}Variables Practice Session${NC}"
    echo ""
    
    # Exercise 1
    echo "Exercise 1: Set a variable DB_HOST to 'localhost' with a default fallback"
    echo "Type your command:"
    read -r user_cmd
    
    if [[ "$user_cmd" =~ DB_HOST.*:- ]]; then
        echo -e "${GREEN}✅ Correct pattern!${NC}"
    else
        echo -e "${YELLOW}💡 Try: DB_HOST=\"\${DB_HOST:-localhost}\"${NC}"
    fi
    
    echo ""
    
    # Exercise 2
    echo "Exercise 2: Create a read-only variable API_VERSION set to 'v1.2.3'"
    echo "Type your command:"
    read -r user_cmd
    
    if [[ "$user_cmd" =~ readonly.*API_VERSION ]]; then
        echo -e "${GREEN}✅ Excellent!${NC}"
    else
        echo -e "${YELLOW}💡 Try: readonly API_VERSION=\"v1.2.3\"${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Practice complete! Try more exercises with real scripts.${NC}"
}

# Main menu
show_menu() {
    echo -e "${BLUE}Bash Skills Assessment Tool${NC}"
    echo -e "${CYAN}===========================${NC}"
    echo ""
    echo "1. 🎯 Quick Skill Test (5 minutes)"
    echo "2. 📊 Detailed Assessment (specific topic)"
    echo "3. 🗺️  Generate Learning Path"
    echo "4. 💪 Practice Mode"
    echo "5. 📈 View Progress"
    echo "6. ❌ Exit"
    echo ""
    read -p "Choose an option (1-6): " choice
    
    case "$choice" in
        1) quick_test ;;
        2) detailed_assessment ;;
        3) generate_learning_path ;;
        4) 
            echo "Enter topic to practice:"
            read topic
            practice_mode "$topic"
            ;;
        5) view_progress ;;
        6) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

# View progress
view_progress() {
    echo -e "${PURPLE}Your Learning Progress${NC}"
    echo -e "${CYAN}=====================${NC}"
    echo ""
    
    if [ -d "$ASSESSMENT_DIR" ] && [ "$(ls -A $ASSESSMENT_DIR/results-*.json 2>/dev/null)" ]; then
        echo "Recent assessments:"
        for result_file in "$ASSESSMENT_DIR"/results-*.json; do
            if [ -f "$result_file" ]; then
                local topic=$(jq -r '.topic' "$result_file" 2>/dev/null)
                local percentage=$(jq -r '.percentage' "$result_file" 2>/dev/null)
                local level=$(jq -r '.level' "$result_file" 2>/dev/null)
                local timestamp=$(jq -r '.timestamp' "$result_file" 2>/dev/null)
                
                echo "  $topic: $percentage% ($level) - $timestamp"
            fi
        done
    else
        echo "No assessments taken yet."
        echo "Start with: './skill-assessor.sh --quick-test'"
    fi
    
    echo ""
}

# Command line interface
main() {
    init_assessment
    load_user_profile
    
    case "$1" in
        "--quick-test")
            quick_test
            ;;
        "--learning-path")
            generate_learning_path
            ;;
        "--practice")
            practice_mode "$2"
            ;;
        "--assessment")
            detailed_assessment "$2"
            ;;
        "--progress")
            view_progress
            ;;
        *)
            show_menu
            ;;
    esac
}

# Run main function with all arguments
main "$@"
