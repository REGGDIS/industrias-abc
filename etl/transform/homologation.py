from dataclasses import dataclass

from etl.transform.business_keys import normalize_business_code


@dataclass(frozen=True)
class HomologationResult:
    source_code: str | None
    target_code: str | None
    source_normalized: str | None
    target_normalized: str | None
    status: str


def compare_business_codes(
    source_code: str | None,
    target_code: str | None,
) -> HomologationResult:
    source_normalized = normalize_business_code(source_code)
    target_normalized = normalize_business_code(target_code)

    if source_normalized is None or target_normalized is None:
        status = "REVIEW"
    elif source_normalized == target_normalized:
        status = "MATCH"
    else:
        status = "NO_MATCH"

    return HomologationResult(
        source_code=source_code,
        target_code=target_code,
        source_normalized=source_normalized,
        target_normalized=target_normalized,
        status=status,
    )
