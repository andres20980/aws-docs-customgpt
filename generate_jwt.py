import jwt
import time

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