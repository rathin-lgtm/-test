from typing import Self

from dagster import ConfigurableResource
from dagster_snowflake import SnowflakeResource
from pydantic import Field, ValidationInfo, field_validator, model_validator


class SnowflakeConfig(ConfigurableResource):
    account: str = Field(description="Snowflake account identifier")
    user: str = Field(description="Snowflake username")
    warehouse: str = Field(description="Snowflake warehouse")
    database: str = Field(description="Snowflake database")
    schema_bronze: str = Field(description="Snowflake schema bronze")
    role: str = Field(description="Snowflake role")
    private_key_path: str | None = Field(description="Snowflake private key path")
    private_key_password: str | None = Field(description="Snowflake private key passphrase")
    authenticator: str | None = Field(description="Snowflake authenticator")

    @field_validator("account", "user", "warehouse", "database", "schema_bronze", "role")
    @classmethod
    def validate_required_fields(cls, value: str, info: ValidationInfo) -> str:
        if not value or not value.strip():
            raise ValueError(f"Required field {info.field_name} cannot be empty")
        return value.strip()

    @model_validator(mode="after")
    def validate_authentication_method(self) -> Self:
        if not self.authenticator and not (self.private_key_path and self.private_key_password):
            raise ValueError(
                "Either 'authenticator' must be set OR both 'private_key_path' and "
                "'private_key_password' must be set for authentication"
            )
        return self

    @property
    def snowflake_resource(self) -> SnowflakeResource:
        return SnowflakeResource(
            account=self.account,
            user=self.user,
            private_key_path=self.private_key_path,
            private_key_password=self.private_key_password,
            authenticator=self.authenticator,
            warehouse=self.warehouse,
            database=self.database,
            schema=self.schema_bronze,
            role=self.role,
        )


class JobConfig(ConfigurableResource):
    full_reload: bool = Field(default=False, description="Whether to perform a full reload of data")
    use_shared_stage: bool = Field(
        default=False, description="Whether to use the shared stage (for personal_dev)"
    )
