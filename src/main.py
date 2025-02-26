# main.py
from scraper import descargar_pagina, explorar_urls
from converter import convertir_a_markdown
from utils import guardar_markdown, generar_nombre_archivo

def main():
    base_url = "https://docs.aws.amazon.com"
    start_url = base_url + "/index.html"
    html = descargar_pagina(start_url)
    if html:
        urls = explorar_urls(base_url, html)
        for url in urls:
            html_pagina = descargar_pagina(url)
            if html_pagina:
                markdown = convertir_a_markdown(html_pagina)
                filename = 'data/' + generar_nombre_archivo(url)
                guardar_markdown(markdown, filename)

if __name__ == '__main__':
    main()