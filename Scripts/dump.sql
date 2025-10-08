--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

-- Started on 2025-10-08 17:32:32

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5100 (class 1262 OID 16420)
-- Name: RailwayPassengerTransportation; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "RailwayPassengerTransportation" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Russian_Russia.1251';


ALTER DATABASE "RailwayPassengerTransportation" OWNER TO postgres;

\connect "RailwayPassengerTransportation"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5101 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 302 (class 1255 OID 16841)
-- Name: add_new_card(character varying, character varying, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_new_card(IN login character varying, IN number character varying, IN before date)
    LANGUAGE plpgsql
    AS $$
declare id int;
	begin
		if(select логин from пользователи where логин=login) is not null
		then
		if (select max(код) from карты) is not null
		then select max(код) from карты into id;
		else id:=0;
		end if;
		insert into карты (код, номер, до) values(id+1, pgp_sym_encrypt(number, (select ключ from ключи where код=1)), before);
		insert into карты_пользователей(код_пользователя, код_карты) values ((select код from пользователи where логин=login), id+1);
		else raise notice 'Некорректный логин';
	end if;
	END;
$$;


ALTER PROCEDURE public.add_new_card(IN login character varying, IN number character varying, IN before date) OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 16758)
-- Name: add_new_flight(character varying, character varying, character varying, integer, character varying, character varying, integer, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_new_flight(IN "_пункт_отправления" character varying, IN "_пункт_назначения" character varying, IN "время" character varying, IN "код_компании" integer, IN "_номер_поезда" character varying, IN "тип_поезда" character varying, IN "количество_вагонов" integer, IN "дата_рейса" date)
    LANGUAGE plpgsql
    AS $$
declare код_состава_н int;

declare код_рейса int;

begin
select
	max(код_состава)
from
	составы
into
	код_состава_н;

select
	max(код)
from
	рейсы
into
	код_рейса;

insert
	into
	public.составы (код_состава,
	номер_поезда,
	тип_поезда,
	код_компании_отправителя)
values (код_состава_н + 1,
_номер_поезда,
тип_поезда,
код_компании);

insert
	into
	public.рейсы (код,
	пункт_отправления,
	пункт_назначения,
	время_в_пути,
	код_состава,
	дата)
values (код_рейса + 1,
_пункт_отправления,
_пункт_назначения,
время,
код_состава_н + 1,
дата_рейса);
end;

$$;


ALTER PROCEDURE public.add_new_flight(IN "_пункт_отправления" character varying, IN "_пункт_назначения" character varying, IN "время" character varying, IN "код_компании" integer, IN "_номер_поезда" character varying, IN "тип_поезда" character varying, IN "количество_вагонов" integer, IN "дата_рейса" date) OWNER TO postgres;

--
-- TOC entry 295 (class 1255 OID 16814)
-- Name: add_new_user(character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.add_new_user(IN login character varying, IN email character varying, IN password character varying)
    LANGUAGE plpgsql
    AS $$
declare salt text;
declare id int;
	BEGIN
		salt:=gen_salt('bf');
		select max(код) from пользователи into id;
		insert into пользователи (код, логин, эл_почта, пароль, роль, соль) values (id+1, login, email, crypt(password, salt), 'П', salt);
	END;
$$;


ALTER PROCEDURE public.add_new_user(IN login character varying, IN email character varying, IN password character varying) OWNER TO postgres;

--
-- TOC entry 304 (class 1255 OID 25031)
-- Name: buy_ticket(integer, integer, date); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.buy_ticket(IN ticket_code integer, IN passenger_code integer, IN buy_date date)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		insert into покупка_билетов(код, код_билета, код_пассажира, дата_бронирования, дата_покупки) values((select max(код) from покупка_билетов)+1, ticket_code, passenger_code, null, buy_date);
	END;
$$;


ALTER PROCEDURE public.buy_ticket(IN ticket_code integer, IN passenger_code integer, IN buy_date date) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16748)
-- Name: cancel_ticket_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cancel_ticket_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
update
	public.билеты
set
	статус = 'Не продан'
where
	код = old.код_билета;

return old;
end;

$$;


ALTER FUNCTION public.cancel_ticket_status() OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 16813)
-- Name: check_credentials(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_credentials(login_input text, password_input text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    hashed_password text;
BEGIN
    SELECT hash_password(password_input) INTO hashed_password;
    
    RETURN EXISTS (
        SELECT 1 
        FROM "пользователи"
        WHERE "логин" = login_input 
        AND "пароль" = hashed_password
    );
END;
$$;


ALTER FUNCTION public.check_credentials(login_input text, password_input text) OWNER TO postgres;

--
-- TOC entry 299 (class 1255 OID 16815)
-- Name: check_user(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user(login character varying, password character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare salt text;
	begin
		if (select логин from пользователи where логин=login) is not null
		then select соль from пользователи where логин=login into salt;
		return (select пароль from пользователи where логин=login)=crypt(password, salt);
		end if;
	return false;
	END;
$$;


ALTER FUNCTION public.check_user(login character varying, password character varying) OWNER TO postgres;

--
-- TOC entry 298 (class 1255 OID 16830)
-- Name: get_card(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_card(login character varying) RETURNS TABLE("номер" character varying, "срок_действия" date)
    LANGUAGE plpgsql
    AS $$
	begin
		if (select логин from пользователи where логин=login) is not null
		then return query 
		select pgp_sym_decrypt(к.номер::bytea, (select ключ from ключи where код=1))::varchar(19), к.до from карты к join карты_пользователей кп on к.код=кп.код_карты join
		пользователи п on п.код=кп.код_пользователя where п.логин = login;
		end if;
	END;
$$;


ALTER FUNCTION public.get_card(login character varying) OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 16745)
-- Name: get_cost(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_cost("код_билета" integer, "код_категории_пассажира" integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	begin
		return (
select
	(б.цена-(к.скидка / 100.0 * б.цена))
from
	билеты б,
	категории_пассажиров к
where
	б.код = код_билета
	and к.код_категории = код_категории_пассажира);
end;

$$;


ALTER FUNCTION public.get_cost("код_билета" integer, "код_категории_пассажира" integer) OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 16756)
-- Name: get_free_seats(character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_free_seats("_номер_вагона" character) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare count_seats int default 0;
	begin

select
	count(*)
into
	count_seats
from
	public.места
where
	номер_вагона = _номер_вагона
	and код not in (
	select
		код_места
	from
		public.билеты
	where
		lower(статус)= 'продан');

return count_seats;
end;

$$;


ALTER FUNCTION public.get_free_seats("_номер_вагона" character) OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 16740)
-- Name: get_routes(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_routes("_код_рейса" integer) RETURNS TABLE("станция" character varying, "порядковый_номер" integer, "время_прибытия" time without time zone, "время_отправления" time without time zone)
    LANGUAGE plpgsql
    AS $$
	begin
		return query
select
	с.название,
	о.порядковый_номер,
	о.время_прибытия,
	о.время_отправления
from
	остановки_в_рейсах о
join
		станции с on
	о.код_станции = с.код
where
	о.код_рейса = _код_рейса
order by
	о.порядковый_номер;
end;

$$;


ALTER FUNCTION public.get_routes("_код_рейса" integer) OWNER TO postgres;

--
-- TOC entry 303 (class 1255 OID 25006)
-- Name: get_tickets(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tickets("рейс" integer) RETURNS TABLE("код" integer, "вагон" character, "номер_места" integer, "тип_места" character varying, "цена" numeric)
    LANGUAGE plpgsql
    AS $$
	begin
		return query
select
	б.код,
	м.номер_вагона,
	м.номер_места,
	м.тип_места,
	б.цена
from
	билеты б
join места м on
	б.код_места = м.код
where
	б.код_рейса = рейс
	and lower(б.статус) = 'не продан';
end;

$$;


ALTER FUNCTION public.get_tickets("рейс" integer) OWNER TO postgres;

--
-- TOC entry 300 (class 1255 OID 16723)
-- Name: select_flights(text, text, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.select_flights("_пункт_отправления" text, "_пункт_назначения" text, "_дата" date) RETURNS TABLE("код" integer, "пункт_отправления" character varying, "пункт_назначения" character varying, "время_отправления" time without time zone, "время_прибытия" time without time zone, "время_в_пути" character varying, "номер_поезда" character varying, "дата" date, "тип_поезда" character varying, "компания" character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return QUERY
select
	р.код,
	р.пункт_отправления,
	р.пункт_назначения,
	(
	select
		о.время_отправления
	from
		остановки_в_рейсах о
	where
		р.код = о.код_рейса
		and о.порядковый_номер = 1),
	(
	select
		о.время_прибытия
	from
		остановки_в_рейсах о
	where
		р.код = о.код_рейса
		and о.порядковый_номер = (
		select
			max(порядковый_номер)
		from
			остановки_в_рейсах
		where
			р.код = код_рейса)),
		р.время_в_пути,
		с.номер_поезда,
		р.дата,
		с.тип_поезда,
		к.название_компании
from
		рейсы р
join составы с on
		р.код_состава = с.код_состава
join компании_отправители к on
		с.код_компании_отправителя = к.код_компании
where
		р.пункт_отправления = _пункт_отправления
	and р.пункт_назначения = _пункт_назначения
	and р.дата = _дата;
end;

$$;


ALTER FUNCTION public.select_flights("_пункт_отправления" text, "_пункт_назначения" text, "_дата" date) OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 16816)
-- Name: update_password(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.update_password(IN login character varying, IN new_password character varying)
    LANGUAGE plpgsql
    AS $$
declare new_salt text;
	begin
		new_salt=gen_salt('bf');
	if (select логин from пользователи where логин=login) is not null 
		then update пользователи set пароль=crypt(new_password, new_salt), соль=new_salt where логин=login;
	else raise notice 'Указанный логин не существует';
end if;
	END;
$$;


ALTER PROCEDURE public.update_password(IN login character varying, IN new_password character varying) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 16746)
-- Name: update_ticket_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_ticket_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
update
	билеты
set
	статус = 'Продан'
where
	new.код_билета = код ;

return new;
end;

$$;


ALTER FUNCTION public.update_ticket_status() OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 16751)
-- Name: update_wagon_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_wagon_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	begin
		if tg_op = 'INSERT' then
update
	public.вагоны
set
	в_составе = true
where
	номер_вагона = new.код_вагона;

elseif tg_op = 'DELETE' then
update
	public.вагоны
set
	в_составе = false
where
	номер_вагона = old.код_вагона;
end if;

return new;
end;

$$;


ALTER FUNCTION public.update_wagon_status() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16421)
-- Name: билеты; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."билеты" (
    "код" integer NOT NULL,
    "код_рейса" integer NOT NULL,
    "цена" numeric(8,2) NOT NULL,
    "код_места" integer NOT NULL,
    "статус" character varying(45) NOT NULL
);


ALTER TABLE public."билеты" OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16424)
-- Name: вагоны; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."вагоны" (
    "номер_вагона" character(12) NOT NULL,
    "код_типа_вагона" integer NOT NULL,
    "в_ремонте" boolean,
    "в_составе" boolean
);


ALTER TABLE public."вагоны" OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16427)
-- Name: вагоны_в_составах; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."вагоны_в_составах" (
    "код_вагона" character(12) NOT NULL,
    "код_состава" integer NOT NULL
);


ALTER TABLE public."вагоны_в_составах" OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16430)
-- Name: должности; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."должности" (
    "код" integer NOT NULL,
    "наименование_должности" character varying(60) NOT NULL,
    "зарплата" numeric(8,2),
    "обязанности" character varying(600),
    "требования" character varying(600)
);


ALTER TABLE public."должности" OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16481)
-- Name: карты; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."карты" (
    "код" integer NOT NULL,
    "номер" text NOT NULL,
    "до" date NOT NULL
);


ALTER TABLE public."карты" OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16546)
-- Name: карты_пользователей; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."карты_пользователей" (
    "код_пользователя" integer NOT NULL,
    "код_карты" integer NOT NULL
);


ALTER TABLE public."карты_пользователей" OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16433)
-- Name: категории_пассажиров; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."категории_пассажиров" (
    "код_категории" integer NOT NULL,
    "название_категории" character varying(45) NOT NULL,
    "скидка" integer
);


ALTER TABLE public."категории_пассажиров" OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16818)
-- Name: ключи; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ключи" (
    "код" integer NOT NULL,
    "ключ" text NOT NULL
);


ALTER TABLE public."ключи" OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16436)
-- Name: компании_отправители; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."компании_отправители" (
    "код_компании" integer NOT NULL,
    "название_компании" character varying(45) NOT NULL,
    "адрес" character varying(200),
    "телефон" character varying(20),
    "электронная_почта" character varying(340),
    "сайт" character varying(100)
);


ALTER TABLE public."компании_отправители" OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16439)
-- Name: медицинские_осмотры; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."медицинские_осмотры" (
    "код_осмотра" integer NOT NULL,
    "место_осмотра" character varying(80) NOT NULL,
    "дата_проведения" date NOT NULL,
    "результаты" character varying(200)
);


ALTER TABLE public."медицинские_осмотры" OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16442)
-- Name: места; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."места" (
    "код" integer NOT NULL,
    "номер_вагона" character(12) NOT NULL,
    "номер_места" integer NOT NULL,
    "тип_места" character varying
);


ALTER TABLE public."места" OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16445)
-- Name: осмотры_сотрудников; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."осмотры_сотрудников" (
    "код_сотрудника" integer NOT NULL,
    "код_осмотра" integer NOT NULL
);


ALTER TABLE public."осмотры_сотрудников" OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16448)
-- Name: остановки_в_рейсах; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."остановки_в_рейсах" (
    "код" integer NOT NULL,
    "код_станции" integer NOT NULL,
    "код_рейса" integer NOT NULL,
    "номер_платформы" integer,
    "порядковый_номер" integer NOT NULL,
    "операция_на_станции" character varying(45),
    "время_прибытия" time without time zone,
    "время_отправления" time without time zone
);


