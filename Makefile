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

update-gen:
	docker compose exec -w /core gen rm -r src
	docker compose cp ./generator/src gen:core

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