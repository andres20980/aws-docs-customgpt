import requests

# Installation ID obtenido
installation_id = '61712945'  # Reemplaza con el Installation ID obtenido
url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'

# Encabezados para la solicitud
headers = {
    'Authorization': f'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NDA1NzI1MDEsImV4cCI6MTc0MDU3MzEwMSwiaXNzIjoiMTE1OTAwNSJ9.Q7hN7NivYW0wTCc4_6JGMWxtqMXKWJnqSL-k7ALMDdJ-SuslMSh5fssqNbyfSeRVEDMDDwlKR3JQCQ1od4PMegTPTCOdxeQd_N8ef0UgLktV4pb9_BxaNG3ENUfhdQbqu4SA8wVXSE0XcWk37XlHI_WOK1lNH6m903yM_nJVDzRONMcoAGFce4TTSO_SxeTj4nczYctqaUZAuui4VCYh8z7euaRUT0ZAHe24JL0lPMIHgMA_32UhsWUEugU26gSOxaSrncowYULzblgP-i8rd3KK7mTCXOqlWv8OEhGqj616MLBLW0ULqZT81P2OACY4JBR1Q39Xbi68ZAQX5JeBWQ',  # Usa el JWT generado previamente
    'Accept': 'application/vnd.github.v3+json'
}

# Realizar la solicitud POST para obtener el Installation Token
response = requests.post(url, headers=headers)

# Verificar si la solicitud fue exitosa
if response.status_code == 201:
    installation_token = response.json()['token']
    print("Installation Token:", installation_token)
else:
    print(f"Error al obtener el Installation Token: {response.status_code}")
    print(response.text)
