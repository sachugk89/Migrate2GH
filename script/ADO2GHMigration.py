import subprocess
import csv
import os

def run_command(command):
    """Run a shell command and print its output."""
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error while running command: {command}")
        print(e.stderr)

# Step 0: Prompt user for input to set environment variables
print("Please provide the following details to set up environment variables:")
azure_devops_instance_url = input("Enter Azure DevOps Instance URL (e.g., https://dev.azure.com/your-instance): ").strip()
azure_devops_access_token = input("Enter Azure DevOps Access Token: ").strip()
ado_project = input("Enter Azure DevOps Project Name: ").strip()
ado_org = input("Enter Azure DevOps Organization Name: ").strip()

# Set environment variables
os.environ["AZURE_DEVOPS_INSTANCE_URL"] = azure_devops_instance_url
os.environ["AZURE_DEVOPS_ACCESS_TOKEN"] = azure_devops_access_token
os.environ["ADO_PROJECT"] = ado_project
os.environ["ADO_ORG"] = ado_org

print("\nEnvironment variables set successfully.")

# Step 1: Install and upgrade the required GitHub CLI extensions
run_command("gh extension install github/gh-ado2gh")
run_command("gh extension upgrade github/gh-ado2gh")
run_command("gh ado2gh inventory-report")
run_command("gh ado2gh generate-script")

run_command("gh extension install github/gh-actions-importer")
run_command("gh actions-importer update")

# Step 2: Process the team-projects.csv file and run commands in a loop
csv_file = "./HomeADO2GH/team-projects.csv"

if os.path.exists(csv_file):
    with open(csv_file, mode="r") as file:
        reader = csv.DictReader(file)
        for row in reader:
            org = row.get("org")
            team_project = row.get("teamproject")
            if org and team_project:
                # Run the audit and forecast commands
                run_command(f"gh actions-importer audit azure-devops -g {org} -p {team_project}")
                run_command(f"gh actions-importer forecast azure-devops -g {org} -p {team_project}")
else:
    print(f"CSV file not found: {csv_file}")