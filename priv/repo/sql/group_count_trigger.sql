CREATE FUNCTION counter(table_name text, column_name text, id integer, step integer)
 RETURNS VOID AS $$
   DECLARE
     table_name text := quote_ident(table_name);
     column_name text := quote_ident(column_name);
     conditions text := ' WHERE id = $1';
     updates text := column_name || '=' || column_name || '+' || step;
   BEGIN
     EXECUTE 'UPDATE ' || table_name || ' SET ' || updates || conditions
     USING id;
   END;
 $$ LANGUAGE plpgsql;

--statement--

CREATE FUNCTION counter_cache()
 RETURNS trigger AS $$
   DECLARE
     table_name text := quote_ident(TG_ARGV[0]);
     counter_name text := quote_ident(TG_ARGV[1]);
     fk_name text := quote_ident(TG_ARGV[2]);
     fk_changed boolean := false;
     fk_value integer;
     record record;
   BEGIN
     IF TG_OP = 'UPDATE' THEN
       record := NEW;
       EXECUTE 'SELECT ($1).' || fk_name || ' != ' || '($2).' || fk_name
       INTO fk_changed
       USING OLD, NEW;
     END IF;

     IF TG_OP = 'DELETE' OR fk_changed THEN
       record := OLD;
       EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
       PERFORM counter(table_name, counter_name, fk_value, -1);
     END IF;

     IF TG_OP = 'INSERT' OR fk_changed THEN
       record := NEW;
       EXECUTE 'SELECT ($1).' || fk_name INTO fk_value USING record;
       PERFORM counter(table_name, counter_name, fk_value, 1);
     END IF;

     RETURN record;
   END;
 $$ LANGUAGE plpgsql;

--statement--

CREATE TRIGGER update_group_tasks_count
 AFTER INSERT OR UPDATE OR DELETE ON tasks_groups
 FOR EACH ROW EXECUTE PROCEDURE counter_cache('groups', 'tasks_count', 'group_id');

--statement--

CREATE TRIGGER update_group_users_count
  AFTER INSERT OR UPDATE OR DELETE ON users_groups
  FOR EACH ROW EXECUTE PROCEDURE counter_cache('groups', 'users_count', 'group_id');
