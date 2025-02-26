# utils.py
import os

def guardar_markdown(markdown, category_path, filename):
    """ Guarda el contenido Markdown en un archivo dentro de una estructura de directorio basada en categorías. """
    full_path = os.path.join('data', category_path)
    os.makedirs(full_path, exist_ok=True)
    file_path = os.path.join(full_path, filename + '.md')
    with open(file_path, "w", encoding='utf-8') as file:
        file.write(markdown)


def generar_nombre_archivo(url):
    """ Genera un nombre de archivo seguro para guardar basado en la URL. """
    partes = url.strip().split('/')
    nombre_archivo = "_".join(partes[-3:])  # Esto puede ajustarse según la estructura de URL
    return nombre_archivo + '.md'