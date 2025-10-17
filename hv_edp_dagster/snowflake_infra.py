import re

from pydantic import BaseModel, field_validator

from hv_edp_dagster.constants import IS_LOCAL_ENVIRONMENT, SHARED_DEV_BRONZE_PATH


def validate_snowflake_identifier(name: str) -> str:
    """
    Validate that a name is a valid Snowflake identifier.

    Rules:
    - Must start with a letter (A-Z, a-z) or underscore (_)
    - Can only contain letters, digits (0-9), underscores (_), and dollar signs ($)
    - Cannot be empty
    """
    if not name:
        raise ValueError("Name cannot be empty")

    if not re.match(r"^[A-Za-z_][A-Za-z0-9_$]*$", name):
        raise ValueError(
            f"Invalid identifier '{name}': must start with letter or underscore "
            "and contain only letters, digits, underscores, and dollar signs"
        )

    return name


class Stage(BaseModel):
    name: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        return validate_snowflake_identifier(v)

    def create_sql(self, db: str, schema: str) -> str:
        return (
            f"CREATE STAGE IF NOT EXISTS {db}.{schema}.{self.name} DIRECTORY = ( ENABLE = TRUE );"
        )


DATA_LANDING_STAGE = Stage(name="landing")


class FileFormat(BaseModel):
    name: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        return validate_snowflake_identifier(v)

    def create_sql(self) -> str:
        return f"""CREATE OR REPLACE FILE FORMAT {self.name} TYPE = CSV,
            PARSE_HEADER = True, FIELD_DELIMITER = ",",
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            """


CSV_FILE_FORMAT = FileFormat(name="csv_file")


class Table(BaseModel):
    name: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        return validate_snowflake_identifier(v)

    def create_sql(
        self,
        db: str,
        schema: str,
        file_format: FileFormat = CSV_FILE_FORMAT,
        use_shared_stage: bool = True,
    ) -> str:
        if IS_LOCAL_ENVIRONMENT and use_shared_stage:
            inferred_data_location = SHARED_DEV_BRONZE_PATH
        else:
            inferred_data_location = f"{db}.{schema}"
        return f"""CREATE TABLE IF NOT EXISTS {db}.{schema}.{self.name}
                        USING TEMPLATE (
                            SELECT ARRAY_CAT(
                               ARRAY_AGG(
                                    OBJECT_CONSTRUCT(
                                        'COLUMN_NAME', UPPER(COLUMN_NAME),
                                        'TYPE', 'STRING',
                                        'NULLABLE', NULLABLE,
                                        'EXPRESSION', EXPRESSION,
                                        'FILENAMES', FILENAMES,
                                        'ORDER_ID', ORDER_ID)),
                               ARRAY_CONSTRUCT(
                                 OBJECT_CONSTRUCT('COLUMN_NAME','INGEST_TIME',
                                                  'TYPE','TIMESTAMP_LTZ',
                                                  'NULLABLE', True),
                                 OBJECT_CONSTRUCT('COLUMN_NAME','FILE_NAME',
                                                  'TYPE','STRING',
                                                  'NULLABLE', True),
                                 OBJECT_CONSTRUCT('COLUMN_NAME', 'FILE_DATE',
                                                  'TYPE','DATE',
                                                  'NULLABLE', True)
                               )
                             )
                  FROM TABLE(
                    INFER_SCHEMA(
                    LOCATION => '@{inferred_data_location}.{DATA_LANDING_STAGE.name}/{self.name}/',
                    FILE_FORMAT => '{file_format.name}',
                    MAX_FILE_COUNT => 10
                    )
                  )
                );"""


class BronzeTables:
    dim_funds = Table(name="DIM_FUNDS")
    fact_investor_transactions_monthly = Table(name="FACT_INVESTOR_TRANSACTIONS_MONTHLY")
    fact_investor_transactions = Table(name="FACT_INVESTOR_TRANSACTIONS")
    fact_investor_transactions_fund_hierarchy = Table(
        name="FACT_INVESTOR_TRANSACTIONS_FUND_HIERARCHY"
    )
    fact_investor_transactions_fund_hierarchy_monthly = Table(
        name="FACT_INVESTOR_TRANSACTIONS_FUND_HIERARCHY_MONTHLY"
    )


ALL_TABLES = [value for value in BronzeTables.__dict__.values() if isinstance(value, Table)]
