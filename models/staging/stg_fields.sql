select *
from {{ source('pipedrive', 'fields') }}
