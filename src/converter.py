# converter.py
import html2text

def convertir_a_markdown(html):
    """ Convierte un contenido HTML en un string de Markdown. """
    convertidor = html2text.HTML2Text()
    convertidor.ignore_links = False
    convertidor.ignore_images = True
    return convertidor.handle(html)