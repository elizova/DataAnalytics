start:
	docker compose up -d
	docker compose run --rm server create_db

update-db:
	docker compose -f docker-compose.yml exec -w /core api python -m alembic upgrade head

update-pkgs:
	docker compose -f docker-compose.yml cp ./generator/requirements.txt generator:/core
	docker compose -f docker-compose.yml exec -w /generator api pip install -r requirements.txt
	docker compose -f docker-compose.yml restart generator

new-migr:
	docker compose -f docker-compose.yml cp ./generator/database api:/core/src
	docker compose -f docker-compose.yml exec -w /generator api python -m alembic revision --autogenerate -m "$(name)"
	docker compose -f docker-compose.yml cp api:/core/database/migrations/versions ./generator/database/migrations

see-db:
	docker compose -f docker-compose.yml exec db psql -U postgres

see-db-redash:
	docker compose -f docker-compose.yml exec db psql -U redash -d redash

see-gen:
	docker compose -f docker-compose.yml logs -f generator --since $(time)

dump:
	docker compose -f docker-compose.yml exec db sh -c 'pg_dump --username=postgres -d postgres > /dumps/$$(date +"%Y-%m-%d_%H-%M-%S").dump'
	docker compose -f docker-compose.yml exec db sh -c 'pg_dump --username=postgres -d redash > /redash_dumps/$$(date +"%Y-%m-%d_%H-%M-%S").dump'