--shipping_datamart
CREATE or REPLACE VIEW public.shipping_datamart AS
with ship as (
	select distinct 
			ss.shipping_id,
			ss.state,
			ss.shipping_start_fact_datetime::timestamp,
			ss.shipping_end_fact_datetime::timestamp,
			s.shipping_plan_datetime,
			extract('day' from ss.shipping_end_fact_datetime - ss.shipping_start_fact_datetime) as full_day_at_shipping,
	case when shipping_end_fact_datetime > shipping_plan_datetime then 1 else 0
				end is_delay,
	case when ss.state = 'finished' then 1 else 0
					end is_shipping_finish 
	from public.shipping_status ss
	join public.shipping s on ss.shipping_id = s.shippingid
	) 
  	select distinct
		  si.shipping_id, 
		  si.vendor_id, 
		  st.transfer_type,
		  ship.full_day_at_shipping,
		  ship.is_delay,
		  ship.is_shipping_finish,
		  si.payment_amount,
		  payment_amount * (st.shipping_transfer_rate + scr.shipping_country_base_rate + sa.agreement_rate) as vat,
		  payment_amount * sa.agreement_commission as profit,
		  case when is_delay = 1 then
		            (extract('day' from ship.shipping_end_fact_datetime-ship.shipping_plan_datetime))
		  			else 0 end delay_day_at_shipping
		  from public.shipping_info si
		  join public.shipping_transfer st on si.transfer_type_id = st.transfer_type_id
		  join public.shipping_country_rates scr on si.shipping_country_id  = scr.shipping_country_id
		  join public.shipping_agreement sa on si.agreement_id = sa.agreement_id
		  join ship on si.shipping_id = ship.shipping_id;

select * from public.shipping_datamart;