ALTER TABLE public."остановки_в_рейсах" OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16451)
-- Name: отзывы; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."отзывы" (
    "код" integer NOT NULL,
    "код_пассажира" integer NOT NULL,
    "код_рейса" integer NOT NULL,
    "оценка" integer NOT NULL,
    "текст_отзыва" character varying(500),
    "дата" date
);


ALTER TABLE public."отзывы" OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16454)
-- Name: пассажиры; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."пассажиры" (
    "код" integer NOT NULL,
    "фамилия" character varying(45) NOT NULL,
    "имя" character varying(45) NOT NULL,
    "отчество" character varying(45),
    "номер_документа" character(10),
    "код_категории_пассажира" integer NOT NULL,
    "телефон" character varying(20),
    "электронная_почта" character varying
);


ALTER TABLE public."пассажиры" OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16457)
-- Name: покупка_билетов; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."покупка_билетов" (
    "код" integer NOT NULL,
    "код_билета" integer NOT NULL,
    "код_пассажира" integer NOT NULL,
    "дата_бронирования" date,
    "дата_покупки" date
);


ALTER TABLE public."покупка_билетов" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16659)
-- Name: покупка_услуги; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."покупка_услуги" (
    "код_покупки" integer NOT NULL,
    "код_услуги" integer NOT NULL
);


ALTER TABLE public."покупка_услуги" OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16478)
-- Name: пользователи; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."пользователи" (
    "код" integer NOT NULL,
    "логин" character varying(25) NOT NULL,
    "эл_почта" character varying(255) NOT NULL,
    "пароль" text NOT NULL,
    "роль" text,
    "соль" character varying
);


ALTER TABLE public."пользователи" OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16724)
-- Name: пользователи_покупки; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."пользователи_покупки" (
    "код_пользователя" integer NOT NULL,
    "код_покупки" integer NOT NULL
);


ALTER TABLE public."пользователи_покупки" OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16460)
-- Name: рейсы; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."рейсы" (
    "код" integer NOT NULL,
    "пункт_отправления" character varying(80) NOT NULL,
    "пункт_назначения" character varying(80) NOT NULL,
    "время_в_пути" character varying(20),
    "код_состава" integer,
    "дата" date
);


ALTER TABLE public."рейсы" OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16463)
-- Name: составы; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."составы" (
    "код_состава" integer NOT NULL,
    "номер_поезда" character varying(9),
    "тип_поезда" character varying(45) NOT NULL,
    "характеристики_поезда" character varying(300),
    "статус" character varying(45),
    "код_компании_отправителя" integer NOT NULL
);


ALTER TABLE public."составы" OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16466)
-- Name: сотрудники; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."сотрудники" (
    "код" integer NOT NULL,
    "фамилия" character varying(45) NOT NULL,
    "имя" character varying(45) NOT NULL,
    "отчество" character varying(45),
    "телефон" character varying(20) NOT NULL,
    "пол" character(2),
    "образование" character varying(100),
    "дата_рождения" date,
    "адрес_проживания" character varying(200),
    "страховой_полис" character varying(16),
    "серия_и_номер_паспорта" character varying(10),
    "дополнительная_информация" character varying(400),
    "код_должности" integer
);


ALTER TABLE public."сотрудники" OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16469)
-- Name: сотрудники_в_рейсах; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."сотрудники_в_рейсах" (
    "код_сотрудника" integer NOT NULL,
    "код_рейса" integer NOT NULL
);


ALTER TABLE public."сотрудники_в_рейсах" OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16472)
-- Name: станции; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."станции" (
    "код" integer NOT NULL,
    "название" character varying(80) NOT NULL,
    "регион" character varying(80) NOT NULL,
    "населенный_пункт" character varying(80) NOT NULL,
    "адрес" character varying(60),
    "телефон_станции" character varying
);


ALTER TABLE public."станции" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16475)
-- Name: типы_вагонов; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."типы_вагонов" (
    "код" integer NOT NULL,
    "название_типа" character varying(45) NOT NULL,
    "описание" character varying(400)
);


ALTER TABLE public."типы_вагонов" OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16651)
-- Name: услуги; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."услуги" (
    "код" integer NOT NULL,
    "услуга" text NOT NULL,
    "цена" numeric(8,2) NOT NULL,
    "дополнительная_информация" text
);


ALTER TABLE public."услуги" OWNER TO postgres;

--
-- TOC entry 5069 (class 0 OID 16421)
-- Dependencies: 216
-- Data for Name: билеты; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."билеты" ("код", "код_рейса", "цена", "код_места", "статус") FROM stdin;
1	3	3879.00	38	Продан
3	4	1875.00	11	Продан
4	4	2875.00	37	Не продан
5	6	3402.00	35	Не продан
6	9	2822.00	30	Не продан
8	3	3311.00	31	Не продан
9	3	3433.00	29	Забронирован
10	4	1684.00	22	Продан
11	11	3747.00	3	Не продан
12	11	1027.00	13	Не продан
13	4	1241.00	4	Не продан
14	11	3507.00	43	Не продан
15	3	1647.00	8	Не продан
16	5	2593.00	14	Не продан
17	11	1054.00	14	Забронирован
18	11	3439.00	21	Не продан
19	8	1679.00	5	Не продан
20	9	1101.00	39	Не продан
21	2	1923.00	42	Продан
22	6	2723.00	40	Продан
23	10	2501.00	36	Продан
24	2	3252.00	34	Продан
25	9	3786.00	33	Продан
26	2	1882.00	32	Продан
27	1	3853.00	28	Продан
28	5	1845.00	27	Продан
29	10	2765.00	26	Не продан
30	7	1675.00	25	Продан
31	4	1980.00	24	Продан
32	4	1364.00	23	Не продан
33	4	2393.00	20	Продан
34	5	2005.00	19	Не продан
35	5	3427.00	18	Продан
36	1	1541.00	17	Продан
37	5	2869.00	16	Продан
38	3	3700.00	15	Продан
39	2	2000.00	18	Продан
40	2	1400.00	44	Не продан
41	2	1800.00	45	Не продан
2	2	1405.00	38	Не продан
7	2	1579.00	41	Продан
\.


--
-- TOC entry 5070 (class 0 OID 16424)
-- Dependencies: 217
-- Data for Name: вагоны; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."вагоны" ("номер_вагона", "код_типа_вагона", "в_ремонте", "в_составе") FROM stdin;
01213702    	4	f	t
01330725    	1	f	t
01462379    	2	f	t
01703439    	1	f	t
02375888    	1	f	t
02416734    	1	f	t
02496992    	1	t	f
02839274    	4	f	t
02910565    	2	t	f
03031086    	2	f	t
03080533    	1	f	t
03252513    	2	f	t
03311064    	3	f	f
03418244    	2	t	f
03503681    	1	f	t
03655660    	1	f	t
03948443    	5	f	t
03967430    	3	f	t
03978003    	6	f	t
04115682    	4	f	t
04555632    	4	f	t
04713481    	4	f	f
04740098    	3	f	t
05239035    	6	f	t
05315633    	1	f	t
05459175    	2	f	t
05865053    	1	f	t
06793806    	5	f	t
07039954    	5	f	t
07135376    	4	f	t
07418549    	5	f	t
07712189    	5	f	t
07723369    	4	f	t
07785389    	3	f	t
07830039    	4	f	t
07872963    	2	f	t
08035352    	5	f	t
08096213    	2	f	t
08172690    	6	f	t
08204230    	1	f	t
08268000    	4	f	t
08702627    	2	f	t
08788230    	4	f	t
08922321    	3	f	t
08999756    	5	f	t
09228326    	5	f	t
09235085    	6	f	t
09697365    	6	f	t
09785440    	5	f	t
09838096    	6	f	t
09343434    	6	f	f
\.


--
-- TOC entry 5071 (class 0 OID 16427)
-- Dependencies: 218
-- Data for Name: вагоны_в_составах; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."вагоны_в_составах" ("код_вагона", "код_состава") FROM stdin;
01462379    	1
02910565    	1
03031086    	1
03252513    	1
03311064    	1
03418244    	1
03948443    	1
04740098    	1
09838096    	1
01330725    	2
01462379    	2
04115682    	2
02496992    	3
04713481    	3
01213702    	4
02416734    	4
05459175    	4
07872963    	4
08096213    	4
08702627    	4
01703439    	5
08999756    	5
03978003    	6
09785440    	6
01330725    	7
03080533    	7
02375888    	8
03967430    	8
04555632    	8
08788230    	8
\.


--
-- TOC entry 5072 (class 0 OID 16430)
-- Dependencies: 219
-- Data for Name: должности; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."должности" ("код", "наименование_должности", "зарплата", "обязанности", "требования") FROM stdin;
1	Машинист поезда	50000.00	Управление локомотивом и обеспечение безопасности движения поезда, Соблюдение правил и инструкций по эксплуатации поезда, Контроль за работой оборудования и состоянием пути, Взаимодействие с диспетчерской службой и другими сотрудниками железнодорожной компании, Проведение технического осмотра локомотива перед отправлением,Учет и отчетность по выполненным работам.	Наличие среднего или среднего профессионального образования,Водительское удостоверение категории «В» или «С»,Опыт работы в сфере железнодорожного транспорта,Знание правил эксплуатации поезда и оборудования,Умение быстро принимать решения и действовать в критических ситуациях,Ответственность и внимательность к деталям,Готовность к ночным и длительным сменам,Способность к физической работе и выносливость.
2	Диспетчер	40000.00	Контроль за движением поездов на маршруте,Обеспечение безопасности пассажиров и персонала поезда,Взаимодействие с диспетчерскими подразделениями и другими специалистами,Выполнение указаний старшего диспетчера,Контроль и регистрация данных о поездах и рейсах, Решение оперативных вопросов и принятие мер по предотвращению возможных аварий и происшествий.	Высшее или среднее профессиональное образование в сфере железнодорожного транспорта, Знание нормативных актов и правил, регулирующих деятельность железнодорожного транспорта, Умение быстро принимать решения и действовать в экстренных ситуациях, Навыки работы с компьютером и специализированным программным обеспечением, Ответственность и внимательность к деталям, Готовность к работе в непрерывном режиме и сменной работе.
3	Инженер-конструктор	60000.00	Проведение исследовательской работы для выявления потребностей в новых разработках или модернизации существующих изделий, Проектирование и разработка железнодорожных транспортных средств и оборудования, Разработка технической документации, включающей чертежи, спецификации и технические условия, Осуществление контроля за соответствием разрабатываемых изделий требованиям технических условий и нормативной документации	Высшее техническое образование в области машиностроения, железнодорожного транспорта или смежных областей, Опыт работы в области инженерного проектирования и конструирования, желательно в железнодорожной отрасли
4	Техник	30000.00	ведение табеля в ЕКАСУТР,техническая документация линейного участка,ведение работ в системах ЕКАСУФР, ЕКАСУИ,участие в осмотрах	уверенный пользователь ПК, образование не ниже среднего профессионального 
5	Электромонтер	35000.00	проверка измерительных комплексов учета электроэнергии, включая коммерческий учет,замена неисправных приборов и трансформаторов,\nобследование электрических установок потребителей и проверка соблюдения ими режимов потребления электрической энергии,ведение и актуализация базы однолинейных схем электроснабжения для внесения изменений в схемы балансовых узлов, ведение технической документации и отчетности.	допуск по электробезопасности, наличие свидетельства о профессии будут являться преимуществом, умение читать электрические схемы, знание принципов работы и правил эксплуатации контрольно-измерительного оборудования, электроприборов и электробезопасности.
6	Механик	40000.00	Проведение плановых и внеплановых ремонтных работ на локомотивах,Диагностика и выявление неисправностей,Замена или восстановление деталей и узлов,Настройка и испытание оборудования, Контроль качества проведенных работ, Соблюдение правил техники безопасности во время работы, Подготовка отчетной документации и ведение учета выполненных работ.	Техническое образование в области железнодорожного транспорта или смежной отрасли, Опыт работы в ремонте и обслуживании локомотивов, Знание технической документации и нормативных актов, регламентирующих ремонтные работы, Умение работать с инструментами и оборудованием, Внимательность к деталям и умение обнаруживать неисправности, Навыки проведения диагностики и выполнения ремонтных работ, Ответственность и исполнительность, Умение работать в команде и соблюдать рабочий режим, Знание правил техники безопасности.
7	Охранник	25000.00	осуществление пропускного и внутриобъектового режимов на объектах охраны, контроль территории посредством анализа систем видеонаблюдения, контроль перемещения материальных ценностей, поддержание общественного правопорядка на территории объекта.	наличие действующего удостоверения ЧО 4, 6 разряда, опыт работы в сфере охраны, строгий деловой костюм (черного, темно-синего цвета), пунктуальность, вежливость, порядочность, стрессоустойчивость.
8	Локомотивный помощник	25000.00	Оказание помощи локомотивному машинисту в выполнении его обязанностей при управлении поездом, Контроль за работой и состоянием локомотива, Проведение технической диагностики и обслуживание локомотива, Выполнение операций по погрузке и разгрузке грузов, Соблюдение правил и норм безопасности в процессе работы.	Образование не ниже среднего профессионального, Медицинская книжка, Опыт работы в сфере железнодорожного транспорта приветствуется, Знание правил и норм безопасности при работе с локомотивами, Физическая выносливость и готовность работать в непростых условиях, Ответственность и внимательность к деталям.
9	Технолог-программист	70000.00	Разработка и поддержка программного обеспечения для автоматизации технологических процессов и операций в РЖД, Анализ и оптимизация существующих систем, Разработка технических заданий, спецификаций и документации для программного обеспечения, Тестирование программного обеспечения на соответствие требованиям и отладка ошибок, Обучение пользователей работе с разработанным программным обеспечением.	Высшее техническое образование по специальности «Информатика», «Программная инженерия» или аналогичная, Опыт работы в области программирования не менее 3-х лет, Уверенное владение языками программирования, такими как Java, C++, Python, Знание принципов объектно-ориентированного программирования, Опыт работы с базами данных и SQL, Навыки разработки и отладки программного обеспечения, Умение работать в команде и выполнять поставленные задачи в срок, Ответственность, внимательность к деталям и исполнительность.
10	Электромеханик	50000.00	Проведение технического обслуживания и ремонта электротехнического оборудования на железных дорогах, Выполнение плановых и внеплановых работ по восстановлению работоспособности устройств и систем, Устранение аварий и неисправностей в работе электротехнического оборудования, Контроль и наладка систем электроснабжения, освещения, сигнализации и других электротехнических устройств, Ведение технической документации и отчетности о проведенных работах, Соблюдение правил и норм безопасности при проведении работ.	Наличие профильного образования (техническое или среднее специальное), Опыт работы на аналогичной должности, Знание принципов и методов ремонта и обслуживания электротехнического оборудования, Умение читать электрические схемы и техническую документацию, Навыки работы с основными инструментами и приборами электромеханика, Знание правил и норм безопасности при работе с электрооборудованием
11	Составитель графика движения поездов	70000.00	Анализ потребностей пассажиров и грузовладельцев, Учет грузовых и пассажирских потоков, Определение оптимальных маршрутов и расписаний движения, Согласование графика с различными отделами и подразделениями, Мониторинг и обновление графика в случае необходимости, Взаимодействие с диспетчерами и другими специалистами для обеспечения планомерного движения поездов.	Высшее техническое образование в области железнодорожного транспорта или смежных специальностей, Знание правил и нормативов движения поездов, Умение работать с расписаниями и графиками, Аналитические навыки и способность к быстрому принятию решений, Умение работать в команде и добросовестно выполнять свои обязанности, Ответственность и внимательность к деталям, Умение общаться с коллегами и клиентами.
12	Печатник	40000.00	подготовку и настройку печатного оборудования, проверку и подготовку материалов для печати, контроль качества печати, организацию и управление рабочим процессом, обслуживание печатного оборудования, выполнение ремонтных работ, соблюдение технологических норм и правил, соблюдение требований по охране труда и пожарной безопасности.	профессиональные навыки в области печати, знание технологий и процессов печати, умение работать с печатным оборудованием, высокая внимательность и ответственность, умение работать в команде.
13	Проводник поезда	45000.00	прием и подготовка вагона к рейсу, контроль посадки и высадки пассажиров, обеспечение клиентского сервиса и безопасности пассажиров в пути, поддержание чистоты и порядка в вагоне.	образование среднее общее (11 классов),наличие свидетельства о профессии будет являться преимуществом.
\.


