start:
	docker compose up -d
	docker compose run --rm server create_db
	docker compose exec -w /core gen python -m alembic upgrade head

rebuild-gen:
	docker rm da-gen-1 -f
	docker image rm da-gen -f
	docker compose up gen -d

stop-gen:
	docker compose pause gen

continue-gen:
	docker compose unpause gen

update-db:
	docker compose exec -w /core gen python -m alembic upgrade head

update-pkgs:
	docker compose cp ./generator/requirements.txt gen:/core
	docker compose exec -w /core gen pip install -r requirements.txt
	docker compose restart gen

new-migr:
	docker compose exec -w /core gen python -m alembic revision --autogenerate -m "$(name)"
	docker compose cp gen:/core/src/migrations/versions ./generator/src/migrations

see-db:
	docker compose exec db psql -U postgres

see-db-redash:
	docker compose exec db psql -U redash -d redash

see-gen:
	docker compose logs -f gen --since $(time)

dump:
	docker compose exec db sh -c 'pg_dump --username=postgres -d postgres > /dumps/$$(date +"%Y-%m-%d_%H-%M-%S").dump'
	docker compose exec db sh -c 'pg_dump --username=postgres -d redash > /redash_dumps/$$(date +"%Y-%m-%d_%H-%M-%S").dump'

restore-redash:
	@if [ -z "$(file)" ]; then echo "Specify dump file: make restore-redash file=YYYY-MM-DD_HH-MM-SS.dump"; exit 1; fi
	docker compose stop server worker
	docker compose exec db sh -c 'psql --username=postgres -v ON_ERROR_STOP=1 -d redash -f /redash_dumps/$(file)'
	docker compose start server worker

restore-postgres:
	@if [ -z "$(file)" ]; then echo "Specify dump file: make restore-postgres file=YYYY-MM-DD_HH-MM-SS.dump"; exit 1; fi
	docker compose exec db sh -c 'psql --username=postgres -v ON_ERROR_STOP=1 -d postgres -f /dumps/$(file)'

# make reset-redash-schema file=YYYY-MM-DD_HH-MM-SS.dump
reset-redash-schema:
	@if [ -z "$(file)" ]; then echo "Specify dump file: make reset-redash-schema file=YYYY-MM-DD_HH-MM-SS.dump"; exit 1; fi
	docker compose stop server worker

	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='redash' AND pid <> pg_backend_pid();\""

	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -d redash -c \"DROP SCHEMA IF EXISTS public CASCADE;\""
	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -d redash -c \"CREATE SCHEMA public;\""
	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -d redash -c \"GRANT ALL ON SCHEMA public TO redash; GRANT ALL ON SCHEMA public TO public;\""

	docker compose exec db sh -c 'psql --username=postgres -v ON_ERROR_STOP=1 -d redash -f /redash_dumps/$(file)'
	docker compose start server worker

# make reset-redash-db file=YYYY-MM-DD_HH-MM-SS.dump
reset-redash-db:
	@if [ -z "$(file)" ]; then echo "Specify dump file: make reset-redash-db file=YYYY-MM-DD_HH-MM-SS.dump"; exit 1; fi
	docker compose stop server worker

	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='redash' AND pid <> pg_backend_pid();\""
	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -c \"DROP DATABASE IF EXISTS redash;\""

	docker compose exec db sh -c "psql -U postgres -v ON_ERROR_STOP=1 -c \"CREATE DATABASE redash OWNER redash;\""

	docker compose exec db sh -c 'psql --username=postgres -v ON_ERROR_STOP=1 -d redash -f /redash_dumps/$(file)'
	docker compose start server worker