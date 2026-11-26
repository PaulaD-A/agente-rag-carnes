-- Configuración del Vector Store en Supabase (pgvector)
-- Ejecutar una vez en Supabase > SQL Editor.
-- Dimensión 3072 = modelo de embeddings gemini-embedding-001 de Google (dimensión por defecto).
-- Sin índice: pgvector no indexa vectores de más de 2000 dimensiones y, con pocos
-- documentos, la búsqueda exacta es suficientemente rápida.

create extension if not exists vector;

drop function if exists match_documents;
drop table if exists documents;

create table documents (
  id bigserial primary key,
  content text,          -- fragmento de texto (chunk)
  metadata jsonb,        -- fuente, documento, fecha de carga
  embedding vector(3072) -- gemini-embedding-001
);

-- Función de búsqueda por similitud que usa el nodo Supabase Vector Store de n8n
create or replace function match_documents (
  query_embedding vector(3072),
  match_count int default null,
  filter jsonb default '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- Para re-indexar la base de conocimiento desde cero (por ejemplo, al cambiar la lista de precios del mes):
-- truncate table documents;