--
-- TOC entry 5089 (class 0 OID 16481)
-- Dependencies: 236
-- Data for Name: карты; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."карты" ("код", "номер", "до") FROM stdin;
3	\\xc30d04070302975d632b67a4280771d2410111a6e9e90b313a6d22a14b616f4d64775242681ac8c35ce23ca4e5b56d7e0cc5e3387f83b5b2b9d076e80b09ef34af6d0eeb0e9533e2cd07dbfdb0a54d48b3be	2026-05-01
4	\\xc30d04070302663be3d5ff35f74176d2410179978e4ab61e56a714b8ea0d2e4cf5cb10b58cf203cdc627ef0794e3ff91c5dee458353b1cdff4303e442c1b1da9d63b2ee866ab76262fbcce8e008e3ae37025	2025-06-01
5	\\xc30d04070302e04a1038888fd4537fd244019cd5923961b3584cbc8a873d00dd8e976fdc437a15205e8245480b804f21241ab0483ac26fd02dce567e35dba5576fbb2ac0e55bedd4cc8cbb2aeb50cd8e6a711bd973	2028-01-01
6	\\xc30d040703027a6929bcf1e49ad96ed2410187ecdb2e8318a18ff28c1509fdef5c355de8408be6f8ec420a8a5eaeaefb61cd7be07c0417906d298009f438e766553e80f8344ae72887a0e096e7a54b9b380b	2025-01-01
1	\\xc30d04070302be24b017fcf74eda60d241012eac700bf7c72806b8d01fcfd37d68704a7492572baa8845a318153d414af262fafb5a3531f6a72b3044ae64ece8788a1b057b9b8fe8ce0e4424cb9405f91ad7	2028-05-01
2	\\xc30d04070302854752ef632c3ed07cd2410187205c19baa18f53cb8cdab1c5bfd5e25b1e8af8b6d558437d32ac97c5b11c39b826a4c35945a8248c21ac922379d43202850152c142bf5385e5a61b6c8076bf	2028-05-01
7	\\xc30d04070302d33194650322490c7bd24401dbb04eaaff84579fb8bdd1ad44d988f4b16c9269b28a34fee2c3ad4a2e75d639b752e866923a8c77d612f785c08b5aa9d7728054d59592111473665e7c4a7fc5531a68	2029-02-01
8	\\xc30d0407030280871f9994a816086ed24401a0ba93b88e818603f4d56733475ebc347e03ab85755032292939b16f8c585e9c4fb7860147b39507f44dc0b7a3a72f0c2876ab4159278c57c56fdeb2a2af14c77ccb27	2027-02-01
9	\\xc30d04070302175a36a98f15eebf71d2410164a99ed3b5b2c34c1ad7da8b2e8a9b9e0e983f4fbf9d119c14d2bea860c2c869ee9d2cce1e7d2ac9503c72adddc8415885c77b3986ed06757c61a2188386c8c4	2027-02-01
10	\\xc30d0407030224be152c5d724dc877d24401fc32418927c74c39a6b08609af20d4392234b9b8ece21103b0ef03114f43147a141d7a48d78e7315fde7b5315670affdc5384c4337e6bbe2511b444ff686a3a65eaa42	2027-02-01
11	\\xc30d04070302df06e0f0c02f56ca79d2410128ff91cf5cb1e4e334dbffd65187a81c2978507f10e4c181042819615ee31cf59562d4bd8c5be57bb8150c7a813e246e97e1078d3fb5c218224ad18d343ae5ec	2027-12-01
12	\\xc30d040703027aad2bf7de46caed76d2410161229c8f9b57e240dc3e1f09141caea2372328f96e5bc538507bc848ef5ee473bf4a55637df0ba026d229cc87965ccd15741e45666001caae0d01515a03f6b98	2026-03-01
13	\\xc30d040703020baf0716a76b7d907ad24101eda759ee21573b2e669360115c5240822579a5ab473bf165cef69ee3a86108d5ca8d0b58d5453a0e199e870770133938277aa0650449278e97a60b6456a390e6	2026-03-01
14	\\xc30d040703027cca41f4f8f141b868d2410186377a48b52517ac0f331fdce493ce56873439e9007ed387c4f8080f70856490991aa0943d113067da92aab9c6b7918aa592df950624858eb1ff770dcd9b73e9	2026-03-01
15	\\xc30d0407030238c9e7afacc5d5677dd24401a206afa4e3e245caeeff1251ec0ecbc141102af9d5a38929bb9227dad173bf4f7a4a2dd67caeac7ea5d38d05720faa6847ca749a903debd48c485ac0187a5449781fe0	2026-03-01
16	\\xc30d040703026b3b24b20b566de67fd24401168852e8514049e2fcb8e6bdcc11933b9434786aeba639a1a276309dab56c48ced821e863fa61957ea2f97472b5b417db901bd4852960bf6294d6d4978ce66016967d7	2028-03-01
17	\\xc30d040703028917040dbadb8cb56fd24101ba06f5badf4a21a29a49abb7094c77d63ee0f11caf5cd63c9dd5165da70b553f4ac8989685f17301999a4ec2dcd79bbd0995b30039ab57add89177123d364ad5	2025-03-01
18	\\xc30d0407030265ca3137b9aec92670d241018c36ba2df0cea6dacac7b335ac5bf72fb9e84b70956210b858c21e31cffa5ca4ae5197ceb787b17ec5233ba876a11c7073e6a1e5d2718982dd4c53bd06812aba	2026-03-01
19	\\xc30d0407030292a6e5dce99eb56e61d24101967054503906e25445dd4627e768ad7ecc560fe84bca23d7a96191e96986ab95a93845d2d16b08a01a071eec74cb50b7426accecf9fc72f608a81f6d11bf98c9	2029-06-01
20	\\xc30d04070302041888bc05c0ca6761d241015691d22bd23c4016f58d3ba63622ff68802d3f681c00ce9930777d26dded3d11117dda35a41bba26195f4a53f74aeca4516c2fab932ddcd090b0d00005973255	2028-01-01
21	\\xc30d04070302e7b5650fb7f982a976d24401d4283d18cc8fc12e0593c7c45c2d31cfd46b039f4b6854ca03b3607cbd613f7aeab654f963d4a0cba1e5092e820e98b201884df72275a63e5cedb816f96c4d874a09e9	2025-01-01
22	\\xc30d0407030271a03d99f06118356cd241011fbde2a925670fbe2e732cad56dbbdb15d2bc42740c1dcaa95cc7ee05e9969a3ddbe0ee97f86e385002306b58e9091a2ea6d358612ec269ad5f5878c21a38879	2028-01-01
23	\\xc30d0407030246bfab34dd7008fd64d2440175f23fad61712742a8db23ec09409ceb462a11352bac0c5e8603c3f5313e59954c9db4e356afe5b7ba73eebdf734ca4f93feff5f21d9685c449086566b99eeb17a500d	2026-01-01
24	\\xc30d040703027f9294b950dae1386bd24101f1ff90231d3016aa71fa92935bca3e5d2fdd78e91cd27d8a8d7fb7ff71298a338368e3cf4434bd8eee1545c5926aa86f2b80fd17a8d1129c5c87f2d0049f7f3b	2026-01-01
\.


--
-- TOC entry 5090 (class 0 OID 16546)
-- Dependencies: 237
-- Data for Name: карты_пользователей; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."карты_пользователей" ("код_пользователя", "код_карты") FROM stdin;
1	1
1	2
3	3
8	5
9	8
11	19
5	20
4	18
3	17
2	16
2	15
6	13
7	12
15	11
31	10
28	7
30	4
29	6
10	9
6	14
31	21
31	22
34	23
35	24
\.


--
-- TOC entry 5073 (class 0 OID 16433)
-- Dependencies: 220
-- Data for Name: категории_пассажиров; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."категории_пассажиров" ("код_категории", "название_категории", "скидка") FROM stdin;
1	Взрослые	0
2	Дети до 10 лет	30
3	Дети до 5 лет	100
\.


--
-- TOC entry 5094 (class 0 OID 16818)
-- Dependencies: 241
-- Data for Name: ключи; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ключи" ("код", "ключ") FROM stdin;
1	d7ac3248c6d405b533b25b012e55f628ef5ac684e01ec41374f7f5da0101ae98
\.


--
-- TOC entry 5074 (class 0 OID 16436)
-- Dependencies: 221
-- Data for Name: компании_отправители; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."компании_отправители" ("код_компании", "название_компании", "адрес", "телефон", "электронная_почта", "сайт") FROM stdin;
1	ООО "Безмятежная труба"	620752 г. Екатеринбург ул. Кооперативная 10 оф. 90	89408870956	jucc27fd707hgwzfqjk@fh4uhiz.ru	https://example.com/amount/bee
2	ООО "Серьезная область"	190425 г. Санкт-Петербург ул. Молодежная 39 оф. 2	89619595492	ofkvlpj47@chak.ru	https://www.example.edu/
3	ООО "Договор"	420378 г. Казань ул. Труда 3 оф. 72	89341580164	m7n8xv6fmty3vta9kd4z@u.7yu.ru	https://brick.example.net/art.html?belief=aunt
4	ООО "Триумфальная река"	614371 г. Пермь ул. Береговая 45 оф. 32	89060652125	td2zwop.s3@aas.ru	http://bridge.example.net/
5	АО "Источник"	400611 г. Волгоград ул. Трудовая 32 оф. 2	89774893816	afcfta29a1bt6hccv@t6.ru	http://www.example.com/account.html?beef=bridge#appliance
6	ООО "Счастье"	344524 г. Ростов-на-Дону ул. Речная 38 оф. 39	89977487538	gjwflyz9gazi@kwe0.ru	https://approval.example.com/action?bed=addition
7	ООО "Шанс"	400621 г. Волгоград ул. Молодежная 50 оф. 28	89872066176	lj.ikojfh3ow8@txjov.ru	https://example.net/bite/bat
8	ООО "Вещь"	400447 г. Волгоград ул. 1 Мая 14 оф. 32	89622767055	dxjdyfn7a7sz6lw7oh9.@ekcfdl.ru	http://example.com/bear
9	ООО "Организация"	344064 г. Ростов-на-Дону ул. Труда 19 оф. 86	89018276676	vrkm@khza.ru	http://example.com/?appliance=amusement&babies=attack
10	ООО "Всесторонная информация"	426186 г. Ижевск ул. Чехова 44 оф. 22	89931225066	guomyn@hohwn0xm9.ru	http://www.example.com/?beds=act&boy=bells
11	ООО "Газета"	450592 г. Уфа ул. Красная 9 оф. 65	89680212107	e04ges0biglygb726@yhsjy0sm2o.ru	https://www.example.com/airplane/bubble.php?attraction=apparatus&bait=balance
12	ООО "Бесчисленный директор"	426185 г. Ижевск ул. Карла Маркса 41 оф. 13	89306058574	ch4v70u884n6vz@ozi0y1y6u.ru	http://account.example.com/amount
13	ПАО "Всемерная точка"	394908 г. Воронеж ул. Строительная 42 оф. 66	89061769463	zxuun@b0.ru	https://www.example.com/
14	ООО "Стекло"	344361 г. Ростов-на-Дону ул. Дачная 36 оф. 62	89740719879	v9q4t7e7rnyqd@h8ih7.ru	https://example.org/aftermath
15	ПАО "Поезд"	644218 г. Омск ул. Луговая 28 оф. 16	89605759477	cyn@o4.jfu1l.ru	https://example.com/#balance
16	ООО "Удивительный номер"	125881 г. Москва ул. Интернациональная 48 оф. 96	89638694889	w.rh4ib3v@v82ryqc20w.ru	http://alarm.example.com/?bell=amusement&agreement=bikes
17	ООО "Порядок"	426763 г. Ижевск ул. Строителей 35 оф. 8	89039396260	rr80kbt2jii0n5brh2@k2ov.ru	https://example.com/
18	ООО "Труд"	443475 г. Самара ул. Набережная 15 оф. 7	89484027041	qyuc@ibi.ru	http://www.example.com/boot/birds
19	ООО "Крутая теория"	454182 г. Челябинск ул. Цветочная 10 оф. 54	89377411194	xmgkbbz3.k1233mw@f.8m.2.ru	https://example.com/amusement/bone
20	АО "Реализация"	660195 г. Красноярск ул. Овражная 28 оф. 37	89355203864	zg@w0ojd.ru	https://www.example.com/
\.


