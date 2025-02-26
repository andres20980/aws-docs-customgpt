import requests

def get_repos(org, token):
    url = f"https://api.github.com/orgs/{org}/repos?per_page=100"
    headers = {'Authorization': f'token {token}'}
    response = requests.get(url, headers=headers)

    # Imprimir la respuesta de la API para depuración
    print("Respuesta de la API:", response.text)  # Esto te ayudará a ver qué está devolviendo la API

    # Intentar convertir la respuesta en JSON
    data = response.json()

    # Verificar si la respuesta contiene un mensaje de error de la API
    if isinstance(data, dict) and "message" in data:
        print("Error de la API de GitHub:", data["message"])
        return []

    # Obtener los repositorios si la respuesta es correcta
    return [repo['clone_url'] for repo in data if isinstance(repo, dict) and repo.get('name', '').startswith('amazon')]

def main():
    org = 'awsdocs'  # Cambia esto si es necesario
    token = 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN'  # Reemplázalo con tu token correcto
    repos = get_repos(org, token)
    for repo_url in repos:
        print("Repo URL:", repo_url)

if __name__ == '__main__':
    main()
