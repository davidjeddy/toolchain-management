#!/bin/python3

# Requires python3 and InquirerPy library - use pip3 install InquirerPy to install it
# (optional) Put this file in $HOME/bin/ folder and do chmod+x on it so it can be executed from anywhere using change_aws_profile.py

# Fancy wrapper for switching AWS_DEFAULT_PROFILE environment variable, ~/.aws/config file is parsed to find available
# profiles and shows them in a menu.
# It spawns new shell process because it is not allowed to change environment variables of the parent process
# I created this script because I had problems with aws-sso command on my WSL machine. I think this approach is simpler
# and easier to maintain, we rely only on AWS official tooling and ENV switching without all the magic aws-sso does
# that we don't need.

from InquirerPy import inquirer
import subprocess
import os

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


if 'AWS_DEFAULT_PROFILE' in os.environ:
   print(bcolors.WARNING + 'WARNING: AWS_DEFAULT_PROFILE is already set, proceeding will spawn another subprocess. Press CTRL+C to stop.')

home = os.environ['HOME']

with open(f'{home}/.aws/config', 'r') as file:
   lines = file.readlines()

# Filter lines that contain aws profile name, strip newlines
choices = [
   line.strip()[len("[profile "):-1].strip()
   for line in lines
   if line.strip().startswith('[profile') and line.strip().endswith(']')
]

selected = inquirer.select(
    message='Choose aws profile',
    choices=choices,
    default=choices[0],
).execute()


print(f"export AWS_DEFAULT_PROFILE={selected}")
print("Spawning new shell with selected profile set, type exit to leave")
os.environ['AWS_DEFAULT_PROFILE'] = selected


subprocess.run(["bash"])


