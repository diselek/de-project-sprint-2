DROP TABLE IF EXISTS PUBLIC.shipping_country_rates;
DROP TABLE IF EXISTS PUBLIC.shipping_agreement;
DROP TABLE IF EXISTS PUBLIC.shipping_transfer;
DROP TABLE IF EXISTS PUBLIC.shipping_info;
DROP TABLE IF EXISTS PUBLIC.shipping_status;

-- create "shipping_country_rates"
CREATE TABLE public.shipping_country_rates(
  shipping_country_id SERIAL PRIMARY KEY,
  shipping_country TEXT,
  shipping_country_base_rate NUMERIC(2,2)
  );
CREATE INDEX shipping_country_rates_index ON public.shipping_country_rates(shipping_country_id);

-- create "shipping_agreement"
CREATE TABLE public.shipping_agreement(
  	agreement_id SERIAL PRIMARY KEY,
	agreement_number text,
	agreement_rate numeric(2,2),
	agreement_commission numeric(2,2)
  );
CREATE INDEX shipping_agreement_index ON public.shipping_agreement(agreement_id);

-- create "shipping_transfer"
CREATE TABLE public.shipping_transfer(
  	transfer_type_id SERIAL PRIMARY KEY,
	transfer_type TEXT,
	transfer_model TEXT,
	shipping_transfer_rate NUMERIC(4,3)
  );
CREATE INDEX shipping_transfer_index ON public.shipping_transfer(transfer_type_id);

-- create shipping_info
create table public.shipping_info (
	shipping_id INT,
	vendor_id INT,
	payment_amount NUMERIC(7,2),
	shipping_plan_datetime TIMESTAMP,
	transfer_type_id INT,
	shipping_country_id INT,
	agreement_id int,
	primary key (shipping_id),
	FOREIGN KEY  (transfer_type_id) REFERENCES shipping_transfer (transfer_type_id) ON UPDATE cascade,
	FOREIGN KEY (shipping_country_id) REFERENCES public.shipping_country_rates (shipping_country_id) ON UPDATE cascade,
	FOREIGN KEY (agreement_id) REFERENCES public.shipping_agreement (agreement_id) ON UPDATE cascade
);

-- create shipping_status
create table public.shipping_status (
	shipping_id int UNIQUE,
	status text,
	state text,
	shipping_start_fact_datetime timestamp,
	shipping_end_fact_datetime timestamp,
	primary key (shipping_id)
);
