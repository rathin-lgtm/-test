select type, count(*) as total_count
from {{ ref('silver_funds') }}
where life_cycle_status is not null and life_cycle_status = 'Investing'
group by 1
