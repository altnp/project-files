#!/bin/bash

create_tests=""
project_type=""
project_name=""
solution_location=""

usage() {
    echo "Usage: $0 <project_type> -n|--name <project_name> [-s|--sln <solution_location>]"
    echo "  <project_type>  Type of the project (e.g., classlib, web)"
    echo "  -n, --name      Name of the project"
    echo "  -s, --sln       Location of the solution file (default: current directory)"
    echo "  -t, --tests     Add a matching tests project y/n"
    exit 1
}

while (( "$#" )); do
    case "$1" in
        -n|--name)
            project_name="$2"
            shift 2
            ;;
        -s|--sln)
            solution_location="$2"
            shift 2
            ;;
        -t|--tests)
            create_tests="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown argument: $1"
            usage
            ;;
        *)
            if [[ -z "$project_type" ]]; then
                project_type="$1"
                shift
            else
                echo "Unknown argument: $1"
                usage
            fi
            ;;
    esac
done

if [[ -z "$project_type" ]]; then
    echo "Project type is required (e.g., classlib, web)"
    usage
fi

if [[ -z "$project_name" ]]; then
    echo "Project name is required"
    usage
fi

if [[ -z "$solution_location" ]]; then
    solution_location=$(find . -maxdepth 1 -name "*.sln" | head -n 1)
    if [[ -z "$solution_location" ]]; then
        echo "Solution file not found in the current directory. Please specify the solution location using -s flag."
        exit 1
    fi
fi

solution_root=$(dirname "$solution_location")

dotnet new "$project_type" -n "$project_name" -o "$solution_root/src/$project_name"
dotnet sln "$solution_location" add "$solution_root/src/$project_name/$project_name.csproj"

if [[ "$create_tests" == "" ]]; then
  read -p "Do you want to create a matching tests project? (y/n): " create_tests
fi

if [[ "$create_tests" == "y" ]]; then
    if [[ ! -d "$solution_root/tests" ]]; then
        mkdir -p "$solution_root/tests"
    fi

    case "$project_name" in
        [A-Z]*)
            test_project_name="${project_name}.Tests"
            ;;
        *)
            test_project_name="${project_name}.tests"
            ;;
    esac

    dotnet new xunit -n "$test_project_name" -o "$solution_root/tests/${test_project_name}"
    dotnet sln "$solution_location" add "$solution_root/tests/${test_project_name}/${test_project_name}.csproj"
    dotnet add "$solution_root/tests/${test_project_name}/${test_project_name}.csproj" reference "$solution_root/src/$project_name/$project_name.csproj"
fi

echo "Project addition complete!"
