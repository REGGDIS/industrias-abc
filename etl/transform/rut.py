def normalize_rut(rut: str | None) -> str | None:
    if rut is None:
        return None

    clean = rut.strip().upper().replace(".", "").replace("-", "")

    if len(clean) < 2:
        return rut.strip().upper()

    body = clean[:-1]
    dv = clean[-1]

    return f"{body}-{dv}"
