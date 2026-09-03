def normalize_business_code(value: str | None) -> str | None:
    if value is None:
        return None

    normalized = value.strip().upper()

    if normalized == "":
        return None

    return normalized
