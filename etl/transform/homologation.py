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


@dataclass(frozen=True)
class BusinessEntityRef:
    source: str
    entity: str
    local_id: int | str
    business_code: str | None
    display_name: str | None = None

    @property
    def normalized_code(self) -> str | None:
        return normalize_business_code(self.business_code)


@dataclass(frozen=True)
class EntityHomologationResult:
    source: BusinessEntityRef
    target: BusinessEntityRef
    source_normalized: str | None
    target_normalized: str | None
    status: str


def compare_entity_refs(
    source: BusinessEntityRef,
    target: BusinessEntityRef,
) -> EntityHomologationResult:
    source_normalized = source.normalized_code
    target_normalized = target.normalized_code

    if source.entity != target.entity:
        status = "REVIEW"
    else:
        comparison = compare_business_codes(
            source.business_code,
            target.business_code,
        )
        status = comparison.status

    return EntityHomologationResult(
        source=source,
        target=target,
        source_normalized=source_normalized,
        target_normalized=target_normalized,
        status=status,
    )


def homologate_entity_collections(
    sources: list[BusinessEntityRef],
    targets: list[BusinessEntityRef],
) -> list[EntityHomologationResult]:
    results: list[EntityHomologationResult] = []

    for source in sources:
        source_matches = [
            target
            for target in targets
            if source.normalized_code is not None
            and target.normalized_code == source.normalized_code
        ]

        if len(source_matches) == 1:
            results.append(
                compare_entity_refs(
                    source,
                    source_matches[0],
                )
            )
            continue

        if len(source_matches) > 1:
            for target in source_matches:
                comparison = compare_entity_refs(
                    source,
                    target,
                )

                results.append(
                    EntityHomologationResult(
                        source=comparison.source,
                        target=comparison.target,
                        source_normalized=comparison.source_normalized,
                        target_normalized=comparison.target_normalized,
                        status="REVIEW",
                    )
                )

            continue

        for target in targets:
            if source.entity == target.entity:
                results.append(
                    compare_entity_refs(
                        source,
                        target,
                    )
                )

    return results


@dataclass(frozen=True)
class HomologationSummary:
    total: int
    match: int
    no_match: int
    review: int


def summarize_homologation_results(
    results: list[EntityHomologationResult],
) -> HomologationSummary:
    return HomologationSummary(
        total=len(results),
        match=sum(result.status == "MATCH" for result in results),
        no_match=sum(result.status == "NO_MATCH" for result in results),
        review=sum(result.status == "REVIEW" for result in results),
    )
