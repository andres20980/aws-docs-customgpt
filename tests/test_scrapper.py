# test_scraper.py
import unittest
from src.scraper import descargar_pagina, explorar_urls

class TestScraper(unittest.TestCase):
    def test_descargar_pagina(self):
        """ Prueba que la función descargar_pagina retorna el contenido HTML correcto para una URL válida. """
        url = "https://www.example.com"
        contenido = descargar_pagina(url)
        self.assertIn("<html", contenido, "El contenido descargado debe incluir una etiqueta <html>.")

    def test_explorar_urls(self):
        """ Prueba que la función explorar_urls extrae correctamente las URLs de un HTML de ejemplo. """
        html = '<html><body><a href="/page1.html">Link 1</a><a href="/page2.html">Link 2</a></body></html>'
        base_url = "https://www.example.com"
        urls = explorar_urls(base_url, html)
        self.assertEqual(urls, ["https://www.example.com/page1.html", "https://www.example.com/page2.html"], "Las URLs extraídas deben coincidir con las esperadas.")

if __name__ == '__main__':
    unittest.main()