--
-- TOC entry 5075 (class 0 OID 16439)
-- Dependencies: 222
-- Data for Name: медицинские_осмотры; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."медицинские_осмотры" ("код_осмотра", "место_осмотра", "дата_проведения", "результаты") FROM stdin;
1	РЖД-Медицина	2014-09-20	Рак мозга
2	Консультативно-диагностический центр с поликлиникой	2016-01-20	Отек глаза
3	Клиника высоких медицинских технологий им. Н.И. Пирогова	2015-12-20	Больной здоров
4	Городская поликлиника №112	2029-10-20	Болезнь
5	РЖД-Медицина	2006-12-20	Здоров
6	РЖД-Медицина	2003-07-20	Здоров
7	Городская поликлиника №112	2020-05-20	Здоров
8	Поликлиника №38	2028-07-20	Здоров
9	Городская поликлиника №27	2017-09-20	Здоров
10	РЖД-Медицина	2022-04-20	Здоров
11	Городская поликлиника №27	2009-11-20	Здоров
12	РЖД-Медицина	2018-01-20	Здоров
13	Городская поликлиника №112	2026-03-20	Перелом носа
14	Поликлиника №38	2028-12-20	Здоров
15	Городская поликлиника №27	2019-08-20	Близорукость
16	РЖД-Медицина	2031-05-20	Здоров
17	Городская поликлиника №112	2003-08-20	Здоров
18	Поликлиника №38	2018-01-20	Здоров
19	РЖД-Медицина	2002-05-20	Здоров
20	РЖД-Медицина	2022-04-20	Здоров
\.


--
-- TOC entry 5076 (class 0 OID 16442)
-- Dependencies: 223
-- Data for Name: места; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."места" ("код", "номер_вагона", "номер_места", "тип_места") FROM stdin;
1	07723369    	96	Верхнее
2	04555632    	20	Нижнее
3	04555632    	22	Сидячее
4	04555632    	61	Верхнее
5	04555632    	29	Верхнее
6	04555632    	44	Верхнее
7	04555632    	81	Верхнее
8	04555632    	41	Верхнее
9	04555632    	94	Верхнее
10	04555632    	34	Верхнее
11	04555632    	72	Сидячее
12	04555632    	24	Нижнее
13	04555632    	45	Нижнее
14	04555632    	48	Нижнее
15	04555632    	8	Нижнее
16	04555632    	79	Нижнее
17	07872963    	89	Нижнее
18	08268000    	65	Нижнее
19	08268000    	8	Нижнее
20	08268000    	88	Нижнее
21	08268000    	30	Нижнее
22	08268000    	19	Нижнее
23	03948443    	23	Верхнее
24	08999756    	88	Верхнее
25	06793806    	18	Верхнее
26	06793806    	93	Верхнее
27	06793806    	28	Верхнее
28	08999756    	69	Верхнее
29	07872963    	64	Верхнее
30	07872963    	19	Верхнее
31	08999756    	3	Сидячее
32	06793806    	48	Сидячее
33	07872963    	13	Сидячее
34	08999756    	79	Верхнее
35	07872963    	24	Нижнее
36	06793806    	3	Верхнее
37	07872963    	15	Нижнее
38	08999756    	8	Нижнее
39	06793806    	16	Нижнее
40	07872963    	46	Нижнее
41	06793806    	92	Нижнее
42	08999756    	23	Нижнее
43	07872963    	34	Нижнее
44	06793806    	28	Верхнее
45	04555632    	23	Верхнее
\.


--
-- TOC entry 5077 (class 0 OID 16445)
-- Dependencies: 224
-- Data for Name: осмотры_сотрудников; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."осмотры_сотрудников" ("код_сотрудника", "код_осмотра") FROM stdin;
25	1
42	2
2	3
32	4
29	5
42	6
48	7
43	8
35	9
49	10
29	11
15	12
49	13
8	14
45	15
2	16
6	17
19	18
9	19
18	20
\.


--
-- TOC entry 5078 (class 0 OID 16448)
-- Dependencies: 225
-- Data for Name: остановки_в_рейсах; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."остановки_в_рейсах" ("код", "код_станции", "код_рейса", "номер_платформы", "порядковый_номер", "операция_на_станции", "время_прибытия", "время_отправления") FROM stdin;
1	3	2	3	2	Посадка-высадка пассажиров	15:22:00	15:25:00
2	4	2	4	3	Посадка-высадка пассажиров	16:43:00	16:45:00
3	26	2	5	4	Пропуск поездов встречного направления	17:24:00	17:26:00
4	25	2	2	5	Посадка-высадка пассажиров	18:00:00	18:02:00
5	27	2	1	6	Посадка пассажиров	18:20:00	18:22:00
6	16	2	1	7	Посадка-высадка пассажиров	18:34:00	18:36:00
7	14	2	2	8	Посадка-высадка пассажиров	19:17:00	19:55:00
8	24	2	3	9	Посадка-высадка пассажиров	21:03:00	21:05:00
9	15	2	2	10	Посадка-высадка пассажиров	21:59:00	22:13:00
10	23	2	4	11	Посадка-высадка пассажиров	22:53:00	22:55:00
11	20	2	2	12	Посадка-высадка пассажиров	23:15:00	23:17:00
12	21	2	2	13	Посадка-высадка пассажиров	23:40:00	23:42:00
13	22	2	1	14	Высадка пассажиров	00:32:00	00:00:00
14	1	2	1	1	Посадка пассажиров	13:00:00	13:30:00
15	2	1	6	1	Посадка пассажиров	23:42:00	00:12:00
16	9	1	5	2	Посадка-высадка пассажиров	02:23:00	02:24:00
17	8	1	3	3	Пропуск поездов встречного направления	03:17:00	03:18:00
18	5	1	3	4	Посадка-высадка пассажиров	04:00:00	04:30:00
19	6	1	2	5	Высадка пассажиров	05:04:00	05:06:00
20	10	1	1	6	Высадка пассажиров	05:30:00	05:31:00
21	11	1	3	7	Высадка пассажиров	06:01:00	06:03:00
22	7	1	4	8	Пропуск поездов встречного направления	06:31:00	06:32:00
23	12	1	10	9	Высадка пассажиров	09:52:00	00:00:00
24	1	3	2	1	Посадка пассажиров	12:40:00	13:10:00
25	5	3	2	2	Высадка пассажиров	16:31:00	17:08:00
26	6	3	3	3	Высадка пассажиров	17:43:00	17:45:00
27	7	3	2	4	Посадка-высадка пассажиров	18:59:00	19:00:00
28	13	3	5	5	Высадка пассажиров	00:28:00	00:00:00
29	13	4	4	1	Посадка пассажиров	12:22:00	12:52:00
30	7	4	6	2	Посадка-высадка пассажиров	14:41:00	14:53:00
31	6	4	1	3	Посадка-высадка пассажиров	19:56:00	19:57:00
32	5	4	2	4	Посадка-высадка пассажиров	21:10:00	21:12:00
33	1	4	2	5	Высадка пассажиров	22:02:00	00:00:00
34	1	5	8	1	Посадка пассажиров	09:59:00	10:29:00
35	22	5	2	2	Посадка-высадка пассажиров	11:31:00	11:33:00
36	21	5	1	3	Посадка-высадка пассажиров	11:55:00	11:57:00
37	20	5	5	4	Посадка-высадка пассажиров	12:15:00	12:17:00
38	23	5	7	5	Посадка-высадка пассажиров	12:55:00	13:09:00
39	15	5	5	6	Посадка-высадка пассажиров	14:08:00	14:10:00
40	24	5	4	7	Посадка-высадка пассажиров	15:26:00	16:00:00
41	14	5	3	8	Посадка-высадка пассажиров	16:50:00	16:52:00
42	16	5	2	9	Посадка-высадка пассажиров	17:05:00	17:07:00
43	27	5	1	10	Посадка-высадка пассажиров	17:26:00	17:28:00
44	25	5	5	11	Посадка-высадка пассажиров	18:08:00	18:10:00
45	26	5	6	12	Высадка пассажиров	18:45:00	18:47:00
46	4	5	4	13	Высадка пассажиров	20:25:00	20:31:00
47	3	5	9	14	Высадка пассажиров	22:40:00	00:00:00
48	2	17	1	1	Посадка пассажиров	11:30:00	12:00:00
49	9	17	1	2	Посадка-высадка пассажиров	13:38:00	13:40:00
50	8	17	4	3	Посадка-высадка пассажиров	14:50:00	14:55:00
51	6	17	4	4	Посадка-высадка пассажиров	16:32:00	16:33:00
52	10	17	2	5	Посадка-высадка пассажиров	18:30:00	18:36:00
53	7	17	2	6	Высадка пассажиров	20:08:00	20:09:00
54	12	17	9	7	Высадка пассажиров	21:38:00	\N
\.


--
-- TOC entry 5079 (class 0 OID 16451)
-- Dependencies: 226
-- Data for Name: отзывы; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."отзывы" ("код", "код_пассажира", "код_рейса", "оценка", "текст_отзыва", "дата") FROM stdin;
1	37	15	2	Поезд пришел с опозданием, что вызвало определенные неудобства!	2023-11-04
2	19	15	5	Впервые спустя много лет встречаю проводника, который следит за тем, чтобы пассажир, которому скоро выходить, был готов, будит если надо, и пастельное белье забирал сам! В туалете и бумаги было много и мыло двух видов. Вообщем все супер было.	2023-11-03
3	50	13	5	Замёрз туалет	2023-11-06
4	37	12	4	В начале поездки было хорошо, тепло. К концу поездки было очень холодно в вагоне. Часто перебои со светом.	2023-12-18
5	24	13	4	Очень хороший туалет. Удобное кресло. Рядом розетка 220В	2023-11-02
6	4	15	5	Все чистенько,очень хороший проводник, внимательный,отзывчивый. 	2023-11-08
7	10	13	5	Поездка приятная! Персонал профессиональный и милый!	2023-11-01
8	17	14	3	Очень грязные туалеты.не закрываются мусорные баки.По окну с внутренней стороны текла оттаянная вода.	2023-10-11
9	47	14	1	В купе жарко, спать не возможно. Туалеты вышли из строя почти сразу. Утром в туалете было по щиколодку воды.	2023-10-11
10	28	13	4	Не было горячей воды в туалете.	2023-11-03
11	16	13	1	Было очень холодно не возможно было спать очень грязно был туалет и света не было в туалете	2023-11-05
12	3	14	3	Вагон древний, в туалетах не спускается содержимое! Темнота кромешная, у проводника в купе нет света и он помогает себе телефоном. Ужасная грязь в вагоне, только поехали, а мусора уже полно.	2023-10-15
13	29	15	4	Верхние полки были не застелины. Окна были покрыты инием. Дверь в вагон не открывалась. Вторую половину пути температура воздуха превышала норму	2023-11-12
14	30	14	2	Ужасный старый вагон.. Это был ад.... А не поездка	2023-10-13
15	11	14	3	С утра туалет засорился. Вода пошла на пол. Пытались еайти проводника- не было на месте. В итоге оказалось, что она спала в своём вагоне. Как только сели в поезд- света не было. Сейчас зима, и температуру в вагонах хотелось бы, чтобы поддерживали. Но утром температура в вагоне номер два была 16 градусов а проводник в это время спит себе. В общем, впечатление ужасное. Больше поездом этим ездить не будем	2023-10-12
16	33	13	2	Ужасные полки. Кто-то придумал сделать мягкие спинки с полочками, которые сожрали 6 см полки. Только очень худой человек может лежать на ней, вытянувшись в струнку. Движок в вагоне слабый, свет гаснет на остановках Персонал старается, но что они сделают	2023-11-01
17	39	15	1	Проводник постоянно твердил что бы обращались в РЖД и он нев чем не виноват,такой вагон прицепили в Питере аварийный. После такой поездки на 5000 рублей лекарства и больничный .	2023-11-05
18	20	12	2	Отвратительный вагон, свет не выключался во время пути, при этом это был ночной рейс.	2023-12-08
19	22	12	5	Отличный вагон, все понравилось	2023-12-10
20	30	15	5	Очень корректный и вежливый проводник Владимир, своевременно предложил и белье, и чай. В вагоне чисто, периодически выполняется влажная уборка. Комфортная температура, не жарко и не холодно. Спокойная и доброжелательная обстановка.	2023-11-06
\.


