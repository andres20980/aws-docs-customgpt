# test_converter.py
import unittest
from src.converter import convertir_a_markdown

class TestConverter(unittest.TestCase):
    def test_convertir_a_markdown(self):
        """ Prueba que convertir_a_markdown convierte correctamente un HTML simple a Markdown. """
        html = '<h1>Encabezado</h1><p>Este es un párrafo.</p>'
        markdown = convertir_a_markdown(html)
        self.assertIn("# Encabezado", markdown, "El Markdown debe contener el encabezado convertido.")
        self.assertIn("Este es un párrafo.", markdown, "El Markdown debe contener el texto del párrafo.")

if __name__ == '__main__':
    unittest.main()
