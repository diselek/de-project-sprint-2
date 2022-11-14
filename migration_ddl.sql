-- add info to shipping_country_rates
CREATE SEQUENCE shipping_country_seq START 1;
insert into public.shipping_country_rates
            (shipping_country_id,shipping_country,shipping_country_base_rate)
select
  nextval('shipping_country_seq')::int AS shipping_country_id,
  shipping_country,
  shipping_country_base_rate
  from (
        select distinct shipping_country, shipping_country_base_rate
				from public.shipping
        ) as s;
DROP SEQUENCE shipping_country_seq;

-- add info to shipping_agreement
insert into public.shipping_agreement
            (agreement_id,agreement_number,agreement_rate,agreement_commission)
    select distinct
            descriptions[1]::int as agreement_id,
            descriptions[2] as agreement_number,
            descriptions[3]::numeric(2,2) as agreement_rate,
            descriptions[4]::numeric(2,2) as agreement_commission
    from (
          select
          regexp_split_to_array(vendor_agreement_description, E'\\:+') as descriptions
          from public.shipping
          ) as s;

-- add info to shipping_transfer
CREATE SEQUENCE transfer_type_id_seq START 1;
insert into public.shipping_transfer 
        (transfer_type_id, transfer_type, transfer_model, shipping_transfer_rate)
      select distinct
              nextval('transfer_type_id_seq')::int AS transfer_type_id,
              transfer_type,
              transfer_model,
              shipping_transfer_rate
      from
      (
        select distinct
                shipping_transfer_rate,
                (regexp_split_to_array(shipping_transfer_description, E'\\:+'))[1] as transfer_type,
                (regexp_split_to_array(shipping_transfer_description, E'\\:+'))[2] as transfer_model
                from public.shipping
      ) as s;
drop sequence transfer_type_id_seq;

-- add info to shipping_info
insert into public.shipping_info 
            (shipping_id, vendor_id, payment_amount, shipping_plan_datetime, transfer_type_id, shipping_country_id, agreement_id)
with table_1 as (
                select
                  transfer_type_id, 
                  concat(transfer_type,':',transfer_model) as shipping_transfer_description,
                  shipping_transfer_rate
                from 
                  public.shipping_transfer )
      select distinct 
        s.shippingid, 
        s.vendorid,
        s.payment_amount,
        s.shipping_plan_datetime,
        table_1.transfer_type_id,
        scr.shipping_country_id,
        (regexp_split_to_array(s.vendor_agreement_description , E'\\:+'))[1]::int as agreement_id
      from 
        public.shipping s 
        left join table_1
        on (s.shipping_transfer_description = table_1.shipping_transfer_description 
            and s.shipping_transfer_rate = table_1.shipping_transfer_rate)
        left join public.shipping_country_rates scr on s.shipping_country_base_rate = scr.shipping_country_base_rate 
;

-- add info to shipping_status 
insert into public.shipping_status 
            (shipping_id, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
WITH max_order AS
      (SELECT shippingid,
              MAX(state_datetime) AS max_state_datetime
       FROM shipping
       GROUP BY 1
       ORDER BY 1),
     booked AS
      (SELECT shippingid,
              state,
              state_datetime AS shipping_start_fact_datetime
       FROM shipping s
       WHERE state = 'booked'
       ORDER BY 1 ASC, state_datetime ASC),
     recieved AS
      (SELECT shippingid,
              state,
              state_datetime AS shipping_end_fact_datetime
       FROM shipping s
       WHERE state = 'recieved'
       ORDER BY 1 ASC, 3 ASC)
SELECT s.shippingid,
       s.status,
       s.state,
       b.shipping_start_fact_datetime,
       r.shipping_end_fact_datetime
FROM shipping s
LEFT JOIN max_order mo ON s.shippingid = mo.shippingid
LEFT JOIN booked b ON s.shippingid = b.shippingid
LEFT JOIN recieved r ON s.shippingid = r.shippingid
WHERE s.state_datetime = mo.max_state_datetime
ORDER BY 1;
