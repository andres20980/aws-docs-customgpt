# scraper.py
import requests
from bs4 import BeautifulSoup

def descargar_pagina(url):
    """ Descarga el contenido HTML de una página web dada una URL. """
    try:
        respuesta = requests.get(url)
        respuesta.raise_for_status()
        return respuesta.text
    except requests.RequestException as e:
        print(f"Error al descargar la página: {e}")
        return None

def explorar_urls(base_url, html):
    """ Extrae y devuelve todas las URLs relevantes encontradas en una página HTML. """
    soup = BeautifulSoup(html, 'html.parser')
    return [base_url + link.get('href') for link in soup.find_all('a', href=True) if link.get('href').startswith('/')]