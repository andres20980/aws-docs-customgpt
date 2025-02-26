import jwt
import time
import requests

# Define tu App ID y la clave privada (.pem)
app_id = '1159005'  # Reemplaza con tu App ID
private_key_path = 'aws-docs-customgpt.2025-02-26.private-key.pem'  # La ruta al archivo .pem

# Lee el archivo .pem
with open(private_key_path, 'r') as key_file:
    private_key = key_file.read()

# Crear un JWT usando la Private Key
now = int(time.time())
payload = {
    'iat': now,  # Tiempo de emisión
    'exp': now + (10 * 60),  # El JWT expira en 10 minutos
    'iss': app_id  # El App ID
}

jwt_token = jwt.encode(payload, private_key, algorithm='RS256')

print("JWT generado:", jwt_token)

# URL para obtener las instalaciones de la GitHub App
url = 'https://api.github.com/app/installations'

headers = {
    'Authorization': f'Bearer {jwt_token}',  # Usa el JWT generado
    'Accept': 'application/vnd.github.v3+json'
}

# Realizar la solicitud GET para obtener las instalaciones
response = requests.get(url, headers=headers)

# Verificar si la solicitud fue exitosa
if response.status_code == 200:
    installations = response.json()
    if installations:
        # Si encontramos instalaciones, imprimimos el Installation ID
        installation_id = installations[0]['id']  # Usa el primer Installation ID encontrado
        print(f"Installation ID: {installation_id}")
    else:
        print("No se encontraron instalaciones para esta aplicación.")
else:
    # Si hay un error, imprimimos el código de error y el mensaje de la API
    print(f"Error al obtener las instalaciones: {response.status_code}")
    print("Respuesta de la API:", response.text)

# Usamos el Installation ID para obtener el Installation Token
url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'

# Realizar la solicitud POST para obtener el Installation Token
response = requests.post(url, headers=headers)

# Verificar si la solicitud fue exitosa
if response.status_code == 201:
    installation_token = response.json()['token']
    print("Installation Token:", installation_token)
else:
    print(f"Error al obtener el Installation Token: {response.status_code}")
    print(response.text)
