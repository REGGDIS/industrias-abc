import re
from dataclasses import dataclass


VALID_IDENTIFIER = re.compile(r"^[a-z0-9_]+$")


@dataclass(frozen=True)
class StagingTableNames:
    source: str
    entity: str

    @property
    def raw(self) -> str:
        return f"stg_{self.source}_{self.entity}_raw"

    @property
    def clean(self) -> str:
        return f"stg_{self.source}_{self.entity}_clean"


def _normalize_identifier(value: str, field_name: str) -> str:
    value = value.strip().lower()

    if not value:
        raise ValueError(
            f"El nombre de {field_name} no puede estar vacío."
        )

    if not VALID_IDENTIFIER.fullmatch(value):
        raise ValueError(
            f"El nombre de {field_name} contiene caracteres no permitidos: "
            f"'{value}'."
        )

    return value


def get_staging_table_names(
    source: str,
    entity: str,
) -> StagingTableNames:
    return StagingTableNames(
        source=_normalize_identifier(source, "la fuente"),
        entity=_normalize_identifier(entity, "la entidad"),
    )
