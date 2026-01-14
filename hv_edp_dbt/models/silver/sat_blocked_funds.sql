with block_list as (
    select 
        *
    from {{ ref('block_list_fund') }}
)
 
select * from block_list