--
-- TOC entry 5080 (class 0 OID 16454)
-- Dependencies: 227
-- Data for Name: пассажиры; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."пассажиры" ("код", "фамилия", "имя", "отчество", "номер_документа", "код_категории_пассажира", "телефон", "электронная_почта") FROM stdin;
1	Колобов	Лев	Тимофеевич	12345     	3	89905406361	xfe@bxoardj08.ru
2	Брагин	Марк	Русланович	354635    	3	89253898048	thpo.qf84fqia0r3ba8@rj657c3mf9.ru
3	Гущина	Оксана	Егоровна	677890    	3	89155046067	y19t@pw4u7.ru
4	Пахомова	Милена	Игнатовна	567678    	3	89482902829	jur5l7jxbre15ug@sk08g38.ru
5	Якушева	Мелания	Федоровна	9434647793	1	89934812068	rm54fnnleeanm@we31.ru
6	Виноградова	Варвара	Яновна	1320609659	1	89401067308	tuiqtsnedq1hx@q03.ru
7	Фокин	Олег	Валерьевич	456788    	3	89384611626	yywu2f9potv@cdkem.ru
8	Сорокин	Павел	Владович	3456788   	3	89605272793	c1lm2t017ntjrsuw@cp.ru
9	Богданов	Захар	Юрьевич	445674    	3	89250577026	r6cc0izd@i.cpfty37.ru
10	Мишин	Тихон	Федорович	8442918158	1	89179768203	nv3lrnhgv8vru3zz3b9@qbm3r0p.ru
11	Сидорова	Юлия	Маратовна	8273838902	1	89395075309	ka104@khjg8k09q.ru
12	Ларионов	Константин	Артурович	5634654   	3	89614205424	iu9l65up@iwtdwq4t.ru
13	Котова	Ника	Святославовна	6437647   	3	89611772492	qk30bbb3rp6d@gb6.ru
14	Давыдова	Агата	Федоровна	8895837507	1	89517729692	pf@v9ms90381p.ru
15	Наумова	Диана	Рустамовна	          	2	89066509066	h3t@wcb.ru
16	Медведев	Григорий	Антонович	          	3	89623310938	b6u@g7c85uc.ru
17	Силин	Тихон	Тимурович	          	3	89384655954	xhzpop1tuth4urpvr@pkg.ru
18	Горбачёва	Мелания	Яновна	6931179567	1	89984198108	ppvbsn10d3v@lh.ru
19	Капустина	Надежда	Егоровна	6067116389	1	89811265576	jh9.0d.@icw3.ru
20	Мухин	Роман	Робертович	6723387915	1	89322911753	toxndosg@i3w0zlcgd.ru
21	Стрелкова	Оксана	Тимуровна	          	3	89762019459	p371wwy54tzmtx08rkkj@o6d55t9l9r.ru
22	Юдина	Алиса	Арсеньевна	9872546697	1	89593482965	l3d.z0m@h5p.ru
23	Наумова	Любовь	Демидовна	          	2	89490998531	q6gdemuk2cw@z4cfs.ru
24	Горбачёва	Людмила	Владовна	          	3	89338122266	dpyrehtswp55l.t1ckyb@dnx.ru
25	Корнилова	Ника	Арсеньевна	          	3	89917433209	yj6xvbdv.exaa49rsm0f@linxydzt.ru
26	Суханова	Алёна	Артуровна	          	3	89718653785	j61qyqjta@w.29gj0.ru
27	Мишин	Макар	Дмитриевич	6991791196	1	89686964073	kcez3q3ziaj9chbds4pa@uf.ru
28	Лукина	Александра	Степановна	1049698965	1	89506831177	vzdydb@be.ru
29	Суханова	Валерия	Викторовна	          	3	89108303476	qm@fpsrj17.ru
30	Сысоева	Амелия	Айдаровна	          	3	89066855903	blq4q64vns1@tti1u71.ru
31	Жданова	Ярослава	Олеговна	          	3	89655837324	fg5qorgydj.yy5m2zi@tv1c.ru
32	Копылов	Антон	Вадимович	4661354567	1	89404415479	ta2s09tmc@qgh.ru
33	Красильников	Леонид	Петрович	          	3	89286829292	zyx0vbnqhjl1yu7em10@xicgk2m8h.ru
34	Дорофеева	София	Ильинична	          	3	89937133668	xj@sfu9c.ru
35	Одинцова	Валерия	Эмильевна	2550401901	1	89338258032	bnj7@xoee3mpff.ru
36	Русаков	Влад	Степанович	9761630007	1	89987201011	u7sckrr@tlc.59q8l4.ru
37	Титов	Сергей	Альбертович	3935034347	1	89200125713	ml5orb33jjnk8om9h8p@eex3g.ru
38	Васильев	Руслан	Платонович	2017748694	1	89942176770	k6ct34n@ui.ru
39	Мартынов	Павел	Ростиславович	          	3	89768897049	c91@fz70gw.ru
40	Савин	Егор	Назарович	          	3	89440989024	lxqu03ih8c3rr74jo@k1.ru
41	Наумов	Глеб	Матвеевич	          	2	89391337355	em6.p320s@eixw.ru
42	Журавлёва	Алина	Платоновна	8430767318	1	89748091018	meh0tu.v3pq@s08.ru
43	Копылова	София	Ильинична	5669640882	1	89418046916	osxu9jnnabb2ek28lj@w5at.ru
44	Антонов	Денис	Владович	          	2	89328533408	nb21tn@wc7l5o6mcb.ru
45	Стрелков	Роман	Глебович	4039038687	1	89851415907	e38ecv8snw88lv@k2stnw6.ru
46	Голубева	Амалия	Владовна	          	3	89522631140	a655bzuy9k8o5z@ppwfrt0.ru
47	Лебедева	Валерия	Айдаровна	          	2	89335785176	qagu.aa23vt9@b9q.ru
48	Полякова	Антонина	Альбертовна	3067449872	1	89036372593	o1aq@um0n9n.ru
49	Денисова	Виталина	Глебовна	          	2	89125990670	dditwa@vtm8i9i.ru
50	Мамонтов	Александр	Егорович	647634    	2	89166930452	qskai7uk@bghemgr.ru
51	Кудринский	Артем	Алексеевич	99999999  	1	89219824904	artjomkudrinsky@yandex.ru
\.


--
-- TOC entry 5081 (class 0 OID 16457)
-- Dependencies: 228
-- Data for Name: покупка_билетов; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."покупка_билетов" ("код", "код_билета", "код_пассажира", "дата_бронирования", "дата_покупки") FROM stdin;
2	3	5	\N	2024-01-21
6	1	10	2024-01-15	2024-01-21
11	17	38	2024-12-23	\N
16	10	28	\N	2024-01-19
20	9	48	2024-01-21	\N
21	21	8	\N	2023-12-10
22	22	37	\N	2023-12-05
23	23	46	\N	2023-12-23
24	24	13	\N	2023-11-18
25	25	49	\N	2023-12-18
26	26	49	\N	2024-01-10
27	27	20	\N	2023-12-21
28	28	49	\N	2024-01-21
29	30	3	\N	2023-12-10
30	31	46	\N	2023-12-08
31	33	13	\N	2023-11-09
32	35	24	\N	2023-11-26
33	36	24	\N	2024-01-12
34	37	5	\N	2023-11-17
35	38	47	\N	2023-11-08
36	7	51	\N	2024-06-16
\.


--
-- TOC entry 5092 (class 0 OID 16659)
-- Dependencies: 239
-- Data for Name: покупка_услуги; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."покупка_услуги" ("код_покупки", "код_услуги") FROM stdin;
2	3
6	3
11	1
16	3
20	1
20	3
2	2
6	1
27	1
28	3
28	1
29	1
29	2
30	3
31	3
31	1
31	2
32	3
35	1
34	3
\.


--
-- TOC entry 5088 (class 0 OID 16478)
-- Dependencies: 235
-- Data for Name: пользователи; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."пользователи" ("код", "логин", "эл_почта", "пароль", "роль", "соль") FROM stdin;
1	rappelling	lup_asasoca62@list.ru	$2a$06$kZ0xdiFUEV1j1GqMe4fPruEfesOiYDbY8cfeAUXwKZjGuAoi76NAy	П	$2a$06$kZ0xdiFUEV1j1GqMe4fPru
2	propendent	jezinar-ili71@list.ru	$2a$06$mJ2Yxaobs9olRmxYFIACLOs6XumlvuWYBxtvWIrybNLYe78ZmIgWy	А	$2a$06$mJ2Yxaobs9olRmxYFIACLO
3	floweriest	jewaje-viyo71@mail.ru	$2a$06$abQv1BmIm.hDaVSUyGGEguDPoRWYHT7EwzRYwhDZYCbi9oNzkOdMu	А	$2a$06$abQv1BmIm.hDaVSUyGGEgu
4	sanguinary	wofi-pewola89@mail.ru	$2a$06$c4BN3Ss1ZeM3Tv9u/FMAfuiitp/CFKJ12/Bj8LVc4Vo1X2TY8piz2	П	$2a$06$c4BN3Ss1ZeM3Tv9u/FMAfu
5	spoonbills	mixulat_ela46@yahoo.com	$2a$06$ZlbJ0N22Xgwpfqt39JuHpe6b4MMuUZNA5FVpTlF4gOcbjB7rKNQDO	П	$2a$06$ZlbJ0N22Xgwpfqt39JuHpe
6	covenanted	wul-ukojopi8@gmail.com	$2a$06$Yn66SUIthIOZlFd7tM90k.3qPlbMYsOMaT.wIreDLSqg1sNURTn4i	П	$2a$06$Yn66SUIthIOZlFd7tM90k.
7	nosologist	wiko-nefise52@internet.ru	$2a$06$8xyJz/S.Qlrd.pPpeEsXhe7gZDtSTIYuam9EJYs82DlUebktQrhSC	П	$2a$06$8xyJz/S.Qlrd.pPpeEsXhe
8	chloralose	zixe-yehewo66@mail.ru	$2a$06$hxGMH0Ipucx.xCWWo6rQteaUHMyAyOtNWPce72hjIweUHzlkbnd/O	П	$2a$06$hxGMH0Ipucx.xCWWo6rQte
9	dauphiness	vacunoj_oce96@gmail.com	$2a$06$cUYjmu2YFi6mL35.XyLP2uLQTFcptvmIArHmfzdj8mIWwigm8TUou	П	$2a$06$cUYjmu2YFi6mL35.XyLP2u
10	stimulancy	gaxuw_idife32@gmail.com	$2a$06$bQGTM92y6YiD36htRc.o5.sRRuGqQ3Cuiz/hxDZ.bhpF0A7zXxV9G	П	$2a$06$bQGTM92y6YiD36htRc.o5.
11	camerawork	muki_rotuli90@yahoo.com	$2a$06$qSTvQuMaGcZLhy/RWhm/ge6rHRPHxHTYlcNvO5x8rLN8B3m37wda2	П	$2a$06$qSTvQuMaGcZLhy/RWhm/ge
12	desiccator	facax-ejewa65@yandex.ru	$2a$06$NfpN6CDsvalZFIJxmXLxku3jN8VxgsbJzN3rTMTxFEHrpwpZGaACy	П	$2a$06$NfpN6CDsvalZFIJxmXLxku
13	telegonous	lag-ehanabi59@aol.com	$2a$06$1oCDbt0v84iInlBQJ0bBTuMdWhaXVTaIqxr86xwnJfNG/tqODS2l6	П	$2a$06$1oCDbt0v84iInlBQJ0bBTu
14	jackarooed	cata_beviyu25@hotmail.com	$2a$06$os6xqt5o1HCidN87n1eEJO951RQ607Xz0NOi.QMv.Pq1nZUDMoERW	П	$2a$06$os6xqt5o1HCidN87n1eEJO
15	fugitively	moralu-kedo29@yahoo.com	$2a$06$ZZpz58Jftv/yQi20LEd.ROesr/1NmZkMTPiRGqVBIBGKFiRFNt93G	П	$2a$06$ZZpz58Jftv/yQi20LEd.RO
16	vestiaries	vekerux-ogo19@list.ru	$2a$06$r0X5bWpRfpt1SyR0gt.cLO7xv2jCVM1bG2smSfb92RuK2ugBbu.FK	П	$2a$06$r0X5bWpRfpt1SyR0gt.cLO
17	chimpanzee	diripeg_aku82@yandex.ru	$2a$06$4Rvha7x1iAN8W2wMM5paz.A1IK.Glu/92n9I5/A5z3cHpKwUxs8fi	П	$2a$06$4Rvha7x1iAN8W2wMM5paz.
34	Artem	artem@mail.ru	$2a$06$fjfF3YYa81DoKdCoeE2oUO5daVknio4N3wZIcyYyW8M89WPYf1Rym	П	$2a$06$fjfF3YYa81DoKdCoeE2oUO
36	optima	coolmail@mail.ru	$2a$06$R0DJTWm0T.fHgEXM7bII.uN6PGzu8jwv373fUXKNa9XqjfL2tCeca	П	$2a$06$R0DJTWm0T.fHgEXM7bII.u
18	scampishly	yodo_wokipe88@hotmail.com	$2a$06$Vg9XAE5vhaAHMDN9UXcPe.B14CXhH/I1A6WQ8Ut6XxvWQQiG1eF1S	А	$2a$06$Vg9XAE5vhaAHMDN9UXcPe.
19	overbuying	vub-onereyu26@mail.ru	$2a$06$wF8lnQ1Ox3n4bNL4B9j.y.uauIto5Nd72uW8Ns9UoDasoNwWhfKby	П	$2a$06$wF8lnQ1Ox3n4bNL4B9j.y.
20	cembalists	gisa-tiyova78@inbox.ru	$2a$06$Rb3Cun9rhEz/I97ShUo2cOdV40Vl3DDisgc.bcgxkOBNDETxtZ1Zq	П	$2a$06$Rb3Cun9rhEz/I97ShUo2cO
21	hypnotises	lalez-uduri70@internet.ru	$2a$06$Ad8jCv3vrW2GczaFVTry3uUbuOGUYYuFZ/QlinjNPoFxTSnpCBsJy	П	$2a$06$Ad8jCv3vrW2GczaFVTry3u
22	alcarrazas	jezi-rebiro11@yahoo.com	$2a$06$tTsLvcp9dJb922YlAaABXeVMRpf.BgNHbXsHr82tLp6O9FK04BPt2	П	$2a$06$tTsLvcp9dJb922YlAaABXe
23	cybercafes	cug_idojeya96@internet.ru	$2a$06$r73fMJ6eTMy5SJRpH26AEeRIdfw1j/zh0D1RhfVt4yA7KpF6.965q	П	$2a$06$r73fMJ6eTMy5SJRpH26AEe
24	successive	kaxuvo_yezo44@aol.com	$2a$06$3ArPFemyK2G4SCVByZxVy.MTODitraxUXLhCFD2x1Fi5Py.Cqjx7i	П	$2a$06$3ArPFemyK2G4SCVByZxVy.
25	insheathed	totiya_wuro66@internet.ru	$2a$06$Hb5C.vJMVrR.ayTDK6Ak1OVi/tes5OZioFu9Tg.VGc7c1hR6Jm8Se	П	$2a$06$Hb5C.vJMVrR.ayTDK6Ak1O
26	mushroomer	yege_cosugu10@list.ru	$2a$06$WVpzlFQez.13Rr3GF/JINu7tc4N9ej40l6QiKz69/1lW0KU7rdCaS	П	$2a$06$WVpzlFQez.13Rr3GF/JINu
27	extroverts	sabeg_oleve82@hotmail.com	$2a$06$nwUrcCDuUNZyIg87zm3Gq.JMSWnkyxgC8zOgGINh/I4vsxc9feIqW	П	$2a$06$nwUrcCDuUNZyIg87zm3Gq.
28	extensible	vinoju_ziye86@yahoo.com	$2a$06$FXOLEJBC4XAMJs2ZVyI4w.8i9aLEnxhmQuowp.bkbdItNWEaZxzUi	А	$2a$06$FXOLEJBC4XAMJs2ZVyI4w.
29	ergonomist	cuhir-uyefu11@gmail.com	$2a$06$L6RIHfAqYY7qMF8FJtSCQ.CI2d97EHKuRZQw.vnjKFZ/5N/VWVc4S	П	$2a$06$L6RIHfAqYY7qMF8FJtSCQ.
30	substructs	degol-okije38@gmail.com	$2a$06$eeRctpXaTTHoklZg7UHnw.QO2wkQmFtHAl7wvb2mRnkTGR9SreCCm	П	$2a$06$eeRctpXaTTHoklZg7UHnw.
32	MyUser	MyUser@mail.ru	$2a$06$pQqn6CoHuET1pRH3nFW3e.9qwA9qlpTiBpIkzFJVs3KjJVrXg9bo2	П	$2a$06$pQqn6CoHuET1pRH3nFW3e.
31	aeronautic	aeronautica@mail.ru	$2a$06$XYxDVobUNLcQ.OKDMDrT9.XYPa9DocYoZGmfKblt7UzN.eJUWSete	П	$2a$06$XYxDVobUNLcQ.OKDMDrT9.
33	submarine	emailmail@mail.ru	$2a$06$046y08kFfrfwJauAFepu3uJnubw6HPJRngN1t4gIuSz8CNIHDvkXy	П	$2a$06$046y08kFfrfwJauAFepu3u
35	oxxxygen	oxxxy@mail.ru	$2a$06$c8k0/f1HNypouujRQPocHuoNHxDJED2FKyrGCxOhkvBO2yZoG9u72	П	$2a$06$c8k0/f1HNypouujRQPocHu
\.


