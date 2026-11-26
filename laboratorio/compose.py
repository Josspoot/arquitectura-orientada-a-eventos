# Recorta las capturas de Terminal y arma una figura por ejercicio.
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

SRC = Path(sys.argv[1])
OUT = Path(sys.argv[2])
OUT.mkdir(exist_ok=True)
BG = (30, 30, 30)
BAR = (52, 62, 76)
FONT = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 26)


def crop(name):
    im = Image.open(SRC / f"{name}.png").convert("RGB")
    im = im.crop((0, 90, im.width, im.height))  # quita la barra de pestañas
    bg = Image.new("RGB", im.size, im.getpixel((5, im.height - 5)))
    box = ImageChops.difference(im, bg).convert("L").point(lambda v: 255 if v > 40 else 0).getbbox()
    l, t, r, b = box
    return im.crop((0, max(t - 20, 0), min(r + 30, im.width), min(b + 20, im.height)))


def panel(name, label, width):
    im = crop(name)
    canvas = Image.new("RGB", (width, im.height + 48), BG)
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 0, width, 46), fill=BAR)
    d.text((16, 9), label, font=FONT, fill=(225, 232, 240))
    if im.width > width:  # se escala para que no se corte el texto
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
        canvas = canvas.resize((width, im.height + 48))
        d = ImageDraw.Draw(canvas)
        d.rectangle((0, 0, width, 46), fill=BAR)
        d.text((16, 9), label, font=FONT, fill=(225, 232, 240))
    canvas.paste(im, (0, 48))
    return canvas


def figure(out, rows, width=2400, gap=12):
    """rows: lista de filas; cada fila es una lista de (captura, etiqueta)."""
    built = []
    for row in rows:
        w = (width - gap * (len(row) - 1)) // len(row)
        panels = [panel(n, lab, w) for n, lab in row]
        h = max(p.height for p in panels)
        line = Image.new("RGB", (width, h), BG)
        for i, p in enumerate(panels):
            line.paste(p, (i * (w + gap), 0))
        built.append(line)
    total = sum(b.height for b in built) + gap * (len(built) - 1)
    fig = Image.new("RGB", (width, total), (255, 255, 255))
    y = 0
    for b in built:
        fig.paste(b, (0, y))
        y += b.height + gap
    fig.save(OUT / f"{out}.png", optimize=True)
    print(out, fig.size)


figure("fig_ej1", [
    [("ej1_api", "Terminal 1 · ./eda api-server")],
    [("ej1_c1", "Terminal 2 · consumidor A"), ("ej1_c2", "Terminal 3 · consumidor B")],
    [("ej1_curl", "Terminal 4 · productor (curl)")],
])
figure("fig_ej2", [
    [("ej2_curl", "Productor: sin suscriptores y se publica el pedido 125")],
    [("ej2_c1", "Consumidor A reiniciado: el pedido 125 no llega")],
])
figure("fig_ej3", [
    [("ej3_np", "nuevoPedido"), ("ej3_dev", "devolucion")],
    [("ej3_cs", "consultaStock")],
    [("ej3_curl", "Productor (curl)")],
])
figure("fig_ej3b", [
    [("ej3b_inv_p", "Inventario · pedido.creado"), ("ej3b_fin_p", "Finanzas · pedido.creado")],
    [("ej3b_aten_p", "Atención · pedido.creado"), ("ej3b_inv_d", "Inventario · devolucion.registrada")],
    [("ej3b_fin_d", "Finanzas · devolucion.registrada")],
    [("ej3b_curl", "Productor (curl)")],
])
figure("fig_ej4", [
    [("ej4_master", "Master · ./eda consumer -d --master"), ("ej4_w2", "Worker reiniciado · ./eda consumer -d")],
    [("ej4_curl", "Productor (curl) y Redis")],
])
