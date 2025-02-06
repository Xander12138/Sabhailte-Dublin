#!/bin/bash
set -e
# Step 1: Install `pre-commit`
# Step 2: Install extensions for Visual Studio Code
# Step 3: Configure `settings.json` within the VSCode workspace
# Step 4: Install third-party support for `pre-commit`
# Step 5: Execute `pre-commit` to evaluate all files

# Step 1: Install `pre-commit`
echo "##################################################"
echo "Install pre-commit"
pip install pre-commit==3.4.0 autopep8==2.0.4 flake8==6.1.0 pep8==1.7.1 yapf==0.40.1 jsonschema==4.19.0
echo "##################################################"

# Step 2: Install extensions for Visual Studio Code
# cat extensions.txt | xargs -L 1 code --install-extension  export all extensions
if [ -x "$(command -v code)" ]; then
    code --install-extension ms-python.autopep8
    code --install-extension ms-python.flake8
    code --install-extension ms-python.isort
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension njpwerner.autodocstring
fi

echo "##################################################"

# Step 3: Configure `settings.json` within the VSCode workspace
echo "Configure settings.json within the VSCode workspace"
python3 << END
import json
import os

# assign settings.json file directory
dir_path = os.path.dirname(os.path.abspath(__file__))
settings_path = os.path.expanduser(f"{dir_path}/.vscode/settings.json")


# check if the directory exist
directory = os.path.dirname(settings_path)
if not os.path.exists(directory):
    os.makedirs(directory)

# check if settings.json exists, create JSON if not exist
if not os.path.exists(settings_path):
    with open(settings_path, "w") as f:
        json.dump({}, f, indent=4)

# read existence settings.json
with open(settings_path, "r") as f:
    settings = json.load(f)

# add or edit current settings
settings["editor.defaultFormatter"] = "ms-python.autopep8"
settings["flake8.args"] = ["--max-line-length=120"]
settings["autopep8.args"] = ["--max-line-length=120"]

# write current settings to settings.json
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=4)
END

# add .style.yapf
cat <<EOT > .style.yapf
[style]
based_on_style = google
column_limit = 120
indent_width = 4
EOT

echo "##################################################"
# Step 4: Install third-party support for `pre-commit`
pre-commit install
# Step 5: Execute `pre-commit` to evaluate all files
echo "##################################################"
pre-commit run --all-files
