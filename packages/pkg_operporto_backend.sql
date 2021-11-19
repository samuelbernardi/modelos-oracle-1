create or replace package body                     pkg_schedule_backend is

function fnc_get_mime_type
(p_extensao in varchar2
) return varchar2
as
v_result varchar2(240);
begin
   select crc.rv_meaning
     into v_result
     from recinto.v$cg_ref_codes crc
    where crc.rv_domain = 'ARQUIVO.MIME_TYPE'
      and crc.rv_low_value = upper(p_extensao);
   return v_result;
exception
   when no_data_found then
      raise_application_error(-20000, 'Extens?o '||p_extensao||' n?o permitida.');
   when others then
      raise;
end;

function fnc_get_tipo_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_low_value    integer       path '/params/tipo_low_value'
                 , tipo_abbreviation varchar2(240) path '/params/tipo_abbreviation'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("tipo_etiqueta",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("tipo_low_value",    xmlattributes(''number'' as "type"), numbertojson(x.tipo_low_value)),
                      xmlelement("tipo_abbreviation", xmlattributes(''string'' as "type"), stringtojson(x.tipo_abbreviation))
                   )
                )
             )
        from (
      select crc.rv_domain
           , crc.rv_low_value as tipo_low_value
           , crc.rv_abbreviation as tipo_abbreviation
        from operporto.v$cg_ref_codes crc
       where crc.rv_domain = ''ETIQUETA.TIPO_ID''
           ) x
       where 1=1');

      if trim(i.tipo_low_value) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_low_value = '||i.tipo_low_value);
      end if;

      if trim(i.tipo_abbreviation) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.tipo_abbreviation)) like upper(kss.pkg_string.fnc_string_clean('''||i.tipo_abbreviation||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_fil_berco
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('berco_id',  'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',  'Descricao', '', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getBerco'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_berco;

function fnc_col_berco
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('berco_id'   ,'Budget (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_string('descricao'  ,'Descricao'),
                kss.pkg_cols_devextreme.fnc_col_number('loa'        ,'LOA', 0),
                kss.pkg_cols_devextreme.fnc_col_number('calado'     ,'Calado'),
                kss.pkg_cols_devextreme.fnc_col_number('beam'       ,'Beam'),
                kss.pkg_cols_devextreme.fnc_col_number('dwt'        ,'Dwt'),
                kss.pkg_cols_devextreme.fnc_col_html('cod_porto'    ,'Cod. Porto'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao' ,'Observa??o'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_berco;

function fnc_get_berco
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id  integer       path '/params/berco_id'
                 , descricao varchar2(100) path '/params/descricao'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                  xmlattributes(''object'' as "type"),
                  xmlconcat(
                     xmlelement("header",
                        xmlattributes(''object'' as "type"),
                        xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''berco'')),
                        operporto.pkg_schedule_backend.fnc_col_berco(),
                        operporto.pkg_schedule_backend.fnc_fil_berco()
                  ),
                  xmlelement("berco",
                  xmlattributes(''array'' as "type"),
                  xmlagg(
                     xmlelement("arrayItem",
                        xmlattributes(''object'' as "type"),
                        xmlelement("berco_id",    xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                        xmlelement("descricao",   xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                        xmlelement("loa",         xmlattributes(''number'' as "type"), numbertojson(x.loa)),
                        xmlelement("calado",      xmlattributes(''number'' as "type"), numbertojson(x.calado)),
                        xmlelement("beam",        xmlattributes(''number'' as "type"), numbertojson(x.beam)),
                        xmlelement("dwt",         xmlattributes(''number'' as "type"), numbertojson(x.dwt)),
                        xmlelement("cod_porto",   xmlattributes(''string'' as "type"), stringtojson(x.cod_porto)),
                        xmlelement("observacao",  xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                        xmlelement("cod_porto",   xmlattributes(''string'' as "type"), stringtojson(x.cod_porto)),
                        xmlelement("user_insert", xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                        xmlelement("date_insert", xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                        xmlelement("user_update", xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                        xmlelement("date_update", xmlattributes(''string'' as "type"), datetojson(x.date_update))
                         )
                      )
                   )
                )
             )
        from (
      select b.berco_id
           , b.descricao
           , b.loa
           , b.calado
           , b.beam
           , b.dwt
           , b.cod_porto
           , b.observacao
           , b.user_insert
           , b.date_insert
           , b.user_update
           , b.date_update
        from  operporto.v$berco b
           ) x
       where 1=1');

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_berco
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation  varchar2(30)  path '/params/operation'
                 , berco_id   integer       path '/params/berco_id'
                 , descricao  varchar2(60)  path '/params/descricao'
                 , loa        number(*,2)   path '/params/loa'
                 , calado     number(*,2)   path '/params/calado'
                 , beam       number(*,2)   path '/params/beam'
                 , dwt        number(*,2)   path '/params/dwt'
                 , cod_porto  varchar2(100) path '/params/cod_porto'
                 , observacao varchar2(500) path '/params/observacao'
                 )
   ) loop
      v_id := i.berco_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_operporto.prc_ins_berco(p_berco_id   => v_id
                                                 ,p_descricao  => i.descricao
                                                 ,p_loa        => i.loa
                                                 ,p_calado     => i.calado
                                                 ,p_beam       => i.beam
                                                 ,p_dwt        => i.dwt
                                                 ,p_cod_porto  => i.cod_porto
                                                 ,p_observacao => i.observacao
                                                 );
            v_msg := 'Berco inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_operporto.prc_alt_berco(p_berco_id   => i.berco_id
                                                 ,p_descricao  => i.descricao
                                                 ,p_loa        => i.loa
                                                 ,p_calado     => i.calado
                                                 ,p_beam       => i.beam
                                                 ,p_dwt        => i.dwt
                                                 ,p_cod_porto  => i.cod_porto
                                                 ,p_observacao => i.observacao
                                                 ,p_msg        => v_msg
                                                  );

            if v_msg is null then
               v_msg := 'Berco alterado com sucesso.';
            end if;   

          when 'DELETE' then
             operporto.pkg_operporto.prc_del_berco(p_berco_id => i.berco_id
                                                  );
            v_msg := 'Berco excluido com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("berco_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_berco;

function fnc_get_prog_status
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   status_low_value    integer       path '/params/status_low_value'
                 , status_abbreviation varchar2(240) path '/params/status_abbreviation'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("status",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("status_low_value",    xmlattributes(''number'' as "type"), numbertojson(x.status_id)),
                      xmlelement("status_abbreviation", xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select crc.rv_domain
           , crc.rv_low_value as status_id
           , crc.rv_abbreviation as descricao
        from operporto.v$cg_ref_codes crc
       where crc.rv_domain = ''PROGRAMACAO.STATUS_ID''
           ) x
       where 1=1');

      if trim(i.status_low_value) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id = '||i.status_low_value);
      end if;

      if trim(i.status_abbreviation) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.status_abbreviation||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_prog_etapa
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etapa_low_value    integer       path '/params/etapa_low_value'
                 , etapa_abbreviation varchar2(240) path '/params/etapa_abbreviation'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("etapa",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("etapa_low_value",    xmlattributes(''number'' as "type"), numbertojson(x.etapa_id)),
                      xmlelement("etapa_abbreviation", xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select crc.rv_domain
           , crc.rv_low_value as etapa_id
           , crc.rv_abbreviation as descricao
        from operporto.v$cg_ref_codes crc
       where crc.rv_domain = ''PROGRAMACAO.ETAPA_ID''
           ) x
       where 1=1');

      if trim(i.etapa_low_value) is not null then
         dbms_lob.append(v_sql, '
         and x.etapa_id = '||i.etapa_low_value);
      end if;

      if trim(i.etapa_abbreviation) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.etapa_abbreviation||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_embarc_status
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   status_low_value    integer       path '/params/status_low_value'
                 , status_abbreviation varchar2(240) path '/params/status_abbreviation'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("status",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("status_low_value",    xmlattributes(''number'' as "type"), numbertojson(x.status_low_value)),
                      xmlelement("status_abbreviation", xmlattributes(''string'' as "type"), stringtojson(x.status_abbreviation))
                   )
                )
             )
        from (
      select crc.rv_domain
           , crc.rv_low_value as status_low_value
           , crc.rv_abbreviation as status_abbreviation
        from  operporto.v$cg_ref_codes crc
       where crc.rv_domain = ''EMBARCACAO.STATUS_ID''
           ) x
       where 1=1');

      if trim(i.status_low_value) is not null then
         dbms_lob.append(v_sql, '
         and x.status_low_value = '||i.status_low_value);
      end if;

      if trim(i.status_abbreviation) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.status_abbreviation)) like upper(kss.pkg_string.fnc_string_clean('''||i.status_abbreviation||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_pais
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   pais_id   integer      path '/params/pais_id'
                 , pais_nome varchar2(60) path '/params/pais_nome'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("pais",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("pais_id",   xmlattributes(''number'' as "type"), numbertojson(x.pais_id)),
                      xmlelement("pais_nome", xmlattributes(''string'' as "type"), stringtojson(x.pais_nome))
                   )
                )
             )
        from (
      select p.pais_id
           , p.descricao_portugues as pais_nome
        from cep.v$pais p

           ) x
       where 1=1');

      if trim(i.pais_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_id = '||i.pais_id);
      end if;

      if trim(i.pais_nome) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.pais_nome)) like upper(kss.pkg_string.fnc_string_clean('''||i.pais_nome||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_fil_produto_categoria
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('categoria_id',  'Identificador', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',  'Descricao', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('ativo',  'Ativo', '', 4)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getCategoria'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_produto_categoria;

function fnc_col_produto_categoria
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('categoria_id'   ,'Categoria (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_string('descricao'   ,'Descricao'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao'   ,'Observacao'),
                kss.pkg_cols_devextreme.fnc_col_boolean_sn('ativo'   ,'Ativo'),
                kss.pkg_cols_devextreme.fnc_col_number('produto_classe_id'   ,'Produto Classe (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('porto_classe_desc'   ,'Produto Classe (desc)'),
                kss.pkg_cols_devextreme.fnc_col_boolean_sn('restrito'   ,'Restrito'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_produto_categoria;

function fnc_get_produto_categoria
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id integer      path '/params/categoria_id'
                 , descricao    varchar2(60) path '/params/descricao'
                 , ativo        integer      path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''produto_categoria'')),
                      operporto.pkg_schedule_backend.fnc_col_produto_categoria(),
                      operporto.pkg_schedule_backend.fnc_fil_produto_categoria()
                   ),
                   xmlelement("produto_categoria",
                      xmlattributes(''array'' as "type"),
                      xmlagg(
                         xmlelement("arrayItem",
                           xmlattributes(''object'' as "type"),
                           xmlelement("categoria_id",        xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                           xmlelement("descricao",           xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                           xmlelement("ativo",               xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                           xmlelement("observacao",          xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                           xmlelement("produto_classe_id",   xmlattributes(''number'' as "type"), numbertojson(x.produto_classe_id)),
                           xmlelement("produto_classe_desc", xmlattributes(''string'' as "type"), stringtojson(x.produto_classe_desc)),
                           xmlelement("restrito",            xmlattributes(''string'' as "type"), stringtojson(x.restrito)),
                           xmlelement("user_insert",         xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                           xmlelement("date_insert",         xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                           xmlelement("user_update",         xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                           xmlelement("date_update",         xmlattributes(''string'' as "type"), datetojson(x.date_update))          
                        )
                     )
                  )
                )
             )
        from (
      select p.categoria_id
           , p.descricao
           , p.ativo
           , p.observacao
           , p.produto_classe_id
           , (select pc.descricao
                from recinto.v$produto_classe pc
               where pc.produto_classe_id = p.produto_classe_id
             ) produto_classe_desc
           , p.date_insert
           , p.user_insert
           , p.date_update
           , p.user_update
           , case
               when (select count(1)
                       from operporto.v$restricao r
                      where r.categoria_id = p.categoria_id
                        and r.liberado = 0) > 0 then ''SIM'' else ''N?O'' end as restrito
        from recinto.v$produto_categoria p
       order by p.descricao
           ) x
       where 1=1');

      if trim(i.categoria_id) is not null then
         dbms_lob.append(v_sql, '
         and x.categoria_id = '||i.categoria_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

/*
procedure prc_cad_produto_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation 	          varchar2(30)  path '/params/operation'
                 , categoria_id         integer       path '/params/categoria_id'
                 , descricao            varchar2(60)  path '/params/descricao'
                 , ativo                integer       path '/params/ativo'
                 , observacao           varchar2(500) path '/params/observacao'
                 , produto_classe_id    integer       path '/params/produto_classe_id'
                 )
   ) loop
      v_id := i.categoria_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_produto_categoria(p_categoria_id          => v_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                 );
            v_msg := 'Categoria Produto inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_produto_categoria(p_categoria_id          => i.categoria_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                  );

            if v_msg is null then
               v_msg := 'Categoria Produto alterado com sucesso.';
            end if;   

          when 'DELETE' then
             operporto.pkg_schedule.prc_del_produto_categoria(p_categoria_id => i.categoria_id
                                                  );
            v_msg := 'Categoria Produto excluido com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_produto_categoria;
*/

function fnc_fil_etiqueta
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('etiqueta_id',  'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',  'Descricao', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('tipo_id',  'Tipo (id)', '', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_inicio',  'Data Inicio', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_fim',  'Data Fim', 6),
                   kss.pkg_form_devextreme.fnc_form_selectbox('ativo',  'Ativo', 'descricao', 'ativo', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getEtiqueta'))
                ),
                xmlelement("model")
              ),
              xmlelement("datasource",
                    xmlattributes('object' as "type"),
                    xmlconcat(
                       xmlelement("ativo",
                          xmlattributes('array' as "type"),
                          xmlelement("arrayItem",
                             xmlattributes('object' as "type"),
                             xmlelement("ativo", xmlattributes('number' as "type"), numbertojson(1)),
                             xmlelement("descricao",   xmlattributes('string' as "type"), stringtojson('ATIVADO'))
                          ),
                          xmlelement("arrayItem",
                             xmlattributes('object' as "type"),
                             xmlelement("ativo", xmlattributes('number' as "type"), numbertojson(0)),
                             xmlelement("descricao",   xmlattributes('string' as "type"), stringtojson('DESATIVADO'))
                          )
                       )
                    )
                 )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_etiqueta;

function fnc_col_etiqueta
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('etiqueta_id' ,'Etiqueta (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('descricao' ,'Descricao'),
                kss.pkg_cols_devextreme.fnc_col_number('tipo_id' ,'Tipo (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('tipo_descricao' ,'Tipo (desc)'),
                kss.pkg_cols_devextreme.fnc_col_string('cor' ,'Cor'),
                kss.pkg_cols_devextreme.fnc_col_boolean_sn('ativo' ,'Ativo'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_etiqueta;

function fnc_get_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etiqueta_id integer       path '/params/etiqueta_id'
                 , descricao   varchar2(50)  path '/params/descricao'
                 , tipo_id     integer       path '/params/tipo_etiqueta_id'
                 , data_inicio varchar2(20)  path '/params/data_inicio'
                 , data_fim    varchar2(20)  path '/params/data_fim'
                 , ativo       integer       path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''etiqueta'')),
                      operporto.pkg_schedule_backend.fnc_col_etiqueta(),
                      operporto.pkg_schedule_backend.fnc_fil_etiqueta()
                   ),
                   xmlelement("etiqueta",
                      xmlattributes(''array'' as "type"),
                      xmlagg(
                         xmlelement("arrayItem",
                           xmlattributes(''object'' as "type"),
                           xmlelement("etiqueta_id",    xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                           xmlelement("descricao",      xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                           xmlelement("tipo_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_id)),
                           xmlelement("tipo_descricao", xmlattributes(''string'' as "type"), stringtojson(x.tipo_descricao)),
                           xmlelement("cor",            xmlattributes(''string'' as "type"), stringtojson(x.cor)),
                           xmlelement("ativo",          xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                           xmlelement("observacao",     xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                           xmlelement("user_insert",    xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                           xmlelement("date_insert",    xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                           xmlelement("user_update",    xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                           xmlelement("date_update",    xmlattributes(''string'' as "type"), datetojson(x.date_update))
                        )
                     )
                  )
                )
             )
        from (
      select e.etiqueta_id
           , e.descricao
           , e.tipo_id
           , (select crc.rv_abbreviation
                from operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''ETIQUETA.TIPO_ID''
                 and crc.rv_low_value = e.tipo_id
             ) as tipo_descricao
           , e.cor
           , e.ativo
           , e.observacao
           , e.user_insert
           , e.date_insert
           , e.user_update
           , e.date_update
        from operporto.v$etiqueta e
       order by e.date_update desc
           ) x
       where 1=1');

      if trim(i.etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etiqueta_id = '||i.etiqueta_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.tipo_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_id = '||i.tipo_id);
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_etiqueta
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id  integer;
v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation     varchar2(30)   path '/params/operation'
                 , etiqueta_id   integer        path '/params/etiqueta_id'
                 , descricao     varchar2(100)  path '/params/descricao'
                 , tipo_id       integer        path '/params/tipo_id'
                 , cor           varchar2(7)    path '/params/cor'
                 , observacao    varchar2(1000) path '/params/observacao'
                 , ativo         integer        path '/params/ativo'
                 , justificativa varchar2(4000) path '/params/justificativa'
                )
   ) loop
      v_id := i.etiqueta_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_etiqueta(p_etiqueta_id => v_id
                                                   ,p_descricao   => i.descricao
                                                   ,p_tipo_id     => i.tipo_id
                                                   ,p_cor         => i.cor
                                                   ,p_observacao  => i.observacao
                                                   ,p_ativo       => i.ativo
                                                 );
            v_msg := 'Etiqueta inserida com sucesso.';


         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_etiqueta(p_etiqueta_id => i.etiqueta_id
                                                   ,p_descricao   => i.descricao
                                                   ,p_tipo_id     => i.tipo_id
                                                   ,p_cor         => i.cor
                                                   ,p_observacao  => i.observacao
                                                   ,p_ativo       => i.ativo
                                                 );
            v_msg := 'Etiqueta alterada com sucesso.';
            
         when 'ATIVAR' then
            operporto.pkg_schedule.prc_alt_ativo_etiqueta(p_etiqueta_id   => i.etiqueta_id
                                                         ,p_ativo         => i.ativo
                                                         ,p_justificativa => i.justificativa
                                                      );
            v_msg := 'Etiqueta ativada com sucesso.';

         when 'DESATIVAR' then
            operporto.pkg_schedule.prc_alt_ativo_etiqueta(p_etiqueta_id   => i.etiqueta_id
                                                         ,p_ativo         => i.ativo
                                                         ,p_justificativa => i.justificativa
                                                          );
            v_msg := 'Etiqueta desativada com sucesso.';

         when 'DELETE' then
            operporto.pkg_schedule.prc_del_etiqueta(p_etiqueta_id     => i.etiqueta_id
                                                   ,p_justificativa   => i.justificativa
                                                   );
            v_msg := 'Etiqueta excluida com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem",  xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("etiqueta_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_etiqueta;

function fnc_fil_restricao
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('restricao_id',  'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('categoria_id',  'Categoria (id)', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('porto_id',      'Porto (id)', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('pais_id',       'Pais (id)', '', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_inicio',   'Data Inicio', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_fim',      'Data Fim', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getRestricao'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_restricao;

function fnc_col_restricao
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('restricao_id'   ,'Restricao (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_number('categoria_id'   ,'Categoria (id)', 0, 'false'),
                kss.pkg_cols_devextreme.fnc_col_string('categoria_descricao'   ,'Categoria (desc)'),
                kss.pkg_cols_devextreme.fnc_col_number('porto_id'   ,'Porto (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('porto_nome'   ,'Porto (nome)'),
                kss.pkg_cols_devextreme.fnc_col_number('pais_id'   ,'Pais (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('pais_nome'   ,'Pais (nome)'),
                kss.pkg_cols_devextreme.fnc_col_boolean('liberado'   ,'Liberado', 'Sim', 'Nao'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao'   ,'Observacao'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_restricao;

function fnc_get_restricao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id integer      path '/params/restricao_id'
                 , categoria_id integer      path '/params/categoria_id'
                 , porto_id     integer      path '/params/porto_id'
                 , pais_id      integer      path '/params/pais_id'
                 , data_inicio  varchar2(20) path '/params/data_inicio'
                 , data_fim     varchar2(20) path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                  xmlattributes(''object'' as "type"),
                  xmlconcat(
                     xmlelement("header",
                        xmlattributes(''object'' as "type"),
                        xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''restricao'')),
                        operporto.pkg_schedule_backend.fnc_col_restricao(),
                        operporto.pkg_schedule_backend.fnc_fil_restricao()
                  ),
                  xmlelement("restricao",
                  xmlattributes(''array'' as "type"),
                  xmlagg(
                     xmlelement("arrayItem",
                        xmlattributes(''object'' as "type"),
                        xmlelement("restricao_id",        xmlattributes(''number'' as "type"), numbertojson(x.restricao_id)),
                        xmlelement("categoria_id",        xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                        xmlelement("categoria_descricao", xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                        xmlelement("porto_id",            xmlattributes(''number'' as "type"), numbertojson(x.porto_id)),
                        xmlelement("porto_nome",          xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                        xmlelement("pais_id",             xmlattributes(''number'' as "type"), numbertojson(x.pais_id)),
                        xmlelement("pais_nome",           xmlattributes(''string'' as "type"), stringtojson(x.pais_nome)),
                        xmlelement("liberado",            xmlattributes(''number'' as "type"), numbertojson(x.liberado)),
                        xmlelement("observacao",          xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                        xmlelement("user_insert",         xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                        xmlelement("date_insert",         xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                        xmlelement("user_update",         xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                        xmlelement("date_update",         xmlattributes(''string'' as "type"), datetojson(x.date_update))
                         )
                      )
                   )
                )
             )
        from (
      select r.restricao_id
           , r.categoria_id
           , (select p.descricao
                from recinto.v$produto_categoria p
               where p.categoria_id = r.categoria_id
             ) as categoria_descricao
           , r.porto_id
           , (select hp.nome
                from  operporto.v$porto hp
               where hp.porto_id = r.porto_id
             ) as porto_nome
           , r.pais_id
           , (select cp.descricao_portugues
                from cep.v$pais cp
               where cp.pais_id = r.pais_id
             ) as pais_nome
           , r.liberado
           , r.observacao
           , r.user_insert
           , r.date_insert
           , r.user_update
           , r.date_update
        from operporto.v$restricao r
       order by r.date_update desc
           ) x
       where 1=1');

      if trim(i.restricao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.restricao_id = '||i.restricao_id);
      end if;

      if trim(i.categoria_id) is not null then
         dbms_lob.append(v_sql, '
         and x.categoria_id = '||i.categoria_id);
      end if;

      if trim(i.porto_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_id = '||i.porto_id);
      end if;

      if trim(i.pais_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_id = '||i.pais_id);
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation     varchar2(30)   path '/params/operation'
                 , restricao_id  integer         path '/params/restricao_id'
                 , categoria_id  integer         path '/params/categoria_id'
                 , porto_id      integer         path '/params/porto_id'
                 , pais_id       integer         path '/params/pais_id'
                 , liberado      integer         path '/params/liberado'
                 , observacao    varchar2(1000)  path '/params/observacao'
                 , justificativa varchar2(1000)  path '/params/justificativa'
                 )
   ) loop
      v_id := i.restricao_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_restricao(p_restricao_id => v_id
                                                     ,p_categoria_id => i.categoria_id
                                                     ,p_porto_id     => i.porto_id
                                                     ,p_pais_id      => i.pais_id
                                                     ,p_liberado     => i.liberado
                                                     ,p_observacao   => i.observacao
                                                    );
            v_msg := 'Restric?o inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_restricao(p_restricao_id    => i.restricao_id
                                                     ,p_categoria_id   => i.categoria_id
                                                     ,p_porto_id       => i.porto_id
                                                     ,p_pais_id        => i.pais_id
                                                     ,p_liberado       => i.liberado
                                                     ,p_observacao     => i.observacao
                                                     );

            if v_msg is null then
               v_msg := 'Restric?o alterado com sucesso.';
            end if;

          when 'DELETE' then
             operporto.pkg_schedule.prc_del_restricao(p_restricao_id   => i.restricao_id
                                                     ,p_justificativa  => i.justificativa
                                                     );
            v_msg := 'Restric?o excluido com sucesso.';

          when 'ATIVAR' then
            operporto.pkg_schedule.prc_ativar_restricao(p_restricao_id  => i.restricao_id
                                                     , p_justificativa => i.justificativa
                                                      );
            v_msg := 'Restrc?o ativada com sucesso.';

          when 'DESATIVAR' then
            operporto.pkg_schedule.prc_desativar_restricao(p_restricao_id  => i.restricao_id
                                                          ,p_justificativa => i.justificativa
                                                          );
            v_msg := 'Restrc?o desativada com sucesso.';

         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("restricao_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_restricao;

function fnc_count_dias_mes
 (etb        date
 ,ets        date
 ,data_mes   date
 ) return integer as
 v_dia_atual date;
 v_count     integer;
begin
   v_dia_atual := trunc(data_mes) - (to_number(to_char(data_mes,'DD')) - 1);
   v_count := 0;

   while v_dia_atual < last_day(v_dia_atual) loop
      if v_dia_atual between etb and ets then
         v_count := v_count + 1;
      end if;
      v_dia_atual := v_dia_atual + 1;
   end loop;

   if last_day(v_dia_atual) between etb and ets then
      v_count := v_count + 1;
   end if;

   return v_count;
end;

function fnc_fil_budget
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('budget_id',  'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',  'Descricao', '', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('mes_inicio',  'Mes Inicio', 6),
                   kss.pkg_form_devextreme.fnc_form_datebox('mes_fim',  'Mes Fim', 6),
                   kss.pkg_form_devextreme.fnc_form_emptybox(8)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getBudget'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_budget;

function fnc_col_budget
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('budget_id'                 ,'Budget (id)'),
                kss.pkg_cols_devextreme.fnc_col_string('descricao'                 ,'Descricao'),
                kss.pkg_cols_devextreme.fnc_col_number('quantidade'                ,'Quantidade', 0),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_budget;

function fnc_get_budget
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   budget_id   integer       path '/params/budget_id'
                 , descricao   varchar2(100) path '/params/descricao'
                 , data        varchar2(30)  path '/params/data'
                 , mes_inicio  varchar2(30)  path '/params/mes_inicio'
                 , mes_fim     varchar2(30)  path '/params/mes_fim'
                 , data_inicio varchar2(30)  path '/params/data_inicio'
                 , data_fim    varchar2(30)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''budget'')),
                      operporto.pkg_schedule_backend.fnc_col_budget(),
                      operporto.pkg_schedule_backend.fnc_fil_budget()
                   ),
                   xmlelement("budget",
                      xmlattributes(''array'' as "type"),
                      xmlagg(
                         xmlelement("arrayItem",
                           xmlattributes(''object'' as "type"),
                           xmlelement("budget_id",   xmlattributes(''number'' as "type"), numbertojson(x.budget_id)),
                           xmlelement("descricao",   xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                           xmlelement("quantidade",  xmlattributes(''number'' as "type"), numbertojson(x.quantidade)),
                           xmlelement("data_inicio", xmlattributes(''string'' as "type"), datetojson(x.data_inicio)),
                           xmlelement("data_fim",    xmlattributes(''string'' as "type"), datetojson(x.data_fim)),
                           xmlelement("observacao",  xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                           xmlelement("user_insert", xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                           xmlelement("date_insert", xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                           xmlelement("user_update", xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                           xmlelement("date_update", xmlattributes(''string'' as "type"), datetojson(x.date_update))
                        )
                     )
                  )
                )
             )
        from (
      select b.budget_id
           , b.descricao
           , b.quantidade
           , b.data_inicio
           , b.data_fim
           , b.observacao
           , b.user_insert
           , b.date_insert
           , b.user_update
           , b.date_update
        from operporto.v$budget b
       order by b.data_inicio desc
           ) x
       where 1=1');

      if trim(i.budget_id) is not null then
         dbms_lob.append(v_sql, '
         and x.budget_id = '||i.budget_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.mes_inicio) is not null then
            dbms_lob.append(v_sql, '
         and to_char(trunc(x.data_inicio), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.mes_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''');
      end if;

      if trim(i.data) is not null then
            dbms_lob.append(v_sql, '
         and ''' || to_char(to_timestamp(i.data, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy hh24:mi:ss') ||''' between x.data_inicio and x.data_fim');
      end if;

      if trim(i.mes_fim) is not null then
            dbms_lob.append(v_sql, '
         and to_char(trunc(x.data_fim), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.mes_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'') >=  ''' || to_char(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') <= ''' || to_char(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
         )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'')  >=  ''' || to_char(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''
         )');
      end if;

      if trim(i.data_inicio) is null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'') <= ''' || to_char(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy hh24:mi:ss') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''
         )');
      end if;


      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_budget_info
(p_parameters in  xmltype
) return xmltype as
v_result         xmltype;
v_sql            clob;
v_total_budget   number;
v_total_rateio   number;
begin
   for i in (
      select budget_id
           , data
           , (to_char(to_date(substr(mes_inicio,0,10),'yyyy-mm-dd'),'mm/yyyy')) as mes_inicio
        from xmltable('/params' passing p_parameters
                columns
                   budget_id  integer      path '/params/budget_id'
                 , data       varchar2(30) path '/params/data'
                 , mes_inicio varchar2(30) path '/params/mes_inicio'
      )
   ) loop
      select (select b.quantidade
                from operporto.v$budget b
               where to_char(b.data_inicio,'mm/yyyy') = i.mes_inicio)
           , (select sum(
                      case
                           when(to_date(to_char(p.etb,'mm/yyyy'),'mm/yyyy') = to_date(i.mes_inicio,'mm/yyyy')) and
                               (to_date(to_char(p.ets,'mm/yyyy'),'mm/yyyy') = to_date(i.mes_inicio,'mm/yyyy')) then
                               qtde_total
                           when(to_date(to_char(add_months(p.etb,-1),'mm/yyyy'),'mm/yyyy') < to_date(i.mes_inicio,'mm/yyyy')) and
                               (to_date(to_char(p.ets,'mm/yyyy'),'mm/yyyy') = to_date(i.mes_inicio,'mm/yyyy')) then
                               qtde_total - ((p.ets-p.etb) * p.prancha) +
                               ((p.ets-trunc(p.ets,'month')) * p.prancha)
                           when(to_date(to_char(p.etb,'mm/yyyy'),'mm/yyyy') = to_date(i.mes_inicio,'mm/yyyy')) and
                               (to_date(to_char(add_months(p.ets,1),'mm/yyyy'),'mm/yyyy') > to_date(i.mes_inicio,'mm/yyyy')) then
                               (last_day(p.etb)-p.etb+1) * p.prancha
                         end
                      ) as total_programado
              from operporto.v$programacao p
             where status_id != 4
               and (to_char(p.etb,'mm/yyyy') = i.mes_inicio or to_char(p.ets,'mm/yyyy') = i.mes_inicio))
        into v_total_budget
           , v_total_rateio
        from dual;

      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("budget_info",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("descricao",   xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                      xmlelement("saldo",       xmlattributes(''number'' as "type"), numbertojson(x.saldo)),
                      xmlelement("percentual",  xmlattributes(''number'' as "type"), numbertojson(
                         (x.saldo / '|| nvl(v_total_rateio,1) ||')
                      )),
                      xmlelement("total_budget", xmlattributes(''number'' as "type"), numbertojson('|| nvl(v_total_budget,0) ||')),
                      xmlelement("total_rateio", xmlattributes(''number'' as "type"), numbertojson('|| nvl(v_total_rateio,0) ||'))
                   )
                )
             )
        from (
           select e.descricao
                , sum(
                     case
                        when(to_date(to_char(p.etb,''mm/yyyy''),''mm/yyyy'') = to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) and
                            (to_date(to_char(p.ets,''mm/yyyy''),''mm/yyyy'') = to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) then
                            pe.qtde_descarga
                        when(to_date(to_char(add_months(p.etb,-1),''mm/yyyy''),''mm/yyyy'') < to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) and
                            (to_date(to_char(p.ets,''mm/yyyy''),''mm/yyyy'') = to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) then
                            (pe.qtde_descarga / p.qtde_total) * (p.qtde_total - ((last_day(p.etb)-p.etb+1) * p.prancha))
                        when(to_date(to_char(p.etb,''mm/yyyy''),''mm/yyyy'') = to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) and
                            (to_date(to_char(add_months(p.ets,1),''mm/yyyy''),''mm/yyyy'') > to_date('''|| i.mes_inicio ||''',''mm/yyyy'')) then
                            (pe.qtde_descarga / p.qtde_total) * (((last_day(p.etb)-p.etb+1) * p.prancha))
                     end
                  ) saldo
             from operporto.v$programacao p
            inner join operporto.programacao_etiqueta pe
               on pe.programacao_id = p.programacao_id
            inner join operporto.v$etiqueta e
               on e.etiqueta_id = pe.etiqueta_id
              and e.tipo_id = 3
            where status_id != 4
              and (to_char(p.etb,''mm/yyyy'') = '''|| i.mes_inicio ||'''
                      or to_char(p.ets,''mm/yyyy'') = '''|| i.mes_inicio ||''')
              group by e.descricao
        ) x
       where 1=1');

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_budget
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id  integer;
v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation     varchar2(30)   path '/params/operation'
                 , budget_id     integer        path '/params/budget_id'
                 , descricao     varchar2(100)  path '/params/descricao'
                 , quantidade    number         path '/params/quantidade'
                 , data_inicio   varchar2(30)   path '/params/data_inicio'
                 , data_fim      varchar2(30)   path '/params/data_inicio'
                 , observacao    varchar2(1000) path '/params/observacao'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
      if upper(i.operation) in ('INSERT','UPDATE') and i.quantidade <= 0 then
         kss.pkg_mensagem.prc_dispara_msg('M5005-30112');
      end if;

      v_id := i.budget_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_budget(p_budget_id   => v_id
                                                 ,p_descricao   => i.descricao
                                                 ,p_quantidade  => i.quantidade
                                                 ,p_data_inicio => to_date(i.data_inicio, 'yyyy-mm')
                                                 ,p_data_fim    => to_date(i.data_fim, 'yyyy-mm')
                                                 ,p_observacao  => i.observacao
                                                 );
            v_msg := 'Budget inserido com sucesso.';


         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_budget(p_budget_id   => v_id
                                                 ,p_descricao   => i.descricao
                                                 ,p_quantidade  => i.quantidade
                                                 ,p_data_inicio => to_date(i.data_inicio, 'yyyy-mm')
                                                 ,p_data_fim    => to_date(i.data_fim, 'yyyy-mm')
                                                 ,p_observacao  => i.observacao
                                                 );
            v_msg := 'Budget alterado com sucesso.';

          when 'DELETE' then
            operporto.pkg_schedule.prc_del_budget(p_budget_id     => i.budget_id
                                                 ,p_justificativa => i.justificativa
                                                 );
            v_msg := 'Budget excluido com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem",  xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("budget_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_budget;

function fnc_get_manutencao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   manutencao_id   integer       path '/params/manutencao_id'
                 , berco_id        integer       path '/params/berco_id'
                 , berco_descricao varchar2(240) path '/params/berco_descricao'
                 , data            varchar2(30)  path '/params/data'
                 , mes_inicio      varchar2(30)  path '/params/mes_inicio'
                 , mes_fim         varchar2(30)  path '/params/mes_fim'
                 , data_inicio     varchar2(30)  path '/params/data_inicio'
                 , data_fim        varchar2(30)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("manutencao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("manutencao_id",   xmlattributes(''number'' as "type"), numbertojson(x.manutencao_id)),
                      xmlelement("berco_id",        xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                      xmlelement("berco_descricao", xmlattributes(''string'' as "type"), stringtojson(x.berco_descricao)),
                      xmlelement("data_inicio",     xmlattributes(''string'' as "type"), datetojson(x.data_inicio)),
                      xmlelement("data_fim",        xmlattributes(''string'' as "type"), datetojson(x.data_fim)),
                      xmlelement("observacao",      xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",     xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",     xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",     xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",     xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select m.manutencao_id
           , m.berco_id
           ,(select b.descricao
               from  operporto.v$berco b
              where b.berco_id = m.berco_id
            ) as berco_descricao
           , m.data_inicio
           , m.data_fim
           , m.observacao
           , m.user_insert
           , m.date_insert
           , m.user_update
           , m.date_update
        from operporto.v$manutencao m
       order by m.data_inicio
           ) x
       where 1=1');

      if trim(i.manutencao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.manutencao_id = '||i.manutencao_id);
      end if;

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.berco_descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.berco_descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.berco_descricao||'%''))');
      end if;

       if trim(i.mes_inicio) is not null then
            dbms_lob.append(v_sql, '
         and to_char(trunc(x.data_inicio), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.mes_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''');
      end if;

      if trim(i.data) is not null then
            dbms_lob.append(v_sql, '
         and ''' || to_char(to_timestamp(i.data, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy hh24:mi:ss') ||''' between x.data_inicio and x.data_fim');
      end if;

      if trim(i.mes_fim) is not null then
            dbms_lob.append(v_sql, '
         and to_char(trunc(x.data_fim), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.mes_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'') >=  ''' || to_char(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') <= ''' || to_char(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
         )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'')  >=  ''' || to_char(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''
         )');
      end if;

      if trim(i.data_inicio) is null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
         and (
            to_date(to_char(trunc(x.data_inicio), ''mm/yyyy''), ''mm/yyyy'') <= ''' || to_char(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'), 'dd/mm/yyyy hh24:mi:ss') ||'''
            and to_date(to_char(trunc(x.data_fim), ''mm/yyyy''), ''mm/yyyy'') = ''' ||  to_char(trunc(to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')), 'mm/yyyy') ||'''
         )');
      end if;


      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_programacao_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_etiqueta_id integer      path '/params/programacao_etiqueta_id'
                 , programacao_id          integer      path '/params/programacao_id'
                 , etiqueta_id             integer      path '/params/etiqueta_id'
                 , tipo_etiqueta_id        integer      path '/params/tipo_etiqueta_id'
                 , categoria_id            integer      path '/params/categoria_id'
                 , categoria_descricao     varchar2(60) path '/params/categoria_descricao'
                 , data_inicio             varchar2(20) path '/params/data_inicio'
                 , data_fim                varchar2(20) path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("prog_etiqueta",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("tipo_etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao)),
                      xmlelement("categoria_id",            xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("categoria_descricao",     xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                      xmlelement("qtde_descarga",           xmlattributes(''number'' as "type"), numbertojson(x.qtde_descarga)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select pe.programacao_etiqueta_id
           , pe.programacao_id
           , pe.etiqueta_id
           , (select e.descricao
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as etiqueta_descricao
           , pe.categoria_id
           , (select pc.descricao
                from recinto.v$produto_categoria pc
               where pc.categoria_id = pe.categoria_id
             ) as categoria_descricao
           , (select e.tipo_id
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as tipo_etiqueta_id
           , pe.qtde_descarga
           , pe.observacao
           , pe.user_insert
           , pe.date_insert
           , pe.user_update
           , pe.date_update
        from operporto.v$programacao_etiqueta pe

           ) x
       where 1=1');

      if trim(i.programacao_etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_etiqueta_id = '||i.programacao_etiqueta_id);
      end if;

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etiqueta_id = '||i.etiqueta_id);
      end if;

      if trim(i.tipo_etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_etiqueta_id = '||i.tipo_etiqueta_id);
      end if;

      if trim(i.categoria_id) is not null then
         dbms_lob.append(v_sql, '
         and x.categoria_id = '||i.categoria_id);
      end if;

      if trim(i.categoria_descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.categoria_descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.categoria_descricao||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_agencia_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer     path '/params/programacao_id'
                 , flag           varchar2(1) path '/params/flag'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("agencia",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("tipo_etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao)),
                      xmlelement("categoria_id",            xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("categoria_descricao",     xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                      xmlelement("qtde_descarga",           xmlattributes(''number'' as "type"), numbertojson(x.qtde_descarga)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select pe.programacao_etiqueta_id
           , pe.programacao_id
           , pe.etiqueta_id
           , (select e.descricao
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as etiqueta_descricao
           , pe.categoria_id
           , (select pc.descricao
                from recinto.v$produto_categoria pc
               where pc.categoria_id = pe.categoria_id
             ) as categoria_descricao
           , (select e.tipo_id
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as tipo_etiqueta_id
           , pe.qtde_descarga
           , pe.observacao
           , pe.user_insert
           , pe.date_insert
           , pe.user_update
           , pe.date_update
        from operporto.v$programacao_etiqueta pe
           ) x
       where x.tipo_etiqueta_id = 2');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.flag) is not null and trim(i.flag) = 'M' then
         dbms_lob.append(v_sql, '
         and 1 <> 1 ');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;


function fnc_get_importador_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer     path '/params/programacao_id'
                 , flag           varchar2(1) path '/params/flag'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);

      if trim(i.flag) is not null and i.flag = 'M' then


            dbms_lob.append(v_sql, '
      select xmlelement("importador",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("tipo_etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao)),
                      xmlelement("etiqueta_cor",            xmlattributes(''string'' as "type"), stringtojson(x.cor)),
                      xmlelement("categoria_id",            xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("categoria_descricao",     xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                      xmlelement("qtde_descarga",           xmlattributes(''number'' as "type"), numbertojson(x.qtde_descarga)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select 0 as programacao_etiqueta_id
           , 0 as programacao_id
           , 0 as etiqueta_id
           , ''Manutenc?o de berco'' as etiqueta_descricao
           , null as categoria_id
           , null as categoria_descricao
           , 0 as tipo_etiqueta_id
           , ''#000000'' as cor
           , null as qtde_descarga
           , null as observacao
           , null as user_insert
           , null as date_insert
           , null as user_update
           , null as date_update
        from dual
           ) x
       where 1=1');
      else

         dbms_lob.append(v_sql, '
      select xmlelement("importador",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("tipo_etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao)),
                      xmlelement("etiqueta_cor",            xmlattributes(''string'' as "type"), stringtojson(x.cor)),
                      xmlelement("categoria_id",            xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("categoria_descricao",     xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                      xmlelement("qtde_descarga",           xmlattributes(''number'' as "type"), numbertojson(x.qtde_descarga)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select pe.programacao_etiqueta_id
           , pe.programacao_id
           , pe.etiqueta_id
           , (select e.descricao
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as etiqueta_descricao
           , pe.categoria_id
           , (select pc.descricao
                from recinto.v$produto_categoria pc
               where pc.categoria_id = pe.categoria_id
             ) as categoria_descricao
           , (select e.tipo_id
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as tipo_etiqueta_id
           , (select e.cor
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as cor
           , pe.qtde_descarga
           , pe.observacao
           , pe.user_insert
           , pe.date_insert
           , pe.user_update
           , pe.date_update
        from operporto.v$programacao_etiqueta pe
           ) x
       where x.tipo_etiqueta_id = 3');

         if trim(i.programacao_id) is not null then
            dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
         end if;
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_exportador_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer     path '/params/programacao_id'
                 , flag           varchar2(1) path '/params/flag'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("exportador",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("tipo_etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.tipo_etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao)),
                      xmlelement("categoria_id",            xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("categoria_descricao",     xmlattributes(''string'' as "type"), stringtojson(x.categoria_descricao)),
                      xmlelement("qtde_descarga",           xmlattributes(''number'' as "type"), numbertojson(x.qtde_descarga)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select pe.programacao_etiqueta_id
           , pe.programacao_id
           , pe.etiqueta_id
           , (select e.descricao
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as etiqueta_descricao
           , pe.categoria_id
           , (select pc.descricao
                from recinto.v$produto_categoria pc
               where pc.categoria_id = pe.categoria_id
             ) as categoria_descricao
           , (select e.tipo_id
                from operporto.v$etiqueta e
               where e.etiqueta_id = pe.etiqueta_id
             ) as tipo_etiqueta_id
           , pe.qtde_descarga
           , pe.observacao
           , pe.user_insert
           , pe.date_insert
           , pe.user_update
           , pe.date_update
        from operporto.v$programacao_etiqueta pe
           ) x
       where x.tipo_etiqueta_id = 4');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.flag) is not null and trim(i.flag) = 'M' then
         dbms_lob.append(v_sql, '
         and 1 <> 1 ');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_prog_grupo_email
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_grupo_email_id integer path '/params/programacao_grupo_email_id'
                 , grupo_email_id             integer path '/params/grupo_email_id'
                 , programacao_id             integer path '/params/programacao_id'
                 , ativo                      integer path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("grupo_email",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_grupo_email_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_grupo_email_id)),
                      xmlelement("grupo_email_id",             xmlattributes(''number'' as "type"), numbertojson(x.grupo_email_id)),
                      xmlelement("grupo_email_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.grupo_email_descricao)),
                      xmlelement("programacao_id",             xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("ativo",                      xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                      xmlelement("user_insert",                xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",                xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",                xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",                xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select g.programacao_grupo_email_id
           , g.grupo_email_id
           , (select r.descricao
                from recinto.v$grupo_email r
               where r.grupo_email_id = g.grupo_email_id
             ) as grupo_email_descricao
           , g.programacao_id
           , g.ativo
           , g.user_insert
           , g.date_insert
           , g.user_update
           , g.date_update
        from operporto.v$programacao_grupo_email g
       order by grupo_email_descricao
           ) x
       where 1=1');

      if trim(i.programacao_grupo_email_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_grupo_email_id = '||i.programacao_grupo_email_id);
      end if;

      if trim(i.grupo_email_id) is not null then
         dbms_lob.append(v_sql, '
         and x.grupo_email_id = '||i.grupo_email_id);
      end if;

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_programacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id   integer      path '/params/programacao_id'
                 , imo              integer      path '/params/imo'
                 , berco_id         integer      path '/params/berco_id'
                 , pais_origem_id   integer      path '/params/pais_origem_id'
                 , porto_origem_id  integer      path '/params/porto_origem_id'
                 , porto_nome       varchar2(50) path '/params/porto_nome'
                 , status_id        integer      path '/params/status_id'
                 , st_nao_cancelado integer      path '/params/st_nao_cancelado'
                 , status_group     varchar2(99) path '/params/status_group'
                 , etapa_id         integer      path '/params/etapa_id'
                 , restricao        integer      path '/params/restricao'
                 , embarcacao_id    integer      path '/params/embarcacao_id'
                 , data_inicio      varchar2(20) path '/params/data_inicio'
                 , data_fim         varchar2(20) path '/params/data_fim'
                 , eta_inicio       varchar2(20) path '/params/eta_inicio'
                 , eta_fim          varchar2(20) path '/params/eta_fim'
                 , etb_inicio       varchar2(20) path '/params/etb_inicio'
                 , etb_fim          varchar2(20) path '/params/etb_fim'
                 , ets_inicio       varchar2(20) path '/params/ets_inicio'
                 , ets_fim          varchar2(20) path '/params/ets_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("programacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_id",    xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("qtde_total",        xmlattributes(''number'' as "type"), numbertojson(x.qtde_total)),
                      xmlelement("imo",               xmlattributes(''number'' as "type"), numbertojson(x.imo)),
                      xmlelement("embarcacao_id",     xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("vessel_name",       xmlattributes(''string'' as "type"), stringtojson(x.vessel_name)),
                      xmlelement("berco_id",          xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                      xmlelement("berco_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.berco_descricao)),
                      xmlelement("eta",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.eta), ''yyyy-mm-dd''))),
                      xmlelement("etb",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.etb), ''yyyy-mm-dd''))),
                      xmlelement("ets",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.ets), ''yyyy-mm-dd''))),
                      xmlelement("prancha",           xmlattributes(''number'' as "type"), numbertojson(x.prancha)),
                      xmlelement("pais_id",           xmlattributes(''number'' as "type"), numbertojson(x.pais_origem_id)),
                      xmlelement("pais_nome",         xmlattributes(''string'' as "type"), stringtojson(x.pais_nome)),
                      xmlelement("porto_origem_id",   xmlattributes(''number'' as "type"), numbertojson(x.porto_origem_id)),
                      xmlelement("porto_nome",        xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                      xmlelement("produtos",          xmlattributes(''string'' as "type"), stringtojson(x.produtos)),
                      xmlelement("status_id",         xmlattributes(''number'' as "type"), numbertojson(x.status_id)),
                      xmlelement("status",            xmlattributes(''string'' as "type"), stringtojson(x.status)),
                      xmlelement("etapa_id",          xmlattributes(''number'' as "type"), numbertojson(x.etapa_id)),
                      xmlelement("etapa_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.etapa_descricao)),
                      xmlelement("restricao",         xmlattributes(''number'' as "type"), numbertojson(x.restricao)),
                      xmlelement("calado_after",      xmlattributes(''number'' as "type"), numbertojson(x.calado_after)),
                      xmlelement("calado_forward",    xmlattributes(''number'' as "type"), numbertojson(x.calado_forward)),
                      xmlelement("dwt_viagem",        xmlattributes(''number'' as "type"), numbertojson(x.dwt_viagem)),
                      xmlelement("observacao",        xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("indicador_os",      xmlattributes(''number'' as "type"), numbertojson(x.indicador_os)),
                      xmlelement("qtde_importadores", xmlattributes(''number'' as "type"), numbertojson(x.qtde_importadores)),
                      xmlelement("user_insert",       xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",       xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",       xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",       xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                      operporto.pkg_schedule_backend.fnc_get_agencia_etiqueta(xmlelement("params",
                                                                                xmlattributes(''object'' as "type"),
                                                                                xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                            ),
                      operporto.pkg_schedule_backend.fnc_get_importador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               ),
                      operporto.pkg_schedule_backend.fnc_get_exportador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               ),
                      operporto.pkg_schedule_backend.fnc_get_prog_grupo_email(xmlelement("params",
                                                                                xmlattributes(''object'' as "type"),
                                                                                xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               )
                   )
                )
             )
        from (
      select p.programacao_id
           , p.qtde_total
           , p.imo
           , (select e.embarcacao_id
                from  operporto.v$embarcacao e
               where e.imo = p.imo
             ) as embarcacao_id
           , (select e.vessel_name
                from  operporto.v$embarcacao e
               where e.imo = p.imo
             ) as vessel_name
           , p.berco_id
           ,(select b.descricao
               from  operporto.v$berco b
              where b.berco_id = p.berco_id
             ) as berco_descricao
           , p.eta
           , p.etb
           , p.ets
           , p.prancha
           , p.pais_origem_id
           , (select cp.descricao_portugues
                from cep.v$pais cp
               where cp.pais_id = p.pais_origem_id
             ) as pais_nome
           , p.porto_origem_id
           , (select hp.nome
                from  operporto.v$porto hp
               where hp.porto_id = p.porto_origem_id
             ) as porto_nome
           , (select kss.fnc_concat_all(
                 kss.to_concat_expr((
                    et.descricao ||
                    '' - '' ||
                    trim(to_char(bl.qtde_descarga, ''999G999G990D99'', ''NLS_NUMERIC_CHARACTERS = '''',.'''''')) ||
                    '' Ton''), ''<br/>'')
                 )
                from recinto.v$produto_categoria prod
               inner join operporto.v$programacao_etiqueta bl
                       on bl.categoria_id = prod.categoria_id
               inner join operporto.v$etiqueta et
                       on et.etiqueta_id = bl.etiqueta_id
               where p.programacao_id = bl.programacao_id
                 and et.tipo_id = 3
             ) as produtos
           , p.status_id
           , (select crc.rv_abbreviation
                from operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''PROGRAMACAO.STATUS_ID''
                 and crc.rv_low_value = p.status_id
             ) as status
           , p.etapa_id
           , (select crc.rv_abbreviation
                from operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''PROGRAMACAO.ETAPA_ID''
                 and crc.rv_low_value = p.etapa_id
             ) as etapa_descricao
           , p.calado_after
           , p.calado_forward
           , p.dwt_viagem
           , p.restricao
           , p.observacao
           , (select count(*)
                from operporto.v$ordem_servico os
               where os.programacao_id = p.programacao_id
                 and os.status_id <> 2
             ) as indicador_os
           , (select sum(i.qtde_descarga)
                from operporto.v$programacao_etiqueta i
               inner join operporto.v$etiqueta et
                       on et.etiqueta_id = i.etiqueta_id
               where i.programacao_id = p.programacao_id
                 and et.tipo_id = 3
             ) as qtde_importadores
           , p.user_insert
           , p.date_insert
           , p.user_update
           , p.date_update
        from operporto.v$programacao p
       order by p.etb asc
           ) x
       where 1=1');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.imo) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.imo)) like upper(kss.pkg_string.fnc_string_clean('''||i.imo||'%''))');
      end if;

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.pais_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_origem_id = '||i.pais_origem_id);
      end if;

      if trim(i.porto_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_origem_id = '||i.porto_origem_id);
      end if;

      if trim(i.porto_nome) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.porto_nome)) like upper(kss.pkg_string.fnc_string_clean('''||i.porto_nome||'%''))');
      end if;

      if trim(i.status_id) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id = '||i.status_id);
      end if;

      if trim(i.st_nao_cancelado) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id <> 4');
      end if;

      if trim(i.status_group) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id in '||i.status_group);
      end if;

      if trim(i.etapa_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etapa_id = '||i.etapa_id);
      end if;

      if trim(i.restricao) is not null then
         dbms_lob.append(v_sql, '
         and x.restricao = '||i.restricao);
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      --Filtro das datas do ETA
      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.eta between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            or x.ets between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is null then
            dbms_lob.append(v_sql, '
            and x.eta >= '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.eta_fim) is not null and trim(i.eta_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.eta <= '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETB
      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.etb between '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is null then
            dbms_lob.append(v_sql, '
            and x.etb >= '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.etb_fim) is not null and trim(i.etb_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.etb <= '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETS
      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.ets between '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is null then
            dbms_lob.append(v_sql, '
            and x.ets >= '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.ets_fim) is not null and trim(i.ets_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.ets <= '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;



function fnc_get_lineup
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id   integer      path '/params/programacao_id'
                 , imo              integer      path '/params/imo'
                 , berco_id         integer      path '/params/berco_id'
                 , pais_origem_id   integer      path '/params/pais_origem_id'
                 , porto_origem_id  integer      path '/params/porto_origem_id'
                 , porto_nome       varchar2(50) path '/params/porto_nome'
                 , status_id        integer      path '/params/status_id'
                 , st_nao_cancelado integer      path '/params/st_nao_cancelado'
                 , etapa_id         integer      path '/params/etapa_id'
                 , restricao        integer      path '/params/restricao'
                 , embarcacao_id    integer      path '/params/embarcacao_id'
                 , data_inicio      varchar2(20) path '/params/data_inicio'
                 , data_fim         varchar2(20) path '/params/data_fim'
                 , eta_inicio       varchar2(20) path '/params/eta_inicio'
                 , eta_fim          varchar2(20) path '/params/eta_fim'
                 , etb_inicio       varchar2(20) path '/params/etb_inicio'
                 , etb_fim          varchar2(20) path '/params/etb_fim'
                 , ets_inicio       varchar2(20) path '/params/ets_inicio'
                 , ets_fim          varchar2(20) path '/params/ets_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("programacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_id",    xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("qtde_total",        xmlattributes(''number'' as "type"), numbertojson(x.qtde_total)),
                      xmlelement("imo",               xmlattributes(''number'' as "type"), numbertojson(x.imo)),
                      xmlelement("embarcacao_id",     xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("vessel_name",       xmlattributes(''string'' as "type"), stringtojson(x.vessel_name)),
                      xmlelement("berco_id",          xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                      xmlelement("berco_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.berco_descricao)),
                      xmlelement("eta",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.eta), ''yyyy-mm-dd''))),
                      xmlelement("etb",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.etb), ''yyyy-mm-dd''))),
                      xmlelement("ets",               xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.ets), ''yyyy-mm-dd''))),
                      xmlelement("pais_id",           xmlattributes(''number'' as "type"), numbertojson(x.pais_origem_id)),
                      xmlelement("pais_nome",         xmlattributes(''string'' as "type"), stringtojson(x.pais_nome)),
                      xmlelement("porto_origem_id",   xmlattributes(''number'' as "type"), numbertojson(x.porto_origem_id)),
                      xmlelement("porto_nome",        xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                      xmlelement("importadores",      xmlattributes(''string'' as "type"), stringtojson(x.importadores)),
                      xmlelement("produtos",          xmlattributes(''string'' as "type"), stringtojson(x.produtos)),
                      xmlelement("status_id",         xmlattributes(''number'' as "type"), numbertojson(x.status_id)),
                      xmlelement("status",            xmlattributes(''string'' as "type"), stringtojson(x.status)),
                      xmlelement("etapa_id",          xmlattributes(''number'' as "type"), numbertojson(x.etapa_id)),
                      xmlelement("etapa_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.etapa_descricao)),
                      xmlelement("restricao",         xmlattributes(''number'' as "type"), numbertojson(x.restricao)),
                      xmlelement("calado_after",      xmlattributes(''number'' as "type"), numbertojson(x.calado_after)),
                      xmlelement("calado_forward",    xmlattributes(''number'' as "type"), numbertojson(x.calado_forward)),
                      xmlelement("dwt_viagem",        xmlattributes(''number'' as "type"), numbertojson(x.dwt_viagem)),
                      xmlelement("observacao",        xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("indicador_os",      xmlattributes(''number'' as "type"), numbertojson(x.indicador_os)),
                      xmlelement("qtde_importadores", xmlattributes(''number'' as "type"), numbertojson(x.qtde_importadores)),
                      xmlelement("user_insert",       xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",       xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",       xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",       xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                      operporto.pkg_schedule_backend.fnc_get_agencia_etiqueta(xmlelement("params",
                                                                                xmlattributes(''object'' as "type"),
                                                                                xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                            ),
                      operporto.pkg_schedule_backend.fnc_get_importador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               ),
                      operporto.pkg_schedule_backend.fnc_get_exportador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               ),
                      operporto.pkg_schedule_backend.fnc_get_prog_grupo_email(xmlelement("params",
                                                                                xmlattributes(''object'' as "type"),
                                                                                xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)))
                                                                               )
                   )
                )
             )
        from (
      select p.programacao_id
           , p.qtde_total
           , p.imo
           , (select e.embarcacao_id
                from  operporto.v$embarcacao e
               where e.imo = p.imo
             ) as embarcacao_id
           , (select e.vessel_name
                from  operporto.v$embarcacao e
               where e.imo = p.imo
             ) as vessel_name
           , p.berco_id
           ,(select b.descricao
               from  operporto.v$berco b
              where b.berco_id = p.berco_id
             ) as berco_descricao
           , p.eta
           , p.etb
           , p.ets
           , p.pais_origem_id
           , (select cp.descricao_portugues
                from cep.v$pais cp
               where cp.pais_id = p.pais_origem_id
             ) as pais_nome
           , p.porto_origem_id
           , (select hp.nome
                from  operporto.v$porto hp
               where hp.porto_id = p.porto_origem_id
             ) as porto_nome
           , (select kss.fnc_concat_all(
                 kss.to_concat_expr((
                    et.descricao ||
                    '' - '' ||
                    trim(to_char(bl.qtde_descarga, ''999G999G990D99'', ''NLS_NUMERIC_CHARACTERS = '''',.'''''')) ||
                    '' Ton''), ''<br/>'')
                 )
                from recinto.v$produto_categoria prod
               inner join operporto.v$programacao_etiqueta bl
                       on bl.categoria_id = prod.categoria_id
               inner join operporto.v$etiqueta et
                       on et.etiqueta_id = bl.etiqueta_id
               where p.programacao_id = bl.programacao_id
                 and et.tipo_id = 3
             ) as importadores
           , (select kss.fnc_concat_all(
                     kss.to_concat_expr((prod.descricao||
                        '' - '' ||
                        trim(to_char((select sum(pe.qtde_descarga)
                                        from recinto.v$produto_categoria cat
                                       inner join operporto.v$programacao_etiqueta pe
                                               on pe.categoria_id = cat.categoria_id
                                       inner join operporto.v$etiqueta etq
                                               on etq.etiqueta_id = pe.etiqueta_id
                                       where pe.programacao_id = p.programacao_id
                                         and etq.tipo_id = 3
                                         and cat.categoria_id = prod.categoria_id
                                      ), ''999G999G990D999'', ''NLS_NUMERIC_CHARACTERS = '''',.'''''')) ||
                        '' Ton'')
                      , ''<br/>''))
                  from recinto.v$produto_categoria prod
                 where exists (
                    select 1
                      from operporto.v$programacao_etiqueta pet
                     inner join operporto.v$etiqueta et
                             on et.etiqueta_id = pet.etiqueta_id
                     where pet.categoria_id = prod.categoria_id
                       and et.tipo_id = 3
                       and pet.programacao_id = p.programacao_id
                 )
             ) as produtos
           , p.status_id
           , (select crc.rv_abbreviation
                from operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''PROGRAMACAO.STATUS_ID''
                 and crc.rv_low_value = p.status_id
             ) as status
           , p.etapa_id
           , (select crc.rv_abbreviation
                from operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''PROGRAMACAO.ETAPA_ID''
                 and crc.rv_low_value = p.etapa_id
             ) as etapa_descricao
           , p.calado_after
           , p.calado_forward
           , p.dwt_viagem
           , p.restricao
           , p.observacao
           , (select count(*)
                from operporto.v$ordem_servico os
               where os.programacao_id = p.programacao_id
                 and os.status_id <> 2
             ) as indicador_os
           , (select sum(i.qtde_descarga)
                from operporto.v$programacao_etiqueta i
               inner join operporto.v$etiqueta et
                       on et.etiqueta_id = i.etiqueta_id
               where i.programacao_id = p.programacao_id
                 and et.tipo_id = 3
             ) as qtde_importadores
           , p.user_insert
           , p.date_insert
           , p.user_update
           , p.date_update
        from operporto.v$programacao p
       order by p.etb asc
           ) x
       where x.status_id in (2,5)');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.imo) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.imo)) like upper(kss.pkg_string.fnc_string_clean('''||i.imo||'%''))');
      end if;

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.pais_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_origem_id = '||i.pais_origem_id);
      end if;

      if trim(i.porto_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_origem_id = '||i.porto_origem_id);
      end if;

      if trim(i.porto_nome) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.porto_nome)) like upper(kss.pkg_string.fnc_string_clean('''||i.porto_nome||'%''))');
      end if;

      if trim(i.status_id) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id = '||i.status_id);
      end if;

      if trim(i.st_nao_cancelado) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id <> 4');
      end if;

      if trim(i.etapa_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etapa_id = '||i.etapa_id);
      end if;

      if trim(i.restricao) is not null then
         dbms_lob.append(v_sql, '
         and x.restricao = '||i.restricao);
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      --Filtro das datas do ETA
      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.eta between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            or x.ets between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is null then
            dbms_lob.append(v_sql, '
            and x.eta >= '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.eta_fim) is not null and trim(i.eta_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.eta <= '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETB
      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.etb between '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is null then
            dbms_lob.append(v_sql, '
            and x.etb >= '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.etb_fim) is not null and trim(i.etb_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.etb <= '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETS
      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.ets between '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is null then
            dbms_lob.append(v_sql, '
            and x.ets >= '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.ets_fim) is not null and trim(i.ets_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.ets <= '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_lineup_produto
 return xmltype as
v_result xmltype;
v_sql    clob;
begin
   dbms_lob.createtemporary(v_sql, true);
   dbms_lob.append(v_sql, '
   select xmlelement("lineup_produto",
             xmlattributes(''array'' as "type"),
             xmlagg(
                xmlelement("arrayItem",
                   xmlattributes(''object'' as "type"),
                   xmlelement("programacao_id",    xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                   xmlelement("produto_qtde",      xmlattributes(''number'' as "type"), numbertojson(x.produto_qtde)),
                   xmlelement("categoria_id",      xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                   xmlelement("produto_descricao", xmlattributes(''string'' as "type"), stringtojson(x.produto_descricao)),
                   xmlelement("importadores",      xmlattributes(''string'' as "type"), stringtojson(x.importadores)),
                   xmlelement("indicador_os",      xmlattributes(''number'' as "type"), numbertojson(x.indicador_os)),
                   x.programacao
                )
             )
          )
     from (
          select pe.programacao_id
               , sum(pe.qtde_descarga) as produto_qtde
               , pe.categoria_id
               , (select pc.descricao
                    from recinto.v$produto_categoria pc
                   where pc.categoria_id = pe.categoria_id
                 ) as produto_descricao
               ,(select kss.fnc_concat_all(distinct kss.to_concat_expr((et.descricao), '', ''))
                   from recinto.v$produto_categoria prod
                  inner join operporto.v$programacao_etiqueta bl
                          on bl.categoria_id = prod.categoria_id
                  inner join operporto.v$etiqueta et
                          on et.etiqueta_id = bl.etiqueta_id
                       where bl.programacao_id = pe.programacao_id
                         and bl.categoria_id = pe.categoria_id
                         and et.tipo_id = 3
                ) as importadores
               , (select xmlelement("programacao",
                            xmlattributes(''object'' as "type"),
                            xmlelement("programacao_id",  xmlattributes(''number'' as "type"), numbertojson(z.programacao_id)),
                            xmlelement("qtde_total",      xmlattributes(''number'' as "type"), numbertojson(z.qtde_total)),
                            xmlelement("imo",             xmlattributes(''number'' as "type"), numbertojson(z.imo)),
                            xmlelement("vessel_name",     xmlattributes(''string'' as "type"), stringtojson(z.vessel_name)),
                            xmlelement("berco_id",        xmlattributes(''number'' as "type"), numbertojson(z.berco_id)),
                            xmlelement("berco_descricao", xmlattributes(''string'' as "type"), stringtojson(z.berco_descricao)),
                            xmlelement("eta",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(z.eta), ''yyyy-mm-dd''))),
                            xmlelement("etb",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(z.etb), ''yyyy-mm-dd''))),
                            xmlelement("ets",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(z.ets), ''yyyy-mm-dd''))),
                            xmlelement("pais_origem_id",  xmlattributes(''number'' as "type"), numbertojson(z.pais_origem_id)),
                            xmlelement("pais_nome",       xmlattributes(''string'' as "type"), stringtojson(z.pais_nome)),
                            xmlelement("porto_origem_id", xmlattributes(''number'' as "type"), numbertojson(z.porto_origem_id)),
                            xmlelement("porto_nome",      xmlattributes(''string'' as "type"), stringtojson(z.porto_nome)),
                            xmlelement("status_id",       xmlattributes(''number'' as "type"), numbertojson(z.status_id)),
                            xmlelement("status",          xmlattributes(''string'' as "type"), stringtojson(z.status)),
                            xmlelement("etapa_id",        xmlattributes(''number'' as "type"), numbertojson(z.etapa_id)),
                            xmlelement("etapa_descricao", xmlattributes(''string'' as "type"), stringtojson(z.etapa_descricao)),
                            xmlelement("calado_after",    xmlattributes(''number'' as "type"), numbertojson(z.calado_after)),
                            xmlelement("calado_forward",  xmlattributes(''number'' as "type"), numbertojson(z.calado_forward)),
                            xmlelement("dwt_viagem",      xmlattributes(''number'' as "type"), numbertojson(z.dwt_viagem)),
                            xmlelement("restricao",       xmlattributes(''number'' as "type"), numbertojson(z.restricao)),
                            xmlelement("observacao",      xmlattributes(''string'' as "type"), stringtojson(z.observacao)),
                            xmlelement("user_insert",     xmlattributes(''string'' as "type"), stringtojson(z.user_insert)),
                            xmlelement("date_insert",     xmlattributes(''string'' as "type"), datetojson(z.date_insert)),
                            xmlelement("user_update",     xmlattributes(''string'' as "type"), stringtojson(z.user_update)),
                            xmlelement("date_update",     xmlattributes(''string'' as "type"), datetojson(z.date_update))
                         )
                    from (
                       select y.*
                            , (select crc.rv_abbreviation
                                 from operporto.v$cg_ref_codes crc
                                where crc.rv_domain = ''PROGRAMACAO.ETAPA_ID''
                                  and crc.rv_low_value = y.etapa_id) as etapa_descricao
                            , (select crc.rv_abbreviation
                                 from operporto.v$cg_ref_codes crc
                                where crc.rv_domain = ''PROGRAMACAO.STATUS_ID''
                                  and crc.rv_low_value = y.status_id) as status
                            , (select hp.nome
                                 from  operporto.v$porto hp
                                where hp.porto_id = y.porto_origem_id) as porto_nome
                            , (select cp.descricao_portugues
                                 from cep.v$pais cp
                                where cp.pais_id = y.pais_origem_id) as pais_nome
                            , (select b.descricao
                                 from  operporto.v$berco b
                                where b.berco_id = y.berco_id) as berco_descricao
                         from operporto.v$programacao y
                    ) z
                   where z.programacao_id = pe.programacao_id
                 ) as programacao
               , (select count(*)
                    from operporto.v$ordem_servico os
                   where os.programacao_id = pe.programacao_id
                     and os.status_id <> 2
                 ) as indicador_os
               , (select etb
                    from operporto.v$programacao
                   where programacao_id = pe.programacao_id
                 ) as ordem_etb
            from operporto.v$programacao_etiqueta pe
           inner join recinto.v$produto_categoria cat
                   on pe.categoria_id = cat.categoria_id
           inner join operporto.v$etiqueta etq
                   on etq.etiqueta_id = pe.etiqueta_id
           inner join operporto.v$programacao p
                   on p.programacao_id = pe.programacao_id
           where etq.tipo_id = 3
             and p.status_id in (2,5)
           group by pe.programacao_id, pe.categoria_id
           order by ordem_etb desc
        ) x
    where 1=1');

   execute immediate v_sql
      into v_result;

   return v_result;
end;

function fnc_get_cards_schedule
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id   integer      path '/params/programacao_id'
                 , imo              integer      path '/params/imo'
                 , berco_id         integer      path '/params/berco_id'
                 , pais_origem_id   integer      path '/params/pais_origem_id'
                 , porto_origem_id  integer      path '/params/porto_origem_id'
                 , porto_nome       varchar2(50) path '/params/porto_nome'
                 , status_id        integer      path '/params/status_id'
                 , st_nao_cancelado integer      path '/params/st_nao_cancelado'
                 , status_group     varchar2(99) path '/params/status_group'
                 , embarcacao_id    integer      path '/params/embarcacao_id'
                 , eta_inicio       varchar2(20) path '/params/eta_inicio'
                 , eta_fim          varchar2(20) path '/params/eta_fim'
                 , etb_inicio       varchar2(20) path '/params/etb_inicio'
                 , etb_fim          varchar2(20) path '/params/etb_fim'
                 , ets_inicio       varchar2(20) path '/params/ets_inicio'
                 , ets_fim          varchar2(20) path '/params/ets_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("programacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("id",              xmlattributes(''number'' as "type"), numbertojson(x.id)),
                      xmlelement("flag",            xmlattributes(''string'' as "type"), stringtojson(x.flag)),
                      xmlelement("programacao_id",  xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("qtde_total",      xmlattributes(''number'' as "type"), numbertojson(x.qtde_total)),
                      xmlelement("imo",             xmlattributes(''number'' as "type"), numbertojson(x.imo)),
                      xmlelement("embarcacao_id",   xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("vessel_name",     xmlattributes(''string'' as "type"), stringtojson(x.vessel_name)),
                      xmlelement("berco_id",        xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                      xmlelement("berco_descricao", xmlattributes(''string'' as "type"), stringtojson(x.berco_descricao)),
                      xmlelement("eta",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.eta), ''yyyy-mm-dd''))),
                      xmlelement("etb",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.etb), ''yyyy-mm-dd''))),
                      xmlelement("ets",             xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.ets), ''yyyy-mm-dd''))),
                      xmlelement("pais_id",         xmlattributes(''number'' as "type"), numbertojson(x.pais_origem_id)),
                      xmlelement("pais_nome",       xmlattributes(''string'' as "type"), stringtojson(x.pais_nome)),
                      xmlelement("porto_origem_id", xmlattributes(''number'' as "type"), numbertojson(x.porto_origem_id)),
                      xmlelement("porto_nome",      xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                      xmlelement("calado_after",    xmlattributes(''number'' as "type"), numbertojson(x.calado_after)),
                      xmlelement("calado_forward",  xmlattributes(''number'' as "type"), numbertojson(x.calado_forward)),
                      xmlelement("dwt_viagem",      xmlattributes(''number'' as "type"), numbertojson(x.dwt_viagem)),
                      xmlelement("status_id",       xmlattributes(''number'' as "type"), numbertojson(x.status_id)),
                      xmlelement("restricao",       xmlattributes(''number'' as "type"), numbertojson(x.restricao)),
                      xmlelement("observacao",      xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      operporto.pkg_schedule_backend.fnc_get_agencia_etiqueta(xmlelement("params",
                                                                                xmlattributes(''object'' as "type"),
                                                                                xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                                                                                xmlelement("flag", xmlattributes(''string'' as "type"), stringtojson(x.flag)))
                                                                            ),
                      operporto.pkg_schedule_backend.fnc_get_importador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                                                                                   xmlelement("flag", xmlattributes(''string'' as "type"), stringtojson(x.flag)))
                                                                               ),
                      operporto.pkg_schedule_backend.fnc_get_exportador_etiqueta(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                                                                                   xmlelement("flag", xmlattributes(''string'' as "type"), stringtojson(x.flag)))
                                                                               )
                   )
                )
             )
        from (
          select rownum as id
               , a.* from (
            select p.programacao_id
                 , ''P'' as flag
                 , p.qtde_total
                 , p.imo
                 , (select e.embarcacao_id
                      from  operporto.v$embarcacao e
                     where e.imo = p.imo
                   ) as embarcacao_id
                 , (select e.vessel_name
                      from  operporto.v$embarcacao e
                     where e.imo = p.imo
                   ) as vessel_name
                 , p.berco_id
                 ,(select b.descricao
                     from  operporto.v$berco b
                    where b.berco_id = p.berco_id
                   ) as berco_descricao
                 , p.eta
                 , p.etb
                 , p.ets
                 , p.pais_origem_id
                 , (select cp.descricao_portugues
                      from cep.v$pais cp
                     where cp.pais_id = p.pais_origem_id
                   ) as pais_nome
                 , p.porto_origem_id
                 , (select hp.nome
                      from  operporto.v$porto hp
                     where hp.porto_id = p.porto_origem_id
                   ) as porto_nome
                 , p.calado_after
                 , p.calado_forward
                 , p.dwt_viagem
                 , p.status_id
                 , p.restricao
                 , p.observacao
              from operporto.v$programacao p
             where trunc(p.eta) <= trunc(p.etb)
               and trunc(p.etb) <= trunc(p.ets)
            union
            select m.manutencao_id as programacao_id
                 , ''M'' as flag
                 , null as qtde_total
                 , null as imo
                 , null as embarcacao_id
                 , null as vessel_name
                 , m.berco_id
                 ,(select b.descricao
                     from  operporto.v$berco b
                    where b.berco_id = m.berco_id
                   ) as berco_descricao
                 , m.data_inicio as eta
                 , m.data_inicio as etb
                 , m.data_fim as ets
                 , null as pais_origem_id
                 , null as pais_nome
                 , null as porto_origem_id
                 , null as porto_nome
                 , null as calado_after
                 , null as calado_forward
                 , null as dwt_viagem
                 , 1 as status_id
                 , 0 as restricao
                 , m.observacao
              from operporto.v$manutencao m
             where m.data_inicio <= m.data_fim
            ) a
          order by a.etb asc
           ) x
       where 1=1');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.imo) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.imo)) like upper(kss.pkg_string.fnc_string_clean('''||i.imo||'%''))');
      end if;

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.pais_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_origem_id = '||i.pais_origem_id);
      end if;

      if trim(i.porto_origem_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_origem_id = '||i.porto_origem_id);
      end if;

      if trim(i.porto_nome) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.porto_nome)) like upper(kss.pkg_string.fnc_string_clean('''||i.porto_nome||'%''))');
      end if;

      if trim(i.status_id) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id = '||i.status_id);
      end if;

      if trim(i.st_nao_cancelado) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id <> 4');
      end if;

      if trim(i.status_group) is not null then
         dbms_lob.append(v_sql, '
         and x.status_id in '||i.status_group);
      end if;

      --Filtro das datas do ETA
      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.eta between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            or x.etb between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
	        or x.ets between '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.eta_inicio) is not null and trim(i.eta_fim) is null then
            dbms_lob.append(v_sql, '
            and x.eta >= '''|| to_date(i.eta_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.eta_fim) is not null and trim(i.eta_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.eta <= '''|| to_date(i.eta_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETB
      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.etb between '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.etb_inicio) is not null and trim(i.etb_fim) is null then
            dbms_lob.append(v_sql, '
            and x.etb >= '''|| to_date(i.etb_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.etb_fim) is not null and trim(i.etb_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.etb <= '''|| to_date(i.etb_fim, 'yyyy-mm-dd') ||'''');
      end if;

      --Filtro das datas do ETS
      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.ets between '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is null then
            dbms_lob.append(v_sql, '
            and x.ets >= '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.ets_fim) is not null and trim(i.ets_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.ets <= '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''');
      end if;



      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_next_programacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id   integer      path '/params/berco_id'
                 , ets_inicio varchar2(20) path '/params/ets_inicio'
                 , ets_fim    varchar2(20) path '/params/ets_fim'
                 , limited    integer      path '/params/limited'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("programacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etb",            xmlattributes(''string'' as "type"), stringtojson(to_char(trunc(x.etb), ''yyyy-mm-dd'')))
                   )
                )
             )
        from (
      select p.programacao_id
           , p.etb
           , p.berco_id
           , p.ets
        from operporto.v$programacao p
       order by p.etb desc
           ) x
       where 1=1');

      if trim(i.limited) is not null then
         dbms_lob.append(v_sql, '
         and rownum = '||i.limited);
      end if;

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      --Filtro das datas do ETS
      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.ets between '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||''' and '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''
            )');
      end if;

      if trim(i.ets_inicio) is not null and trim(i.ets_fim) is null then
            dbms_lob.append(v_sql, '
            and x.ets >= '''|| to_date(i.ets_inicio, 'yyyy-mm-dd') ||'''');
      end if;

      if trim(i.ets_fim) is not null and trim(i.ets_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.ets <= '''|| to_date(i.ets_fim, 'yyyy-mm-dd') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_col_porto
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('porto_id',          'Porto (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_string('nome',              'Porto (nome)'),
                kss.pkg_cols_devextreme.fnc_col_number('pais.descricao',    'Descric?o', 0),
                kss.pkg_cols_devextreme.fnc_col_number('bigrama',           'Bigrama'),
                kss.pkg_cols_devextreme.fnc_col_number('trigrama',          'Trigrama'),
                kss.pkg_cols_devextreme.fnc_col_string('ativo',             'Cod. Porto'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao',        'Observac?o'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_porto;

function fnc_fil_porto
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('porto_id',  'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('nome',  'Porto (nome)', '', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getPorto'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_porto;

function fnc_get_porto
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   porto_id integer       path '/params/porto_id'
                 , pais_id  integer       path '/params/pais_id'
                 , bigrama  varchar2(2)   path '/params/bigrama'
                 , trigrama varchar2(3)   path '/params/trigrama'
                 , nome     varchar2(100) path '/params/nome'
                 , ativo    integer       path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                 xmlattributes(''object'' as "type"),
                 xmlconcat(
                    xmlelement("header",
                       xmlattributes(''object'' as "type"),
                       xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''porto'')),
                       operporto.pkg_schedule_backend.fnc_col_porto(),
                       operporto.pkg_schedule_backend.fnc_fil_porto()
                 ),
                 xmlelement("porto",
                    xmlattributes(''array'' as "type"),
                    xmlagg(
                       xmlelement("arrayItem",
                          xmlattributes(''object'' as "type"),
                          xmlelement("porto_id",    xmlattributes(''number'' as "type"), numbertojson(x.porto_id)),
                          xmlelement("nome",        xmlattributes(''string'' as "type"), stringtojson(x.nome)),
                          xmlelement("pais_id",     xmlattributes(''number'' as "type"), numbertojson(x.pais_id)),
                          xmlelement("pais_nome",   xmlattributes(''string'' as "type"), stringtojson(x.pais_nome)),
                          xmlelement("bigrama",     xmlattributes(''string'' as "type"), stringtojson(x.bigrama)),
                          xmlelement("trigrama",    xmlattributes(''string'' as "type"), stringtojson(x.trigrama)),
                          xmlelement("observacao",  xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                          xmlelement("ativo",       xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                          xmlelement("user_insert", xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                          xmlelement("date_insert", xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                          xmlelement("user_update", xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                          xmlelement("date_update", xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                          xmlelement("display_name",xmlattributes(''string'' as "type"), stringtojson(upper(x.nome||'' / ''||x.pais_nome||'' / ''||x.bigrama||x.trigrama)))
                       )
                    )
                 )
              )
           )
        from (
      select p.porto_id
           , p.nome
           , p.pais_id
           , (select nvl(cp.descricao_portugues,descricao)
                from cep.v$pais cp
               where cp.pais_id = p.pais_id
             ) as pais_nome
           , p.bigrama
           , p.trigrama
           , p.observacao
           , p.ativo
           , p.user_insert
           , p.date_insert
           , p.user_update
           , p.date_update
        from  operporto.v$porto p
           ) x
       where 1=1');

      if trim(i.porto_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_id = '||i.porto_id);
      end if;

      if trim(i.pais_id) is not null then
         dbms_lob.append(v_sql, '
         and x.pais_id = '||i.pais_id);
      end if;

      if trim(i.bigrama) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.bigrama)) like upper(kss.pkg_string.fnc_string_clean('''||i.bigrama||'%''))');
      end if;

      if trim(i.trigrama) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.trigrama)) like upper(kss.pkg_string.fnc_string_clean('''||i.trigrama||'%''))');
      end if;

      if trim(i.nome) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.nome)) like upper(kss.pkg_string.fnc_string_clean('''||i.nome||'%''))');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;
   procedure prc_cad_porto
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation  varchar2(30)      path '/params/operation'
                 , porto_id   integer           path '/params/porto_id'
                 , nome       varchar2(50)      path '/params/nome'
                 , pais_id    integer           path '/params/pais_id'
                 , bigrama    varchar2(2)       path '/params/bigrama'
                 , trigrama   varchar2(3)       path '/params/trigrama'
                 , observacao varchar2(1000)    path '/params/observacao'
                 , ativo      integer           path '/params/ativo'
                 , justificativa varchar2(200)  path '/params/justificativa'
                 )
   ) loop
      v_id := i.porto_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_operporto.prc_ins_porto(p_porto_id   => v_id
                                                 ,p_nome       => i.nome
                                                 ,p_pais_id    => i.pais_id
                                                 ,p_bigrama    => i.bigrama
                                                 ,p_trigrama   => i.trigrama
                                                 ,p_observacao => i.observacao
                                                 ,p_ativo      => i.ativo
                                                 );
            v_msg := 'Berco inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_operporto.prc_alt_porto(p_porto_id   => i.porto_id
                                                 ,p_nome       => i.nome
                                                 ,p_pais_id    => i.pais_id
                                                 ,p_bigrama    => i.bigrama
                                                 ,p_trigrama   => i.trigrama
                                                 ,p_observacao => i.observacao
                                                 ,p_ativo      => i.ativo
                                                  );
            if v_msg is null then
               v_msg := 'Berco alterado com sucesso.';
            end if;   
            
         when 'ATIVO' then
            operporto.pkg_operporto.prc_alt_ativo_porto(p_porto_id  => i.porto_id
                                                 ,p_ativo           => i.ativo
                                                 ,p_justificativa   => i.justificativa
                                                  );

            case i.ativo
               when 1 then
                  v_msg:='Porto ativado com sucesso.';
               when 0 then
                  v_msg:='Porto inativado com sucesso.';
               else
                  v_msg:='Indicador da flag n?o consta nas opc?es.';
            end case;


          when 'DELETE' then
             operporto.pkg_operporto.prc_del_porto(p_porto_id => i.porto_id
             	                                    ,p_justificativa => i.justificativa
                                                  );
            v_msg := 'Berco excluido com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("porto_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_porto;

function fnc_col_tipo_embarcao
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('tipo_embarcacao_id','Porto (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_string('descricao',         'Descricac?o'),
                --kss.pkg_cols_devextreme.fnc_col_string('ativo',             'Ativo'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao',        'Observac?o'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;

   return v_result;
end fnc_col_tipo_embarcao;

function fnc_fil_tipo_embarcao
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('tipo_embarcacao_id', 'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',            'Descric?o', '', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getTipoEmbarcacao'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_tipo_embarcao;

function fnc_get_tipo_embarcacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_embarcacao_id integer      path '/params/tipo_embarcacao_id'
                 , descricao          varchar2(60) path '/params/descricao'
                 , ativo              integer      path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
         select xmlelement("root",
                   xmlattributes(''object'' as "type"),
                   xmlconcat(
                      xmlelement("header",
                         xmlattributes(''object'' as "type"),
                         xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''tipo_embarcacao'')),
                         operporto.pkg_schedule_backend.fnc_col_tipo_embarcao(),
                         operporto.pkg_schedule_backend.fnc_fil_tipo_embarcao()
                      ),
                      xmlelement("tipo_embarcacao",
                      xmlattributes(''array'' as "type"),
                      xmlagg(
                         xmlelement("arrayItem",
                            xmlattributes(''object'' as "type"),
                            xmlelement("tipo_embarcacao_id", xmlattributes(''number'' as "type"), numbertojson(x.tipo_embarcacao_id)),
                            xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                            xmlelement("observacao",         xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                            xmlelement("ativo",              xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                            xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                            xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                            xmlelement("user_update",        xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                            xmlelement("date_update",        xmlattributes(''string'' as "type"), datetojson(x.date_update))
                         )
                      )
                   )
                )
             )
        from (
      select t.tipo_embarcacao_id
           , t.observacao
           , t.descricao
           , t.ativo
           , t.user_insert
           , t.date_insert
           , t.user_update
           , t.date_update
        from  operporto.v$tipo_embarcacao t

           ) x
       where 1=1
      ');

      if trim(i.tipo_embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_embarcacao_id = '||i.tipo_embarcacao_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_tipo_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation          varchar2(30)     path '/params/operation'
                 , tipo_embarcacao_id integer          path '/params/tipo_embarcacao_id'
                 , descricao          varchar2(60)     path '/params/descricao'
                 , observacao         varchar2(500)    path '/params/observacao'
                 , ativo              integer          path '/params/ativo'
                 , justificativa      varchar2(4000)   path '/params/justificativa'
                 )
   ) loop
      v_id := i.tipo_embarcacao_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_operporto.prc_ins_tipo_embarcacao(p_tipo_embarcacao_id => v_id
                                                      ,p_observacao         => i.observacao
                                                      ,p_descricao          => i.descricao
                                                      ,p_ativo              => i.ativo
                                                    );
            v_msg := 'Tipo embarcacao inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_operporto.prc_alt_tipo_embarcacao(p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                      ,p_observacao         => i.observacao
                                                      ,p_descricao          => i.descricao
                                                      ,p_ativo              => i.ativo
                                                     );

            if v_msg is null then
               v_msg := 'Tipo embarcacao alterado com sucesso.';
            end if;

          when 'DELETE' then
             operporto.pkg_operporto.prc_del_tipo_embarcacao(p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                       ,p_justificativa      => i.justificativa
                                                       );
            v_msg := 'Tipo embarcacao excluido com sucesso.';

          when 'ATIVAR' then
            operporto.pkg_operporto.prc_alt_ativo_tipo_embarcacao(p_tipo_embarcacao_id   => i.tipo_embarcacao_id
                                                            ,p_ativo                => i.ativo
                                                      	     ,p_justificativa        => i.justificativa
                                                            );
            v_msg := 'Tipo embarcacao ativado com sucesso.';

          when 'DESATIVAR' then
            operporto.pkg_operporto.prc_alt_ativo_tipo_embarcacao(p_tipo_embarcacao_id  => i.tipo_embarcacao_id
                                                            ,p_ativo               => i.ativo
                                                      	     ,p_justificativa       => i.justificativa
                                                            );
            v_msg := 'Tipo embarcacao desativado com sucesso.';

         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("tipo_embarcacao_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_tipo_embarcacao;

function fnc_col_mec_abe_tam
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('mec_abertura_tampa_id', 'ID', 0),
                kss.pkg_cols_devextreme.fnc_col_string('descricao',         'Descricac?o'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao',        'Observac?o'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;
   return v_result;
end fnc_col_mec_abe_tam;

function fnc_fil_mec_abe_tam
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('mec_abertura_tampa_id', 'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',             'Descric?o', '', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getMecanismoAberturaTampa'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_mec_abe_tam;

function fnc_get_mec_abertura_tampa
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mec_abertura_tampa_id integer       path '/params/mec_abertura_tampa_id'
                 , descricao             varchar2(100) path '/params/descricao'
                 , ativo                 integer       path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''mecanismo_abertura_tampa'')),
                      operporto.pkg_schedule_backend.fnc_col_mec_abe_tam(),
                      operporto.pkg_schedule_backend.fnc_fil_mec_abe_tam()
                   ),
                   xmlelement("mecanismo_abertura_tampa",
                      xmlattributes(''array'' as "type"),
                      xmlagg(
                         xmlelement("arrayItem",
                            xmlattributes(''object'' as "type"),
                            xmlelement("mec_abertura_tampa_id", xmlattributes(''number'' as "type"), numbertojson(x.mec_abertura_tampa_id)),
                            xmlelement("descricao",             xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                            xmlelement("observacao",            xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                            xmlelement("restricao",             xmlattributes(''number'' as "type"), numbertojson(x.restricao)),
                            xmlelement("ativo",                 xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                            xmlelement("date_insert",           xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                            xmlelement("user_insert",           xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                            xmlelement("date_update",           xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                            xmlelement("user_update",           xmlattributes(''string'' as "type"), stringtojson(x.user_update))
                        )
                     )
                  )
               )
           )
        from (
      select m.mec_abertura_tampa_id
           , m.descricao
           , m.observacao
           , m.restricao
           , m.ativo
           , m.date_insert
           , m.user_insert
           , m.date_update
           , m.user_update
        from  operporto.v$mec_abertura_tampa m

           ) x
       where 1=1');

      if trim(i.mec_abertura_tampa_id) is not null then
         dbms_lob.append(v_sql, '
         and x.mec_abertura_tampa_id = '||i.mec_abertura_tampa_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_mec_abertura_tampa
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation             varchar2(30)     path '/params/operation'
                 , mec_abertura_tampa_id integer          path '/params/mec_abertura_tampa_id'
                 , descricao             varchar2(100)    path '/params/descricao'
                 , observacao            varchar2(500)    path '/params/observacao'
                 , restricao             integer          path '/params/restricao'
                 , ativo                 integer          path '/params/ativo'
                 , justificativa         varchar2(4000)   path '/params/justificativa'
                 )
   ) loop
      v_id := i.mec_abertura_tampa_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_mec_abertura_tampa(p_mec_abertura_tampa_id => v_id
                                                             ,p_descricao             => i.descricao
                                                             ,p_observacao            => i.observacao
                                                             ,p_restricao             => i.restricao
                                                             ,p_ativo                 => i.ativo
                                                            );
            v_msg := 'Mecanismo Abertura Tampa inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_mec_abertura_tampa(p_mec_abertura_tampa_id => i.mec_abertura_tampa_id
                                                             ,p_descricao             => i.descricao
                                                             ,p_observacao            => i.observacao
                                                             ,p_restricao             => i.restricao
                                                             ,p_ativo                 => i.ativo
                                                             );

            if v_msg is null then
               v_msg := 'Mecanismo Abertura Tampa alterado com sucesso.';
            end if;

          when 'DELETE' then
             operporto.pkg_schedule.prc_del_mec_abertura_tampa(p_mec_abertura_tampa_id   => i.mec_abertura_tampa_id
                                                              ,p_justificativa           => i.justificativa
                                                              );
            v_msg := 'Mecanismo Abertura Tampa excluido com sucesso.';

          when 'ATIVAR' then
            operporto.pkg_schedule.prc_alt_ativo_mecanismo_tampa(p_mec_abertura_tampa_id  => i.mec_abertura_tampa_id
                                                                ,p_ativo                  => i.ativo
                                                      	         ,p_justificativa          => i.justificativa
                                                                );
            v_msg := 'Mecanismo de Abertura ativado com sucesso.';

          when 'DESATIVAR' then
            operporto.pkg_schedule.prc_alt_ativo_mecanismo_tampa(p_mec_abertura_tampa_id  => i.mec_abertura_tampa_id
                                                                ,p_ativo                  => i.ativo
                                                      	         ,p_justificativa          => i.justificativa
                                                                );
            v_msg := 'Mecanismo de Abertura ativado com sucesso.';

         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("mec_abertura_tampa_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_mec_abertura_tampa;

function fnc_col_tipo_porao
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('tipo_porao_id', 'ID', 0),
                kss.pkg_cols_devextreme.fnc_col_string('descricao',         'Descricac?o'),
                kss.pkg_cols_devextreme.fnc_col_string('observacao',        'Observac?o'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;
   return v_result;
end fnc_col_tipo_porao;

function fnc_fil_tipo_porao
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('tipo_porao_id', 'Identificador', '', 6),
                   kss.pkg_form_devextreme.fnc_form_textbox('descricao',             'Descric?o', '', 6)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getTipoPorao'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_tipo_porao;

function fnc_get_tipo_porao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_porao_id integer      path '/params/tipo_porao_id'
                 , descricao     varchar2(60) path '/params/descricao'
                 , ativo         integer      path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''tipo_porao'')),
                      operporto.pkg_schedule_backend.fnc_col_tipo_porao(),
                      operporto.pkg_schedule_backend.fnc_fil_tipo_porao()
                   ),
                   xmlelement("tipo_porao",
                   xmlattributes(''array'' as "type"),
                   xmlagg(
                      xmlelement("arrayItem",
                         xmlattributes(''object'' as "type"),
                         xmlelement("tipo_porao_id", xmlattributes(''number'' as "type"), numbertojson(x.tipo_porao_id)),
                         xmlelement("descricao",     xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                         xmlelement("observacao",    xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                         xmlelement("restricao",     xmlattributes(''number'' as "type"), numbertojson(x.restricao)),
                         xmlelement("ativo",         xmlattributes(''number'' as "type"), numbertojson(x.ativo)),
                         xmlelement("date_insert",   xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                         xmlelement("user_insert",   xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                         xmlelement("date_update",   xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                         xmlelement("user_update",   xmlattributes(''string'' as "type"), stringtojson(x.user_update))
                      )
                   )
                )
             )
          )
        from (
      select t.tipo_porao_id
           , t.descricao
           , t.observacao
           , t.restricao
           , t.ativo
           , t.date_insert
           , t.user_insert
           , t.date_update
           , t.user_update
        from  operporto.v$tipo_porao t
       order by t.date_insert
           ) x
       where 1=1');

      if trim(i.tipo_porao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_porao_id = '||i.tipo_porao_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      if trim(i.ativo) is not null then
         dbms_lob.append(v_sql, '
         and x.ativo = '||i.ativo);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_tipo_porao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation          varchar2(30)     path '/params/operation'
                 , tipo_porao_id      integer          path '/params/tipo_porao_id'
                 , descricao          varchar2(60)     path '/params/descricao'
                 , observacao         varchar2(500)    path '/params/observacao'
                 , restricao          integer          path '/params/restricao'
                 , ativo              integer          path '/params/ativo'
                 , justificativa      varchar2(4000)   path '/params/justificativa'
                 )
   ) loop
      v_id := i.tipo_porao_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_operporto.prc_ins_tipo_porao(p_tipo_porao_id => v_id
                                                     ,p_descricao     => i.descricao
                                                     ,p_observacao    => i.observacao
                                                     ,p_restricao     => i.restricao
                                                     ,p_ativo         => i.ativo
                                                    );
            v_msg := 'Tipo de porao inserido com sucesso.';

         when 'UPDATE' then
            operporto.pkg_operporto.prc_alt_tipo_porao(p_tipo_porao_id => i.tipo_porao_id
                                                     ,p_descricao     => i.descricao
                                                     ,p_observacao    => i.observacao
                                                     ,p_restricao     => i.restricao
                                                     ,p_ativo         => i.ativo
                                                     );

            if v_msg is null then
               v_msg := 'Tipo porao alterado com sucesso.';
            end if;

          when 'DELETE' then
             operporto.pkg_operporto.prc_del_tipo_porao(p_tipo_porao_id => i.tipo_porao_id
                                                       ,p_justificativa => i.justificativa
                                                       );
            v_msg := 'Tipo porao excluido com sucesso.';

          when 'ATIVAR' then
            operporto.pkg_operporto.prc_alt_ativo_tipo_porao(p_tipo_porao_id  => i.tipo_porao_id
                                                            ,p_ativo                  => i.ativo
                                                      	     ,p_justificativa          => i.justificativa
                                                            );
            v_msg := 'Tipo Porao ativado com sucesso.';

          when 'DESATIVAR' then
            operporto.pkg_operporto.prc_alt_ativo_tipo_porao(p_tipo_porao_id  => i.tipo_porao_id
                                                            ,p_ativo                  => i.ativo
                                                      	     ,p_justificativa          => i.justificativa
                                                            );
            v_msg := 'Tipo Porao desativado com sucesso.';

         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("tipo_porao_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_tipo_porao;

function fnc_get_embarcacao_blob
(p_parameters in  xmltype
) return xmltype as
v_result    xmltype;
v_sql       clob;
v_extension varchar2(5);
v_mime_type varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_anexo_id integer path '/params/embarcacao_anexo_id'
      )
   ) loop
      -- busca a extens?o do Arquivo
      begin       
         select upper(substr(a.descricao, instr(a.descricao, '.', -1, 1) +1))
           into v_extension
           from operporto.v$embarcacao_anexo a
          where a.embarcacao_anexo_id = i.embarcacao_anexo_id;
      exception
         when no_data_found then
            null;
      end;
      
      -- consulta o Mime-Type do Arquivo
      v_mime_type:= fnc_get_mime_type(v_extension);

      -- monta o Retorno
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("arquivo",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_anexo_id", xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_anexo_id)),
                      xmlelement("arquivo",             xmlattributes(''string'' as "type"), x.arquivo),
                      xmlelement("mime_type",           xmlattributes(''string'' as "type"), stringtojson('''||v_mime_type||'''))
                   )
                )
             )
        from (
      select a.embarcacao_anexo_id
           , replace(replace(kss.pkg_remote.fnc_blob2base64(a.arquivo), chr(13), ''''), chr(10), '''') as arquivo
        from  operporto.v$embarcacao_anexo a
           ) x
       where 1=1');

      if trim(i.embarcacao_anexo_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_anexo_id = '||i.embarcacao_anexo_id);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_porao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_porao_id integer path '/params/embarcacao_porao_id'
                 , embarcacao_id       integer path '/params/embarcacao_id'
                 , num_porao           integer path '/params/num_porao'
                 , ativo               integer path '/params/ativo'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("poroes",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_porao_id",     xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_porao_id)),
                      xmlelement("embarcacao_id",           xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("num_porao",               xmlattributes(''number'' as "type"), numbertojson(x.num_porao)),
                      xmlelement("comprimento_porao",       xmlattributes(''number'' as "type"), numbertojson(x.comprimento_porao)),
                      xmlelement("largura_porao",           xmlattributes(''number'' as "type"), numbertojson(x.largura_porao)),
                      xmlelement("comprimento_boca",        xmlattributes(''number'' as "type"), numbertojson(x.comprimento_boca)),
                      xmlelement("largura_boca",            xmlattributes(''number'' as "type"), numbertojson(x.largura_boca)),
                      xmlelement("tipo_porao_id",           xmlattributes(''number'' as "type"), numbertojson(x.tipo_porao_id)),
                      xmlelement("tipo_porao_descricao",    xmlattributes(''string'' as "type"), stringtojson(x.tipo_porao_descricao)),
                      xmlelement("mec_abertura_tampa_id",   xmlattributes(''number'' as "type"), numbertojson(x.mec_abertura_tampa_id)),
                      xmlelement("mec_abertura_tampa_desc", xmlattributes(''string'' as "type"), stringtojson(x.mec_abertura_tampa_desc)),
                      xmlelement("observacao",              xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",             xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",             xmlattributes(''string'' as "type"), datetojson(x.date_update))
                   )
                )
             )
        from (
      select p.embarcacao_porao_id
           , p.embarcacao_id
           , p.num_porao
           , p.comprimento_porao
           , p.largura_porao
           , p.comprimento_boca
           , p.largura_boca
           , p.tipo_porao_id
           , (select t.descricao
                from  operporto.v$tipo_porao t
               where t.tipo_porao_id = p.tipo_porao_id
             ) as tipo_porao_descricao
           , p.mec_abertura_tampa_id
           , (select mec.descricao
                from  operporto.v$mec_abertura_tampa mec
               where mec.mec_abertura_tampa_id = p.mec_abertura_tampa_id
             ) as mec_abertura_tampa_desc
           , p.observacao
           , p.user_insert
           , p.date_insert
           , p.user_update
           , p.date_update
        from  operporto.v$embarcacao_porao p

           ) x
       where 1=1');

      if trim(i.embarcacao_porao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_porao_id = '||i.embarcacao_porao_id);
      end if;

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.num_porao) is not null then
         dbms_lob.append(v_sql, '
         and x.num_porao = '||i.num_porao);
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_embarcacao_anexo
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_anexo_id integer      path '/params/embarcacao_anexo_id'
                 , embarcacao_id       integer      path '/params/embarcacao_id'
                 , descricao           varchar2(60) path '/params/descricao'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("anexos",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_anexo_id", xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_anexo_id)),
                      xmlelement("embarcacao_id",       xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("descricao",           xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                      xmlelement("url",                 xmlattributes(''string'' as "type"), stringtojson(x.url)),
                      xmlelement("date_insert",         xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_insert",         xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_update",         xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                      xmlelement("user_update",         xmlattributes(''string'' as "type"), stringtojson(x.user_update))
                   )
                )
             )
        from (
      select a.embarcacao_anexo_id
           , a.embarcacao_id
           , a.descricao
           , a.url
           , a.date_insert
           , a.user_insert
           , a.date_update
           , a.user_update
        from  operporto.v$embarcacao_anexo a
       order by a.descricao
           ) x
       where 1=1');

      if trim(i.embarcacao_anexo_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_anexo_id = '||i.embarcacao_anexo_id);
      end if;

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.descricao) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.descricao)) like upper(kss.pkg_string.fnc_string_clean('''||i.descricao||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_fil_embarcacao
 return xmltype as
v_result       xmltype;
begin
    select xmlelement("filtro",
              xmlattributes('object' as "type"),
              xmlconcat(
                xmlelement("items",
                   xmlattributes('array' as "type"),
                   kss.pkg_form_devextreme.fnc_form_textbox('embarcacao_id',     'Identificador', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('vessel_name',       'Vessel (name)', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('vessel_ex_name',    'Vessel (ex name)', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('charterers',        'Charterers', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('ano_construcao',    'Ano Construcao', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('imo',               'IMO', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('porto_id',          'Porto (id)', '', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('status',            'Status', '', 4),
                   --kss.pkg_form_devextreme.fnc_form_textbox('aprovadas',         'Aprovadas', '', 4),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_inicio',       'Data Inicio', 4),
                   kss.pkg_form_devextreme.fnc_form_datebox('data_fim',          'Data Fim', 4),
                   kss.pkg_form_devextreme.fnc_form_textbox('search',            'Search', '', 4),
                   kss.pkg_form_devextreme.fnc_form_emptybox(4)
                ),
                xmlelement("submit",
                   xmlattributes('object' as "type"),
                    xmlelement("module",    xmlattributes('string' as "type"), stringtojson('M5005_SCH')),
                    xmlelement("operation", xmlattributes('string' as "type"), stringtojson('getEmbarcacao'))
                ),
                xmlelement("model")
              )
           )
      into v_result
      from dual;

    return v_result;
end fnc_fil_embarcacao;

function fnc_col_embarcacao
 return xmltype as
v_result xmltype;
begin
   select xmlelement("columns",
             xmlattributes('array' as "type"),
             xmlconcat(
                kss.pkg_cols_devextreme.fnc_col_number('embarcacao_id', 'ID', 0),
                kss.pkg_cols_devextreme.fnc_col_string('vessel_name',    'Vessel (name)'),
                kss.pkg_cols_devextreme.fnc_col_string('vessel_ex_name',    'Vessel (ex name)'),
                kss.pkg_cols_devextreme.fnc_col_string('charterers',    'Charterers'),
                kss.pkg_cols_devextreme.fnc_col_number('ano_construcao', 'Ano Construcao', 0),
                kss.pkg_cols_devextreme.fnc_col_number('imo', 'IMO', 0),
                kss.pkg_cols_devextreme.fnc_col_number('porto_id', 'Porto (id)', 0),
                kss.pkg_cols_devextreme.fnc_col_html('status' ,'Status'),
                kss.pkg_cols_devextreme.fnc_col_number('aprovadas', 'Aprovadas', 0),
                kss.pkg_cols_devextreme.fnc_col_date('data_inicio', 'Data Inicio'),
                kss.pkg_cols_devextreme.fnc_col_date('data_fim', 'Data Fim'),
                kss.pkg_cols_devextreme.fnc_col_string('search', 'Search'),
                kss.pkg_cols_devextreme.fnc_cols_auditoria()               
             ))
     into v_result
     from dual;
   return v_result;
end fnc_col_embarcacao;

function fnc_get_embarcacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id  integer       path '/params/embarcacao_id'
                 , vessel_name    varchar2(50)  path '/params/vessel_name'
                 , vessel_ex_name varchar2(50)  path '/params/vessel_ex_name'
                 , charterers     varchar2(50)  path '/params/charterers'
                 , ano_construcao integer       path '/params/ano_construcao'
                 , imo            integer       path '/params/imo'
                 , porto_id       integer       path '/params/porto_id'
                 , status         integer       path '/params/status'
                 , aprovadas      integer       path '/params/aprovadas'
                 , data_inicio    varchar2(20)  path '/params/data_inicio'
                 , data_fim       varchar2(20)  path '/params/data_fim'
                 , search         varchar2(100) path '/params/search'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("root",
                xmlattributes(''object'' as "type"),
                xmlconcat(
                   xmlelement("header",
                      xmlattributes(''object'' as "type"),
                      xmlelement("resultset", xmlattributes(''string'' as "type"), stringtojson(''embarcacao'')),
                      operporto.pkg_schedule_backend.fnc_col_embarcacao(),
                      operporto.pkg_schedule_backend.fnc_fil_embarcacao()
                   ),
                   xmlelement("embarcacao",
                   xmlattributes(''array'' as "type"),
                   xmlagg(
                      xmlelement("arrayItem",
                         xmlattributes(''object'' as "type"),
                         xmlelement("embarcacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                         xmlelement("vessel_name",            xmlattributes(''string'' as "type"), stringtojson(x.vessel_name)),
                         xmlelement("display_name",           xmlattributes(''string'' as "type"), stringtojson(x.vessel_name || '' - '' || x.imo)),
                         xmlelement("vessel_ex_name",         xmlattributes(''string'' as "type"), stringtojson(x.vessel_ex_name)),
                         xmlelement("charterers",             xmlattributes(''string'' as "type"), stringtojson(x.charterers)),
                         xmlelement("tipo_embarcacao_id",     xmlattributes(''number'' as "type"), numbertojson(x.tipo_embarcacao_id)),
                         xmlelement("tipo_embarcacao_desc",   xmlattributes(''string'' as "type"), stringtojson(x.tipo_embarcacao_desc)),
                         xmlelement("ano_construcao",         xmlattributes(''number'' as "type"), numbertojson(x.ano_construcao)),
                         xmlelement("gear",                   xmlattributes(''string'' as "type"), stringtojson(x.gear)),
                         xmlelement("outreach",               xmlattributes(''number'' as "type"), numbertojson(x.outreach)),
                         xmlelement("imo",                    xmlattributes(''number'' as "type"), numbertojson(x.imo)),
                         xmlelement("call_sign",              xmlattributes(''string'' as "type"), stringtojson(x.call_sign)),
                         xmlelement("flag_id",                xmlattributes(''number'' as "type"), numbertojson(x.flag)),
                         xmlelement("flag_nome",              xmlattributes(''string'' as "type"), stringtojson(x.flag_nome)),
                         xmlelement("porto_id",               xmlattributes(''number'' as "type"), numbertojson(x.porto_id)),
                         xmlelement("porto_nome",             xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                         xmlelement("dwt",                    xmlattributes(''number'' as "type"), numbertojson(x.dwt)),
                         xmlelement("grt",                    xmlattributes(''number'' as "type"), numbertojson(x.grt)),
                         xmlelement("net",                    xmlattributes(''number'' as "type"), numbertojson(x.net)),
                         xmlelement("grain",                  xmlattributes(''number'' as "type"), numbertojson(x.grain)),
                         xmlelement("bale",                   xmlattributes(''number'' as "type"), numbertojson(x.bale)),
                         xmlelement("gangway",                xmlattributes(''string'' as "type"), stringtojson(x.gangway)),
                         xmlelement("loa",                    xmlattributes(''number'' as "type"), numbertojson(x.loa)),
                         xmlelement("beam",                   xmlattributes(''number'' as "type"), numbertojson(x.beam)),
                         xmlelement("calado",                 xmlattributes(''number'' as "type"), numbertojson(x.calado)),
                         xmlelement("restricao_tp",           xmlattributes(''number'' as "type"), numbertojson(x.restricao_tp)),
                         xmlelement("restricao_mat",          xmlattributes(''number'' as "type"), numbertojson(x.restricao_mat)),
                         xmlelement("observacao",             xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                         xmlelement("status",                 xmlattributes(''number'' as "type"), numbertojson(x.status)),
                         xmlelement("status_descricao",       xmlattributes(''string'' as "type"), stringtojson(x.status_descricao)),
                         xmlelement("data_expiracao",         xmlattributes(''string'' as "type"), datetojson(x.data_expiracao)),
                         xmlelement("user_insert",            xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                         xmlelement("date_insert",            xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                         xmlelement("user_update",            xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                         xmlelement("date_update",            xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                         xmlelement("concat_poroes",          xmlattributes(''string'' as "type"), stringtojson(x.concat_poroes)),
                         operporto.pkg_schedule_backend.fnc_get_porao(xmlelement("params",
                                                                        xmlattributes(''object'' as "type"),
                                                                        xmlelement("embarcacao_id", xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)))
                                                                     ),
                         operporto.pkg_schedule_backend.fnc_get_embarcacao_anexo(xmlelement("params",
                                                                                   xmlattributes(''object'' as "type"),
                                                                                   xmlelement("embarcacao_id", xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)))
                                                                                )
                       )
                    )
                 )
             )
          ) from (
     select e.embarcacao_id
          , e.vessel_name
          , e.vessel_ex_name
          , e.charterers
          , e.tipo_embarcacao_id
          , (select te.descricao
               from  operporto.v$tipo_embarcacao te
              where te.tipo_embarcacao_id = e.tipo_embarcacao_id
            ) as tipo_embarcacao_desc
          , e.ano_construcao
          , e.gear
          , e.outreach
          , e.imo
          , e.call_sign
          , e.flag
          ,(select cp.descricao_portugues
               from cep.v$pais cp
              where cp.pais_id = e.flag
            ) as flag_nome
          , e.porto_id
          , (select p.nome
               from  operporto.v$porto p
              where p.porto_id = e.porto_id
            ) as porto_nome
          , e.dwt
          , e.grt
          , e.net
          , e.grain
          , e.bale
          , e.gangway
          , e.loa
          , e.beam
          , e.calado
          , e.restricao_tp
          , e.restricao_mat
          , e.observacao
          , e.status
          , (select crc.rv_abbreviation
               from  operporto.v$cg_ref_codes crc
              where crc.rv_domain = ''EMBARCACAO.STATUS_ID''
                and crc.rv_low_value = e.status
            ) as status_descricao
          , e.data_expiracao
          , (select kss.fnc_concat_all(kss.to_concat_expr(descricao, '',''))
               from (select distinct tp.descricao
               from  operporto.v$embarcacao_porao ep
              inner join  operporto.v$tipo_porao tp
                 on tp.tipo_porao_id = ep.tipo_porao_id)) as concat_poroes
          , e.user_insert
          , e.date_insert
          , e.user_update
          , e.date_update
       from  operporto.v$embarcacao e
      order by e.status desc, e.vessel_name
          ) x
      where 1=1');

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.vessel_name) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.vessel_name)) like upper(kss.pkg_string.fnc_string_clean('''||i.vessel_name||'%''))');
      end if;

      if trim(i.search) is not null then
         dbms_lob.append(v_sql, '
         and (
            upper(kss.pkg_string.fnc_string_clean(x.vessel_name)) like upper(kss.pkg_string.fnc_string_clean('''||i.search||'%''))
            or to_char(x.imo) like upper(kss.pkg_string.fnc_string_clean('''||i.search||'%''))
            or to_char(x.embarcacao_id) like upper(kss.pkg_string.fnc_string_clean('''||i.search||'%''))
         )');
      end if;

      if trim(i.vessel_ex_name) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.vessel_ex_name)) like upper(kss.pkg_string.fnc_string_clean('''||i.vessel_ex_name||'%''))');
      end if;

      if trim(i.charterers) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.charterers)) like upper(kss.pkg_string.fnc_string_clean('''||i.charterers||'%''))');
      end if;

      if trim(i.ano_construcao) is not null then
         dbms_lob.append(v_sql, '
         and x.ano_construcao = '||i.ano_construcao);
      end if;

      if trim(i.imo) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.imo)) like upper(kss.pkg_string.fnc_string_clean('''||i.imo||'%''))');
      end if;

      if trim(i.porto_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_id = '||i.porto_id);
      end if;

      if trim(i.status) is not null then
         dbms_lob.append(v_sql, '
         and x.status = '||i.status);
      end if;

      if trim(i.aprovadas) is not null then
         dbms_lob.append(v_sql, '
         and x.status in (1,4)');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_porao_embarcacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id integer      path '/params/embarcacao_id'
                 , vessel_name   varchar2(50) path '/params/vessel_name'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("porao_embarcacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_porao_id",    xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_porao_id)),
                      xmlelement("embarcacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("num_porao",              xmlattributes(''number'' as "type"), numbertojson(x.num_porao)),
                      xmlelement("comprimento_porao",      xmlattributes(''number'' as "type"), numbertojson(x.comprimento_porao)),
                      xmlelement("largura_porao",          xmlattributes(''number'' as "type"), numbertojson(x.largura_porao)),
                      xmlelement("comprimento_boca",       xmlattributes(''number'' as "type"), numbertojson(x.comprimento_boca)),
                      xmlelement("largura_boca",           xmlattributes(''number'' as "type"), numbertojson(x.largura_boca)),
                      xmlelement("observacao",             xmlattributes(''string'' as "type"), stringtojson(x.observacao)),
                      xmlelement("tipo_porao_id",          xmlattributes(''number'' as "type"), numbertojson(x.tipo_porao_id)),
                      xmlelement("mec_abertura_tampa_id",  xmlattributes(''number'' as "type"), numbertojson(x.mec_abertura_tampa_id)),
                      xmlelement("data_exclusao",          xmlattributes(''string'' as "type"), datetojson(x.data_exclusao)),
                      xmlelement("user_insert",            xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",            xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("user_update",            xmlattributes(''string'' as "type"), stringtojson(x.user_update)),
                      xmlelement("date_update",            xmlattributes(''string'' as "type"), datetojson(x.date_update)),
                      xmlelement("site",                   xmlattributes(''string'' as "type"), stringtojson(x.site)),
                      xmlelement("tipo_porao_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.tipo_porao_descricao)),
                      xmlelement("vessel_name",            xmlattributes(''string'' as "type"), stringtojson(x.vessel_name)),
                      xmlelement("vessel_ex_name",         xmlattributes(''string'' as "type"), stringtojson(x.vessel_ex_name)),
                      xmlelement("charterers",             xmlattributes(''string'' as "type"), stringtojson(x.charterers)),
                      xmlelement("tipo_embarcacao_id",     xmlattributes(''number'' as "type"), numbertojson(x.tipo_embarcacao_id)),
                      xmlelement("tipo_embarcacao_desc",   xmlattributes(''string'' as "type"), stringtojson(x.tipo_embarcacao_desc)),
                      xmlelement("mec_abertura_descricao", xmlattributes(''string'' as "type"), stringtojson(x.mec_abertura_descricao)),
                      xmlelement("ano_construcao",         xmlattributes(''number'' as "type"), numbertojson(x.ano_construcao)),
                      xmlelement("gear",                   xmlattributes(''string'' as "type"), stringtojson(x.gear)),
                      xmlelement("outreach",               xmlattributes(''number'' as "type"), numbertojson(x.outreach)),
                      xmlelement("imo",                    xmlattributes(''number'' as "type"), numbertojson(x.imo)),
                      xmlelement("call_sign",              xmlattributes(''string'' as "type"), stringtojson(x.call_sign)),
                      xmlelement("flag",                   xmlattributes(''number'' as "type"), numbertojson(x.flag)),
                      xmlelement("flag_nome",              xmlattributes(''string'' as "type"), stringtojson(x.flag_nome)),
                      xmlelement("porto_id",               xmlattributes(''number'' as "type"), numbertojson(x.porto_id)),
                      xmlelement("porto_nome",             xmlattributes(''string'' as "type"), stringtojson(x.porto_nome)),
                      xmlelement("dwt",                    xmlattributes(''number'' as "type"), numbertojson(x.dwt)),
                      xmlelement("grt",                    xmlattributes(''number'' as "type"), numbertojson(x.grt)),
                      xmlelement("net",                    xmlattributes(''number'' as "type"), numbertojson(x.net)),
                      xmlelement("grain",                  xmlattributes(''number'' as "type"), numbertojson(x.grain)),
                      xmlelement("bale",                   xmlattributes(''number'' as "type"), numbertojson(x.bale)),
                      xmlelement("gangway",                xmlattributes(''string'' as "type"), stringtojson(x.gangway)),
                      xmlelement("loa",                    xmlattributes(''number'' as "type"), numbertojson(x.loa)),
                      xmlelement("beam",                   xmlattributes(''number'' as "type"), numbertojson(x.beam)),
                      xmlelement("calado",                 xmlattributes(''number'' as "type"), numbertojson(x.calado)),
                      xmlelement("restricao_tp",           xmlattributes(''number'' as "type"), numbertojson(x.restricao_tp)),
                      xmlelement("restricao_mat",          xmlattributes(''number'' as "type"), numbertojson(x.restricao_mat)),
                      xmlelement("vessel_observacao",      xmlattributes(''string'' as "type"), stringtojson(x.vessel_observacao)),
                      xmlelement("status",                 xmlattributes(''number'' as "type"), numbertojson(x.status)),
                      xmlelement("status_descricao",       xmlattributes(''string'' as "type"), stringtojson(x.status_descricao)),
                      xmlelement("data_expiracao",         xmlattributes(''string'' as "type"), datetojson(x.data_expiracao))
                   )
                )
             )
        from (
      select po.*
           , (select tp.descricao
                from  operporto.v$tipo_porao tp
               where tp.tipo_porao_id = po.tipo_porao_id
             ) as tipo_porao_descricao
           , e.vessel_name
           , e.vessel_ex_name
           , e.charterers
           , e.tipo_embarcacao_id
           , (select te.descricao
                from  operporto.v$tipo_embarcacao te
               where te.tipo_embarcacao_id = e.tipo_embarcacao_id
             ) as tipo_embarcacao_desc
           , (select m.descricao
                from  operporto.v$mec_abertura_tampa m
               where m.mec_abertura_tampa_id = po.mec_abertura_tampa_id
             ) as mec_abertura_descricao
           , e.ano_construcao
           , e.gear
           , e.outreach
           , e.imo
           , e.call_sign
           , e.flag
           ,(select cp.descricao_portugues
                from cep.v$pais cp
               where cp.pais_id = e.flag
             ) as flag_nome
           , e.porto_id
           , (select p.nome
                from  operporto.v$porto p
               where p.porto_id = e.porto_id
             ) as porto_nome
           , e.dwt
           , e.grt
           , e.net
           , e.grain
           , e.bale
           , e.gangway
           , e.loa
           , e.beam
           , e.calado
           , e.restricao_tp
           , e.restricao_mat
           , e.observacao as vessel_observacao
           , e.status
           , (select crc.rv_abbreviation
                from  operporto.v$cg_ref_codes crc
               where crc.rv_domain = ''EMBARCACAO.STATUS_ID''
                 and crc.rv_low_value = e.status
             ) as status_descricao
           , e.data_expiracao
        from  operporto.v$embarcacao_porao po
       inner join  operporto.v$embarcacao e
               on e.embarcacao_id = po.embarcacao_id

           ) x
       where 1=1');

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.vessel_name) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.vessel_name)) like upper(kss.pkg_string.fnc_string_clean('''||i.vessel_name||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_logs_restricao_prog
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer path '/params/programacao_id'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("restricao_programacao",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_id",        xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("log_id",                xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",           xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",           xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("descricao",             xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.programacao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,el.evento_id as prog_evento_id
--            ,(select ev.titulo
--                from operporto_log.v$programa cao_evento ev
--               where el.evento_id = ev.evento_id
--                ) as prog_evento_titulo
--            ,(select t.log_id_restricao
--                from operporto_log.v$programacao t
--               where t.log_id_restricao is not null
--                 and t.programacao_id = 1
--                ) as log_id_restricao
            ,l.descricao
        from operporto_log.v$programacao el
       inner join operporto_log.v$programacao_log l
               on l.log_id = el.log_id
       where el.evento_id in (1,2,3,4,5,8,9,12,13,14)
         and el.log_id not in 1
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);

         execute immediate v_sql
            into v_result;
      else
         select xmlconcat(
                xmlelement("erro", xmlattributes('string' as "type"), stringtojson('E obrigatorio informar uma programac?o para essa consulta.'))
             )
        into v_result
        from dual;
      end if;

      return v_result;

   end loop;
end;

function fnc_get_log_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etiqueta_id integer       path '/params/etiqueta_id'
                 , log_id      integer       path '/params/log_id'
                 , evento_id   integer       path '/params/evento_id'
                 , origem      varchar2(25)  path '/params/origem'
                 , data_inicio varchar2(20)  path '/params/data_inicio'
                 , data_fim    varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("etiqueta_id",        xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.etiqueta_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$etiqueta el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etiqueta_id = '||i.etiqueta_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_restricao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id integer       path '/params/restricao_id'
                 , log_id       integer       path '/params/log_id'
                 , evento_id    integer       path '/params/evento_id'
                 , origem       varchar2(25)  path '/params/origem'
                 , data_inicio  varchar2(20)  path '/params/data_inicio'
                 , data_fim     varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("restricao_id",       xmlattributes(''number'' as "type"), numbertojson(x.restricao_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.restricao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$restricao el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.restricao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.restricao_id = '||i.restricao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_budget
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   budget_id  integer       path '/params/budget_id'
                 , log_id     integer       path '/params/log_id'
                 , evento_id  integer       path '/params/evento_id'
                 , origem     varchar2(25)  path '/params/origem'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("budget_id",          xmlattributes(''number'' as "type"), numbertojson(x.budget_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.budget_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$budget el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.budget_id) is not null then
         dbms_lob.append(v_sql, '
         and x.budget_id = '||i.budget_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_manutencao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   manutencao_id      integer       path '/params/manutencao_id'
                 , log_id             integer       path '/params/log_id'
                 , evento_id          integer       path '/params/evento_id'
                 , origem             varchar2(25)  path '/params/origem'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("manutencao_id",      xmlattributes(''number'' as "type"), numbertojson(x.manutencao_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select ml.manutencao_id
            ,ml.log_id
            ,ml.user_insert
            ,ml.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$manutencao ml
       inner join operporto_log.v$log l
               on l.log_id = ml.log_id
       order by ml.log_id desc
           ) x
       where 1=1');

      if trim(i.manutencao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.manutencao_id = '||i.manutencao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;


function fnc_get_log_prog_etiqueta
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_etiqueta_id integer       path '/params/programacao_etiqueta_id'
                 , log_id                  integer       path '/params/log_id'
                 , evento_id               integer       path '/params/evento_id'
                 , origem                  varchar2(25)  path '/params/origem'
                 , programacao_id          integer       path '/params/programacao_id'
                 , etiqueta_id             integer       path '/params/etiqueta_id'
                 , etiqueta_titulo         varchar2(50)  path '/params/etiqueta_titulo'
                 , data_inicio             varchar2(20)  path '/params/data_inicio'
                 , data_fim                varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_etiqueta_id", xmlattributes(''number'' as "type"), numbertojson(x.programacao_etiqueta_id)),
                      xmlelement("log_id",                  xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",             xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",             xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",               xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura",      xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",                  xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",               xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                      xmlelement("programacao_id",          xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("etiqueta_id",             xmlattributes(''number'' as "type"), numbertojson(x.etiqueta_id)),
                      xmlelement("etiqueta_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.etiqueta_descricao))
                   )
                )
             )
        from (
      select el.programacao_etiqueta_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
            ,e.programacao_id
            ,e.etiqueta_id
            ,(select q.descricao
                from operporto.v$etiqueta_todos q
               where q.etiqueta_id = e.etiqueta_id
             ) as etiqueta_descricao
        from operporto_log.v$programacao_etiqueta el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       inner join operporto.v$programacao_etiqueta_todos e
               on e.programacao_etiqueta_id = el.programacao_etiqueta_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.programacao_etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_etiqueta_id = '||i.programacao_etiqueta_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.etiqueta_id) is not null then
         dbms_lob.append(v_sql, '
         and x.etiqueta_id = '||i.etiqueta_id);
      end if;

      if trim(i.etiqueta_titulo) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.etiqueta_titulo)) like upper(kss.pkg_string.fnc_string_clean('''||i.etiqueta_titulo||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_programacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id     integer       path '/params/programacao_id'
                 , log_id             integer       path '/params/log_id'
                 , evento_id          integer       path '/params/evento_id'
                 , prog_evento_id     integer       path '/params/prog_evento_id'
                 , evento_abreviatura varchar2(240) path '/params/evento_abreviatura'
                 , origem             varchar2(25)  path '/params/origem'
                 , data_inicio        varchar2(20)  path '/params/data_inicio'
                 , data_fim           varchar2(20)  path '/params/data_fim'
       )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("programacao_id",        xmlattributes(''number'' as "type"), numbertojson(x.programacao_id)),
                      xmlelement("log_id",                xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("restricao_id",          xmlattributes(''number'' as "type"), numbertojson(x.restricao_id)),
                      xmlelement("user_insert",           xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",           xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",             xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura",    xmlattributes(''string'' as "type"), stringtojson(x.evento_abreviatura)),
                      xmlelement("evento_descricao",      xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("prog_evento_id",        xmlattributes(''number'' as "type"), numbertojson(x.prog_evento_id)),
                      xmlelement("prog_evento_titulo",    xmlattributes(''string'' as "type"), stringtojson(x.prog_evento_titulo)),
                      xmlelement("prog_evento_descricao", xmlattributes(''string'' as "type"), stringtojson(x.prog_evento_descricao)),
                      xmlelement("origem",                xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",             xmlattributes(''string'' as "type"), stringtojson(x.descricao)),
                      xmlelement("log_id_restricao",      xmlattributes(''number'' as "type"), numbertojson(x.log_id_restricao)),
                      xmlelement("descricao_liberada",    xmlattributes(''string'' as "type"), stringtojson(x.descricao_liberada))
                   )
                )
             )
        from (
      select el.programacao_id
            ,el.log_id
            ,el.restricao_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,(select crc.rv_abbreviation
                from operporto_log.v$cg_ref_codes crc
               where crc.rv_domain = ''LOG.EVENTO_ID''
                 and crc.rv_low_value = l.evento_id
             ) as evento_abreviatura
            ,(select crc.rv_meaning
                from operporto_log.v$cg_ref_codes crc
               where crc.rv_domain = ''LOG.EVENTO_ID''
                 and crc.rv_low_value = l.evento_id
             ) as evento_descricao
            , el.evento_id as prog_evento_id
            , (select ev.titulo
                 from operporto_log.v$programacao_evento ev
                where el.evento_id = ev.evento_id
               ) as prog_evento_titulo
            , (select ev.descricao
                 from operporto_log.v$programacao_evento ev
                where el.evento_id = ev.evento_id
               ) as prog_evento_descricao
            ,''PROGRAMACAO'' as origem
            ,l.descricao
            , el.log_id_restricao
            , (select rl.descricao
                 from operporto_log.v$programacao_log rl
                where rl.log_id = el.log_id_restricao
              ) as descricao_liberada
        from operporto_log.v$programacao el
       inner join operporto_log.v$programacao_log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.programacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.programacao_id = '||i.programacao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.prog_evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.prog_evento_id = '||i.prog_evento_id);
      end if;

      if trim(i.evento_abreviatura) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.evento_abreviatura)) like upper(kss.pkg_string.fnc_string_clean('''||i.evento_abreviatura||'%''))');
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_porto
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   porto_id    integer       path '/params/porto_id'
                 , log_id      integer       path '/params/log_id'
                 , evento_id   integer       path '/params/evento_id'
                 , origem      varchar2(25)  path '/params/origem'
                 , data_inicio varchar2(20)  path '/params/data_inicio'
                 , data_fim    varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("porto_id",           xmlattributes(''number'' as "type"), numbertojson(x.porto_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select pl.porto_id
            ,pl.log_id
            ,pl.user_insert
            ,pl.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$porto pl
       inner join operporto_log.v$log l
               on l.log_id = pl.log_id
       order by pl.log_id desc
           ) x
       where 1=1');

      if trim(i.porto_id) is not null then
         dbms_lob.append(v_sql, '
         and x.porto_id = '||i.porto_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_tipo_embarcacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_embarcacao_id integer       path '/params/tipo_embarcacao_id'
                 , log_id             integer       path '/params/log_id'
                 , evento_id          integer       path '/params/evento_id'
                 , origem             varchar2(25)  path '/params/origem'
                 , data_inicio        varchar2(20)  path '/params/data_inicio'
                 , data_fim           varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("tipo_embarcacao_id", xmlattributes(''number'' as "type"), numbertojson(x.tipo_embarcacao_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select tl.tipo_embarcacao_id
            ,tl.log_id
            ,tl.user_insert
            ,tl.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$tipo_embarcacao tl
       inner join operporto_log.v$log l
               on l.log_id = tl.log_id
       order by tl.log_id desc
           ) x
       where 1=1');

      if trim(i.tipo_embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_embarcacao_id = '||i.tipo_embarcacao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
         dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_tipo_porao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_porao_id integer       path '/params/tipo_porao_id'
                 , log_id        integer       path '/params/log_id'
                 , evento_id     integer       path '/params/evento_id'
                 , origem        varchar2(25)  path '/params/origem'
                 , data_inicio   varchar2(20)  path '/params/data_inicio'
                 , data_fim      varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("tipo_porao_id",      xmlattributes(''number'' as "type"), numbertojson(x.tipo_porao_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select tl.tipo_porao_id
            ,tl.log_id
            ,tl.user_insert
            ,tl.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$tipo_porao tl
       inner join operporto_log.v$log l
               on l.log_id = tl.log_id
       order by tl.log_id desc
           ) x
       where 1=1');

      if trim(i.tipo_porao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.tipo_porao_id = '||i.tipo_porao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_mec_abertura_tampa
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mec_abertura_tampa_id integer       path '/params/mec_abertura_tampa_id'
                 , log_id                integer       path '/params/log_id'
                 , evento_id             integer       path '/params/evento_id'
                 , origem                varchar2(25)  path '/params/origem'
                 , data_inicio           varchar2(20)  path '/params/data_inicio'
                 , data_fim              varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("mec_abertura_tampa_id", xmlattributes(''number'' as "type"), numbertojson(x.mec_abertura_tampa_id)),
                      xmlelement("log_id",                xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",           xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",           xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",             xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura",    xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",                xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",             xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select tl.mec_abertura_tampa_id
            ,tl.log_id
            ,tl.user_insert
            ,tl.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$mec_abertura_tampa tl
       inner join operporto_log.v$log l
               on l.log_id = tl.log_id
       order by tl.log_id desc
           ) x
       where 1=1');

      if trim(i.mec_abertura_tampa_id) is not null then
         dbms_lob.append(v_sql, '
         and x.mec_abertura_tampa_id = '||i.mec_abertura_tampa_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_embarcacao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id      integer       path '/params/embarcacao_id'
                 , log_id             integer       path '/params/log_id'
                 , evento_id          integer       path '/params/evento_id'
                 , origem             varchar2(25)  path '/params/origem'
                 , data_inicio        varchar2(20)  path '/params/data_inicio'
                 , data_fim           varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_id",      xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.embarcacao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$embarcacao el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
      union all
      select e.embarcacao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$embarcacao_porao el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       inner join  operporto.v$embarcacao_porao_todos e
               on e.embarcacao_porao_id = el.embarcacao_porao_id
      union all
      select e.embarcacao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$embarcacao_anexo el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       inner join  operporto.v$embarcacao_anexo_todos e
               on e.embarcacao_anexo_id = el.embarcacao_anexo_id
       order by log_id desc
           ) x
       where 1=1');

      if trim(i.embarcacao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_id = '||i.embarcacao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_porao
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_porao_id integer       path '/params/embarcacao_porao_id'
                 , log_id              integer       path '/params/log_id'
                 , evento_id           integer       path '/params/evento_id'
                 , origem              varchar2(25)  path '/params/origem'
                 , num_porao           integer       path '/params/num_porao'
                 , data_inicio         varchar2(20)  path '/params/data_inicio'
                 , data_fim            varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("embarcacao_porao_id", xmlattributes(''number'' as "type"), numbertojson(x.embarcacao_porao_id)),
                      xmlelement("log_id",              xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",         xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",         xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",           xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura",  xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",              xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",           xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.embarcacao_porao_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$embarcacao_porao el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.embarcacao_porao_id) is not null then
         dbms_lob.append(v_sql, '
         and x.embarcacao_porao_id = '||i.embarcacao_porao_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_produto_categoria
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id        integer       path '/params/categoria_id'
                 , log_id              integer       path '/params/log_id'
                 , evento_id           integer       path '/params/evento_id'
                 , origem              varchar2(25)  path '/params/origem'
                 , data_inicio         varchar2(20)  path '/params/data_inicio'
                 , data_fim            varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("categoria_id",       xmlattributes(''number'' as "type"), numbertojson(x.categoria_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.categoria_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from recinto_log.v$produto_categoria el
       inner join recinto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.categoria_id) is not null then
         dbms_lob.append(v_sql, '
         and x.categoria_id = '||i.categoria_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_berco
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id    integer       path '/params/berco_id'
                 , log_id      integer       path '/params/log_id'
                 , evento_id   integer       path '/params/evento_id'
                 , origem      varchar2(25)  path '/params/origem'
                 , data_inicio varchar2(20)  path '/params/data_inicio'
                 , data_fim    varchar2(20)  path '/params/data_fim'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("berco_id",           xmlattributes(''number'' as "type"), numbertojson(x.berco_id)),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_abreviatura", xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
      select el.berco_id
            ,el.log_id
            ,el.user_insert
            ,el.date_insert
            ,l.evento_id
            ,l.evento_descricao
            ,l.origem
            ,l.descricao
        from operporto_log.v$berco el
       inner join operporto_log.v$log l
               on l.log_id = el.log_id
       order by el.log_id desc
           ) x
       where 1=1');

      if trim(i.berco_id) is not null then
         dbms_lob.append(v_sql, '
         and x.berco_id = '||i.berco_id);
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

function fnc_get_log_modulo
(p_parameters in  xmltype
) return xmltype as
v_result xmltype;
v_sql    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   log_id      integer       path '/params/log_id'
                 , evento_id   integer       path '/params/evento_id'
                 , origem      varchar2(25)  path '/params/origem'
                 , data_inicio varchar2(20)  path '/params/data_inicio'
                 , data_fim    varchar2(20)  path '/params/data_fim'
                 , usuario     varchar2(30)  path '/params/usuario'
      )
   ) loop
      dbms_lob.createtemporary(v_sql, true);
      dbms_lob.append(v_sql, '
      select xmlelement("log",
                xmlattributes(''array'' as "type"),
                xmlagg(
                   xmlelement("arrayItem",
                      xmlattributes(''object'' as "type"),
                      xmlelement("log_id",             xmlattributes(''number'' as "type"), numbertojson(x.log_id)),
                      xmlelement("user_insert",        xmlattributes(''string'' as "type"), stringtojson(x.user_insert)),
                      xmlelement("date_insert",        xmlattributes(''string'' as "type"), datetojson(x.date_insert)),
                      xmlelement("evento_id",          xmlattributes(''number'' as "type"), numbertojson(x.evento_id)),
                      xmlelement("evento_descricao",   xmlattributes(''string'' as "type"), stringtojson(x.evento_descricao)),
                      xmlelement("origem",             xmlattributes(''string'' as "type"), stringtojson(x.origem)),
                      xmlelement("descricao",          xmlattributes(''string'' as "type"), stringtojson(x.descricao))
                   )
                )
             )
        from (
           select *
             from (
                  select sl.log_id
                       , sl.evento_id
                       , sl.origem
                       , sl.descricao
                       , sl.user_insert
                       , sl.date_insert
                       , sl.evento_descricao
                    from operporto_log.v$log sl
                  union all
                  select pl.log_id
                       , pl.evento_id
                       , ''PROGRAMACAO'' as origem
                       , pl.descricao
                       , pl.user_insert
                       , pl.date_insert
                       , (select crc.rv_abbreviation
                            from operporto_log.v$cg_ref_codes crc
                           where crc.rv_domain = ''LOG.EVENTO_ID''
                             and crc.rv_low_value = pl.evento_id
                         ) as evento_descricao
                    from operporto_log.v$programacao_log pl
                  union all
                  select hl.log_id
                       , hl.evento_id
                       , hl.origem
                       , hl.descricao
                       , hl.user_insert
                       , hl.date_insert
                       , hl.evento_descricao
                    from operporto_log.v$log hl
                  union all
                  select l.log_id
                       , l.evento_id
                       , l.origem
                       , dbms_lob.substr(l.descricao, 4000, 1) as descricao
                       , l.user_insert
                       , l.date_insert
                       , l.evento_descricao
                    from recinto_log.v$produto_categoria pc
                   inner join recinto_log.v$log l
                           on l.log_id = pc.log_id
                 ) a
           order by a.date_insert desc
          ) x
       where 1=1');

      if trim(i.usuario) is not null then
         dbms_lob.append(v_sql, '
         and upper(x.user_insert) like upper('''||i.usuario||''')');
      end if;

      if trim(i.log_id) is not null then
         dbms_lob.append(v_sql, '
         and x.log_id = '||i.log_id);
      end if;

      if trim(i.evento_id) is not null then
         dbms_lob.append(v_sql, '
         and x.evento_id = '||i.evento_id);
      end if;

      if trim(i.origem) is not null then
         dbms_lob.append(v_sql, '
         and upper(kss.pkg_string.fnc_string_clean(x.origem)) like upper(kss.pkg_string.fnc_string_clean('''||i.origem||'%''))');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is not null then
            dbms_lob.append(v_sql, '
            and (
               x.date_insert between '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||''' and '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''
            )');
      end if;

      if trim(i.data_inicio) is not null and trim(i.data_fim) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert >= '''|| to_date(i.data_inicio, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      if trim(i.data_fim) is not null and trim(i.data_inicio) is null then
            dbms_lob.append(v_sql, '
            and x.date_insert <= '''|| to_date(i.data_fim, 'yyyy-mm-dd hh24:mi:ss') ||'''');
      end if;

      execute immediate v_sql
         into v_result;

      return v_result;

   end loop;
end;

procedure prc_cad_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_embarcacao operporto.v$embarcacao%rowtype;
v_id         integer;
v_porao_id   integer;
v_msg        varchar2(100);
v_mensagem   varchar2(1000);
v_titulo     varchar2(100);
v_email      clob;

begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   operation          varchar2(30)  path '/params/operation'
                 , embarcacao_id      integer       path '/params/embarcacao_id'
                 , vessel_name        varchar2(50)  path '/params/vessel_name'
                 , vessel_ex_name     varchar2(50)  path '/params/vessel_ex_name'
                 , charterers         varchar2(50)  path '/params/charterers'
                 , tipo_embarcacao_id integer       path '/params/tipo_embarcacao/tipo_embarcacao_id'
                 , ano_construcao     integer       path '/params/ano_construcao'
                 , gear               varchar2(50)  path '/params/gear'
                 , outreach           number        path '/params/outreach'
                 , imo                integer       path '/params/imo'
                 , call_sign          varchar2(20)  path '/params/call_sign'
                 , flag               integer       path '/params/flag/pais_id'
                 , porto_id           integer       path '/params/porto/porto_id'
                 , dwt                number        path '/params/dwt'
                 , grt                number        path '/params/grt'
                 , net                number        path '/params/net'
                 , grain              number        path '/params/grain'
                 , bale               number        path '/params/bale'
                 , gangway            varchar2(20)  path '/params/gangway'
                 , loa                number        path '/params/loa'
                 , beam               number        path '/params/beam'
                 , calado             number        path '/params/calado'
                 , observacao         varchar2(500) path '/params/observacao'
                 , data_expiracao     varchar2(30)  path '/params/data_expiracao'
                 , poroes             xmltype       path '/params/poroes'
                 , anexos             xmltype       path '/params/anexos'
                 , justificativa      varchar2(4000) path '/params/motivo'
                )
   ) loop
      v_id := i.embarcacao_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_operporto.prc_ins_embarcacao(p_embarcacao_id      => v_id
                                                      ,p_vessel_name        => i.vessel_name
                                                      ,p_vessel_ex_name     => i.vessel_ex_name
                                                      ,p_charterers         => i.charterers
                                                      ,p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                      ,p_ano_construcao     => i.ano_construcao
                                                      ,p_gear               => i.gear
                                                      ,p_outreach           => i.outreach
                                                      ,p_imo                => i.imo
                                                      ,p_call_sign          => i.call_sign
                                                      ,p_flag               => i.flag
                                                      ,p_porto_id           => i.porto_id
                                                      ,p_dwt                => i.dwt
                                                      ,p_grt                => i.grt
                                                      ,p_net                => i.net
                                                      ,p_grain              => i.grain
                                                      ,p_bale               => i.bale
                                                      ,p_gangway            => i.gangway
                                                      ,p_loa                => i.loa
                                                      ,p_beam               => i.beam
                                                      ,p_calado             => i.calado
                                                      ,p_observacao         => i.observacao
                                                      ,p_data_expiracao     => trunc(to_timestamp(i.data_expiracao, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'))
                                                      );
            v_msg := 'Embarcac?o inserida com sucesso.';

         when 'UPDATE' then
            select *
              into v_embarcacao
              from  operporto.v$embarcacao
             where embarcacao_id = v_id;

            operporto.pkg_operporto.prc_alt_embarcacao(p_embarcacao_id      => v_id
                                                      ,p_vessel_name        => i.vessel_name
                                                      ,p_vessel_ex_name     => i.vessel_ex_name
                                                      ,p_charterers         => i.charterers
                                                      ,p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                      ,p_ano_construcao     => i.ano_construcao
                                                      ,p_gear               => i.gear
                                                      ,p_outreach           => i.outreach
                                                      ,p_imo                => i.imo
                                                      ,p_call_sign          => i.call_sign
                                                      ,p_flag               => i.flag
                                                      ,p_porto_id           => i.porto_id
                                                      ,p_dwt                => i.dwt
                                                      ,p_grt                => i.grt
                                                      ,p_net                => i.net
                                                      ,p_grain              => i.grain
                                                      ,p_bale               => i.bale
                                                      ,p_gangway            => i.gangway
                                                      ,p_loa                => i.loa
                                                      ,p_beam               => i.beam
                                                      ,p_calado             => i.calado
                                                      ,p_observacao         => i.observacao
                                                      ,p_data_expiracao     => trunc(to_timestamp(i.data_expiracao, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'))
                                                      );

            -- Valida embarcacao
            operporto.pkg_operporto.prc_define_status_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                                ,p_status        => v_embarcacao.status
                                                                );

            v_msg := 'Embarcac?o alterada com sucesso.';

          when 'APROVAR' then
             operporto.pkg_operporto.prc_aprova_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                          ,p_justificativa => i.justificativa
                                                          );
            v_msg := 'Embarcac?o aprovada com sucesso.';

          when 'REPROVAR' then
            operporto.pkg_operporto.prc_reprova_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                          ,p_justificativa => i.justificativa
                                                          );

            --Enviar Notificac?o de Embarcac?o Reprovada para a Programac?o
            for j in (
               select p.programacao_id
                    , e.vessel_name
                 from operporto.v$programacao p
                inner join  operporto.v$embarcacao e
                        on e.imo = p.imo
                where e.embarcacao_id = i.embarcacao_id
                  and p.status_id not in (3, 4)
            )loop

               -- notificac?o email
               select '<hr>EMBARCAC?O REPROVADA<hr>'
                    ||'Programac?o     : '||p.programacao_id||'<br/>'
                    ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
                    ||'Agencia         : '||(select e.descricao||' <br/>'
                                               from operporto.v$programacao_etiqueta pe
                                              inner join operporto.v$etiqueta e
                                                 on e.etiqueta_id = pe.etiqueta_id
                                                and e.tipo_id = 2
                                              where pe.programacao_id = p.programacao_id)
                    ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
                    ||'Periodo previsto:<br/><ul>'
                    ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
                    ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
                    ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
                    ||'Importadores:<br/><ul>'
                    ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                         from operporto.v$programacao_etiqueta pe
                        inner join operporto.v$etiqueta e
                           on e.etiqueta_id = pe.etiqueta_id
                          and e.tipo_id = 3
                        inner join recinto.v$produto_categoria c
                           on c.categoria_id = pe.categoria_id
                        where pe.programacao_id = p.programacao_id)||'</ul><hr>'
                    ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
                    , 'Embarcac?o reprovada / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
                 into v_mensagem
                    , v_titulo
                 from operporto.v$programacao p
                where p.programacao_id = j.programacao_id;

            /*   recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                                 , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                                 , p_anexos    => null
                                                 , p_email     => v_email
                                                  );*/

               for k in (
                  select pge.grupo_email_id
                    from operporto.v$programacao_grupo_email pge
                   where pge.programacao_id = j.programacao_id
                     and pge.ativo = 1
               ) loop
                  recinto.pkg_email.prc_enviar_email(p_grupo_email_id => k.grupo_email_id
                                                   , p_corpo          => v_email
                                                   , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                                   , p_multipart      => 1
                                                    );
               end loop;

            end loop;

            v_msg := 'Embarcac?o reprovada com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      -- poroes
      for j in (
         select *
           from xmltable('/poroes/arrayItem' passing i.poroes
                   columns
                      operation             varchar2(30)  path '/params/operation'
                    , porao_id              integer       path '/arrayItem/porao_id'
                    , num_porao             integer       path '/arrayItem/num_porao'
                    , comprimento_porao     number        path '/arrayItem/comprimento_porao'
                    , largura_porao         number        path '/arrayItem/largura_porao'
                    , comprimento_boca      number        path '/arrayItem/comprimento_boca'
                    , largura_boca          number        path '/arrayItem/largura_boca'
                    , tipo_porao_id         integer       path '/arrayItem/tipo_porao_id'
                    , mec_abertura_tampa_id integer       path '/arrayItem/mec_abertura_tampa_id'
                    , observacao            varchar2(500) path '/arrayItem/observacao'
                   )
      )loop
         v_porao_id := j.porao_id;
         case upper(j.operation)
            when 'INSERT' then
               operporto.pkg_operporto.prc_ins_embarcacao_porao(p_embarcacao_porao_id   => v_porao_id
                                                              ,p_embarcacao_id         => v_id
                                                              ,p_num_porao             => j.num_porao
                                                              ,p_comprimento_porao     => j.comprimento_porao
                                                              ,p_largura_porao         => j.largura_porao
                                                              ,p_comprimento_boca      => j.comprimento_boca
                                                              ,p_largura_boca          => j.largura_boca
                                                              ,p_tipo_porao_id         => j.tipo_porao_id
                                                              ,p_mec_abertura_tampa_id => j.mec_abertura_tampa_id
                                                              ,p_observacao            => j.observacao
                                                              );
               v_msg := v_msg ||'</br>'||'Por?o inserido com sucesso.';

            when 'UPDATE' then
               operporto.pkg_operporto.prc_alt_embarcacao_porao(p_embarcacao_porao_id   => v_porao_id
                                                               ,p_embarcacao_id         => v_id
                                                               ,p_num_porao             => j.num_porao
                                                               ,p_comprimento_porao     => j.comprimento_porao
                                                               ,p_largura_porao         => j.largura_porao
                                                               ,p_comprimento_boca      => j.comprimento_boca
                                                               ,p_largura_boca          => j.largura_boca
                                                               ,p_tipo_porao_id         => j.tipo_porao_id
                                                               ,p_mec_abertura_tampa_id => j.mec_abertura_tampa_id
                                                               ,p_observacao            => j.observacao
                                                               );
               v_msg := v_msg ||'</br>'||'Por?o alterado com sucesso.';

            when 'DELETE' then
               operporto.pkg_operporto.prc_del_embarcacao_porao(p_embarcacao_porao_id => v_porao_id
                                                                );
               v_msg := v_msg ||'</br>'||'Por?o excluido com sucesso.';
            else
               null;
         end case;
      end loop;

      select xmlconcat(
                xmlelement("mensagem",  xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("budget_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_embarcacao;

procedure prc_ins_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_embarcacao_id       integer;
v_embarcacao_porao_id integer;
v_embarcacao_anexo_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   vessel_name        varchar2(50)  path '/params/vessel_name'
                 , vessel_ex_name     varchar2(50)  path '/params/vessel_ex_name'
                 , charterers         varchar2(50)  path '/params/charterers'
                 , tipo_embarcacao_id integer       path '/params/tipo_embarcacao/tipo_embarcacao_id'
                 , ano_construcao     integer       path '/params/ano_construcao'
                 , gear               varchar2(50)  path '/params/gear'
                 , outreach           number        path '/params/outreach'
                 , imo                integer       path '/params/imo'
                 , call_sign          varchar2(20)  path '/params/call_sign'
                 , flag               integer       path '/params/flag/pais_id'
                 , porto_id           integer       path '/params/porto/porto_id'
                 , dwt                number        path '/params/dwt'
                 , grt                number        path '/params/grt'
                 , net                number        path '/params/net'
                 , grain              number        path '/params/grain'
                 , bale               number        path '/params/bale'
                 , gangway            varchar2(20)  path '/params/gangway'
                 , loa                number        path '/params/loa'
                 , beam               number        path '/params/beam'
                 , calado             number        path '/params/calado'
                 , observacao         varchar2(500) path '/params/observacao'
                 , data_expiracao     varchar2(30)  path '/params/data_expiracao'
                 , poroes             xmltype       path '/params/poroes'
                 , anexos             xmltype       path '/params/anexos'
                )
   ) loop
       operporto.pkg_operporto.prc_ins_embarcacao(p_embarcacao_id      => v_embarcacao_id
                                                 ,p_vessel_name        => i.vessel_name
                                                 ,p_vessel_ex_name     => i.vessel_ex_name
                                                 ,p_charterers         => i.charterers
                                                 ,p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                 ,p_ano_construcao     => i.ano_construcao
                                                 ,p_gear               => i.gear
                                                 ,p_outreach           => i.outreach
                                                 ,p_imo                => i.imo
                                                 ,p_call_sign          => i.call_sign
                                                 ,p_flag               => i.flag
                                                 ,p_porto_id           => i.porto_id
                                                 ,p_dwt                => i.dwt
                                                 ,p_grt                => i.grt
                                                 ,p_net                => i.net
                                                 ,p_grain              => i.grain
                                                 ,p_bale               => i.bale
                                                 ,p_gangway            => i.gangway
                                                 ,p_loa                => i.loa
                                                 ,p_beam               => i.beam
                                                 ,p_calado             => i.calado
                                                 ,p_observacao         => i.observacao
                                                 ,p_data_expiracao     => trunc(to_timestamp(i.data_expiracao, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'))
                                                 );

      for j in (
         select *
           from xmltable('/poroes/arrayItem' passing i.poroes
                   columns
                      num_porao             integer       path '/arrayItem/num_porao'
                    , comprimento_porao     number        path '/arrayItem/comprimento_porao'
                    , largura_porao         number        path '/arrayItem/largura_porao'
                    , comprimento_boca      number        path '/arrayItem/comprimento_boca'
                    , largura_boca          number        path '/arrayItem/largura_boca'
                    , tipo_porao_id         integer       path '/arrayItem/tipo_porao_id'
                    , mec_abertura_tampa_id integer       path '/arrayItem/mec_abertura_tampa_id'
                    , observacao            varchar2(500) path '/arrayItem/observacao'
                   )
      )loop
          operporto.pkg_operporto.prc_ins_embarcacao_porao(p_embarcacao_porao_id   => v_embarcacao_porao_id
                                                          ,p_embarcacao_id         => v_embarcacao_id
                                                          ,p_num_porao             => j.num_porao
                                                          ,p_comprimento_porao     => j.comprimento_porao
                                                          ,p_largura_porao         => j.largura_porao
                                                          ,p_comprimento_boca      => j.comprimento_boca
                                                          ,p_largura_boca          => j.largura_boca
                                                          ,p_tipo_porao_id         => j.tipo_porao_id
                                                          ,p_mec_abertura_tampa_id => j.mec_abertura_tampa_id
                                                          ,p_observacao            => j.observacao
                                                          );
      end loop;

      for j in (
         select *
           from xmltable('/anexos/arrayItem' passing i.anexos
                   columns
                      descricao varchar2(61)   path '/arrayItem/descricao'
                    , arquivo   clob           path '/arrayItem/arquivo'
                    , url       varchar2(1000) path '/arrayItem/url'
                   )
      ) loop
          operporto.pkg_operporto.prc_ins_embarcacao_anexo(p_embarcacao_anexo_id => v_embarcacao_anexo_id
                                                          ,p_embarcacao_id       => v_embarcacao_id
                                                          ,p_descricao           => j.descricao
                                                          ,p_arquivo             => kss.pkg_remote.fnc_base642blob(j.arquivo)
                                                          ,p_url                 => j.url
                                                          );
      end loop;

      -- Valida embarcacao
       operporto.pkg_operporto.prc_define_status_embarcacao(p_embarcacao_id => v_embarcacao_id
                                                          , p_status        => 2 -- aguardando revisao
                                                           );

      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Embarcac?o inserida com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(v_embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end prc_ins_embarcacao;

procedure prc_alt_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_embarcacao_porao_id integer;
 v_embarcacao_anexo_id integer;
 v_status_atual        integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id      integer       path '/params/embarcacao_id'
                 , vessel_name        varchar2(50)  path '/params/vessel_name'
                 , vessel_ex_name     varchar2(50)  path '/params/vessel_ex_name'
                 , charterers         varchar2(50)  path '/params/charterers'
                 , tipo_embarcacao_id integer       path '/params/tipo_embarcacao/tipo_embarcacao_id'
                 , ano_construcao     integer       path '/params/ano_construcao'
                 , gear               varchar2(50)  path '/params/gear'
                 , outreach           number        path '/params/outreach'
                 , imo                integer       path '/params/imo'
                 , call_sign          varchar2(20)  path '/params/call_sign'
                 , flag               integer       path '/params/flag/pais_id'
                 , porto_id           integer       path '/params/porto/porto_id'
                 , dwt                number        path '/params/dwt'
                 , grt                number        path '/params/grt'
                 , net                number        path '/params/net'
                 , grain              number        path '/params/grain'
                 , bale               number        path '/params/bale'
                 , gangway            varchar2(20)  path '/params/gangway'
                 , loa                number        path '/params/loa'
                 , beam               number        path '/params/beam'
                 , calado             number        path '/params/calado'
                 , observacao         varchar2(500) path '/params/observacao'
                 , data_expiracao     varchar2(30)  path '/params/data_expiracao'
                 , poroes             xmltype       path '/params/poroes'
                 , anexos             xmltype       path '/params/anexos'
                )
   ) loop
      select status
        into v_status_atual
        from  operporto.v$embarcacao
       where embarcacao_id = i.embarcacao_id;

       operporto.pkg_operporto.prc_alt_embarcacao(p_embarcacao_id      => i.embarcacao_id
                                                 ,p_vessel_name        => i.vessel_name
                                                 ,p_vessel_ex_name     => i.vessel_ex_name
                                                 ,p_charterers         => i.charterers
                                                 ,p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                 ,p_ano_construcao     => i.ano_construcao
                                                 ,p_gear               => i.gear
                                                 ,p_outreach           => i.outreach
                                                 ,p_imo                => i.imo
                                                 ,p_call_sign          => i.call_sign
                                                 ,p_flag               => i.flag
                                                 ,p_porto_id           => i.porto_id
                                                 ,p_dwt                => i.dwt
                                                 ,p_grt                => i.grt
                                                 ,p_net                => i.net
                                                 ,p_grain              => i.grain
                                                 ,p_bale               => i.bale
                                                 ,p_gangway            => i.gangway
                                                 ,p_loa                => i.loa
                                                 ,p_beam               => i.beam
                                                 ,p_calado             => i.calado
                                                 ,p_observacao         => i.observacao
                                                 ,p_data_expiracao     => trunc(to_timestamp(i.data_expiracao, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"'))
                                                 );

      for j in (
         select *
           from xmltable('/poroes/arrayItem' passing i.poroes
                   columns
                      embarcacao_porao_id   integer       path '/arrayItem/embarcacao_porao_id'
                    , num_porao             integer       path '/arrayItem/num_porao'
                    , comprimento_porao     number        path '/arrayItem/comprimento_porao'
                    , largura_porao         number        path '/arrayItem/largura_porao'
                    , comprimento_boca      number        path '/arrayItem/comprimento_boca'
                    , largura_boca          number        path '/arrayItem/largura_boca'
                    , tipo_porao_id         integer       path '/arrayItem/tipo_porao_id'
                    , mec_abertura_tampa_id integer       path '/arrayItem/mec_abertura_tampa_id'
                    , observacao            varchar2(500) path '/arrayItem/observacao'
                    , operation             varchar2(30)  path '/arrayItem/operation'
                   )
      )loop
         case
            when upper(trim(j.operation)) = 'INSERT' then
                operporto.pkg_operporto.prc_ins_embarcacao_porao(p_embarcacao_porao_id   => v_embarcacao_porao_id
                                                                ,p_embarcacao_id         => i.embarcacao_id
                                                                ,p_num_porao             => j.num_porao
                                                                ,p_comprimento_porao     => j.comprimento_porao
                                                                ,p_largura_porao         => j.largura_porao
                                                                ,p_comprimento_boca      => j.comprimento_boca
                                                                ,p_largura_boca          => j.largura_boca
                                                                ,p_tipo_porao_id         => j.tipo_porao_id
                                                                ,p_mec_abertura_tampa_id => j.mec_abertura_tampa_id
                                                                ,p_observacao            => j.observacao
                                                                );
            when upper(trim(j.operation)) = 'UPDATE' then
                operporto.pkg_operporto.prc_alt_embarcacao_porao(p_embarcacao_porao_id   => j.embarcacao_porao_id
                                                                ,p_embarcacao_id         => i.embarcacao_id
                                                                ,p_num_porao             => j.num_porao
                                                                ,p_comprimento_porao     => j.comprimento_porao
                                                                ,p_largura_porao         => j.largura_porao
                                                                ,p_comprimento_boca      => j.comprimento_boca
                                                                ,p_largura_boca          => j.largura_boca
                                                                ,p_tipo_porao_id         => j.tipo_porao_id
                                                                ,p_mec_abertura_tampa_id => j.mec_abertura_tampa_id
                                                                ,p_observacao            => j.observacao
                                                                );
            when upper(trim(j.operation)) = 'DELETE' then
                operporto.pkg_operporto.prc_del_embarcacao_porao(p_embarcacao_porao_id => j.embarcacao_porao_id);

            else null;

         end case;
      end loop;

      for j in (
         select *
           from xmltable('/anexos/arrayItem' passing i.anexos
                   columns
                      embarcacao_anexo_id integer        path '/arrayItem/embarcacao_anexo_id'
                    , descricao           varchar2(61)   path '/arrayItem/descricao'
                    , arquivo             clob           path '/arrayItem/arquivo'
                    , url                 varchar2(1000) path '/arrayItem/url'
                    , operation           varchar2(30)   path '/arrayItem/operation'
                   )
      ) loop
         case upper(j.operation)
            when 'INSERT' then
                operporto.pkg_operporto.prc_ins_embarcacao_anexo(p_embarcacao_anexo_id => v_embarcacao_anexo_id
                                                                ,p_embarcacao_id       => i.embarcacao_id
                                                                ,p_descricao           => j.descricao
                                                                ,p_arquivo             => kss.pkg_remote.fnc_base642blob(j.arquivo)
                                                                ,p_url                 => j.url
                                                                );
            when 'UPDATE' then
                operporto.pkg_operporto.prc_alt_embarcacao_anexo(p_embarcacao_anexo_id => j.embarcacao_anexo_id
                                                                ,p_descricao           => j.descricao
                                                                ,p_arquivo             => kss.pkg_remote.fnc_base642blob(j.arquivo)
                                                                ,p_url                 => j.url
                                                                );
            when 'DELETE' then
                operporto.pkg_operporto.prc_del_embarcacao_anexo(j.embarcacao_anexo_id);
            else null;
         end case;
      end loop;

      -- Valida embarcacao
       operporto.pkg_operporto.prc_define_status_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                          , p_status        => v_status_atual
                                                           );

      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Embarcac?o alterada com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_aprova_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id integer        path '/params/embarcacao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_aprova_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                   , p_justificativa => i.justificativa
                                                    );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Embarcac?o aprovada com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_libera_tp
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id integer        path '/params/embarcacao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_liberar_restricao_tp(p_embarcacao_id => i.embarcacao_id
                                                      , p_justificativa => i.justificativa
                                                       );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Restric?o do tipo de por?o liberada com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_libera_mat
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id integer        path '/params/embarcacao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_liberar_restricao_mat(p_embarcacao_id => i.embarcacao_id
                                                       , p_justificativa => i.justificativa
                                                        );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Restric?o do mecanismo de abertura da tampa liberada com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_reprova_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_mensagem varchar2(1000);
v_titulo   varchar2(100);
v_email    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   embarcacao_id integer        path '/params/embarcacao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_reprova_embarcacao(p_embarcacao_id => i.embarcacao_id
                                                    , p_justificativa => i.justificativa
                                                     );

      --Enviar Notificac?o de Embarcac?o Reprovada para a Programac?o
      for j in (
         select p.programacao_id
              , e.vessel_name
           from operporto.v$programacao p
          inner join  operporto.v$embarcacao e
                  on e.imo = p.imo
          where e.embarcacao_id = i.embarcacao_id
            and p.status_id not in (3, 4)
      )loop

         -- notificac?o email
         select '<hr>EMBARCAC?O REPROVADA<hr>'
              ||'Programac?o     : '||p.programacao_id||'<br/>'
              ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
              ||'Agencia         : '||(select e.descricao||' <br/>'
                                         from operporto.v$programacao_etiqueta pe
                                        inner join operporto.v$etiqueta e
                                           on e.etiqueta_id = pe.etiqueta_id
                                          and e.tipo_id = 2
                                        where pe.programacao_id = p.programacao_id)
              ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
              ||'Periodo previsto:<br/><ul>'
              ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
              ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
              ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
              ||'Importadores:<br/><ul>'
              ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                   from operporto.v$programacao_etiqueta pe
                  inner join operporto.v$etiqueta e
                     on e.etiqueta_id = pe.etiqueta_id
                    and e.tipo_id = 3
                  inner join recinto.v$produto_categoria c
                     on c.categoria_id = pe.categoria_id
                  where pe.programacao_id = p.programacao_id)||'</ul><hr>'
              ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
              , 'Embarcac?o reprovada / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
           into v_mensagem
              , v_titulo
           from operporto.v$programacao p
          where p.programacao_id = j.programacao_id;

      /*   recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                           , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                           , p_anexos    => null
                                           , p_email     => v_email
                                            );*/

         for k in (
            select pge.grupo_email_id
              from operporto.v$programacao_grupo_email pge
             where pge.programacao_id = j.programacao_id
               and pge.ativo = 1
         ) loop
            recinto.pkg_email.prc_enviar_email(p_grupo_email_id => k.grupo_email_id
                                             , p_corpo          => v_email
                                             , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                             , p_multipart      => 1
                                              );
         end loop;

      end loop;
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Embarcac?o reprovada com sucesso.')),
                xmlelement("embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_porto
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_porto_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   nome       varchar2(50)     path '/params/nome'
                 , pais_id    integer          path '/params/pais_id'
                 , bigrama    varchar2(2)      path '/params/bigrama'
                 , trigrama   varchar2(3)      path '/params/trigrama'
                 , observacao varchar2(1000)   path '/params/observacao'
                 , ativo      integer          path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_ins_porto(p_porto_id   => v_porto_id
                                            ,p_nome       => i.nome
                                            ,p_pais_id    => i.pais_id
                                            ,p_bigrama    => i.bigrama
                                            ,p_trigrama   => i.trigrama
                                            ,p_observacao => i.observacao
                                            ,p_ativo      => i.ativo
                                            );

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Porto inserido com sucesso.')),
                xmlelement("porto_id", xmlattributes('number' as "type"), numbertojson(v_porto_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_porto
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   porto_id integer          path '/params/porto_id'
                 , nome     varchar2(50)     path '/params/nome'
                 , pais_id  integer          path '/params/pais_id'
                 , bigrama  varchar2(2)      path '/params/bigrama'
                 , trigrama varchar2(3)      path '/params/trigrama'
                 , observacao varchar2(1000) path '/params/observacao'
                 , ativo      integer          path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_porto(p_porto_id   => i.porto_id
                                            ,p_nome       => i.nome
                                            ,p_pais_id    => i.pais_id
                                            ,p_bigrama    => i.bigrama
                                            ,p_trigrama   => i.trigrama
                                            ,p_observacao => i.observacao
                                            ,p_ativo      => i.ativo
                                            );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Porto alterado com sucesso.')),
                xmlelement("porto_id", xmlattributes('number' as "type"), numbertojson(i.porto_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_porto
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   porto_id        integer        path '/params/porto_id'
                 , ativo           integer        path '/params/ativo'
                 , justificativa   varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_ativo_porto(p_porto_id      => i.porto_id
                                                  ,p_ativo         => i.ativo
                                                  ,p_justificativa => i.justificativa
                                                  );
      case i.ativo
         when 1 then
            v_msg:='Porto ativado com sucesso.';
         when 0 then
            v_msg:='Porto inativado com sucesso.';
         else
            v_msg:='Indicador da flag n?o consta nas opc?es.';
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("porto_id", xmlattributes('number' as "type"), numbertojson(i.porto_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_porto
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   porto_id      integer        path '/params/porto_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_del_porto(p_porto_id      => i.porto_id
                                           , p_justificativa => i.justificativa
                                            );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Porto excluido com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_tipo_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_tipo_embarcacao_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao  varchar2(60)  path '/params/descricao'
                 , observacao varchar2(500) path '/params/observacao'
                 , ativo      integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_ins_tipo_embarcacao(p_tipo_embarcacao_id => v_tipo_embarcacao_id
                                                      ,p_observacao         => i.observacao
                                                      ,p_descricao          => i.descricao
                                                      ,p_ativo              => i.ativo
                                                      );
      select xmlconcat(
                xmlelement("mensagem",           xmlattributes('string' as "type"), stringtojson('Tipo de embarcac?o inserida com sucesso.')),
                xmlelement("tipo_embarcacao_id", xmlattributes('number' as "type"), numbertojson(v_tipo_embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_tipo_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_embarcacao_id integer       path '/params/tipo_embarcacao_id'
                 , descricao          varchar2(60)  path '/params/descricao'
                 , observacao         varchar2(500) path '/params/observacao'
                 , ativo              integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_tipo_embarcacao(p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                      ,p_observacao         => i.observacao
                                                      ,p_descricao          => i.descricao
                                                      ,p_ativo              => i.ativo
                                                      );
      select xmlconcat(
                xmlelement("mensagem",           xmlattributes('string' as "type"), stringtojson('Tipo de embarcac?o alterada com sucesso.')),
                xmlelement("tipo_embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.tipo_embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_tipo_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_embarcacao_id integer        path '/params/tipo_embarcacao_id'
                 , ativo              integer        path '/params/ativo'
                 , justificativa      varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_ativo_tipo_embarcacao(p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                           , p_ativo              => i.ativo
                                                           , p_justificativa      => i.justificativa
                                                            );
      case i.ativo
         when 1 then
            v_msg:='Tipo de embarcac?o ativado com sucesso.';
         when 0 then
            v_msg:='Tipo de embarcac?o inativado com sucesso.';
         else
            v_msg:='Indicador da flag n?o consta nas opc?es.';
      end case;
      select xmlconcat(
                xmlelement("mensagem",           xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("tipo_embarcacao_id", xmlattributes('number' as "type"), numbertojson(i.tipo_embarcacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_tipo_embarcacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_embarcacao_id integer        path '/params/tipo_embarcacao_id'
                 , justificativa      varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_del_tipo_embarcacao(p_tipo_embarcacao_id => i.tipo_embarcacao_id
                                                     , p_justificativa      => i.justificativa
                                                      );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Tipo de embarcac?o excluida com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

/*
procedure prc_cad_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_id   integer;
v_msg  varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                    operation  varchar2(30)   path '/params/operation'
                 ,  categoria_id integer      path '/params/categoria_id'
                 , descricao    varchar2(60)  path '/params/descricao'
                 , ativo        integer       path '/params/ativo'
                 , observacao   varchar2(500) path '/params/observacao'
                 , produto_classe_id integer  path '/params/produto_classe_id'
                 )
   ) loop
      v_id := i.categoria_id;
      case upper(i.operation)
         when 'INSERT' then
            operporto.pkg_schedule.prc_ins_categoria(p_categoria_id      => v_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                 );
            v_msg := 'Categoria inserida com sucesso.';

         when 'UPDATE' then
            operporto.pkg_schedule.prc_alt_categoria(p_categoria_id        => i.categoria_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                  );

            if v_msg is null then
               v_msg := 'Categoria alterada com sucesso.';
            end if;   

          when 'DELETE' then
             operporto.pkg_schedule.prc_del_categoria(p_categoria_id => i.categoria_id
                                                  );
            v_msg := 'Categoria excluida com sucesso.';
         else
            raise_application_error(-20000, 'Operacao '||i.operation||' invalida');
      end case;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(v_id))
             )
        into p_result
        from dual;
   end loop;
end prc_cad_categoria;
*/


procedure prc_ins_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_categoria_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao         varchar2(60)  path '/params/descricao'
                 , ativo             integer       path '/params/ativo'
                 , observacao        varchar2(500) path '/params/observacao'
                 , produto_classe_id integer       path '/params/produto_classe_id'
                )
   ) loop
      recinto.pkg_recinto.prc_ins_produto_categoria(p_categoria_id        => v_categoria_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                   );
/*      fiscal.pkg_fiscal_cadastros.prc_ins_produto_categoria(p_categoria_id            => v_categoria_id
                                                          , p_descricao               => i.descricao
                                                          , p_ativo                   => i.ativo
                                                          , p_cod_contabil            => null
                                                          , p_historico_contabil      => null
                                                          , p_cod_contabil_debito     => null
                                                          , p_cod_contabil_debito_jan => null
                                                          , p_cod_contabil_debito_fev => null
                                                          , p_cod_contabil_debito_mar => null
                                                          , p_cod_contabil_debito_abr => null
                                                          , p_cod_contabil_debito_mai => null
                                                          , p_cod_contabil_debito_jun => null
                                                          , p_cod_contabil_debito_jul => null
                                                          , p_cod_contabil_debito_ago => null
                                                          , p_cod_contabil_debito_set => null
                                                          , p_cod_contabil_debito_out => null
                                                          , p_cod_contabil_debito_nov => null
                                                          , p_cod_contabil_debito_dez => null
                                                          , p_deduz_pedagio_bc        => 0
                                                          , p_permite_registro_nft    => 1
                                                          , p_tipo_item               => 99
                                                          , p_contabilizar            => null
                                                          , p_rowid                   => v_rowid
                                                           );*/
      select xmlconcat(
                xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Categoria de produto inserida com sucesso.')),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(v_categoria_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id integer       path '/params/categoria_id'
                 , descricao    varchar2(60)  path '/params/descricao'
                 , ativo        integer       path '/params/ativo'
                 , observacao   varchar2(500) path '/params/observacao'
                 , produto_classe_id integer  path '/params/produto_classe_id'
                )
   ) loop
      recinto.pkg_recinto.prc_alt_produto_categoria(p_categoria_id        => i.categoria_id
                                                  , p_descricao           => i.descricao
                                                  , p_ativo               => i.ativo
                                                  , p_observacao          => i.observacao
                                                  , p_fiscal_categoria_id => null
                                                  , p_produto_classe_id   => i.produto_classe_id
                                                   );
      /*fiscal.pkg_fiscal_cadastros.prc_alt_produto_categoria(p_categoria_id            => i.categoria_id
                                                          , p_descricao               => i.descricao
                                                          , p_ativo                   => i.ativo
                                                          , p_cod_contabil            => null
                                                          , p_historico_contabil      => null
                                                          , p_cod_contabil_debito     => null
                                                          , p_cod_contabil_debito_jan => null
                                                          , p_cod_contabil_debito_fev => null
                                                          , p_cod_contabil_debito_mar => null
                                                          , p_cod_contabil_debito_abr => null
                                                          , p_cod_contabil_debito_mai => null
                                                          , p_cod_contabil_debito_jun => null
                                                          , p_cod_contabil_debito_jul => null
                                                          , p_cod_contabil_debito_ago => null
                                                          , p_cod_contabil_debito_set => null
                                                          , p_cod_contabil_debito_out => null
                                                          , p_cod_contabil_debito_nov => null
                                                          , p_cod_contabil_debito_dez => null
                                                          , p_deduz_pedagio_bc        => 0
                                                          , p_permite_registro_nft    => 1
                                                          , p_tipo_item               => 99
                                                          , p_contabilizar            => null
                                                           );*/
      select xmlconcat(
                xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Categoria de produto alterada com sucesso.')),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(i.categoria_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(200);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id  integer        path '/params/categoria_id'
                 , ativo         integer        path '/params/ativo'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
      recinto.pkg_recinto.prc_alt_ativo_categoria(p_categoria_id    => i.categoria_id
                                                 ,p_ativo           => i.ativo
                                                 ,p_justificativa   => i.justificativa
                                                 );
      case i.ativo
         when 0 then
            v_msg:='Categoria de Produto inativada com sucesso.';
         when 1 then
            v_msg:='Categoria de Produto ativada com sucesso.';
         else
            v_msg:='';
      end case;
      select xmlconcat(
                xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(i.categoria_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_categoria
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id  integer        path '/params/categoria_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
      recinto.pkg_recinto.prc_del_produto_categoria(p_categoria_id  => i.categoria_id
                                                  , p_justificativa => i.justificativa
                                                   );
      --fiscal.pkg_fiscal_cadastros.prc_del_produto_categoria(p_categoria_id => i.categoria_id);
      select xmlconcat(
                xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Categoria de produto excluida com sucesso.')),
                xmlelement("categoria_id", xmlattributes('number' as "type"), numbertojson(i.categoria_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_etiqueta
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_etiqueta_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao  varchar2(100)  path '/params/descricao'
                 , tipo_id    integer        path '/params/tipo_id'
                 , cor        varchar2(7)    path '/params/cor'
                 , observacao varchar2(1000) path '/params/observacao'
                 , ativo      integer        path '/params/ativo'
                )
   ) loop
      operporto.pkg_schedule.prc_ins_etiqueta(p_etiqueta_id => v_etiqueta_id
                                            ,p_descricao   => i.descricao
                                            ,p_tipo_id     => i.tipo_id
                                            ,p_cor         => i.cor
                                            ,p_observacao  => i.observacao
                                            ,p_ativo       => i.ativo
                                            );
      select xmlconcat(
                xmlelement("mensagem",    xmlattributes('string' as "type"), stringtojson('Etiqueta inserida com sucesso.')),
                xmlelement("etiqueta_id", xmlattributes('number' as "type"), numbertojson(v_etiqueta_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_etiqueta
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etiqueta_id integer        path '/params/etiqueta_id'
                 , descricao   varchar2(100)  path '/params/descricao'
                 , tipo_id     integer        path '/params/tipo_id'
                 , cor         varchar2(7)    path '/params/cor'
                 , observacao  varchar2(1000) path '/params/observacao'
                 , ativo       integer        path '/params/ativo'
                )
   ) loop
      operporto.pkg_schedule.prc_alt_etiqueta(p_etiqueta_id => i.etiqueta_id
                                            ,p_descricao   => i.descricao
                                            ,p_tipo_id     => i.tipo_id
                                            ,p_cor         => i.cor
                                            ,p_observacao  => i.observacao
                                            ,p_ativo       => i.ativo
                                            );
      select xmlconcat(
                xmlelement("mensagem",    xmlattributes('string' as "type"), stringtojson('Etiqueta alterada com sucesso.')),
                xmlelement("etiqueta_id", xmlattributes('number' as "type"), numbertojson(i.etiqueta_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_etiqueta
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etiqueta_id   integer        path '/params/etiqueta_id'
                 , ativo         integer        path '/params/ativo'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
      operporto.pkg_schedule.prc_alt_ativo_etiqueta(p_etiqueta_id   => i.etiqueta_id
                                                  ,p_ativo         => i.ativo
                                                  ,p_justificativa => i.justificativa
                                                  );
      case i.ativo
         when 1 then
            v_msg:='Etiqueta ativada com sucesso.';
         when 0 then
            v_msg:='Etiqueta inativada com sucesso.';
         else
            v_msg:='Indicador da flag n?o consta nas opc?es.';
      end case;

      select xmlconcat(
                xmlelement("mensagem",    xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("etiqueta_id", xmlattributes('number' as "type"), numbertojson(i.etiqueta_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_etiqueta
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   etiqueta_id   integer        path '/params/etiqueta_id'
                 , justificativa varchar2(2000) path '/params/motivo'
                )
   ) loop
      operporto.pkg_schedule.prc_del_etiqueta(p_etiqueta_id   => i.etiqueta_id
                                           , p_justificativa => i.justificativa
                                            );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Etiqueta excluida com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_restricao_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   categoria_id integer        path '/params/categoria_id'
                 , porto_id     integer        path '/params/porto_id'
                 , pais_id      integer        path '/params/pais_id'
                 , liberado     integer        path '/params/liberado'
                 , observacao   varchar2(1000) path '/params/observacao'
                )
   ) loop
      if i.porto_id is not null
         or i.pais_id is not null
         or i.categoria_id is not null then
         operporto.pkg_schedule.prc_ins_restricao(p_restricao_id => v_restricao_id
                                                ,p_categoria_id => i.categoria_id
                                                ,p_porto_id     => i.porto_id
                                                ,p_pais_id      => i.pais_id
                                                ,p_liberado     => i.liberado
                                                ,p_observacao  => i.observacao
                                                );
         select xmlconcat(
                   xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Restric?o inserida com sucesso.')),
                   xmlelement("restricao_id", xmlattributes('number' as "type"), numbertojson(v_restricao_id))
                )
           into p_result
           from dual;
      else
         kss.pkg_mensagem.prc_dispara_msg('M5005-30111');
         /*raise_application_error(-20000,'N?o foi possivel inserir a restric?o pois todos os campos est?o nulos.'||chr(13)||chr(10)||
                                     'CAUSA:'||chr(13)||chr(10)||
                                     'Pelo menos um dos campos deve estar preenchido'||chr(13)||chr(10)||
                                     'ACAO:'||chr(13)||
                                     'Selecione pelo menos um PORTO, PAIS ou PRODUTO.'||chr(10)||chr(10)); */
      end if;
   end loop;
end;

procedure prc_alt_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id integer        path '/params/restricao_id'
                 , categoria_id integer        path '/params/categoria_id'
                 , porto_id     integer        path '/params/porto_id'
                 , pais_id      integer        path '/params/pais_id'
                 , liberado     integer        path '/params/liberado'
                 , observacao   varchar2(1000) path '/params/observacao'
                )
   ) loop
      operporto.pkg_schedule.prc_alt_restricao(p_restricao_id => i.restricao_id
                                             ,p_categoria_id => i.categoria_id
                                             ,p_porto_id     => i.porto_id
                                             ,p_pais_id      => i.pais_id
                                             ,p_liberado     => i.liberado
                                             , p_observacao  => i.observacao
                                             );
      select xmlconcat(
                xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Restric?o alterada com sucesso.')),
                xmlelement("restricao_id", xmlattributes('number' as "type"), numbertojson(i.restricao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ativar_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id  integer        path '/params/restricao_id'
                 , justificativa varchar2(3000) path '/params/motivo'
                )
   ) loop
      operporto.pkg_schedule.prc_ativar_restricao(p_restricao_id  => i.restricao_id
                                               , p_justificativa => i.justificativa
                                                );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Restric?o reativada com sucesso.'))
             )
        into p_result
        from dual;

   end loop;

end;

procedure prc_desativar_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id  integer        path '/params/restricao_id'
                 , justificativa varchar2(3000) path '/params/motivo'
                )
   ) loop
      operporto.pkg_schedule.prc_desativar_restricao(p_restricao_id  => i.restricao_id
                                                  , p_justificativa => i.justificativa
                                                   );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Restric?o liberada com sucesso.'))
             )
        into p_result
        from dual;

   end loop;

end;

procedure prc_del_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   restricao_id  integer        path '/params/restricao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
      operporto.pkg_schedule.prc_del_restricao(p_restricao_id  => i.restricao_id
                                            , p_justificativa => i.justificativa
                                             );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Restric?o excluida com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_manutencao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_manutencao_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id    integer       path '/params/berco_id'
                 , data_inicio varchar2(30)  path '/params/data_inicio'
                 , data_fim    varchar2(30)  path '/params/data_fim'
                 , observacao  varchar2(500) path '/params/observacao'
                )
   ) loop
      operporto.pkg_schedule.prc_ins_manutencao(p_manutencao_id => v_manutencao_id
                                              ,p_berco_id      => i.berco_id
                                              ,p_data_inicio   => to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')
                                              ,p_data_fim      => to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')
                                              ,p_observacao    => i.observacao
                                              );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Periodo de manutenc?o inserido com sucesso.')),
                xmlelement("manutencao_id", xmlattributes('number' as "type"), numbertojson(v_manutencao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_manutencao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   manutencao_id integer       path '/params/manutencao_id'
                 , berco_id      integer       path '/params/berco_id'
                 , data_inicio   varchar2(30)  path '/params/data_inicio'
                 , data_fim      varchar2(30)  path '/params/data_fim'
                 , observacao    varchar2(500) path '/params/observacao'
                )
   ) loop
      operporto.pkg_schedule.prc_alt_manutencao(p_manutencao_id => i.manutencao_id
                                              ,p_berco_id      => i.berco_id
                                              ,p_data_inicio   => to_timestamp(i.data_inicio, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')
                                              ,p_data_fim      => to_timestamp(i.data_fim, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')
                                              ,p_observacao    => i.observacao
                                              );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Periodo de manutenc?o alterado com sucesso.')),
                xmlelement("manutencao_id", xmlattributes('number' as "type"), numbertojson(i.manutencao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_manutencao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   manutencao_id integer path '/params/manutencao_id'
                )
   ) loop
      operporto.pkg_schedule.prc_del_manutencao(p_manutencao_id => i.manutencao_id);
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Periodo de manutenc?o excluido com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;
                   

procedure prc_ins_berco
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_berco_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao  varchar2(60)  path '/params/descricao'
                 , loa        number(*,2)   path '/params/loa'
                 , calado     number(*,2)   path '/params/calado'
                 , beam       number(*,2)   path '/params/beam'
                 , dwt        number(*,2)   path '/params/dwt'
                 , cod_porto  number(*,2)   path '/params/cod_porto'
                 , observacao varchar2(500) path '/params/observacao'
                )
   ) loop
       operporto.pkg_operporto.prc_ins_berco(p_berco_id   => v_berco_id
                                            ,p_descricao  => i.descricao
                                            ,p_loa        => i.loa
                                            ,p_calado     => i.calado
                                            ,p_beam       => i.beam
                                            ,p_dwt        => i.dwt
                                            ,p_cod_porto  => i.cod_porto
                                            ,p_observacao => i.observacao
                                            );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Berco inserido com sucesso.')),
                xmlelement("berco_id", xmlattributes('number' as "type"), numbertojson(v_berco_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_berco
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(2000);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id   integer       path '/params/berco_id'
                 , descricao  varchar2(60)  path '/params/descricao'
                 , loa        number(*,2)   path '/params/loa'
                 , calado     number(*,2)   path '/params/calado'
                 , beam       number(*,2)   path '/params/beam'
                 , dwt        number(*,2)   path '/params/dwt'
                 , cod_porto  varchar2(100) path '/params/cod_porto'
                 , observacao varchar2(500) path '/params/observacao'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_berco(p_berco_id   => i.berco_id
                                           ,p_descricao  => i.descricao
                                           ,p_loa        => i.loa
                                           ,p_calado     => i.calado
                                           ,p_beam       => i.beam
                                           ,p_dwt        => i.dwt
                                           ,p_cod_porto  => i.cod_porto
                                           ,p_observacao => i.observacao
                                           ,p_msg        => v_msg
                                            );
                                            
                                            
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Berco alterado com sucesso.')),
                xmlelement("berco_id", xmlattributes('number' as "type"), numbertojson(i.berco_id)),
                xmlelement("msg_os",   xmlattributes('string' as "type"), stringtojson(v_msg))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_berco
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   berco_id integer path '/params/berco_id'
                )
   ) loop
       operporto.pkg_operporto.prc_del_berco(p_berco_id => i.berco_id);
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Berco excluido com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_mec_abertura_tampa
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_mec_abertura_tampa_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao  varchar2(100) path '/params/descricao'
                 , observacao varchar2(500) path '/params/observacao'
                 , restricao  integer       path '/params/restricao'
                 , ativo      integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_schedule.prc_ins_mec_abertura_tampa(p_mec_abertura_tampa_id => v_mec_abertura_tampa_id
                                                         ,p_descricao             => i.descricao
                                                         ,p_observacao            => i.observacao
                                                         ,p_restricao             => i.restricao
                                                         ,p_ativo                 => i.ativo
                                                         );
      select xmlconcat(
                xmlelement("mensagem",              xmlattributes('string' as "type"), stringtojson('Mecanismo de Abertura da Tampa inserido com sucesso.')),
                xmlelement("mec_abertura_tampa_id", xmlattributes('number' as "type"), numbertojson(v_mec_abertura_tampa_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_mec_abertura_tampa
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mec_abertura_tampa_id integer       path '/params/mec_abertura_tampa_id'
                 , descricao             varchar2(100) path '/params/descricao'
                 , observacao            varchar2(500) path '/params/observacao'
                 , restricao             integer       path '/params/restricao'
                 , ativo                 integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_schedule.prc_alt_mec_abertura_tampa(p_mec_abertura_tampa_id => i.mec_abertura_tampa_id
                                                         ,p_descricao             => i.descricao
                                                         ,p_observacao            => i.observacao
                                                         ,p_restricao             => i.restricao
                                                         ,p_ativo                 => i.ativo
                                                         );
      select xmlconcat(
                xmlelement("mensagem",              xmlattributes('string' as "type"), stringtojson('Mecanismo de Abertura da Tampa alterado com sucesso.')),
                xmlelement("mec_abertura_tampa_id", xmlattributes('number' as "type"), numbertojson(i.mec_abertura_tampa_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_mecanismo_tampa
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_msg varchar2(100);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mec_abertura_tampa_id integer        path '/params/mec_abertura_tampa_id'
                 , ativo                 integer        path '/params/ativo'
                 , justificativa         varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_schedule.prc_alt_ativo_mecanismo_tampa(p_mec_abertura_tampa_id => i.mec_abertura_tampa_id
                                                            ,p_ativo                 => i.ativo
                                                            ,p_justificativa         => i.justificativa
                                                            );
      case i.ativo
         when 1 then
            v_msg:='Mecanismo ativado com sucesso.';
         when 0 then
            v_msg:='Mecanismo inativado com sucesso.';
         else
            v_msg:='Indicador da flag n?o consta nas opc?es.';
      end case;

      select xmlconcat(
                xmlelement("mensagem",              xmlattributes('string' as "type"), stringtojson(v_msg)),
                xmlelement("mec_abertura_tampa_id", xmlattributes('number' as "type"), numbertojson(i.mec_abertura_tampa_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_mec_abertura_tampa
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mec_abertura_tampa_id integer        path '/params/mec_abertura_tampa_id'
                 , justificativa         varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_schedule.prc_del_mec_abertura_tampa(p_mec_abertura_tampa_id => i.mec_abertura_tampa_id
                                                        , p_justificativa         => i.justificativa
                                                         );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Mecanismo de Abertura da Tampa excluido com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_tipo_porao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_tipo_porao_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao  varchar2(60)  path '/params/descricao'
                 , observacao varchar2(500) path '/params/observacao'
                 , restricao  integer       path '/params/restricao'
                 , ativo      integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_ins_tipo_porao(p_tipo_porao_id => v_tipo_porao_id
                                                 ,p_descricao     => i.descricao
                                                 ,p_observacao    => i.observacao
                                                 ,p_restricao     => i.restricao
                                                 ,p_ativo         => i.ativo
                                                 );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Tipo de Por?o inserido com sucesso.')),
                xmlelement("tipo_porao_id", xmlattributes('number' as "type"), numbertojson(v_tipo_porao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_tipo_porao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_porao_id integer       path '/params/tipo_porao_id'
                 , descricao     varchar2(60)  path '/params/descricao'
                 , observacao    varchar2(500) path '/params/observacao'
                 , restricao     integer       path '/params/restricao'
                 , ativo         integer       path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_tipo_porao(p_tipo_porao_id => i.tipo_porao_id
                                                 ,p_descricao     => i.descricao
                                                 ,p_observacao    => i.observacao
                                                 ,p_restricao     => i.restricao
                                                 ,p_ativo         => i.ativo
                                                 );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Tipo de Por?o alterado com sucesso.')),
                xmlelement("tipo_porao_id", xmlattributes('number' as "type"), numbertojson(i.tipo_porao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alt_ativo_tipo_porao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_porao_id integer        path '/params/tipo_porao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                 , ativo         integer        path '/params/ativo'
                )
   ) loop
       operporto.pkg_operporto.prc_alt_ativo_tipo_porao(p_tipo_porao_id => i.tipo_porao_id
                                                       ,p_ativo         => i.ativo
                                                       ,p_justificativa => i.justificativa
                                                       );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Tipo de Por?o alterado com sucesso.')),
                xmlelement("tipo_porao_id", xmlattributes('number' as "type"), numbertojson(i.tipo_porao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_del_tipo_porao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   tipo_porao_id integer        path '/params/tipo_porao_id'
                 , justificativa varchar2(4000) path '/params/motivo'
                )
   ) loop
       operporto.pkg_operporto.prc_del_tipo_porao(p_tipo_porao_id => i.tipo_porao_id
                                                , p_justificativa => i.justificativa
                                                 );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Tipo de Por?o excluido com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_programacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_programacao_id               operporto.v$programacao.programacao_id%type;
v_programacao_etiqueta_id      operporto.v$programacao_etiqueta.programacao_etiqueta_id%type;
v_programacao_grupo_email_id   integer;
v_imo                          operporto.v$programacao.imo%type;
v_sum                          integer;
v_mensagem                     varchar2(1000);
v_titulo                       varchar2(100);
v_email_insert                 clob;
v_matching_et                  integer;
v_inserir                      integer;
v_qtde_importador              number;

begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   qtde_total          number        path '/params/qtde_total'
                 , imo                 integer       path '/params/imo'
                 , berco_id            integer       path '/params/berco_id'
                 , eta                 varchar2(20)  path '/params/eta_string'
                 , etb                 varchar2(20)  path '/params/etb_string'
                 , ets                 varchar2(20)  path '/params/ets_string'
                 , prancha             number        path '/params/prancha'
                 , pais_origem_id      integer       path '/params/porto_origem/pais/pais_id'
                 , porto_origem_id     integer       path '/params/porto_origem/porto_id'
                 , calado_after        number        path '/params/calado_after'
                 , calado_forward      number        path '/params/calado_forward'
                 , dwt_viagem          number        path '/params/dwt_viagem'
                 , observacao          varchar2(500) path '/params/observacao'
                 , etq_agencia_id      integer       path '/params/agencia_maritima'
                 , etq_importador      xmltype       path '/params/importador'
                 , etq_exportador      xmltype       path '/params/exportador'
                 , grupo_email         xmltype       path '/params/grupo_email'
                 , atrasar_prog        integer       path '/params/atrasar_prog'
                )
   ) loop
      select decode(i.imo, 0, null, i.imo)
        into v_imo
        from dual;

      select count(*)
        into v_matching_et
        from operporto.v$programacao p
       where (to_date(i.etb, 'yyyy-mm-dd') between p.etb and p.ets
           or to_date(i.ets, 'yyyy-mm-dd') between p.etb and p.ets)
         and p.berco_id = i.berco_id
         and p.status_id <> 4;

      if v_matching_et > 0 then --Nessas datas tem uma programac?o
         if trim(i.atrasar_prog) = 1 then --Usuario esta ciente disso e quer atrasar as programac?es
            v_inserir:=1;
         else --Usuario n?o esta ciente disso e precisa ser avisado
            v_inserir:=0;
         end if;
      else-- N?o achou nenhuma programac?o nessas datas
         v_inserir:=1;
      end if;

      if v_inserir = 1 then
      --Na chamada de inserc?o executa a procedure de atraso das datas das programac?es futuras
      operporto.pkg_schedule.prc_ins_programacao(p_programacao_id  => v_programacao_id
                                               ,p_sum             => v_sum
                                               ,p_qtde_total      => i.qtde_total
                                               ,p_imo             => v_imo
                                               ,p_berco_id        => i.berco_id
                                               ,p_eta             => to_date(nvl(i.eta, i.etb), 'yyyy-mm-dd')
                                               ,p_etb             => to_date(i.etb, 'yyyy-mm-dd')
                                               ,p_ets             => to_date(i.ets, 'yyyy-mm-dd')
                                               ,p_prancha         => i.prancha
                                               ,p_pais_origem_id  => i.pais_origem_id
                                               ,p_porto_origem_id => i.porto_origem_id
                                               ,p_calado_after    => i.calado_after
                                               ,p_calado_forward  => i.calado_forward
                                               ,p_dwt_viagem      => i.dwt_viagem
                                               ,p_observacao      => i.observacao
                                               );

      select xmlconcat(
                xmlelement("info", xmlattributes('string' as "type"), stringtojson(v_sum||' programac?es foram atrasadas para encaixar a nova data.'))
             )
        into p_result
        from dual;

      -- Cadastro da Etiqueta de agencia
      if trim(i.etq_agencia_id) is not null then
         operporto.pkg_schedule.prc_ins_programacao_etiqueta(p_programacao_etiqueta_id => v_programacao_etiqueta_id
                                                           ,p_programacao_id          => v_programacao_id
                                                           ,p_etiqueta_id             => i.etq_agencia_id
                                                           ,p_categoria_id            => null
                                                           ,p_qtde_descarga           => null
                                                           ,p_observacao              => null
                                                           );
      end if;

      for j in (
         select *
           from xmltable('/importador/arrayItem' passing i.etq_importador
                   columns
                      etiqueta_id   integer       path '/arrayItem/etiqueta/etiqueta_id'
                    , categoria_id  integer       path '/arrayItem/categoria/categoria_id'
                    , qtde_descarga number        path '/arrayItem/qtde_descarga'
                    , observacao    varchar2(500) path '/arrayItem/observacao'
                   )
      ) loop
         operporto.pkg_schedule.prc_ins_programacao_etiqueta(p_programacao_etiqueta_id => v_programacao_etiqueta_id
                                                           ,p_programacao_id          => v_programacao_id
                                                           ,p_etiqueta_id             => j.etiqueta_id
                                                           ,p_categoria_id            => j.categoria_id
                                                           ,p_qtde_descarga           => j.qtde_descarga
                                                           ,p_observacao              => j.observacao
                                                           );
      end loop;

      -- valida quantidade
      select nvl(sum(qtde_descarga),0)
        into v_qtde_importador
        from operporto.v$programacao_etiqueta t
       inner join operporto.v$etiqueta e
          on e.etiqueta_id = t.etiqueta_id
         and e.tipo_id = 3
       where programacao_id = v_programacao_id;

      if i.qtde_total != v_qtde_importador then
         raise_application_error(-20000, 'ATENC?O! A "Qtde total embarcac?o (ton):" da embarcac?o n?o corresponde a soma da "Qtde Descarga (ton)" dos importadores!');
      end if;

      for j in (
         select *
           from xmltable('/exportador/arrayItem' passing i.etq_exportador
                   columns
                      etiqueta_id   integer       path '/arrayItem/etiqueta/etiqueta_id'
                    , categoria_id  integer       path '/arrayItem/categoria/categoria_id'
                    , qtde_descarga number        path '/arrayItem/qtde_descarga'
                    , observacao    varchar2(500) path '/arrayItem/observacao'
                   )
      ) loop
         operporto.pkg_schedule.prc_ins_programacao_etiqueta(p_programacao_etiqueta_id => v_programacao_etiqueta_id
                                                           ,p_programacao_id          => v_programacao_id
                                                           ,p_etiqueta_id             => j.etiqueta_id
                                                           ,p_categoria_id            => j.categoria_id
                                                           ,p_qtde_descarga           => j.qtde_descarga
                                                           ,p_observacao              => j.observacao
                                                           );
      end loop;

      for j in (
         select distinct grupo_email_id
           from xmltable('/grupo_email/arrayItem' passing i.grupo_email
                   columns
                      grupo_email_id integer path '/arrayItem/grupo_email_id'
                   )
      ) loop
         operporto.pkg_schedule.prc_ins_prog_grupo_email(p_programacao_grupo_email_id => v_programacao_grupo_email_id
                                                       ,p_programacao_id             => v_programacao_id
                                                       ,p_grupo_email_id             => j.grupo_email_id
                                                       );
      end loop;

      -- notificac?o email
      select '<hr>CADASTRO DE PROGRAMAC?O<hr>'
           ||'Programac?o     : '||p.programacao_id||'<br/>'
           ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
           ||'Agencia         : '||(select e.descricao||' <br/>'
                                      from operporto.v$programacao_etiqueta pe
                                     inner join operporto.v$etiqueta e
                                        on e.etiqueta_id = pe.etiqueta_id
                                       and e.tipo_id = 2
                                     where pe.programacao_id = p.programacao_id)
           ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
           ||'Periodo previsto:<br/><ul>'
           ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
           ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
           ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
           ||'Importadores:<br/><ul>'
           ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                from operporto.v$programacao_etiqueta pe
               inner join operporto.v$etiqueta e
                  on e.etiqueta_id = pe.etiqueta_id
                 and e.tipo_id = 3
               inner join recinto.v$produto_categoria c
                  on c.categoria_id = pe.categoria_id
               where pe.programacao_id = p.programacao_id)||'</ul><hr>'
           ||'As seguintes restric?es se aplicam a programac?o:<br/><ul>'
           ||nvl((select kss.fnc_concat_all(kss.to_concat_expr('- '||substr(l.descricao,instr(l.descricao,'Restric?o:')+length('Restric?o:')+1,length(l.descricao)),'<br/>'))
                    from operporto_log.v$programacao el
                   inner join operporto_log.v$programacao_log l
                     on l.log_id = el.log_id
                  where el.evento_id in (1,2,3,4,5,8,9,12,13,14)
                    and not exists(select 1
                                     from operporto_log.v$programacao t
                                    where log_id_restricao is not null
                                      and programacao_id = el.programacao_id)
                    and el.programacao_id = p.programacao_id),'- SEM RESTRIC?ES')||'</ul><hr>'
           ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
           , 'Nova Programac?o Fospar / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
        into v_mensagem
           , v_titulo
        from operporto.v$programacao p
       where p.programacao_id = v_programacao_id;

/*      recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                        , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                        , p_anexos    => null
                                        , p_email     => v_email_insert
                                         );*/

      for j in (
         select pge.grupo_email_id
           from operporto.v$programacao_grupo_email pge
          where pge.programacao_id = v_programacao_id
            and pge.ativo = 1
      ) loop
         recinto.pkg_email.prc_enviar_email(p_grupo_email_id => j.grupo_email_id
                                          , p_corpo          => v_email_insert
                                          , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                          , p_multipart      => 1
                                           );
      end loop;

      select xmlconcat(
                xmlelement("mensagem",       xmlattributes('string' as "type"), stringtojson('Programac?o inserida com sucesso.')),
                xmlelement("programacao_id", xmlattributes('number' as "type"), numbertojson(v_programacao_id))
             )
        into p_result
        from dual;
      else
         select xmlconcat(
                   xmlelement("mensagem",     xmlattributes('string' as "type"), stringtojson('Ja existem programac?es nessa data, e necessario informar se deseja atrasa-las.')),
                   xmlelement("atrasar_prog", xmlattributes('number' as "type"), numbertojson(1))
                )
           into p_result
           from dual;
      end if;

   end loop;
end;

procedure prc_alt_programacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_programacao_etiqueta_id integer;
 v_programacao_grupo_email_id integer;
 v_imo                     operporto.v$programacao.imo%type;
 v_matching_et             integer;
 v_sum                     integer;
 v_mensagem                     varchar2(1000);
 v_titulo                       varchar2(100);
 v_email_insert                 clob;
 v_qtde_importador              number;

begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id      integer       path '/params/programacao_id'
                 , qtde_total          number        path '/params/qtde_total'
                 , imo                 integer       path '/params/imo'
                 , berco_id            integer       path '/params/berco_id'
                 , eta                 varchar2(20)  path '/params/eta_string'
                 , etb                 varchar2(20)  path '/params/etb_string'
                 , ets                 varchar2(20)  path '/params/ets_string'
                 , prancha             number        path '/params/prancha'
                 , pais_origem_id      integer       path '/params/porto_origem/pais/pais_id'
                 , porto_origem_id     integer       path '/params/porto_origem/porto_id'
                 , calado_after        number        path '/params/calado_after'
                 , calado_forward      number        path '/params/calado_forward'
                 , dwt_viagem          number        path '/params/dwt_viagem'
                 , etq_agencia_id      integer       path '/params/agencia_maritima'
                 , etq_proprietario_id integer       path '/params/proprietario_id'
                 , observacao          varchar2(500) path '/params/observacao'
                 , etq_importador      xmltype       path '/params/importador'
                 , etq_exportador      xmltype       path '/params/exportador'
                 , grupo_email         xmltype       path '/params/grupo_email'
                )
   ) loop
      select decode(i.imo, 0, null, i.imo)
        into v_imo
        from dual;

      select count(*)
        into v_matching_et
        from operporto.v$programacao p
       where to_date(i.etb, 'yyyy-mm-dd') between p.etb and p.ets
         and p.berco_id = i.berco_id
         and i.programacao_id <> p.programacao_id
         and p.status_id <> 4;

      if v_matching_et = 0 then --Quando o v_matching_et for maior que 0 deve gerar uma excec?o na validac?o do PKG, n?o pode alterar as datas

         operporto.pkg_schedule.prc_alt_dt_programacao(p_programacao_id => i.programacao_id
                                                    , p_etb            => to_date(i.etb, 'yyyy-mm-dd')
                                                    , p_ets            => to_date(i.ets, 'yyyy-mm-dd')
                                                    , p_sum            => v_sum
                                                    );
         select xmlconcat(
                   xmlelement("info", xmlattributes('string' as "type"), stringtojson(v_sum||' programac?es foram atrasadas para encaixar a nova data.'))
                )
           into p_result
           from dual;

      end if;

      operporto.pkg_schedule.prc_alt_programacao(p_programacao_id  => i.programacao_id
                                               ,p_qtde_total      => i.qtde_total
                                               ,p_imo             => v_imo
                                               ,p_berco_id        => i.berco_id
                                               ,p_eta             => to_date(nvl(i.eta, i.etb), 'yyyy-mm-dd')
                                               ,p_etb             => to_date(i.etb, 'yyyy-mm-dd')
                                               ,p_ets             => to_date(i.ets, 'yyyy-mm-dd')
                                               ,p_prancha         => i.prancha
                                               ,p_calado_after    => i.calado_after
                                               ,p_calado_forward  => i.calado_forward
                                               ,p_dwt_viagem      => i.dwt_viagem
                                               ,p_pais_origem_id  => i.pais_origem_id
                                               ,p_porto_origem_id => i.porto_origem_id
                                               ,p_observacao      => i.observacao
                                               );
      if trim(i.etq_agencia_id) is not null then
         --Faz a verificac?o se essa etiqueta ja existe para a programac?o e se e diferente do parametro
         operporto.pkg_schedule.prc_alt_etiqueta_agencia(p_programacao_id => i.programacao_id
                                                      , p_etiqueta_id    => i.etq_agencia_id
                                                       );
      end if;

      for j in (
         select *
           from xmltable('/importador/arrayItem' passing i.etq_importador
                   columns
                      programacao_etiqueta_id integer       path '/arrayItem/programacao_etiqueta_id'
                    , etiqueta_id             integer       path '/arrayItem/etiqueta/etiqueta_id'
                    , categoria_id            integer       path '/arrayItem/categoria/categoria_id'
                    , qtde_descarga           number        path '/arrayItem/qtde_descarga'
                    , observacao              varchar2(500) path '/arrayItem/observacao'
                    , operation               varchar2(30)  path '/arrayItem/operation'
                   )
      ) loop
         case
            when upper(trim(j.operation)) = 'INSERT' then
               operporto.pkg_schedule.prc_ins_programacao_etiqueta(p_programacao_etiqueta_id => v_programacao_etiqueta_id
                                                                 ,p_programacao_id          => i.programacao_id
                                                                 ,p_etiqueta_id             => j.etiqueta_id
                                                                 ,p_categoria_id            => j.categoria_id
                                                                 ,p_qtde_descarga           => j.qtde_descarga
                                                                 ,p_observacao              => j.observacao
                                                                 );
            when upper(trim(j.operation)) = 'UPDATE' then
               operporto.pkg_schedule.prc_alt_programacao_etiqueta(p_programacao_etiqueta_id => j.programacao_etiqueta_id
                                                                 ,p_programacao_id          => i.programacao_id
                                                                 ,p_etiqueta_id             => j.etiqueta_id
                                                                 ,p_categoria_id            => j.categoria_id
                                                                 ,p_qtde_descarga           => j.qtde_descarga
                                                                 ,p_observacao              => j.observacao
                                                                 );
            when upper(trim(j.operation)) = 'DELETE' then
               operporto.pkg_schedule.prc_del_programacao_etiqueta(p_programacao_etiqueta_id => j.programacao_etiqueta_id);

            else null;

         end case;
      end loop;

      -- valida quantidade
      select nvl(sum(qtde_descarga),0)
        into v_qtde_importador
        from operporto.v$programacao_etiqueta t
       inner join operporto.v$etiqueta e
          on e.etiqueta_id = t.etiqueta_id
         and e.tipo_id = 3
       where programacao_id = i.programacao_id;

      if i.qtde_total != v_qtde_importador then
         raise_application_error(-20000, 'ATENC?O! A "Qtde total embarcac?o (ton):" da embarcac?o n?o corresponde a soma da "Qtde Descarga (ton)" dos importadores!');
      end if;

      for j in (
         select *
           from xmltable('/exportador/arrayItem' passing i.etq_exportador
                   columns
                      programacao_etiqueta_id integer       path '/arrayItem/programacao_etiqueta_id'
                    , etiqueta_id             integer       path '/arrayItem/etiqueta/etiqueta_id'
                    , categoria_id            integer       path '/arrayItem/categoria/categoria_id'
                    , qtde_descarga           number        path '/arrayItem/qtde_descarga'
                    , observacao              varchar2(500) path '/arrayItem/observacao'
                    , operation               varchar2(30)  path '/arrayItem/operation'
                   )
      ) loop
         case
            when upper(trim(j.operation)) = 'INSERT' then
               operporto.pkg_schedule.prc_ins_programacao_etiqueta(p_programacao_etiqueta_id => v_programacao_etiqueta_id
                                                                 ,p_programacao_id          => i.programacao_id
                                                                 ,p_etiqueta_id             => j.etiqueta_id
                                                                 ,p_categoria_id            => j.categoria_id
                                                                 ,p_qtde_descarga           => j.qtde_descarga
                                                                 ,p_observacao              => j.observacao
                                                                 );
            when upper(trim(j.operation)) = 'UPDATE' then
               operporto.pkg_schedule.prc_alt_programacao_etiqueta(p_programacao_etiqueta_id => j.programacao_etiqueta_id
                                                                 ,p_programacao_id          => i.programacao_id
                                                                 ,p_etiqueta_id             => j.etiqueta_id
                                                                 ,p_categoria_id            => j.categoria_id
                                                                 ,p_qtde_descarga           => j.qtde_descarga
                                                                 ,p_observacao              => j.observacao
                                                                 );
            when upper(trim(j.operation)) = 'DELETE' then
               operporto.pkg_schedule.prc_del_programacao_etiqueta(p_programacao_etiqueta_id => j.programacao_etiqueta_id);

            else null;

         end case;
      end loop;

      for j in (
         select *
           from xmltable('/grupo_email/arrayItem' passing i.grupo_email
                   columns
                      programacao_grupo_email_id integer        path '/arrayItem/programacao_grupo_email_id'
                    , grupo_email_id             integer        path '/arrayItem/grupo_email_id'
                    , ativo                      integer        path '/arrayItem/ativo'
                    , justificativa              varchar2(4000) path '/arrayItem/motivo'
                    , operation                  varchar2(30)   path '/arrayItem/operation'
                   )
      ) loop
         case upper(j.operation)
            when 'INSERT' then
               operporto.pkg_schedule.prc_ins_prog_grupo_email(p_programacao_grupo_email_id => v_programacao_grupo_email_id
                                                             ,p_programacao_id             => i.programacao_id
                                                             ,p_grupo_email_id             => j.grupo_email_id
                                                             );
            when 'UPDATE' then
               operporto.pkg_schedule.prc_atv_prog_grupo_email(p_programacao_grupo_email_id => j.programacao_grupo_email_id
                                                             ,p_ativo                      => j.ativo
                                                             ,p_justificativa              => j.justificativa
                                                             );
            when 'DELETE' then
               operporto.pkg_schedule.prc_del_prog_grupo_email(p_programacao_grupo_email_id => j.programacao_grupo_email_id);
            else null;
         end case;
      end loop;

      -- notificac?o email
      select '<hr>ALTERAC?O DE PROGRAMAC?O<hr>'
           ||'Programac?o     : '||p.programacao_id||'<br/>'
           ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
           ||'Agencia         : '||(select e.descricao||' <br/>'
                                      from operporto.v$programacao_etiqueta pe
                                     inner join operporto.v$etiqueta e
                                        on e.etiqueta_id = pe.etiqueta_id
                                       and e.tipo_id = 2
                                     where pe.programacao_id = p.programacao_id)
           ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
           ||'Periodo previsto:<br/><ul>'
           ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
           ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
           ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
           ||'Importadores:<br/><ul>'
           ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                from operporto.v$programacao_etiqueta pe
               inner join operporto.v$etiqueta e
                  on e.etiqueta_id = pe.etiqueta_id
                 and e.tipo_id = 3
               inner join recinto.v$produto_categoria c
                  on c.categoria_id = pe.categoria_id
               where pe.programacao_id = p.programacao_id)||'</ul><hr>'
           ||'As seguintes restric?es se aplicam a programac?o:<br/><ul>'
           ||nvl((select kss.fnc_concat_all(kss.to_concat_expr('- '||substr(l.descricao,instr(l.descricao,'Restric?o:')+length('Restric?o:')+1,length(l.descricao)),'<br/>'))
                    from operporto_log.v$programacao el
                   inner join operporto_log.v$programacao_log l
                     on l.log_id = el.log_id
                  where el.evento_id in (1,2,3,4,5,8,9,12,13,14)
                    and not exists(select 1
                                     from operporto_log.v$programacao t
                                    where log_id_restricao is not null
                                      and programacao_id = el.programacao_id)
                    and el.programacao_id = p.programacao_id),'- SEM RESTRIC?ES')||'</ul><hr>'
           ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
           , 'Alterac?o de programac?o Fospar / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
        into v_mensagem
           , v_titulo
        from operporto.v$programacao p
       where p.programacao_id = i.programacao_id;

      /*recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                        , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                        , p_anexos    => null
                                        , p_email     => v_email_insert
                                         );*/

      for j in (
         select pge.grupo_email_id
           from operporto.v$programacao_grupo_email pge
          where pge.programacao_id = i.programacao_id
            and pge.ativo = 1
      ) loop
         recinto.pkg_email.prc_enviar_email(p_grupo_email_id => j.grupo_email_id
                                          , p_corpo          => v_email_insert
                                          , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                          , p_multipart      => 1
                                           );
      end loop;

      select xmlconcat(
                xmlelement("mensagem",       xmlattributes('string' as "type"), stringtojson('Programac?o alterada com sucesso.')),
                xmlelement("programacao_id", xmlattributes('number' as "type"), numbertojson(i.programacao_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_atrasar_programacoes
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_sum integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer      path '/params/programacao_id'
                 , etb            varchar2(20) path '/params/etb'
                 , ets            varchar2(20) path '/params/ets'
                )
   ) loop

      operporto.pkg_schedule.prc_alt_dt_programacao(p_programacao_id => i.programacao_id
                                                 , p_etb            => to_date(i.etb, 'yyyy-mm-dd')
                                                 , p_ets            => to_date(i.ets, 'yyyy-mm-dd')
                                                 , p_sum            => v_sum
                                                 );
      select xmlconcat(
                xmlelement("mensagem",      xmlattributes('string' as "type"), stringtojson('Programac?o alterada com sucesso.')),
                xmlelement("qtd_alterados", xmlattributes('number' as "type"), numbertojson(v_sum))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_libera_prog_restricao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_aprovacao varchar2(500);
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer        path '/params/programacao_id'
                 , log_id         integer        path '/params/log_id'
                 , justificativa  varchar2(4000) path '/params/motivo'
                )
   ) loop

      operporto.pkg_schedule.prc_liberar_restricao(p_programacao_id => i.programacao_id
                                                , p_log_id         => i.log_id
                                                , p_msg            => i.justificativa
                                                , p_aprovacao      => v_aprovacao
                                                 );
      select xmlconcat(
                xmlelement("mensagem",  xmlattributes('string' as "type"), stringtojson('Restric?o liberada com sucesso.')),
                xmlelement("aprovacao", xmlattributes('string' as "type"), stringtojson(v_aprovacao))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_cancelar_programacao
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_p              operporto.v$programacao%rowtype;
 v_programacao_id operporto.v$programacao.programacao_id%type;
 v_intervalo      integer;
 v_diff_sys       integer;
 v_eta            operporto.v$programacao.eta%type;
 v_etb            operporto.v$programacao.etb%type;
 v_ets            operporto.v$programacao.ets%type;
 v_dias_cancelada integer;
 v_dias_proxima   integer;
 v_sum            integer;
 v_mensagem       varchar2(1000);
 v_titulo         varchar2(100);
 v_email_insert   clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer        path '/params/programacao_id'
                 , justificativa  varchar2(4000) path '/params/motivo'
                 , adiantar_prog  integer        path '/params/adiantar_prog'
                )
   ) loop
      -- notificac?o email
      select '<hr>CANCELAMENTO DE PROGRAMAC?O<hr>'
           ||'Programac?o     : '||p.programacao_id||'<br/>'
           ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
           ||'Agencia         : '||(select e.descricao||' <br/>'
                                      from operporto.v$programacao_etiqueta pe
                                     inner join operporto.v$etiqueta e
                                        on e.etiqueta_id = pe.etiqueta_id
                                       and e.tipo_id = 2
                                     where pe.programacao_id = p.programacao_id)
           ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
           ||'Justificativa:<br><ul>'||i.justificativa||'</ul><hr>'
           ||'Periodo previsto:<br/><ul>'
           ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
           ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
           ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
           ||'Importadores:<br/><ul>'
           ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                from operporto.v$programacao_etiqueta pe
               inner join operporto.v$etiqueta e
                  on e.etiqueta_id = pe.etiqueta_id
                 and e.tipo_id = 3
               inner join recinto.v$produto_categoria c
                  on c.categoria_id = pe.categoria_id
               where pe.programacao_id = p.programacao_id)||'</ul><hr>'
           ||'As seguintes restric?es se aplicam a programac?o:<br/><ul>'
           ||nvl((select kss.fnc_concat_all(kss.to_concat_expr('- '||substr(l.descricao,instr(l.descricao,'Restric?o:')+length('Restric?o:')+1,length(l.descricao)),'<br/>'))
                    from operporto_log.v$programacao el
                   inner join operporto_log.v$programacao_log l
                     on l.log_id = el.log_id
                  where el.evento_id in (1,2,3,4,5,8,9,12,13,14)
                    and not exists(select 1
                                     from operporto_log.v$programacao t
                                    where log_id_restricao is not null
                                      and programacao_id = el.programacao_id)
                    and el.programacao_id = p.programacao_id),'- SEM RESTRIC?ES')||'</ul><hr>'
           ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
           , 'Cancelamento de programac?o Fospar / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
        into v_mensagem
           , v_titulo
        from operporto.v$programacao p
       where p.programacao_id = i.programacao_id;

      if trim(i.adiantar_prog) = 1 then --Adiantar as Programac?es Posteriores
         select p.*
           into v_p
           from operporto.v$programacao p
          where p.programacao_id = i.programacao_id;

         /*CONSULTA A QUANTIDADE DE DIAS DA PROGRAMAC?O QUE ESTA SENDO CANCELADA (ETB-ETS)*/
         select v_p.ets - v_p.etb
           into v_dias_cancelada
           from dual;

         /*CONSULTA A QUANTIDADE DE DIAS DE WAITING TIME DA PROXIMA PROGRAMAC?O (ETA-ETB)*/
         select p.etb - p.eta
           into v_dias_proxima
           from operporto.v$programacao p
          where p.berco_id = v_p.berco_id
            and p.status_id not in (3,4)
            and p.programacao_id <> v_p.programacao_id
            and p.etb > v_p.etb
                       and not exists (
                          select 1
                            from operporto.v$programacao p1
                where p1.etb between v_p.etb and p.etb
                  and p1.programacao_id <> p.programacao_id
                             and p1.programacao_id <> v_p.programacao_id
                  and p1.berco_id = p.berco_id
                             and p1.status_id not in (3,4)
            );
         /*SE O INTERVALO DA PROGRAMAC?O CANCELADA FOR MENOR QUE O WAITING TIME DA PROXIMA PROGRAMAC?O
         USA ESSE INTERVALOR, CASO CONTRARIO TRAZ O INTERVALO DA PROXIMA PROGRAMAC?O ATE O ETA DA MESMA*/
         if v_dias_cancelada < v_dias_proxima then
            v_intervalo := v_dias_cancelada+1;
         else
            v_intervalo := v_dias_proxima;
         end if;
         --Busca a Programac?o seguinte e o itervalo entre a proxima Programac?o depois da cancelada e a anterior a cancelada,
         --se n?o houver continua a execuc?o
         begin
            select p.programacao_id
                 , p.eta
                 , p.etb
                 , p.ets
              into v_programacao_id
                 , v_eta
                 , v_etb
                 , v_ets
              from operporto.v$programacao p
             where p.berco_id = v_p.berco_id
               and p.status_id not in (3,4)
               and p.programacao_id <> v_p.programacao_id
               and p.etb > v_p.etb
               and not exists (
                  select 1
                    from operporto.v$programacao p1
                   where p1.etb between v_p.etb and p.etb
                     and p1.programacao_id <> p.programacao_id
                     and p1.programacao_id <> v_p.programacao_id
                     and p1.berco_id = p.berco_id
                     and p1.status_id not in (3,4)
               );
            --Atribui os novos valores de Data
            --v_eta:= v_eta - v_intervalo;
            v_etb:= v_etb - v_intervalo;
            v_ets:= v_ets - v_intervalo;
            --Quando o ETB e menor que a data atual, o ETA e ETB adianta ate a data atual
            if v_etb < trunc(sysdate) then
               v_diff_sys:= trunc(sysdate) - v_etb;
               v_intervalo := v_intervalo - v_diff_sys;
               --v_eta:= v_eta + v_diff_sys;
               v_etb:= trunc(sysdate-1);
               v_ets:= v_ets + v_diff_sys;
            end if;
         exception
            when no_data_found then
               null;
            when others then
               raise;
         end;

      end if;

      --Cancela a Programac?o
      operporto.pkg_schedule.prc_cancelar_programacao(p_programacao_id => i.programacao_id
                                                   , p_justificativa  => i.justificativa
                                                    );

      if trim(i.adiantar_prog) = 1 and v_programacao_id is not null then
         --Chamada da prc que adianta as Programac?es
         operporto.pkg_schedule.prc_adiantar_programacao(p_programacao_id => v_programacao_id
                                                      , p_etb            => v_etb
                                                      , p_ets            => v_ets
                                                      , p_intervalo      => v_intervalo
                                                      , p_sum            => v_sum
                                                       );
      end if;

      -- Notificac?o de cancelamento de programac?o
       /*recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                        , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                        , p_anexos    => null
                                        , p_email     => v_email_insert
                                         );*/

      for j in (
         select pge.grupo_email_id
           from operporto.v$programacao_grupo_email pge
          where pge.programacao_id = v_programacao_id
            and pge.ativo = 1
      ) loop
         recinto.pkg_email.prc_enviar_email(p_grupo_email_id => j.grupo_email_id
                                          , p_corpo          => v_email_insert
                                          , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                          , p_multipart      => 1
                                           );
      end loop;

      select xmlconcat(
                xmlelement("mensagem",        xmlattributes('string' as "type"), stringtojson('Programac?o cancelada com sucesso.')),
                xmlelement("programacao_id",  xmlattributes('number' as "type"), numbertojson(i.programacao_id)),
                xmlelement("prog_adiantadas", xmlattributes('string' as "type"), stringtojson(nvl(v_sum, 0) ||' Programac?es adiantadas.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_criar_os
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_os_id    operporto.v$ordem_servico.os_id%type;
 v_mensagem varchar2(1000);
 v_titulo   varchar2(100);
 v_email    clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id   integer       path '/params/programacao_id'
                 , data_abertura    varchar2(30)  path '/params/data_abertura'
                 , qtde             number        path '/params/qtde'
                 , embarcacao_id    integer       path '/params/embarcacao_id'
                 , agencia_id       integer       path '/params/agencia_id'
                 , programacao_appa varchar2(20)  path '/params/programacao_appa'
                 , observacao       varchar2(500) path '/params/observacao'
                )
   ) loop
      --Cria a OS na Controladoria
/*CONVERTER      operporto.pkg_control.prc_ins_ordem_servico(p_os_id            => v_os_id
                                                    , p_programacao_id   => i.programacao_id
                                                    , p_programacao_appa => i.programacao_appa
                                                    , p_data_abertura    => to_timestamp(i.data_abertura, 'yyyy-mm-dd"T"hh24:mi:ss.ff3"Z"')
                                                    , p_qtde             => i.qtde
                                                    , p_embarcacao_id    => i.embarcacao_id
                                                    , p_agencia_id       => i.agencia_id
                                                    , p_observacao       => i.observacao
                                                     );*/
      --Atualiza o status da Programac?o para "Em operac?o" e insere LOG-PROGRAMACAO indicando a existencia de uma OS
      operporto.pkg_schedule.prc_criar_os( p_programacao_id => i.programacao_id
                                        , p_os_id          => v_os_id
                                         );

      /*A principio o codigo comentado abaixo e desnecessario, pois a mesma validac?o e executada no pkg_control.prc_ins_ordem_servico
      --Atualiza COCKPIT com a OS criada e altera status da OS para "OK"
      select c.cockpit_id
        into v_cockpit_id
        from operporto.v$cockpit c
       where c.programacao_id = i.programacao_id;
      operporto.pkg_control.prc_alt_cockpit(p_cockpit_id   => v_cockpit_id
                                              , p_dt_atracacao => null
                                              , p_os_id        => v_os_id
                                              , p_os_status    => 3
                                               );*/


      -- notificac?o email
      select '<hr>ORDEM SERVICO >> '||v_os_id||' << <hr>'
           ||'Programac?o     : '||p.programacao_id||'<br/>'
           ||'Embarcac?o      : '||nvl(p.vessel_name,'TBN')||' <br/>'
           ||'Agencia         : '||(select e.descricao||' <br/>'
                                      from operporto.v$programacao_etiqueta pe
                                     inner join operporto.v$etiqueta e
                                        on e.etiqueta_id = pe.etiqueta_id
                                       and e.tipo_id = 2
                                     where pe.programacao_id = p.programacao_id)
           ||'Quantidade total: '|| to_char(p.qtde_total,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')|| 'ton<hr>'
           ||'Periodo previsto:<br/><ul>'
           ||'- ETA: '||to_char(p.eta, 'dd/mm/yyyy')||'<br/>'
           ||'- ETB: '||to_char(p.etb, 'dd/mm/yyyy')||'<br/>'
           ||'- ETS: '||to_char(p.ets, 'dd/mm/yyyy')||'</ul><hr>'
           ||'Importadores:<br/><ul>'
           ||(select kss.fnc_concat_all(kss.to_concat_expr(('- '||e.descricao || ' | '|| c.descricao||' | ' || to_char(pe.qtde_descarga,'999G999G990D999','NLS_NUMERIC_CHARACTERS='',.''')||'ton'),'<br/>'))
                from operporto.v$programacao_etiqueta pe
               inner join operporto.v$etiqueta e
                  on e.etiqueta_id = pe.etiqueta_id
                 and e.tipo_id = 3
               inner join recinto.v$produto_categoria c
                  on c.categoria_id = pe.categoria_id
               where pe.programacao_id = p.programacao_id)||'</ul><hr>'
           ||'Informac?o gerada em '||to_char(sysdate,'dd/mm/yyyy hh24:mi:ss')
           , 'Ordem de Servico / Embarcac?o: '||nvl(p.vessel_name,'TBN')||' / ETB: '||to_char(p.etb, 'dd/mm/yyyy')
        into v_mensagem
           , v_titulo
        from operporto.v$programacao p
       where p.programacao_id = i.programacao_id;

      /*recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                        , p_corpo     => translate(v_mensagem,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                        , p_anexos    => null
                                        , p_email     => v_email
                                         );*/

      for j in (
         select pge.grupo_email_id
           from operporto.v$programacao_grupo_email pge
          where pge.programacao_id = i.programacao_id
            and pge.ativo = 1
      ) loop
         recinto.pkg_email.prc_enviar_email(p_grupo_email_id => j.grupo_email_id
                                          , p_corpo          => v_email
                                          , p_titulo         => translate(v_titulo,'c?aaeei?ouC?AAEEI?OU','caaaeeioouCAAAEEIOOU')
                                          , p_multipart      => 1
                                           );
      end loop;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('O.S. criada com sucesso. Cockpit atualizado.')),
                xmlelement("os_id",    xmlattributes('number' as "type"), numbertojson(v_os_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_enviar_email_notify
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_email clob;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   mensagem varchar2(1000) path '/params/mensagem'
                 , titulo   varchar2(100)  path '/params/titulo'
                 , anexos   xmltype        path '/params/anexos'
                 , grupos   xmltype        path '/params/grupos'
                )
   ) loop
      /*recinto.pkg_email.prc_prepara_email(p_modelo_id => 3
                                        , p_corpo     => i.mensagem
                                        , p_anexos    => i.anexos
                                        , p_email     => v_email
                                         );*/

      for j in (
         select *
           from xmltable('/grupos/arrayItem' passing i.grupos
                   columns
                      grupo_email_id integer path '/arrayItem/grupo_email_id'
                   )
      ) loop
         recinto.pkg_email.prc_enviar_email(p_grupo_email_id => j.grupo_email_id
                                          , p_corpo          => v_email
                                          , p_titulo         => i.titulo
                                          , p_multipart      => 1
                                           );
      end loop;

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Notificac?o enviada com sucesso.'))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alterar_os
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   os_id            integer       path '/params/os_id'
                 , programacao_id   integer       path '/params/programacao_id'
                 , programacao_appa varchar2(20)  path '/params/programacao_appa'
                 , data_abertura    varchar2(30)  path '/params/data_abertura'
                 , qtde             number        path '/params/qtde'
                 , embarcacao_id    integer       path '/params/embarcacao_id'
                 , agencia_id       integer       path '/params/agencia_id'
                 , observacao       varchar2(500) path '/params/observacao'
                )
   ) loop
/*CONVERTER      operporto.pkg_control.prc_alt_ordem_servico(p_os_id            => i.os_id
                                                    , p_programacao_id   => i.programacao_id
                                                    , p_programacao_appa => i.programacao_appa
                                                    , p_data_abertura    => to_date(i.data_abertura, 'yyyy-mm-dd hh24:mi:ss')
                                                    , p_qtde             => i.qtde
                                                    , p_embarcacao_id    => i.embarcacao_id
                                                    , p_agencia_id       => i.agencia_id
                                                    , p_observacao       => i.observacao
                                                     );*/
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('O.S. alterada com sucesso.')),
                xmlelement("os_id",    xmlattributes('number' as "type"), numbertojson(i.os_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_alterar_os_encerrada
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   os_id          integer        path '/params/os_id'
                 , programacao_id integer        path '/params/programacao_id'
                 , data_abertura  varchar2(30)   path '/params/data_abertura'
                 , qtde           number         path '/params/qtde'
                 , embarcacao_id  integer        path '/params/embarcacao_id'
                 , agencia_id     integer        path '/params/agencia_id'
                 , observacao     varchar2(500)  path '/params/observacao'
                 , justificativa  varchar2(4000) path '/params/motivo'
                )
   ) loop
/*CONVERTER      operporto.pkg_control.prc_alt_os_encerrada(p_os_id          => i.os_id
                                                   , p_programacao_id => i.programacao_id
                                                   , p_data_abertura  => to_date(i.data_abertura, 'yyyy-mm-dd hh24:mi:ss')
                                                   , p_qtde           => i.qtde
                                                   , p_status_id      => 1
                                                   , p_embarcacao_id  => i.embarcacao_id
                                                   , p_agencia_id     => i.agencia_id
                                                   , p_observacao     => i.observacao
                                                   , p_justificativa  => i.justificativa
                                                    );*/
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('O.S. alterada com sucesso.')),
                xmlelement("os_id",    xmlattributes('number' as "type"), numbertojson(i.os_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_cancelar_os
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_cockpit_id operporto.v$cockpit.cockpit_id%type;
 v_log_id     integer;
 v_os_id      integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   programacao_id integer        path '/params/programacao_id'
                 , justificativa  varchar2(4000) path '/params/motivo'
                )
   ) loop
      select o.os_id
        into v_os_id
        from operporto.v$ordem_servico o
       where o.programacao_id = i.programacao_id
         and o.status_id = 1;

      -- Cancela OS na Controladoria
/*CONVERTER      operporto.pkg_control.prc_cancel_ordem_servico(p_os_id         => v_os_id
                                                       , p_justificativa => i.justificativa
                                                       , p_log_id        => v_log_id
                                                        );*/

      --Atualiza o status da PROGRAMAC?O para o anterior "Aprovado".
      operporto.pkg_schedule.prc_cancelar_os(p_programacao_id => i.programacao_id
                                          , p_os_id          => v_os_id
                                           );

      --Atualiza o COCKPIT com a OS removida e altera status da OS para "Aguardando"
      select c.cockpit_id
        into v_cockpit_id
        from operporto.v$cockpit c
       where c.programacao_id = i.programacao_id;
/*CONVERTER      operporto.pkg_control.prc_alt_cockpit(p_cockpit_id   => v_cockpit_id
                                              , p_dt_atracacao => null
                                              , p_os_id        => null
                                              , p_os_status    => 1
                                               );*/

      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('O.S. cancelada.')),
                xmlelement("os_id",    xmlattributes('number' as "type"), numbertojson(v_os_id)),
                xmlelement("log_id",   xmlattributes('number' as "type"), numbertojson(v_log_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_encerrar_os
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
 v_log_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   os_id          integer path '/params/os_id'
                 , programacao_id integer path '/params/programacao_id'
                )
   ) loop
/*CONVERTER      operporto.pkg_control.prc_encerrar_ordem_servico(p_os_id  => i.os_id
                                                         , p_log_id => v_log_id
                                                          );*/

      operporto.pkg_schedule.prc_encerrar_programacao(p_programacao_id => i.programacao_id
                                                   , p_os_id          => i.os_id
                                                    );
      select xmlconcat(
                xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('O.S. encerrada.')),
                xmlelement("os_id",    xmlattributes('number' as "type"), numbertojson(i.os_id)),
                xmlelement("log_id",   xmlattributes('number' as "type"), numbertojson(v_log_id))
             )
        into p_result
        from dual;
   end loop;
end;

procedure prc_ins_log_manual
 (p_parameters in  xmltype
 ,p_result     out xmltype
 ) is
v_log_id integer;
begin
   for i in (
      select *
        from xmltable('/params' passing p_parameters
                columns
                   descricao varchar2(4000) path '/params/descricao'
                 , origem    varchar2(100)  path '/params/origem'
                 , id        integer        path '/params/id'
                 , evento_id integer        path '/params/evento_id'
                 , macro     varchar2(30)   path '/params/macro'
                )
   ) loop
      if trim(i.macro) is not null then
         case
            when upper(i.macro) = 'SCHEDULE' then
               operporto.pkg_schedule.prc_ins_sch_log_manual(p_log_id    => v_log_id
                                                          , p_descricao => i.descricao
                                                          , p_origem    => i.origem
                                                          , p_id        => i.id
                                                           );
               select xmlconcat(
                         xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Ocorrencia manual inserida com sucesso.')),
                         xmlelement("log_id",   xmlattributes('number' as "type"), numbertojson(v_log_id))
                      )
                 into p_result
                 from dual;

            when upper(i.macro) = 'HIDROVIARIO' then
                operporto.pkg_operporto.prc_ins_hid_log_manual(p_log_id    => v_log_id
                                                             , p_descricao => i.descricao
                                                             , p_origem    => i.origem
                                                             , p_id        => i.id
                                                              );
               select xmlconcat(
                         xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Ocorrencia manual inserida com sucesso.')),
                         xmlelement("log_id",   xmlattributes('number' as "type"), numbertojson(v_log_id))
                      )
                 into p_result
                 from dual;

            when upper(i.macro) = 'PROGRAMACAO' then
               operporto.pkg_schedule.prc_ins_prg_log_manual(p_log_id         => v_log_id
                                                          , p_descricao      => i.descricao
                                                          , p_evento_id      => i.evento_id
                                                          , p_programacao_id => i.id
                                                           );
               select xmlconcat(
                         xmlelement("mensagem", xmlattributes('string' as "type"), stringtojson('Ocorrencia manual inserida com sucesso na programac?o.')),
                         xmlelement("log_id",   xmlattributes('number' as "type"), numbertojson(v_log_id))
                      )
                 into p_result
                 from dual;

            else
               kss.pkg_mensagem.prc_dispara_msg('M5005-30113');
               /*raise_application_error(-20000,'Falha ao inserir Ocorrencia Manual'||chr(13)||chr(10)||
                                              'CAUSA:'||chr(13)||chr(10)||
                                              'Seletor de macro n?o corresponde com o esperado'||chr(13)||chr(10)||
                                              'ACAO:'||chr(13)||chr(10)||
                                              'Preencher o parametro <macro> com "SCHEDULE", "HIDROVIARIO" ou "PROGRAMACAO"'||chr(10)||chr(10)); */
         end case;
      else
         kss.pkg_mensagem.prc_dispara_msg('M5005-30114');
         /*raise_application_error(-20000,'Falha ao inserir Ocorrencia Manual'||chr(13)||chr(10)||
                                        'CAUSA:'||chr(13)||chr(10)||
                                        'Seletor de macro n?o informado'||chr(13)||chr(10)||
                                        'ACAO:'||chr(13)||chr(10)||
                                        'Preencher o parametro <macro> com "SCHEDULE", "HIDROVIARIO" ou "PROGRAMACAO"'||chr(10)||chr(10));*/
      end if;
   end loop;
end;

procedure prc_module_gateway
(p_operation  in varchar2
,p_parameters in xmltype
,p_result     out xmltype
) as
begin
   case p_operation
      when 'getTipoEtiqueta' then
         p_result := fnc_get_tipo_etiqueta(p_parameters => p_parameters);
      when 'getBerco' then
         p_result := fnc_get_berco(p_parameters => p_parameters);
      when 'cadBerco' then
         prc_cad_berco(p_parameters => p_parameters
                      ,p_result     => p_result
                      );
      when 'getProgramacaoStatus' then
         p_result := fnc_get_prog_status(p_parameters => p_parameters);
      when 'getProgramacaoEtapa' then
         p_result := fnc_get_prog_etapa(p_parameters => p_parameters);
      when 'getEmbarcacaoAnexo' then
         p_result := fnc_get_embarcacao_anexo(p_parameters => p_parameters);
      when 'getArquivoEmbarcacao' then
         p_result := fnc_get_embarcacao_blob(p_parameters => p_parameters);
      when 'getEmbarcacao' then
         p_result := fnc_get_embarcacao(p_parameters => p_parameters);
      when 'getPoraoEmbarcacao' then
         p_result := fnc_get_porao_embarcacao(p_parameters => p_parameters);
      when 'getEmbarcacaoStatus' then
         p_result := fnc_get_embarc_status(p_parameters => p_parameters);
      when 'cadEmbarcacao' then
         prc_cad_embarcacao(p_parameters => p_parameters
                           ,p_result     => p_result
                           );
      when 'getPais' then
         p_result := fnc_get_pais(p_parameters => p_parameters);
      when 'getCategoria' then
         p_result := fnc_get_produto_categoria(p_parameters => p_parameters);
      /*
      when 'cadCategoria' then
         prc_cad_categoria(p_parameters => p_parameters
                          ,p_result     => p_result);
      */
      when 'getEtiqueta' then
         p_result := fnc_get_etiqueta(p_parameters => p_parameters);
      when 'cadEtiqueta' then
         prc_cad_etiqueta(p_parameters => p_parameters
                         ,p_result     => p_result);
      when 'getBudgetInfo' then
         p_result := fnc_get_budget_info(p_parameters => p_parameters);
      when 'getBudget' then
         p_result := fnc_get_budget(p_parameters => p_parameters);
      when 'cadBudget' then
         prc_cad_budget(p_parameters => p_parameters
                       ,p_result     => p_result
                       );
      when 'getManutencao' then
         p_result := fnc_get_manutencao(p_parameters => p_parameters);
      when 'getProgramacaoEtiqueta' then
         p_result := fnc_get_programacao_etiqueta(p_parameters => p_parameters);
      when 'getProgramacaoGrupoEmail' then
         p_result := fnc_get_prog_grupo_email(p_parameters => p_parameters);
      when 'getProgramacao' then
         p_result := fnc_get_programacao(p_parameters => p_parameters);
      when 'getCardsSchedule' then
         p_result := fnc_get_cards_schedule(p_parameters => p_parameters);
      when 'getLineup' then
         p_result := fnc_get_lineup(p_parameters => p_parameters);
      when 'getLineupProduto' then
         p_result := fnc_get_lineup_produto;
      when 'getNextProgramacao' then
         p_result := fnc_get_next_programacao(p_parameters => p_parameters);
      when 'getPorto' then
         p_result := fnc_get_porto(p_parameters => p_parameters);
      when 'cadPorto' then
         prc_cad_porto(p_parameters => p_parameters
                       ,p_result     => p_result);
      when 'getRestricao' then
         p_result := fnc_get_restricao(p_parameters => p_parameters);
      when 'cadRestricao' then
         prc_cad_restricao(p_parameters => p_parameters
                       ,p_result     => p_result);
      when 'getTipoEmbarcacao' then
         p_result := fnc_get_tipo_embarcacao(p_parameters => p_parameters);
      when 'cadTipoEmbarcacao' then
         prc_cad_tipo_embarcacao(p_parameters => p_parameters
                       ,p_result     => p_result);
      when 'getMecanismoAberturaTampa' then
         p_result := fnc_get_mec_abertura_tampa(p_parameters => p_parameters);
      when 'cadMecanismoAberturaTampa' then
         prc_cad_mec_abertura_tampa(p_parameters => p_parameters
                       ,p_result     => p_result
                       );
      when 'getTipoPorao' then
         p_result := fnc_get_tipo_porao(p_parameters => p_parameters);
      when 'cadTipoPorao' then
         prc_cad_tipo_porao(p_parameters => p_parameters
                           ,p_result     => p_result
                           );
      when 'getPorao' then
         p_result := fnc_get_porao(p_parameters => p_parameters);
      when 'getLogRestricaoProgramacao' then
         p_result := fnc_get_logs_restricao_prog(p_parameters => p_parameters);
      when 'getLogEtiqueta' then
         p_result := fnc_get_log_etiqueta(p_parameters => p_parameters);
      when 'getLogRestricao' then
         p_result := fnc_get_log_restricao(p_parameters => p_parameters);
      when 'getLogBudget' then
         p_result := fnc_get_log_budget(p_parameters => p_parameters);
       when 'getLogManutencao' then
         p_result := fnc_get_log_manutencao(p_parameters => p_parameters);
      when 'getLogProgramacaoEtiqueta' then
         p_result := fnc_get_log_prog_etiqueta(p_parameters => p_parameters);
      when 'getLogProgramacao' then
         p_result := fnc_get_log_programacao(p_parameters => p_parameters);
      when 'getLogPorto' then
         p_result := fnc_get_log_porto(p_parameters => p_parameters);
      when 'getLogTipoEmbarcacao' then
         p_result := fnc_get_log_tipo_embarcacao(p_parameters => p_parameters);
      when 'getLogTipoPorao' then
         p_result := fnc_get_log_tipo_porao(p_parameters => p_parameters);
      when 'getLogMecanismoAberturaTampa' then
         p_result := fnc_get_log_mec_abertura_tampa(p_parameters => p_parameters);
      when 'getLogEmbarcacao' then
         p_result := fnc_get_log_embarcacao(p_parameters => p_parameters);
      when 'getLogPorao' then
         p_result := fnc_get_log_porao(p_parameters => p_parameters);
      when 'getLogCategoria' then
         p_result := fnc_get_log_produto_categoria(p_parameters => p_parameters);
      when 'getLogBerco' then
         p_result := fnc_get_log_berco(p_parameters => p_parameters);
      when 'getLogsModulo' then
         p_result := fnc_get_log_modulo(p_parameters => p_parameters);
      when 'insEmbarcacao' then
         prc_ins_embarcacao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'altEmbarcacao' then
         prc_alt_embarcacao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'aprovaEmbarcacao' then
         prc_aprova_embarcacao(p_parameters => p_parameters
                             , p_result     => p_result
                              );
      when 'liberarRestricaoTP' then
         prc_libera_tp(p_parameters => p_parameters
                     , p_result     => p_result
                      );
      when 'liberarRestricaoMAT' then
         prc_libera_mat(p_parameters => p_parameters
                      , p_result     => p_result
                       );
      when 'reprovaEmbarcacao' then
         prc_reprova_embarcacao(p_parameters => p_parameters
                              , p_result     => p_result
                               );
      when 'insPorto' then
         prc_ins_porto(p_parameters => p_parameters
                     , p_result     => p_result
                      );
      when 'altPorto' then
         prc_alt_porto(p_parameters => p_parameters
                     , p_result     => p_result
                      );
      when 'altAtivoPorto' then
         prc_alt_ativo_porto(p_parameters => p_parameters
                           , p_result     => p_result
                           );
      when 'delPorto' then
         prc_del_porto(p_parameters => p_parameters
                     , p_result     => p_result
                      );
      when 'insTipoEmbarcacao' then
         prc_ins_tipo_embarcacao(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'altTipoEmbarcacao' then
         prc_alt_tipo_embarcacao(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'altAtivoTipoEmbarcacao' then
         prc_alt_ativo_tipo_embarcacao(p_parameters => p_parameters
                                      , p_result     => p_result
                                      );
      when 'delTipoEmbarcacao' then
         prc_del_tipo_embarcacao(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'insCategoria' then
         prc_ins_categoria(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'altCategoria' then
         prc_alt_categoria(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'altAtivoCategoria' then
         prc_alt_ativo_categoria(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'delCategoria' then
         prc_del_categoria(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'insEtiqueta' then
         prc_ins_etiqueta(p_parameters => p_parameters
                        , p_result     => p_result
                         );
      when 'altEtiqueta' then
         prc_alt_etiqueta(p_parameters => p_parameters
                        , p_result     => p_result
                         );
      when 'altAtivoEtiqueta' then
         prc_alt_ativo_etiqueta(p_parameters => p_parameters
                              , p_result     => p_result
                              );
      when 'delEtiqueta' then
         prc_del_etiqueta(p_parameters => p_parameters
                        , p_result     => p_result
                         );
      when 'insRestricao' then
         prc_ins_restricao(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'altRestricao' then
         prc_alt_restricao(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'ativarRestricao' then
         prc_ativar_restricao(p_parameters => p_parameters
                            , p_result     => p_result
                             );
      when 'desativarRestricao' then
         prc_desativar_restricao(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'delRestricao' then
         prc_del_restricao(p_parameters => p_parameters
                         , p_result     => p_result
                          );
      when 'insManutencao' then
         prc_ins_manutencao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'altManutencao' then
         prc_alt_manutencao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'delManutencao' then
         prc_del_manutencao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'insMecanismoAberturaTampa' then
         prc_ins_mec_abertura_tampa(p_parameters => p_parameters
                                  , p_result     => p_result
                                   );
      when 'altMecanismoAberturaTampa' then
         prc_alt_mec_abertura_tampa(p_parameters => p_parameters
                     	            , p_result     => p_result
                                   );
      when 'altAtivoMecanismoAberturaTampa' then
         prc_alt_ativo_mecanismo_tampa(p_parameters => p_parameters
                     	               , p_result     => p_result
                                      );
      when 'delMecanismoAberturaTampa' then
         prc_del_mec_abertura_tampa(p_parameters => p_parameters
                                  , p_result     => p_result
                                   );
      when 'insTipoPorao' then
         prc_ins_tipo_porao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'altTipoPorao' then
         prc_alt_tipo_porao(p_parameters => p_parameters
                     	    , p_result     => p_result
                           );
      when 'altAtivoTipoPorao' then
         prc_alt_ativo_tipo_porao(p_parameters => p_parameters
                     	          , p_result     => p_result
                                 );
      when 'delTipoPorao' then
         prc_del_tipo_porao(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      when 'insProgramacao' then
         prc_ins_programacao(p_parameters => p_parameters
                           , p_result     => p_result
                            );
      when 'altProgramacao' then
         prc_alt_programacao(p_parameters => p_parameters
                           , p_result     => p_result
                            );
      when 'liberarRestricao' then
         prc_libera_prog_restricao(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'cancelarProgramacao' then
         prc_cancelar_programacao(p_parameters => p_parameters
                                , p_result     => p_result
                                 );
      when 'atrasarProgramacao' then
         prc_atrasar_programacoes(p_parameters => p_parameters
                                , p_result     => p_result
                                 );
      when 'criarOS' then
         prc_criar_os(p_parameters => p_parameters
                    , p_result     => p_result
                     );
      when 'enviarEmailNotificacao' then
         prc_enviar_email_notify(p_parameters => p_parameters
                               , p_result     => p_result
                                );
      when 'alterarOS' then
         prc_alterar_os(p_parameters => p_parameters
                      , p_result     => p_result
                       );
      when 'alterarOSEncerrada' then
         prc_alterar_os_encerrada(p_parameters => p_parameters
                                , p_result     => p_result
                                 );
      when 'cancelarOS' then
         prc_cancelar_os(p_parameters => p_parameters
                       , p_result     => p_result
                        );
      when 'encerrarOS' then
         prc_encerrar_os(p_parameters => p_parameters
                       , p_result     => p_result
                        );
      when 'insOcorrenciaManual' then
         prc_ins_log_manual(p_parameters => p_parameters
                          , p_result     => p_result
                           );
      else
         raise_application_error(-20000, 'Operacao ' || p_operation || ' invalida');
   end case;
end;

end pkg_schedule_backend;