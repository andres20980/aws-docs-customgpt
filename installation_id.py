import requests

# URL para obtener las instalaciones de la GitHub App
url = 'https://api.github.com/app/installations'

# Usa tu JWT generado
jwt_token = 'tu_jwt_aqui'  # Reemplaza con tu JWT generado

headers = {
    'Authorization': f'Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NDA1NzI1MDEsImV4cCI6MTc0MDU3MzEwMSwiaXNzIjoiMTE1OTAwNSJ9.Q7hN7NivYW0wTCc4_6JGMWxtqMXKWJnqSL-k7ALMDdJ-SuslMSh5fssqNbyfSeRVEDMDDwlKR3JQCQ1od4PMegTPTCOdxeQd_N8ef0UgLktV4pb9_BxaNG3ENUfhdQbqu4SA8wVXSE0XcWk37XlHI_WOK1lNH6m903yM_nJVDzRONMcoAGFce4TTSO_SxeTj4nczYctqaUZAuui4VCYh8z7euaRUT0ZAHe24JL0lPMIHgMA_32UhsWUEugU26gSOxaSrncowYULzblgP-i8rd3KK7mTCXOqlWv8OEhGqj616MLBLW0ULqZT81P2OACY4JBR1Q39Xbi68ZAQX5JeBWQ',  # Usa el JWT generado
    'Accept': 'application/vnd.github.v3+json'
}

# Realizar la solicitud GET para obtener las instalaciones
response = requests.get(url, headers=headers)

# Verificar si la solicitud fue exitosa
if response.status_code == 200:
    installations = response.json()
    if installations:
        # Si encontramos instalaciones, imprimimos el Installation ID
        for installation in installations:
            print(f"Installation ID: {installation['id']}")
    else:
        print("No se encontraron instalaciones para esta aplicación.")
else:
    # Si hay un error, imprimimos el código de error y el mensaje de la API
    print(f"Error al obtener las instalaciones: {response.status_code}")
    print("Respuesta de la API:", response.text)
