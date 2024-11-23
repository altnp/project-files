#!/bin/bash

project_type=""
project_name=""
output_location=""

usage() {
    echo "Usage: $0 <project_type> -n|--name <project_name> -o|--output <output_location>"
    echo "  <project_type>  Type of the project (e.g., classlib, web)"
    echo "  -n, --name      Name of the project"
    echo "  -o, --output    Output location for the project (default: current directory)"
    exit 1
}

while (( "$#" )); do
    case "$1" in
        -n|--name)
            project_name="$2"
            shift 2
            ;;
        -o|--output)
            output_location="$2"
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

if [[ -z "$output_location" ]]; then
    output_location="./"
fi

output_location="${output_location%/}/"

if [[ ! -d "$output_location" ]]; then
    mkdir -p "$output_location"
fi
if [[ ! -d "${output_location}src" ]]; then
    mkdir -p "${output_location}src"
fi
if [[ ! -d "${output_location}tests" ]]; then
    mkdir -p "${output_location}tests"
fi

case "$project_name" in
    [A-Z]*)
        test_project_name="${project_name}.Tests"
        ;;
    *)
        test_project_name="${project_name}.tests"
        ;;
esac

dotnet new solution -n "$project_name" -o "$output_location"
dotnet new "$project_type" -n "$project_name" -o "${output_location}src/$project_name"
dotnet new xunit -n $test_project_name -o "${output_location}tests/${test_project_name}"

dotnet sln "${output_location}${project_name}.sln" add "${output_location}src/$project_name/$project_name.csproj"
dotnet sln "${output_location}${project_name}.sln" add "${output_location}tests/${test_project_name}/${test_project_name}.csproj"

dotnet add "${output_location}tests/${test_project_name}/${test_project_name}.csproj" reference "${output_location}src/$project_name/$project_name.csproj"

curl -o "${output_location}.editorconfig" https://raw.githubusercontent.com/altnp/project-files/master/dotnet/.editorconfig
curl -o "${output_location}.gitignore" https://raw.githubusercontent.com/altnp/project-files/master/dotnet/.gitignore

echo "Project setup complete!"
