## описание

простая end-toend система, которая генерирует данные, сохраняет их и позволяет анализировать через redash и jupyter notebook.

## требования

- **gnu make**
- **docker compose**

## пайплайн

1. make start
2. make reset-redash-db file=main.sql
3. посмотреть дашборд: http://127.0.0.1:8052/dashboard/dash

## кейсы

1. если потребуется авторизация в redash, то учетные данные такие:
    - почта: admin@gmail.com
    - пароль: 1u2u3u4u

## команды

- ребилд (обновление) генератора: **make rebuild-gen**
- остановка генератора: **make stop-gen**
- восстановление работы генератора: **make continue-gen**
- просмотр логов генератора: **make see-gen time=1h**
- дамп бд: **make dump**