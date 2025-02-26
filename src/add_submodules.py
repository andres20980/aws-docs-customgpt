import requests
import subprocess

def get_repos(org, token):
    url = f"https://api.github.com/orgs/{org}/repos"
    headers = {'Authorization': f'token {token}'}
    response = requests.get(url, headers=headers)
    data = response.json()
    return [repo['clone_url'] for repo in data if repo['name'].startswith('amazon')]  # Filtra repositorios específicos

def add_submodule(clone_url):
    submodule_path = 'awsdocs_submodules/' + clone_url.split('/')[-1].replace('.git', '')
    subprocess.run(['git', 'submodule', 'add', clone_url, submodule_path], check=True)
    subprocess.run(['git', 'add', '.'], check=True)
    subprocess.run(['git', 'commit', '-m', f'Added submodule {submodule_path}'], check=True)
    subprocess.run(['git', 'push'], check=True)

def main():
    org = 'awsdocs'
    token = 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN'  # Asegúrate de configurar esto de manera segura
    repos = get_repos(org, token)
    for repo_url in repos:
        add_submodule(repo_url)

if __name__ == '__main__':
    main()