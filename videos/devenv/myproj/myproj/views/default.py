from pyramid.view import view_config
import psycopg2

@view_config(route_name='home', renderer='myproj:templates/mytemplate.pt')
def my_view(request):
    conn = psycopg2.connect(
        host="/tmp/",
        database="mydb",
    )
    cur = conn.cursor()
    cur.execute("SELECT version()")
    pg_version = cur.fetchone()
    return {'project': 'myproj', 'pg_version': pg_version}
