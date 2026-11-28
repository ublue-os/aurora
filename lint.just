just := just_executable()
shellcheck:
    #!/usr/bin/env bash
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi

    find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

shfmt-check:
    #!/usr/bin/env bash
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    find . -iname "*.sh" -type f -exec shfmt --diff "{}" ';'

shfmt-fix:
    #!/usr/bin/env bash
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'

# Check Just Syntax
[group('Just')]
just-check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      {{ just }} --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
just-fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      {{ just }} --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --fmt -f Justfile || { exit 1; }

shell: shellcheck shfmt-check
