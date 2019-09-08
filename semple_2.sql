--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.5
-- Dumped by pg_dump version 9.5.5

-- Started on 2019-09-07 23:55:18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12355)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2168 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 194 (class 1255 OID 25002)
-- Name: add_acc_na_nc(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_acc_na_nc() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
 
 INSERT INTO account (isin,date,acc_na,acc_nc) SELECT isin, trade_date,quantity*price,accrued_int FROM trade ORDER BY trade_id DESC LIMIT 1;
  
  END;$$;


ALTER FUNCTION public.add_acc_na_nc() OWNER TO postgres;

--
-- TOC entry 195 (class 1255 OID 25003)
-- Name: add_acc_nj(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_acc_nj() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
 
 INSERT INTO account (isin,date,acc_nj) SELECT isin, trade_date,quantity*price FROM trade ORDER BY trade_id DESC LIMIT 1;
  
  END;$$;


ALTER FUNCTION public.add_acc_nj() OWNER TO postgres;

--
-- TOC entry 196 (class 1255 OID 16692)
-- Name: add_trade(text, text, text, date, date, integer, numeric, numeric, text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_trade(text, text, text, date, date, integer, numeric, numeric, text, text, text, text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE
portfolio_name ALIAS FOR $1;
isin ALIAS FOR $2;
name ALIAS FOR $3;
trade_date ALIAS FOR $4;
settlement_date ALIAS FOR $5;
quantity ALIAS FOR $6;
price ALIAS FOR $7;
accrued_int ALIAS FOR $8;
counterparty ALIAS FOR $9;
side ALIAS FOR $10;
trader ALIAS FOR $11;
custody ALIAS FOR $12;

BEGIN
 
 INSERT INTO trade VALUES (DEFAULT,portfolio_name, isin ,name,trade_date,settlement_date,quantity,price,accrued_int,counterparty,side,trader,custody );
  
  END; $_$;


ALTER FUNCTION public.add_trade(text, text, text, date, date, integer, numeric, numeric, text, text, text, text) OWNER TO postgres;

--
-- TOC entry 197 (class 1255 OID 25005)
-- Name: revaluation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION revaluation() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
 
INSERT INTO account(isin,date,acc_ne,currency)
SELECT price_eod.isin, price_eod.date,average_price_currency.quantity*(to_number(price_eod.price,'999999D99999')-average_price_currency.price), average_price_currency.currency
FROM price_eod INNER JOIN average_price_currency ON (price_eod.isin=average_price_currency.isin);

END;$$;


ALTER FUNCTION public.revaluation() OWNER TO postgres;

--
-- TOC entry 210 (class 1255 OID 25004)
-- Name: selection(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION selection() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
 
 IF (SELECT type_instr FROM instrument WHERE isin IN (SELECT isin FROM trade ORDER BY trade_id DESC LIMIT 1))='bond' THEN
  PERFORM add_acc_na_nc();
  ELSE PERFORM add_acc_nj();
  END IF;
  END;$$;


ALTER FUNCTION public.selection() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 186 (class 1259 OID 16580)
-- Name: account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE account (
    block_id integer NOT NULL,
    isin character varying(30),
    date date,
    acc_na numeric(10,2),
    acc_nb numeric(10,2),
    acc_nc numeric(10,2),
    acc_nd numeric(10,2),
    acc_nt numeric(10,2),
    acc_ne numeric(10,2),
    acc_nk numeric(10,2),
    acc_nj numeric(10,2),
    currency character varying(10)
);


ALTER TABLE account OWNER TO postgres;

--
-- TOC entry 185 (class 1259 OID 16578)
-- Name: account_block_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE account_block_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE account_block_id_seq OWNER TO postgres;

--
-- TOC entry 2169 (class 0 OID 0)
-- Dependencies: 185
-- Name: account_block_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE account_block_id_seq OWNED BY account.block_id;


--
-- TOC entry 184 (class 1259 OID 16486)
-- Name: trade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE trade (
    trade_id integer NOT NULL,
    portfolio_name character varying(10) NOT NULL,
    isin character varying(30) NOT NULL,
    name character varying(30) NOT NULL,
    trade_date date NOT NULL,
    settlement_date date NOT NULL,
    quantity integer NOT NULL,
    price numeric(10,6) NOT NULL,
    accrued_int numeric(10,2) NOT NULL,
    counterparty character varying(30) NOT NULL,
    side character varying(10) NOT NULL,
    trader character varying(30) NOT NULL,
    custody character varying(30) NOT NULL
);


ALTER TABLE trade OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 16758)
-- Name: average_price; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW average_price AS
 SELECT trade.isin,
    sum(trade.quantity) AS quantity,
    (sum(((trade.quantity)::numeric * trade.price)) / (sum(trade.quantity))::numeric) AS price
   FROM trade
  GROUP BY trade.isin;


ALTER TABLE average_price OWNER TO postgres;

--
-- TOC entry 181 (class 1259 OID 16416)
-- Name: instrument; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE instrument (
    isin character varying(30) NOT NULL,
    coupon real NOT NULL,
    currency character varying(10) NOT NULL,
    type_instr character varying(10) NOT NULL,
    maturity date,
    rate_type character varying(10) NOT NULL,
    cusip character varying(30) NOT NULL,
    number_pmnts integer NOT NULL,
    name_instr character varying(30) NOT NULL,
    base character varying(10) NOT NULL,
    eq_number integer
);


ALTER TABLE instrument OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 25006)
-- Name: average_price_currency; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW average_price_currency AS
 SELECT average_price.isin,
    average_price.quantity,
    average_price.price,
    instrument.currency
   FROM (average_price
     JOIN instrument ON (((average_price.isin)::text = (instrument.isin)::text)));


ALTER TABLE average_price_currency OWNER TO postgres;

--
-- TOC entry 191 (class 1259 OID 25031)
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE exchange_rates (
    currency character varying(10),
    conversion_to_usd character varying(30),
    date date
);


ALTER TABLE exchange_rates OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 25042)
-- Name: export_xml; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW export_xml AS
 SELECT account.isin,
    account.acc_ne,
    account.currency,
    account.date,
    instrument.eq_number
   FROM (account
     JOIN instrument ON (((account.isin)::text = (instrument.isin)::text)))
  WHERE (account.date IN ( SELECT account_1.date
           FROM account account_1
          WHERE (account_1.acc_ne IN ( SELECT account_2.acc_ne
                   FROM account account_2
                  ORDER BY account_2.block_id DESC
                 LIMIT 1))));


ALTER TABLE export_xml OWNER TO postgres;

--
-- TOC entry 182 (class 1259 OID 16421)
-- Name: issuer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE issuer (
    eq_number integer NOT NULL,
    company_name character varying(30) NOT NULL,
    country character varying(30) NOT NULL,
    sector character varying(30) NOT NULL,
    reiting character varying(10)
);


ALTER TABLE issuer OWNER TO postgres;

--
-- TOC entry 188 (class 1259 OID 16784)
-- Name: price_eod; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE price_eod (
    isin character varying(30),
    date date,
    price character varying(30)
);


ALTER TABLE price_eod OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 25027)
-- Name: total_per_currency; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW total_per_currency AS
 SELECT average_price_currency.currency,
    sum(((average_price_currency.quantity)::numeric * average_price_currency.price)) AS total
   FROM average_price_currency
  GROUP BY average_price_currency.currency;


ALTER TABLE total_per_currency OWNER TO postgres;

--
-- TOC entry 193 (class 1259 OID 25050)
-- Name: total_investment; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW total_investment AS
 SELECT sum((total_per_currency.total * to_number((exchange_rates.conversion_to_usd)::text, '999999D99999'::text))) AS total
   FROM (total_per_currency
     JOIN exchange_rates ON (((total_per_currency.currency)::text = (exchange_rates.currency)::text)));


ALTER TABLE total_investment OWNER TO postgres;

--
-- TOC entry 183 (class 1259 OID 16484)
-- Name: trade_trade_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE trade_trade_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE trade_trade_id_seq OWNER TO postgres;

--
-- TOC entry 2170 (class 0 OID 0)
-- Dependencies: 183
-- Name: trade_trade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE trade_trade_id_seq OWNED BY trade.trade_id;


--
-- TOC entry 2029 (class 2604 OID 16583)
-- Name: block_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY account ALTER COLUMN block_id SET DEFAULT nextval('account_block_id_seq'::regclass);


--
-- TOC entry 2028 (class 2604 OID 16489)
-- Name: trade_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trade ALTER COLUMN trade_id SET DEFAULT nextval('trade_trade_id_seq'::regclass);


--
-- TOC entry 2038 (class 2606 OID 16585)
-- Name: account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_pkey PRIMARY KEY (block_id);


--
-- TOC entry 2031 (class 2606 OID 16420)
-- Name: instrument_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instrument
    ADD CONSTRAINT instrument_pkey PRIMARY KEY (isin);


--
-- TOC entry 2033 (class 2606 OID 16425)
-- Name: issuer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY issuer
    ADD CONSTRAINT issuer_pkey PRIMARY KEY (eq_number);


--
-- TOC entry 2035 (class 2606 OID 16491)
-- Name: trade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trade
    ADD CONSTRAINT trade_pkey PRIMARY KEY (trade_id);


--
-- TOC entry 2036 (class 1259 OID 25011)
-- Name: acc_ne; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX acc_ne ON account USING btree (isin, date, acc_ne, currency);


--
-- TOC entry 2041 (class 2606 OID 16586)
-- Name: account_isin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_isin_fkey FOREIGN KEY (isin) REFERENCES instrument(isin);


--
-- TOC entry 2039 (class 2606 OID 16446)
-- Name: instrument_eq_number_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY instrument
    ADD CONSTRAINT instrument_eq_number_fkey FOREIGN KEY (eq_number) REFERENCES issuer(eq_number);


--
-- TOC entry 2040 (class 2606 OID 16492)
-- Name: trade_isin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY trade
    ADD CONSTRAINT trade_isin_fkey FOREIGN KEY (isin) REFERENCES instrument(isin);


--
-- TOC entry 2167 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2019-09-07 23:55:18

--
-- PostgreSQL database dump complete
--