--
-- TOC entry 5093 (class 0 OID 16724)
-- Dependencies: 240
-- Data for Name: пользователи_покупки; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."пользователи_покупки" ("код_пользователя", "код_покупки") FROM stdin;
1	2
2	6
2	11
2	16
3	20
2	21
1	22
11	23
16	24
17	25
18	26
20	27
8	28
5	29
4	30
24	31
25	32
30	33
29	34
29	35
\.


--
-- TOC entry 5082 (class 0 OID 16460)
-- Dependencies: 229
-- Data for Name: рейсы; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."рейсы" ("код", "пункт_отправления", "пункт_назначения", "время_в_пути", "код_состава", "дата") FROM stdin;
1	Санкт-Петербург	Москва	9 ч 40 м	1	2024-01-28
2	Санкт-Петербург	Вологда	12 ч 12 м	2	2024-02-09
3	Санкт-Петербург	Владимир	11 ч 18 м	8	2024-03-03
4	Владимир	Санкт-Петербург	8 ч 18 м	4	2024-02-12
5	Вологда	Санкт-Петербург	12 ч 11 м	2	2024-02-11
6	Москва	Санкт-Петербург	8 ч 41 м	1	2024-01-26
7	Владимир	Москва	1 ч 42 м	7	2024-02-29
8	Санкт-Петербург	Тверь	6 ч 19 м	1	2024-02-29
9	Тверь	Санкт-Петербург	5 ч 28 м	3	2024-01-25
10	Санкт-Петербург	Шарья	16 ч 43 м	5	2024-02-09
11	Шарья	Санкт-Петербург	17 ч 19 м	6	2024-02-09
12	Шарья	Санкт-Петербург	15 ч 59 м	1	2023-12-08
13	Тверь	Санкт-Петербург	6 ч 01 м	2	2023-11-01
14	Москва	Воронеж	9 ч 45 м	8	2023-10-10
15	Санкт-Петербург	Екатеринбург	25 ч 12 м	1	2023-11-02
16	Шарья	Санкт-Петербург	25 ч 1 м	8	2024-01-28
17	Санкт-Петербург	Москва	9ч 38 м	4	2024-01-28
18	Москва	Санкт-Петербург	9 ч 38 м	9	2024-04-30
\.


--
-- TOC entry 5083 (class 0 OID 16463)
-- Dependencies: 230
-- Data for Name: составы; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."составы" ("код_состава", "номер_поезда", "тип_поезда", "характеристики_поезда", "статус", "код_компании_отправителя") FROM stdin;
1	451-890	Скорый	Количество пассажиров 600. Конструкторская скорость 90 км/ч.	В рейсе	5
2	123-343	Скорый	Количество пассажиров 400. Конструкторская скорость 91 км/ч.	Свободен	12
3	676-456	Скоростной	Количество пассажиров 409. Конструкторская скорость 160 км/ч.	В рейсе	11
4	567-890	Скорый	Количество пассажиров 600. Конструкторская скорость 90 км/ч.	В рейсе	8
5	678-765	Простой	Количество пассажиров 800. Конструкторская скорость 50 км/ч.	Свободен	17
6	569-876	Скорый	Количество пассажиров 600. Конструкторская скорость 90 км/ч.	Свободен	9
7	560-976	Высокоскоростной	Максимальная скорость 350 км/ч. Количество пассажиров 604	Свободен	4
8	458-987	Скоростной	Количество пассажиров 404. Конструкторская скорость 200 км/ч.	Свободен	17
9	479-081	Скорый	\N	\N	1
10	479-081	Скорый	\N	\N	1
\.


