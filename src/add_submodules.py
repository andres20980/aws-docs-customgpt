import requests
import subprocess

def get_repos(org, token):
    url = f"https://api.github.com/orgs/{org}/repos?per_page=100"
    headers = {'Authorization': f'token {token}'}
    response = requests.get(url, headers=headers)
    data = response.json()
    return [repo['clone_url'] for repo in data if repo['name'].startswith('amazon')]

def add_submodule(clone_url):
    repo_name = clone_url.split('/')[-1].replace('.git', '')
    submodule_path = f'awsdocs_submodules/{repo_name}'
    subprocess.run(['git', 'submodule', 'add', clone_url, submodule_path], check=True)

def main():
    org = 'awsdocs'
    token = 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN'  # Replace with your actual token
    repos = get_repos(org, token)
    for repo_url in repos:
        add_submodule(repo_url)

if __name__ == '__main__':
    main()