--
-- TOC entry 5084 (class 0 OID 16466)
-- Dependencies: 231
-- Data for Name: сотрудники; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."сотрудники" ("код", "фамилия", "имя", "отчество", "телефон", "пол", "образование", "дата_рождения", "адрес_проживания", "страховой_полис", "серия_и_номер_паспорта", "дополнительная_информация", "код_должности") FROM stdin;
1	Соколов	Иван	Денисович	89373526399	М 	Среднее	1973-07-29	Тольятти ул. Дорожная 38 кв. 19	9551949795844550	4834524490	выдан ГУ МВД России по г. Саратову к/п 026-188 	1
2	Морозов	Артём	Дмитриевич	89017973467	М 	Высшее	1989-11-29	Ижевск ул. Трактовая 46 кв. 69	7963176211090400	197416214	выдан ГУ МВД России по Пермскому краю к/п 260-884 	1
3	Соколова	Арина	Денисовна	89800717378	Ж 	Высшее	1973-04-24	Саратов ул. Верхняя 45 кв. 49	6830812623156940	330807649	выдан ГУ МВД России по г. Волгограду к/п 093-758 	6
4	Титов	Дмитрий	Ильич	89630487922	М 	Высшее	1970-08-18	Красноярск ул. Степная 12 кв. 47	1356809778961950	1366748058	выдан ГУ МВД России по г. Красноярску к/п 144-547 	6
5	Иванова	Арина	Маратовна	89282269033	Ж 	Высшее	1985-01-04	Санкт-Петербург ул. Дорожная 1 кв. 57	6838403039746700	6019715580	выдан ГУ МВД России по г. Тюмени к/п 771-615 	4
6	Судакова	Арина	Андреевна	89150835615	Ж 	Высшее	1993-01-31	Москва ул. Сосновая 36 кв. 42	1056001464198920	9323227271	выдан ГУ МВД России по г. Уфе к/п 720-276 	4
7	Соколов	Максим	Борисович	89343821218	М 	Высшее	1985-01-17	Краснодар ул. Пролетарская 9 кв. 87	5107055129639890	682762875	выдан ГУ МВД России по г. Волгограду к/п 133-494 	11
8	Кузнецова	Марина	Тимофеевна	89115427697	Ж 	Высшее	1985-12-26	Санкт-Петербург ул. Светлая 31 кв. 70	9159249458675390	287877156	выдан ГУ МВД России по г. Екатеринбургу к/п 567-656 	10
9	Березин	Мирон	Михайлович	89237096351	М 	Высшее	1977-09-08	Новосибирск ул. Октябрьская 1 кв. 71	9567538932943100	2812511467	выдан ГУ МВД России по г. Воронежу к/п 470-490 	3
10	Никольский	Илья	Маратович	89659108693	М 	Высшее	1981-04-18	Саратов ул. Московская 47 кв. 83	5556738565169940	186865221	выдан ГУ МВД России по г. Омску к/п 161-415 	1
11	Симонова	Ольга	Кирилловна	89920490484	Ж 	Высшее	1997-06-05	Уфа ул. Горная 40 кв. 80	7279430344754400	4741600447	выдан ГУ МВД России по г. Москве к/п 066-672 	5
12	Колесов	Максим	Фёдорович	89696279182	М 	Высшее	1971-05-13	Ижевск ул. Строителей 8 кв. 97	6584764333436830	8354370929	выдан ГУ МВД России по г. Самаре к/п 992-397 	11
13	Петрова	Екатерина	Михайловна	89231390464	Ж 	Высшее	1999-08-27	Москва ул. Овражная 22 кв. 73	8105633614681960	4668536709	выдан ГУ МВД России по г. Волгограду к/п 554-872 	1
14	Овчинников	Артём	Елисеевич	89207611534	М 	Высшее	1995-07-25	Тольятти ул. Юбилейная 40 кв. 94	9909715137979330	9919547776	выдан ГУ МВД России по г. Краснодару к/п 565-913 	8
15	Денисова	Арина	Александровна	89211072491	Ж 	Среднее	1996-10-18	Ростов-на-Дону ул. Маяковского 41 кв. 94	2280539337969250	3456926093	выдан ГУ МВД России по г. Тюмени к/п 745-392 	11
16	Шапошников	Максим	Вадимович	89832111014	М 	Среднее	1974-03-29	Уфа ул. Чехова 35 кв. 57	9923340104383870	4752789975	выдан ГУ МВД России по г. Воронежу к/п 798-966 	4
17	Нечаева	Анна	Матвеевна	89323772375	Ж 	Среднее	1978-11-03	Екатеринбург ул. Советская 17 кв. 64	8475183166263240	683824380	выдан ГУ МВД России по г. Санкт-Петербургу к/п 604-275 	7
18	Чернышев	Матвей	Романович	89708630138	М 	Среднее	2001-10-20	Тольятти ул. Вишневая 38 кв. 48	6101024819167750	8589670471	выдан ГУ МВД России по г. Волгограду к/п 203-540 	9
19	Матвеев	Александр	Леонидович	89789713073	Ж 	Среднее	1991-09-08	Новосибирск ул. Свободы 35 кв. 12	1335566497686150	33212533	выдан ГУ МВД России по г. Тольятти к/п 727-611 	4
20	Сухова	Стефания	Глебовна	89872961079	Ж 	Высшее	1973-08-03	Волгоград ул. Береговая 3 кв. 80	3251358986388360	1891100380	выдан ГУ МВД России по г. Новосибирску к/п 800-744 	13
21	Фадеева	Ульяна	Георгиевна	89708294005	Ж 	Среднее	1983-05-23	Екатеринбург ул. Больничная 48 кв. 83	4314315991453570	7029714037	выдан ГУ МВД России по г. Новосибирску к/п 819-505 	7
22	Малинин	Дмитрий	Михайлович	89899296245	М 	Высшее	1980-06-04	Краснодар ул. Победы 26 кв. 60	9104381520777200	782763770	выдан ГУ МВД России по г. Казани к/п 161-742 	1
23	Николаева	Мирослава	Тимуровна	89588699337	М 	Высшее	1993-01-07	Омск ул. Майская 40 кв. 6	8434689153782570	58269624	выдан ГУ МВД России по г. Воронежу к/п 126-969 	6
24	Давыдова	Софья	Романовна	89672454800	Ж 	Высшее	1994-12-10	Новосибирск ул. Лесная 10 кв. 57	5253786110544250	5696780539	выдан ГУ МВД России по г. Нижнему Новгороду к/п 	5
25	Лебедева	Виктория	Артёмовна	89234146369	Ж 	Высшее	1995-12-14	Санкт-Петербург ул. Строительная 12 кв. 47	7982880408377940	6618253858	выдан ГУ МВД России по г. Челябинску к/п 282-248 	5
26	Акимова	Арина	Егоровна	89629129437	Ж 	Среднее	1971-12-15	Самара ул. Пролетарская 25 кв. 26	9777962676185720	5161731832	выдан ГУ МВД России по г. Тюмени к/п 462-252 	2
27	Голикова	Милана	Егоровна	89369746956	Ж 	Высшее	1998-10-03	Екатеринбург ул. Совхозная 33 кв. 65	4141508149460630	382340457	выдан ГУ МВД России по г. Челябинску к/п 994-274 	12
28	Никулин	Роман	Андреевич	89896887860	М 	Высшее	2001-09-25	Волгоград ул. Дачная 2 кв. 15	9463915929426520	7590298369	выдан ГУ МВД России по г. Самаре к/п 090-824 	6
29	Ефимова	Айша	Саввична	89830424952	Ж 	Высшее	1975-01-01	Уфа ул. Интернациональная 40 кв. 66	3202849520537550	75795776	выдан ГУ МВД России по г. Ижевску к/п 953-060 	7
30	Троицкий	Роман	Александрович	89005159324	М 	Высшее	1982-06-16	Челябинск ул. Светлая 38 кв. 31	1805056028794390	239401251	выдан ГУ МВД России по г. Москве к/п 452-495 	4
31	Иванова	Полина	Марсельевна	89279662898	Ж 	Среднее	2002-03-15	Челябинск ул. Некрасова 50 кв. 46	2407771756304120	157163308	выдан ГУ МВД России по г. Красноярску к/п 610-932 	11
32	Моргунова	Елизавета	Ивановна	89034480223	Ж 	Высшее	1985-10-06	Саратов ул. Майская 49 кв. 52	2197994531448550	5391591095	выдан ГУ МВД России по г. Ижевску к/п 378-445 	7
33	Ульянов	Артемий	Михайлович	89532072580	М 	Высшее	1980-07-11	Новосибирск ул. Красноармейская 1 кв. 77	2122536024839490	665310410	выдан ГУ МВД России по г. Челябинску к/п 775-981 	10
34	Сазонова	Анна	Артемьевна	89835872571	Ж 	Среднее	1999-07-28	Волгоград ул. Колхозная 40 кв. 29	8505955271413140	6999756331	выдан ГУ МВД России по г. Нижнему Новгороду к/п 	13
35	Алексеева	Анастасия	Андреевна	89716553918	Ж 	Высшее	1981-08-13	Новосибирск ул. Горького 4 кв. 65	9762976253069780	924789284	выдан ГУ МВД России по г. Санкт-Петербургу к/п 625-201 	6
36	Кузьмина	Диана	Марковна	89095860991	Ж 	Высшее	1993-10-26	Саратов ул. Набережная 22 кв. 26	6585535984470520	3870377477	выдан ГУ МВД России по г. Краснодару к/п 509-204 	2
37	Назарова	Алиса	Матвеевна	89349598712	Ж 	Высшее	2001-02-19	Челябинск ул. Совхозная 8 кв. 71	5317793294351750	375605583	выдан ГУ МВД России по г. Москве к/п 122-797 	5
38	Казакова	Варвара	Матвеевна	89086025257	Ж 	Среднее	1971-06-08	Екатеринбург ул. Нагорная 5 кв. 37	6136358432708870	1833676447	выдан ГУ МВД России по г. Тюмени к/п 671-744 	7
39	Дмитриев	Александр	Алексеевич	89697418231	М 	Высшее	1996-09-06	Красноярск ул. Комсомольская 25 кв. 30	8217588699936400	8358435047	выдан ГУ МВД России по г. Челябинску к/п 056-959 	9
40	Соловьева	Алиса	Артёмовна	89893836538	Ж 	Высшее	1982-03-05	Саратов ул. Интернациональная 28 кв. 26	9143502680978070	1658150226	выдан ГУ МВД России по г. Омску к/п 482-124 	9
41	Терентьев	Виктор	Глебович	89387306839	М 	Высшее	1980-08-27	Красноярск ул. Зеленая 18 кв. 43	1842867063003030	799669014	выдан ГУ МВД России по г. Омску к/п 190-054 	10
42	Константинова	Злата	Артемьевна	89549815243	Ж 	Высшее	1975-09-21	Казань ул. Строителей 26 кв. 37	1679551019009020	9794199618	выдан ГУ МВД России по г. Челябинску к/п 078-878 	7
43	Терехова	Мария	Савельевна	89950254698	Ж 	Высшее	1996-05-18	Красноярск ул. Центральная 45 кв. 32	9654169320008200	183103380	выдан ГУ МВД России по г. Уфе к/п 873-534 	3
44	Сорокин	Макар	Евгеньевич	89964452238	М 	Среднее	1982-12-08	Уфа ул. Чкалова 37 кв. 3	3891031504240370	1265397694	выдан ГУ МВД России по г. Казани к/п 293-625 	9
45	Назарова	Ульяна	Артёмовна	89534134735	Ж 	Среднее	1998-01-10	Москва ул. Клубная 24 кв. 21	4444296702887020	8291918255	выдан ГУ МВД России по г. Волгограду к/п 931-239 	5
46	Горбачева	Таисия	Демидовна	89016849762	Ж 	Среднее	1973-06-19	Красноярск ул. Березовая 12 кв. 29	8524395456628580	6318950447	выдан ГУ МВД России по г. Санкт-Петербургу к/п 772-411 	11
47	Беляева	Арина	Кирилловна	89518083497	Ж 	Среднее	1984-11-04	Казань ул. Колхозная 21 кв. 56	9876475069126400	4756913852	выдан ГУ МВД России по Пермскому краю к/п 141-057 	6
48	Блинова	Алиса	Вадимовна	89125971229	Ж 	Высшее	1988-05-15	Челябинск ул. Спортивная 13 кв. 16	3813776225782970	84765162	выдан ГУ МВД России по г. Новосибирску к/п 018-339 	2
49	Новиков	Владимир	Павлович	89419229305	М 	Среднее	1996-05-05	Уфа ул. Овражная 49 кв. 62	6954145338182600	8910449985	выдан ГУ МВД России по г. Москве к/п 494-570 	9
50	Матвеева	Дарина	Максимовна	89849414061	Ж 	Среднее	1979-02-17	Красноярск ул. Дорожная 9 кв. 54	2949470712550230	8517237540	выдан ГУ МВД России по г. Омску к/п 842-831 	9
\.


--
-- TOC entry 5085 (class 0 OID 16469)
-- Dependencies: 232
-- Data for Name: сотрудники_в_рейсах; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."сотрудники_в_рейсах" ("код_сотрудника", "код_рейса") FROM stdin;
1	1
3	4
4	2
10	2
10	4
13	3
14	1
20	1
23	2
23	5
28	2
30	4
33	4
35	3
38	5
38	13
42	1
46	4
46	15
47	3
\.


--
-- TOC entry 5086 (class 0 OID 16472)
-- Dependencies: 233
-- Data for Name: станции; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."станции" ("код", "название", "регион", "населенный_пункт", "адрес", "телефон_станции") FROM stdin;
1	Санкт-Петербург Ладожский вокзал	Санкт-Петербург	г. Санкт-Петербург	Заневский пр. 73	88007750000
2	Санкт-Петербург Московский вокзал	Санкт-Петербург	г. Санкт-Петербург	Невский пр. 85	88007750000
3	Волховстрой-1	Ленинградская область	г. Волхов	Привокзальная пл. 1	88007750000
4	Тихвин	Ленинградская область	г. Тихвин	Привокзальная пл. 1	88007750000
5	Бологое-Московское	Тверская область	г. Бологое	Привокзальная ул. 5	88007750000
6	Вышний Волочёк	Тверская область	г. Вышний Волочёк	Казанский пр. 124	88007750000
7	Тверь	Тверская область	г. Тверь	ул. Коминтерна 18	88007750000
8	Окуловка	Новгородская область	г. Окуловка	ул. Ленина 43	88007750000
9	Малая Вишера	Новгородская область	г. Малая Вишера	ул. Революции 20	88007750000
10	Спирово	Тверская область	п. Спирово	пер. Советский 8	88007750000
11	Лихославль	Тверская область	г. Лихославль	Советская ул. 39	88007750000
12	Москва Восточный вокзал	Москва	г. Москва	Щелковское ш. 1 стр.5	88007750000
13	Владимир	Владимирская область	г. Владимир	ул. Вокзальная 2	88007750000
14	Бабаево	Вологодская область	г. Бабаево	Привокзальная пл. 1	88007750000
15	Череповец-1	Вологодская область	г. Череповец	Завокзальная ул. 9	88007750000
16	Заборье	Ленинградская область	п. Заборье	Вокзальная ул. 5	88007750000
17	Ковров-1	Владимирская область	г. Ковров	Октябрьская ул. 10	88007750000
18	Дзержинск	Нижегородская область	г. Дзержинск	ул. Привокзальная 1	88007750000
19	Вязники	Владимирская область	г. Вязники	ул. Привокзальная 1Б	88007750000
20	Чебсара	Вологодская область	п. Чебсара	ул. Мира 1-а	88007750000
21	Кипелово	Вологодская область	п. Кипелово	Железнодорожная ул. 7	88007750000
22	 Вокзал Вологда	Вологодская область	г. Вологда	пл. Бабушкина 5	88007750000
23	Шексна	Вологодская область	п. Шексна	ул. Нагорная 6	88007750000
24	Кадуй	Вологодская область	п. Кадуй	ул. Железнодорожная 1	88007750000
25	Ефимовская	Ленинградская область	п. Ефимовский	ул. Привокзальная 11	88007750000
26	Пикалёво-1	Ленинградская область	г. Пикалево	ж/д вокзал Пикалево	88007750000
27	Подборовье	Ленинградская область	п. Подборовье	ул. Железнодорожная 27	88007750000
28	Суда	Вологодская область	п. Суда	Советская ул. 12	88007750000
29	Буй	Костромская область	г. Буй	Привокзальная пл. 1	88007750000
30	Галич	Костромская область	г. Галич	ул. Касаткиной 10	88007750000
31	Антропово	Костромская область	п. Антропово	ул. Белоусова 25	88007750000
32	Николо-Полома	Костромская область	п. Николо-Полома	ул. Вокзальная 18	88007750000
33	Нея	Костромская область	г. Нея	ул. Советская 31	88007750000
34	Брантовка	Костромская область	п. Октябрьский	ст. Брантовка	88007750000
35	Мантурово	Костромская область	г. Мантурово	ул. Вокзальная 65	88007750000
36	Шарья	Костромская область	г. Шарья	ул. Вокзальная 27	88007750000
\.


--
-- TOC entry 5087 (class 0 OID 16475)
-- Dependencies: 234
-- Data for Name: типы_вагонов; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."типы_вагонов" ("код", "название_типа", "описание") FROM stdin;
1	Спальный вагон (СВ)	Железнодорожный вагон, предназначенный для размещения пассажиров при их перевозке с обеспечением необходимых удобств в составе 
2	Плацкартный вагон	Обычный плацкартный вагон состоит из 9 открытых купе по 6 мест в каждом, всего 54 места (лежащих спальных мест в вагонах в составе поездов дальнего следования)
3	Купейный вагон	Купе (вагон второго класса) — один из типов пассажирских вагонов. 
4	Почтовый вагон	Железнодорожный вагон, специально предназначенный для перевозки почтовых отправлений, их обработки в пути и обмена в пунктах остановки.
5	Вагон-ресторан	Железнодорожный вагон, предназначенный для обеспечения пассажиров горячим питанием, безалкогольными и алкогольными напитками в пути следования
6	Двухэтажный вагон	Вагон, в котором для увеличения пассажировместимости устроены два салона для пассажиров, один над другим. Двухэтажные вагоны применяются как в поездах локомотивной тяги, так и в моторвагонных поездах (электро и реже дизель-поездах).
\.


--
-- TOC entry 5091 (class 0 OID 16651)
-- Dependencies: 238
-- Data for Name: услуги; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."услуги" ("код", "услуга", "цена", "дополнительная_информация") FROM stdin;
1	Страхование на время поездки	400.00	Застраховать жизнь и здоровье от несчастных случаев во время поездки
2	100% возврат билета по любой причине	412.00	На вашу карту вернется сумма, заплаченная за билет. Онлайн-возврат можно сделать не позднее чем за 1 час до начала поездки
3	Бесплатное СМС с напоминанием о поездке	0.00	\N
\.


--
-- TOC entry 4841 (class 2606 OID 16485)
-- Name: билеты билеты_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."билеты"
    ADD CONSTRAINT "билеты_pk" PRIMARY KEY ("код");


--
-- TOC entry 4843 (class 2606 OID 16487)
-- Name: вагоны вагоны_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."вагоны"
    ADD CONSTRAINT "вагоны_pk" PRIMARY KEY ("номер_вагона");


--
-- TOC entry 4845 (class 2606 OID 16491)
-- Name: вагоны_в_составах вагоны_в_составах_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."вагоны_в_составах"
    ADD CONSTRAINT "вагоны_в_составах_pk" PRIMARY KEY ("код_вагона", "код_состава");


--
-- TOC entry 4847 (class 2606 OID 16497)
-- Name: должности должности_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."должности"
    ADD CONSTRAINT "должности_pk" PRIMARY KEY ("код");


--
-- TOC entry 4849 (class 2606 OID 16493)
-- Name: должности должности_un; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."должности"
    ADD CONSTRAINT "должности_un" UNIQUE ("наименование_должности");


--
-- TOC entry 4887 (class 2606 OID 16545)
-- Name: карты карты_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."карты"
    ADD CONSTRAINT "карты_pk" PRIMARY KEY ("код");


--
-- TOC entry 4889 (class 2606 OID 16550)
-- Name: карты_пользователей карты_пользователей_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."карты_пользователей"
    ADD CONSTRAINT "карты_пользователей_pk" PRIMARY KEY ("код_пользователя", "код_карты");


--
-- TOC entry 4851 (class 2606 OID 16499)
-- Name: категории_пассажиров категории_пассажиров_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."категории_пассажиров"
    ADD CONSTRAINT "категории_пассажиров_pk" PRIMARY KEY ("код_категории");


--
-- TOC entry 4897 (class 2606 OID 16824)
-- Name: ключи ключи_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ключи"
    ADD CONSTRAINT "ключи_pk" PRIMARY KEY ("код");


--
-- TOC entry 4853 (class 2606 OID 16501)
-- Name: компании_отправители компании_отправители_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."компании_отправители"
    ADD CONSTRAINT "компании_отправители_pk" PRIMARY KEY ("код_компании");


--
-- TOC entry 4855 (class 2606 OID 16505)
-- Name: медицинские_осмотры медицинские_осмотры_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."медицинские_осмотры"
    ADD CONSTRAINT "медицинские_осмотры_pk" PRIMARY KEY ("код_осмотра");


--
-- TOC entry 4857 (class 2606 OID 16507)
-- Name: места места_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."места"
    ADD CONSTRAINT "места_pk" PRIMARY KEY ("код");


--
-- TOC entry 4859 (class 2606 OID 16509)
-- Name: осмотры_сотрудников осмотры_сотрудников_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."осмотры_сотрудников"
    ADD CONSTRAINT "осмотры_сотрудников_pk" PRIMARY KEY ("код_сотрудника", "код_осмотра");


--
-- TOC entry 4861 (class 2606 OID 16511)
-- Name: остановки_в_рейсах остановки_в_рейсах_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."остановки_в_рейсах"
    ADD CONSTRAINT "остановки_в_рейсах_pk" PRIMARY KEY ("код");


--
-- TOC entry 4863 (class 2606 OID 16513)
-- Name: отзывы отзывы_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."отзывы"
    ADD CONSTRAINT "отзывы_pk" PRIMARY KEY ("код");


--
-- TOC entry 4865 (class 2606 OID 16517)
-- Name: пассажиры пассажиры_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пассажиры"
    ADD CONSTRAINT "пассажиры_pk" PRIMARY KEY ("код");


--
-- TOC entry 4867 (class 2606 OID 16521)
-- Name: покупка_билетов покупка_билетов_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_билетов"
    ADD CONSTRAINT "покупка_билетов_pk" PRIMARY KEY ("код");


--
-- TOC entry 4893 (class 2606 OID 16663)
-- Name: покупка_услуги покупка_услуги_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_услуги"
    ADD CONSTRAINT "покупка_услуги_pk" PRIMARY KEY ("код_покупки", "код_услуги");


--
-- TOC entry 4883 (class 2606 OID 16539)
-- Name: пользователи пользователи_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пользователи"
    ADD CONSTRAINT "пользователи_pk" PRIMARY KEY ("код");


--
-- TOC entry 4885 (class 2606 OID 16541)
-- Name: пользователи пользователи_un; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пользователи"
    ADD CONSTRAINT "пользователи_un" UNIQUE ("логин", "эл_почта");


--
-- TOC entry 4895 (class 2606 OID 16738)
-- Name: пользователи_покупки пользователи_покупки_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пользователи_покупки"
    ADD CONSTRAINT "пользователи_покупки_pk" PRIMARY KEY ("код_пользователя", "код_покупки");


--
-- TOC entry 4869 (class 2606 OID 16523)
-- Name: рейсы рейсы_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."рейсы"
    ADD CONSTRAINT "рейсы_pk" PRIMARY KEY ("код");


--
-- TOC entry 4871 (class 2606 OID 16525)
-- Name: составы составы_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."составы"
    ADD CONSTRAINT "составы_pk" PRIMARY KEY ("код_состава");


--
-- TOC entry 4873 (class 2606 OID 16527)
-- Name: сотрудники сотрудники_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сотрудники"
    ADD CONSTRAINT "сотрудники_pk" PRIMARY KEY ("код");


--
-- TOC entry 4875 (class 2606 OID 16531)
-- Name: сотрудники_в_рейсах сотрудники_в_рейсах_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сотрудники_в_рейсах"
    ADD CONSTRAINT "сотрудники_в_рейсах_pk" PRIMARY KEY ("код_сотрудника", "код_рейса");


--
-- TOC entry 4877 (class 2606 OID 16533)
-- Name: станции станции_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."станции"
    ADD CONSTRAINT "станции_pk" PRIMARY KEY ("код");


--
-- TOC entry 4879 (class 2606 OID 16535)
-- Name: типы_вагонов типы_вагонов_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."типы_вагонов"
    ADD CONSTRAINT "типы_вагонов_pk" PRIMARY KEY ("код");


--
-- TOC entry 4881 (class 2606 OID 16537)
-- Name: типы_вагонов типы_вагонов_un; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."типы_вагонов"
    ADD CONSTRAINT "типы_вагонов_un" UNIQUE ("название_типа");


--
-- TOC entry 4891 (class 2606 OID 16657)
-- Name: услуги услуги_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."услуги"
    ADD CONSTRAINT "услуги_pk" PRIMARY KEY ("код");


--
-- TOC entry 4924 (class 2620 OID 16749)
-- Name: покупка_билетов cancel_ticket_status_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER cancel_ticket_status_trigger AFTER DELETE ON public."покупка_билетов" FOR EACH ROW EXECUTE FUNCTION public.cancel_ticket_status();


--
-- TOC entry 4925 (class 2620 OID 16747)
-- Name: покупка_билетов update_ticket_status_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_ticket_status_trigger AFTER INSERT ON public."покупка_билетов" FOR EACH ROW EXECUTE FUNCTION public.update_ticket_status();


--
-- TOC entry 4923 (class 2620 OID 16753)
-- Name: вагоны_в_составах update_wagon_status_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_wagon_status_trigger AFTER INSERT OR DELETE ON public."вагоны_в_составах" FOR EACH ROW EXECUTE FUNCTION public.update_wagon_status();


--
-- TOC entry 4898 (class 2606 OID 16561)
-- Name: билеты билеты_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."билеты"
    ADD CONSTRAINT "билеты_fk" FOREIGN KEY ("код_места") REFERENCES public."места"("код");


--
-- TOC entry 4899 (class 2606 OID 16674)
-- Name: вагоны вагоны_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."вагоны"
    ADD CONSTRAINT "вагоны_fk" FOREIGN KEY ("код_типа_вагона") REFERENCES public."типы_вагонов"("код");


--
-- TOC entry 4900 (class 2606 OID 16566)
-- Name: вагоны_в_составах вагоны_в_составах_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."вагоны_в_составах"
    ADD CONSTRAINT "вагоны_в_составах_fk" FOREIGN KEY ("код_вагона") REFERENCES public."вагоны"("номер_вагона");


--
-- TOC entry 4901 (class 2606 OID 16571)
-- Name: вагоны_в_составах вагоны_в_составах_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."вагоны_в_составах"
    ADD CONSTRAINT "вагоны_в_составах_fk_1" FOREIGN KEY ("код_состава") REFERENCES public."составы"("код_состава");


--
-- TOC entry 4917 (class 2606 OID 16551)
-- Name: карты_пользователей карты_пользователей_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."карты_пользователей"
    ADD CONSTRAINT "карты_пользователей_fk" FOREIGN KEY ("код_пользователя") REFERENCES public."пользователи"("код");


--
-- TOC entry 4918 (class 2606 OID 16556)
-- Name: карты_пользователей карты_пользователей_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."карты_пользователей"
    ADD CONSTRAINT "карты_пользователей_fk_1" FOREIGN KEY ("код_карты") REFERENCES public."карты"("код");


--
-- TOC entry 4902 (class 2606 OID 16576)
-- Name: места места_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."места"
    ADD CONSTRAINT "места_fk" FOREIGN KEY ("номер_вагона") REFERENCES public."вагоны"("номер_вагона");


--
-- TOC entry 4903 (class 2606 OID 16581)
-- Name: осмотры_сотрудников осмотры_сотрудников_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."осмотры_сотрудников"
    ADD CONSTRAINT "осмотры_сотрудников_fk" FOREIGN KEY ("код_сотрудника") REFERENCES public."сотрудники"("код");


--
-- TOC entry 4904 (class 2606 OID 16586)
-- Name: осмотры_сотрудников осмотры_сотрудников_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."осмотры_сотрудников"
    ADD CONSTRAINT "осмотры_сотрудников_fk_1" FOREIGN KEY ("код_осмотра") REFERENCES public."медицинские_осмотры"("код_осмотра");


--
-- TOC entry 4905 (class 2606 OID 16591)
-- Name: остановки_в_рейсах остановки_в_рейсах_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."остановки_в_рейсах"
    ADD CONSTRAINT "остановки_в_рейсах_fk" FOREIGN KEY ("код_станции") REFERENCES public."станции"("код");


--
-- TOC entry 4906 (class 2606 OID 16596)
-- Name: остановки_в_рейсах остановки_в_рейсах_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."остановки_в_рейсах"
    ADD CONSTRAINT "остановки_в_рейсах_fk_1" FOREIGN KEY ("код_рейса") REFERENCES public."рейсы"("код");


--
-- TOC entry 4907 (class 2606 OID 16601)
-- Name: отзывы отзывы_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."отзывы"
    ADD CONSTRAINT "отзывы_fk" FOREIGN KEY ("код_пассажира") REFERENCES public."пассажиры"("код");


--
-- TOC entry 4908 (class 2606 OID 16606)
-- Name: отзывы отзывы_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."отзывы"
    ADD CONSTRAINT "отзывы_fk_1" FOREIGN KEY ("код_рейса") REFERENCES public."рейсы"("код");


--
-- TOC entry 4909 (class 2606 OID 16611)
-- Name: пассажиры пассажиры_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пассажиры"
    ADD CONSTRAINT "пассажиры_fk" FOREIGN KEY ("код_категории_пассажира") REFERENCES public."категории_пассажиров"("код_категории");


--
-- TOC entry 4910 (class 2606 OID 16616)
-- Name: покупка_билетов покупка_билетов_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_билетов"
    ADD CONSTRAINT "покупка_билетов_fk" FOREIGN KEY ("код_билета") REFERENCES public."билеты"("код");


--
-- TOC entry 4911 (class 2606 OID 16621)
-- Name: покупка_билетов покупка_билетов_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_билетов"
    ADD CONSTRAINT "покупка_билетов_fk_1" FOREIGN KEY ("код_пассажира") REFERENCES public."пассажиры"("код");


--
-- TOC entry 4919 (class 2606 OID 16664)
-- Name: покупка_услуги покупка_услуги_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_услуги"
    ADD CONSTRAINT "покупка_услуги_fk" FOREIGN KEY ("код_покупки") REFERENCES public."покупка_билетов"("код");


--
-- TOC entry 4920 (class 2606 OID 16669)
-- Name: покупка_услуги покупка_услуги_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."покупка_услуги"
    ADD CONSTRAINT "покупка_услуги_fk_1" FOREIGN KEY ("код_услуги") REFERENCES public."услуги"("код");


--
-- TOC entry 4921 (class 2606 OID 16727)
-- Name: пользователи_покупки пользователи_покупки_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пользователи_покупки"
    ADD CONSTRAINT "пользователи_покупки_fk" FOREIGN KEY ("код_пользователя") REFERENCES public."пользователи"("код");


--
-- TOC entry 4922 (class 2606 OID 16732)
-- Name: пользователи_покупки пользователи_покупки_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."пользователи_покупки"
    ADD CONSTRAINT "пользователи_покупки_fk_1" FOREIGN KEY ("код_покупки") REFERENCES public."покупка_билетов"("код");


--
-- TOC entry 4912 (class 2606 OID 16626)
-- Name: рейсы рейсы_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."рейсы"
    ADD CONSTRAINT "рейсы_fk" FOREIGN KEY ("код_состава") REFERENCES public."составы"("код_состава");


--
-- TOC entry 4913 (class 2606 OID 16631)
-- Name: составы составы_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."составы"
    ADD CONSTRAINT "составы_fk" FOREIGN KEY ("код_компании_отправителя") REFERENCES public."компании_отправители"("код_компании");


--
-- TOC entry 4914 (class 2606 OID 16646)
-- Name: сотрудники сотрудники_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сотрудники"
    ADD CONSTRAINT "сотрудники_fk" FOREIGN KEY ("код_должности") REFERENCES public."должности"("код");


--
-- TOC entry 4915 (class 2606 OID 16636)
-- Name: сотрудники_в_рейсах сотрудники_в_рейсах_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сотрудники_в_рейсах"
    ADD CONSTRAINT "сотрудники_в_рейсах_fk" FOREIGN KEY ("код_сотрудника") REFERENCES public."сотрудники"("код");


--
-- TOC entry 4916 (class 2606 OID 16641)
-- Name: сотрудники_в_рейсах сотрудники_в_рейсах_fk_1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."сотрудники_в_рейсах"
    ADD CONSTRAINT "сотрудники_в_рейсах_fk_1" FOREIGN KEY ("код_рейса") REFERENCES public."рейсы"("код");


-- Completed on 2025-10-08 17:32:32

--
-- PostgreSQL database dump complete
--

